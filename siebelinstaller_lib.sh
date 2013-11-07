#!/bin/bash -e

prepare_host ()
{
  yum -y install zip unzip
  #TODO make the following dynamic
  echo 'export JAVA_HOME=/opt/jre1.7.0_45' >> /etc/profile
  echo 'export PATH=$PATH:$JAVA_HOME/bin' >> /etc/profile
  source /etc/profile
}

download_from_mos ()
{
  #Adaped from MOS wget script
 
  OLD_LANG=$LANG
  LANG=C
  export LANG

  if [ x"$MOS_PASSWORD" = x"CHANGE_ME" ] && [ x"$MOS_USERNAME" = x"foo@bar.com" ]
  then
    echo "Please set MOS_PASSWORD and MOS_USERNAME in config.local file" 1>&2
    exit 1
  fi

  echo "Downloading from MOS: $1"
  source $SCRIPT_ROOT/products/$1.info

  WGET="/usr/bin/wget --no-check-certificate"
  COOKIE_FILE=/tmp/$$.cookies
  LOGDIR=.
  LOGFILE=$SCRIPT_ROOT/log/wgetlog-$1.log
  OUTPUT_DIR=$SCRIPT_ROOT/downloads/$1
  mkdir -p $SCRIPT_ROOT/downloads/$1
  # Contact updates site so that we can get SSO Params for logging in
  SSO_RESPONSE=`$WGET --user-agent="Mozilla/5.0" https://updates.oracle.com/Orion/Services/download 2>&1|grep Location`

  # Extract request parameters for SSO
  SSO_TOKEN=`echo $SSO_RESPONSE| cut -d '=' -f 2|cut -d ' ' -f 1`
  SSO_SERVER=`echo $SSO_RESPONSE| cut -d ' ' -f 2|cut -d 'p' -f 1,2`
  SSO_AUTH_URL=sso/auth
  AUTH_DATA="ssousername=$MOS_USERNAME&password=$MOS_PASSWORD&site2pstoretoken=$SSO_TOKEN"

  $WGET --user-agent="Mozilla/5.0" --secure-protocol=auto --post-data $AUTH_DATA --save-cookies=$COOKIE_FILE --keep-session-cookies $SSO_SERVER$SSO_AUTH_URL -O sso.out >> $LOGFILE 2>&1

  rm -f sso.out

  for file in $FILES_LIST
  do
    file_url=$(eval "echo \$${file}_URL")
    file_name=$(eval "echo \$${file}_NAME")
    echo "Downloading file: $file_name"
    if [ -e $OUTPUT_DIR/$file_name ]
    then 
      echo "File $OUTPUT_DIR/$file_name already exists. Skipping ..."
    else
      $WGET --user-agent="Mozilla/5.0"  --load-cookies=$COOKIE_FILE --save-cookies=$COOKIE_FILE --keep-session-cookies $file_url -O $OUTPUT_DIR/$file_name >> $LOGFILE 2>&1
    fi
  done
  rm -f $COOKIE_FILE
  export LANG=$OLD_LANG
  return 0
}

download_and_unpack ()
{

  echo "Downloading : $1"
  source $SCRIPT_ROOT/products/$1.info

  WGET="/usr/bin/wget --no-check-certificate"
  LOGFILE=$SCRIPT_ROOT/log/wgetlog-$1.log
  OUTPUT_DIR=$SCRIPT_ROOT/downloads/$1
  mkdir -p $SCRIPT_ROOT/downloads/$1
  for file in $FILES_LIST
  do
    file_url=$(eval "echo \$${file}_URL")
    file_name=$(eval "echo \$${file}_NAME")
    file_dest_path=$(eval "echo \$${file}_TARGET_PATH")
    if [ -e $OUTPUT_DIR/$file_name ]
    then
      echo "File $OUTPUT_DIR/$file_name already exists. Skipping ..."
    else
      $WGET $file_url -O $OUTPUT_DIR/$file_name >> $LOGFILE 2>&1
    fi
    case $file_name in
      *.tar.gz)
        tar zxf $OUTPUT_DIR/$file_name -C $file_dest_path
        ;;
      *)
        echo "File extention unknown"
        ;;
    esac
  done
}

unpack_product  ()
{
  echo "Unpacking : $1"
  source $SCRIPT_ROOT/products/$1.info
  if [ -e $SCRIPT_ROOT/unpack/$1 ]
  then
    echo "File $SCRIPT_ROOT/unpack/$1 already exists. Skipping ..."
    return 0
  fi
  mkdir -p $SCRIPT_ROOT/unpack/$1

  for file in $FILES_LIST
  do
    file_url=$(eval "echo \$${file}_URL")
    file_name=$(eval "echo \$${file}_NAME")
    echo "Unpacking file: $file_name"
    unzip -o -q $SCRIPT_ROOT/downloads/$1/$file_name -d $SCRIPT_ROOT/unpack/$1/
  done
}

execute_once ()
{
  if [ ! -e $SCRIPT_ROOT/.status/$1_$2 ]
  then
    echo "Executing: $1 \"$2\""
    $1 "$2" >> $SCRIPT_ROOT/log/$1_$2.log && touch $SCRIPT_ROOT/.status/$1_$2
  else
    echo "Skipping execution of : $1 \"$2\" please remove $SCRIPT_ROOT/.status/$1_$2 if this is incorrect" 1>&2 >> $SCRIPT_ROOT/log/$1_$2.log
  fi
}

install_oracle ()
{
  #see http://www.oracle-base.com/articles/11g/oracle-db-11gr2-installation-on-oracle-linux-5.php

  if [ -e $ORACLE_HOME/oradata ]
  then
    echo "Oracle already installed. Skipping...."
    return 0
  fi
  cat $SCRIPT_ROOT/templates/oracle_sysctl_$ORACLE_VERSION.conf >> /etc/sysctl.conf
  /sbin/sysctl -p 2>&1
  cat $SCRIPT_ROOT/templates/oracle_limits_$ORACLE_VERSION.conf >> /etc/security/limits.conf
  yum -y install binutils compat-libstdc++-33 compat-libstdc++-33 elfutils-libelf gcc gcc-c++ glibc glibc-common glibc-devel glibc-headers ksh libaio libaio-devel libgomp libgcc libstdc++ libstdc++-devel make sysstat unixODBC unixODBC-devel numactl-devel xorg-x11-utils xauth elfutils-libelf-devel pdksh compat-libcap1
  groupadd oinstall
  groupadd dba
  groupadd oper

  useradd -g oinstall -G dba,oper oracle
  sed -i -e 's/^SELINUX=.*$/SELINUX=permissive/' /etc/selinux/config
  service iptables stop
  chkconfig iptables off
  mkdir -p $ORACLE_HOME
  chown -R oracle:oinstall $ORACLE_BASE
  chmod -R 775 $ORACLE_BASE
  cat >/home/oracle/.bash_profile <<EOF
# Oracle Settings
TMP=/tmp; export TMP
TMPDIR=\$TMP; export TMPDIR

ORACLE_HOSTNAME=localhost.localdomain; export ORACLE_HOSTNAME
ORACLE_UNQNAME=orcl; export ORACLE_UNQNAME
ORACLE_BASE=$ORACLE_BASE; export ORACLE_BASE
ORACLE_HOME=$ORACLE_HOME; export ORACLE_HOME
ORACLE_SID=orcl; export ORACLE_SID
PATH=/usr/sbin:\$PATH; export PATH
PATH=\$ORACLE_HOME/bin:\$PATH; export PATH

LD_LIBRARY_PATH=\$ORACLE_HOME/lib:/lib:/usr/lib; export LD_LIBRARY_PATH
CLASSPATH=\$ORACLE_HOME/jlib:\$ORACLE_HOME/rdbms/jlib; export CLASSPATH
EOF
  sed -i -e 's/^CV_ASSUME_DISTID=OEL4*$/CV_ASSUME_DISTID=OEL6/' $SCRIPT_ROOT/unpack/oracle_$ORACLE_VERSION/database/stage/cvu/cv/admin/cvu_config

  #TODO: fix response file
  sed "s,CHANGE_ME_ORACLE_BASE,$ORACLE_BASE," $SCRIPT_ROOT/templates/oracle_runInstaller_$ORACLE_VERSION.rsp > /tmp/oracle_runInstaller_$ORACLE_VERSION.rsp
  sed -i -e "s,CHANGE_ME_ORACLE_HOME,$ORACLE_HOME," /tmp/oracle_runInstaller_$ORACLE_VERSION.rsp 
  sed -i -e "s,CHANGE_ME_ORACLE_PASSWROD,$ORACLE_PASSWROD," /tmp/oracle_runInstaller_$ORACLE_VERSION.rsp 
  su -l oracle -c "$SCRIPT_ROOT/unpack/oracle_$ORACLE_VERSION/database/runInstaller -silent -waitforcompletion -responseFile /tmp/oracle_runInstaller_$ORACLE_VERSION.rsp"
  $ORACLE_BASE/oraInventory/orainstRoot.sh
  $ORACLE_HOME/root.sh
  sed "s,CHANGE_ME_ORACLE_HOME,$ORACLE_HOME," templates/oracle_$ORACLE_VERSION.dbora > /etc/init.d/dbora
  chkconfig --add dbora
  sed -i -e "s,^orcl:$ORACLE_HOME:N,orcl:$ORACLE_HOME:Y," /etc/oratab
  touch /var/lock/subsys/dbora

}

create_siebel_install_image ()
{
  if [ ! -e $SCRIPT_ROOT/unpack/siebel_install_image_$1 ]
  then 
    source /etc/profile
    cp $SCRIPT_ROOT/templates/snic_${1}.rsp $SCRIPT_ROOT/unpack/$1/
    sed -i -e "s,CHANGE_ME,$SCRIPT_ROOT/unpack/siebel_install_image_$1," $SCRIPT_ROOT/unpack/$1/snic_${1}.rsp
    OLD_LANG=$LANG
    export LANG=C
    echo "" | $SCRIPT_ROOT/unpack/$1/snic.sh -silent -responseFile $SCRIPT_ROOT/unpack/$1/snic_${1}.rsp > $SCRIPT_ROOT/log/create_siebel_install_image_${1}.log
    export LANG=$OLD_LANG
  else
    echo "Siebel Install Image $SCRIPT_ROOT/unpack/siebel_install_image_$1 exists. Skipping ..."
  fi
}

install_siebel_enterprise_server ()
{
  #TODO use own oraInventory
  yum -y install glibc.i686 libXmu.i686 libXtst.i686  libstdc++.x86_64 libstdc++.i686  compat-libstdc++-33.i686 compat-libstdc++-33.x86_64
  groupadd siebel

  useradd -g siebel -G siebel,oinstall siebel
  mkdir -p $SIEBEL_BASE
  chown -R siebel:siebel $SIEBEL_BASE
  cat >/home/siebel/.bash_profile <<EOF
# Oracle Settings
TMP=/tmp; export TMP
TMPDIR=\$TMP; export TMPDIR
ORACLE_BASE=$SIEBEL_BASE/oracle_client; export ORACLE_BASE
ORACLE_HOME=$SIEBEL_BASE/oracle_client/client; export ORACLE_HOME
ORACLE_SID=orcl; export ORACLE_SID
PATH=/usr/sbin:\$PATH; export PATH
PATH=\$ORACLE_HOME/bin:\$PATH; export PATH
LD_LIBRARY_PATH=\$ORACLE_HOME/lib:/lib:/usr/lib; export LD_LIBRARY_PATH
RESOLV_MULTI=off ; export RESOLV_MULTI
EOF
  cp $SCRIPT_ROOT/templates/install_siebel_enterprise_server_$SIEBEL_VERSION.rsp $SCRIPT_ROOT/unpack/siebel_install_image_siebel_linux_$SIEBEL_VERSION/$SIEBEL_VERSION/Linux/Server/Siebel_Enterprise_Server/Disk1/install/
  sed -i -e "s,CHANGE_ME_INSTALL_IMAGE,$SCRIPT_ROOT/unpack/siebel_install_image_siebel_linux_$SIEBEL_VERSION/$SIEBEL_VERSION," $SCRIPT_ROOT/unpack/siebel_install_image_siebel_linux_$SIEBEL_VERSION/$SIEBEL_VERSION/Linux/Server/Siebel_Enterprise_Server/Disk1/install/install_siebel_enterprise_server_$SIEBEL_VERSION.rsp
  sed -i -e "s,CHANGE_ME_SIEBEL_BASE,$SIEBEL_BASE," $SCRIPT_ROOT/unpack/siebel_install_image_siebel_linux_$SIEBEL_VERSION/$SIEBEL_VERSION/Linux/Server/Siebel_Enterprise_Server/Disk1/install/install_siebel_enterprise_server_$SIEBEL_VERSION.rsp
  echo "" | su -l siebel -c "$SCRIPT_ROOT/unpack/siebel_install_image_siebel_linux_$SIEBEL_VERSION/$SIEBEL_VERSION/Linux/Server/Siebel_Enterprise_Server/Disk1/install/runInstaller -silent -waitforcompletion -responseFile $SCRIPT_ROOT/unpack/siebel_install_image_siebel_linux_$SIEBEL_VERSION/$SIEBEL_VERSION/Linux/Server/Siebel_Enterprise_Server/Disk1/install/install_siebel_enterprise_server_$SIEBEL_VERSION.rsp"
}

configure_siebel_gateway () {
  cp $SCRIPT_ROOT/templates/siebel_configure_gateway_$SIEBEL_VERSION.rsp /tmp/siebel_configure_gateway_$SIEBEL_VERSION.rsp
  sed -i -e "s,CHANGE_ME_SIEBEL_BASE,$SIEBEL_BASE," /tmp/siebel_configure_gateway_$SIEBEL_VERSION.rsp
  su -l siebel -c "cd $SIEBEL_BASE/ses/config/; source $SIEBEL_BASE/ses/gtwysrvr/cfgenv.sh; $SIEBEL_BASE/ses/config/config.sh -mode enterprise  -responseFile /tmp/siebel_configure_gateway_$SIEBEL_VERSION.rsp"
}

install_oracle_client ()
{
  yum -y install libaio.i686 libaio-devel.i686 compat-libstdc++-33.686 compat-libstdc++-33.i686 glibc-devel.i686 libstdc++-devel.i686
  sed -i -e 's/^CV_ASSUME_DISTID=OEL4*$/CV_ASSUME_DISTID=OEL6/' $SCRIPT_ROOT/unpack/oracle_client_$ORACLE_VERSION/client/stage/cvu/cv/admin/cvu_config
  mkdir -p $SIEBEL_BASE/oracle_client/oraInventory
cat > $SIEBEL_BASE/oracle_client/oraInst.loc <<EOF
inventory_loc=$SIEBEL_BASE/oracle_client/oraInventory
inst_group=siebel
EOF
  chown -R siebel:siebel $SIEBEL_BASE/oracle_client
  cp $SCRIPT_ROOT/templates/oracle_client_runInstaller_$ORACLE_VERSION.rsp $SCRIPT_ROOT/unpack/oracle_client_$ORACLE_VERSION/client/
  sed -i -e "s,CHANGE_ME_SIEBEL_BASE,$SIEBEL_BASE," $SCRIPT_ROOT/unpack/oracle_client_$ORACLE_VERSION/client/oracle_client_runInstaller_$ORACLE_VERSION.rsp
  su -l siebel -c "$SCRIPT_ROOT/unpack/oracle_client_$ORACLE_VERSION/client/runInstaller -invPtrLoc $SIEBEL_BASE/oracle_client/oraInst.loc -silent -waitforcompletion -responseFile $SCRIPT_ROOT/unpack/oracle_client_$ORACLE_VERSION/client/oracle_client_runInstaller_$ORACLE_VERSION.rsp"
  su -l siebel -c "cat $ORACLE_HOME/network/admin/tnsnames.ora > $SIEBEL_BASE/oracle_client/client/network/admin/tnsnames.ora"
}

create_siebel_database ()
{
  su -l oracle -c "sqlplus / as sysdba @$SCRIPT_ROOT/sql/create_tablespace_sdata.sql $ORACLE_HOME"
  su -l oracle -c "sqlplus / as sysdba @$SCRIPT_ROOT/sql/create_tablespace_sindex.sql $ORACLE_HOME"
  su -l oracle -c "sqlplus / as sysdba @$SCRIPT_ROOT/sql/grantusr.sql"
  cp $SCRIPT_ROOT/templates/siebel_${SIEBEL_VERSION}_master_install.ucf $SIEBEL_BASE/ses/siebsrvr/bin/master_install.ucf
  sed -i -e "s,CHANGE_ME_SIEBEL_BASE,$SIEBEL_BASE," $SIEBEL_BASE/ses/siebsrvr/bin/master_install.ucf
  chown siebel:siebel $SIEBEL_BASE/ses/siebsrvr/bin/master_install.ucf
  su -l siebel -c "source $SIEBEL_BASE/ses/siebsrvr/cfgenv.sh; source $SIEBEL_BASE/ses/gtwysrvr/siebenv.sh; cd $SIEBEL_BASE/ses/siebsrvr/bin/ ; srvrupgwiz /m master_install.ucf"
  yum -y install libxslt.x86_64
  xsltproc $SCRIPT_ROOT/templates/siebel_lic_keys.xslt http://www.oracle.com/ocom/groups/public/@ocom/documents/webcontent/license_code.xml| grep -v Expires | sed 's/;//' | grep -vE "^$" > /tmp/siebel_lic_codes
  number=1
  cat /tmp/siebel_lic_codes | while read code
  do
    su -l oracle -c "sqlplus / as sysdba @$SCRIPT_ROOT/sql/lic_codes.sql \"$code\" \"0-$number\""
    number=$(expr $number + 1)
  done
}

configure_siebel_enterprise () {
  mkdir -p $SIEBEL_BASE/siebelfs
  chown -R siebel:siebel $SIEBEL_BASE/siebelfs
  cp $SCRIPT_ROOT/templates/siebel_configure_enterprise_$SIEBEL_VERSION.rsp /tmp/siebel_configure_enterprise_$SIEBEL_VERSION.rsp
  sed -i -e "s,CHANGE_ME_SIEBEL_BASE,$SIEBEL_BASE," /tmp/siebel_configure_enterprise_$SIEBEL_VERSION.rsp
  su -l siebel -c "cd $SIEBEL_BASE/ses/config/; source $SIEBEL_BASE/ses/gtwysrvr/siebenv.sh; $SIEBEL_BASE/ses/config/config.sh -mode enterprise -responseFile /tmp/siebel_configure_enterprise_$SIEBEL_VERSION.rsp"
}

configure_siebel_swe_profile () {
  cp $SCRIPT_ROOT/templates/siebel_configure_swe_profile_$SIEBEL_VERSION.rsp /tmp/siebel_configure_swe_profile_$SIEBEL_VERSION.rsp
  sed -i -e "s,CHANGE_ME_SIEBEL_BASE,$SIEBEL_BASE," /tmp/siebel_configure_swe_profile_$SIEBEL_VERSION.rsp
  su -l siebel -c "cd $SIEBEL_BASE/ses/config/; source $SIEBEL_BASE/ses/gtwysrvr/siebenv.sh; $SIEBEL_BASE/ses/config/config.sh -mode enterprise -responseFile /tmp/siebel_configure_swe_profile_$SIEBEL_VERSION.rsp"
}

configure_siebel_server () {
  cp $SCRIPT_ROOT/templates/siebel_configure_siebel_server_$SIEBEL_VERSION.rsp /tmp/siebel_configure_siebel_server_$SIEBEL_VERSION.rsp
  sed -i -e "s,CHANGE_ME_SIEBEL_BASE,$SIEBEL_BASE," /tmp/siebel_configure_siebel_server_$SIEBEL_VERSION.rsp
  su -l siebel -c "cd $SIEBEL_BASE/ses/config/; source $SIEBEL_BASE/ses/siebsrvr/cfgenv.sh; $SIEBEL_BASE/ses/config/config.sh -mode siebsrvr -responseFile /tmp/siebel_configure_siebel_server_$SIEBEL_VERSION.rsp"
}

import_repository () {
  cp $SCRIPT_ROOT/templates/siebel_import_repository_${SIEBEL_VERSION}.ucf $SIEBEL_BASE/ses/siebsrvr/bin/master_imprep.ucf
  chown siebel:siebel $SIEBEL_BASE/ses/siebsrvr/bin/master_imprep.ucf
  sed -i -e "s,CHANGE_ME_SIEBEL_BASE,$SIEBEL_BASE," $SIEBEL_BASE/ses/siebsrvr/bin/master_imprep.ucf
  su -l siebel -c "source $SIEBEL_BASE/ses/siebsrvr/siebenv.sh; cd $SIEBEL_BASE/ses/siebsrvr/bin/ ; srvrupgwiz /m master_imprep.ucf"
}

install_orcale_ohs () {
  if [ ! -e /usr/bin/gcc.orig ] 
  then 
    mv /usr/bin/gcc /usr/bin/gcc.orig
    cp $SCRIPT_ROOT/templates/gcc_fix_for_ohsx64_on_i686 /usr/bin/gcc41
  fi
  ln -s -f /usr/bin/gcc41 /usr/bin/gcc
  cp $SCRIPT_ROOT/templates/oracle_ohs_runInstaller_${OHS_VERSION}.rsp /tmp/oracle_ohs_runInstaller_${OHS_VERSION}.rsp
  sed -i -e "s,CHANGE_ME_SIEBEL_BASE,$SIEBEL_BASE," /tmp/oracle_ohs_runInstaller_${OHS_VERSION}.rsp
  mkdir -p $SIEBEL_BASE/ohs/oraInventory
cat > $SIEBEL_BASE/ohs/oraInst.loc <<EOF
inventory_loc=$SIEBEL_BASE/ohs
inst_group=siebel
EOF
  chown -R siebel:siebel $SIEBEL_BASE/ohs
  su -l siebel -c "linux32 bash <<EOF
$SCRIPT_ROOT/unpack/ohs_${OHS_VERSION}/Disk1/install/linux/runInstaller -invPtrLoc $SIEBEL_BASE/ohs/oraInst.loc -ignoreSysPrereqs -silent -waitforcompletion -responseFile /tmp/oracle_ohs_runInstaller_${OHS_VERSION}.rsp
EOF
"
  ln -sf /usr/bin/gcc.orig /usr/bin/gcc
}

run_srvrmgr () {
  su -l siebel -c "source $SIEBEL_BASE/ses/siebsrvr/siebenv.sh; srvrmgr -g localhost -e Siebel -u sadmin -p $SADMIN_PASSWORD -i $SCRIPT_ROOT/srvrmgr/$1 -o $SIEBEL_BASE/ses/siebsrvr/log/run_srvrmgr_$1.log"
}

install_siebel_webserver_extention () {
  #TODO use own oraInventory
  cp $SCRIPT_ROOT/templates/install_siebel_webserver_entention_$SIEBEL_VERSION.rsp $SCRIPT_ROOT/unpack/siebel_install_image_siebel_linux_$SIEBEL_VERSION/$SIEBEL_VERSION/Linux/Server/Siebel_Web_Server_Extension/Disk1/install/
  sed -i -e "s,CHANGE_ME_INSTALL_IMAGE,$SCRIPT_ROOT/unpack/siebel_install_image_siebel_linux_$SIEBEL_VERSION/$SIEBEL_VERSION," $SCRIPT_ROOT/unpack/siebel_install_image_siebel_linux_$SIEBEL_VERSION/$SIEBEL_VERSION/Linux/Server/Siebel_Web_Server_Extension/Disk1/install/install_siebel_webserver_entention_$SIEBEL_VERSION.rsp
  sed -i -e "s,CHANGE_ME_SIEBEL_BASE,$SIEBEL_BASE," $SCRIPT_ROOT/unpack/siebel_install_image_siebel_linux_$SIEBEL_VERSION/$SIEBEL_VERSION/Linux/Server/Siebel_Web_Server_Extension/Disk1/install/install_siebel_webserver_entention_$SIEBEL_VERSION.rsp
  echo "" | su -l siebel -c "$SCRIPT_ROOT/unpack/siebel_install_image_siebel_linux_$SIEBEL_VERSION/$SIEBEL_VERSION/Linux/Server/Siebel_Web_Server_Extension/Disk1/install/runInstaller -silent -waitforcompletion -responseFile $SCRIPT_ROOT/unpack/siebel_install_image_siebel_linux_$SIEBEL_VERSION/$SIEBEL_VERSION/Linux/Server/Siebel_Web_Server_Extension/Disk1/install/install_siebel_webserver_entention_$SIEBEL_VERSION.rsp"
}

siebel_apply_swe_profile () {
  cp $SCRIPT_ROOT/templates/siebel_apply_swe_profile_$SIEBEL_VERSION.rsp /tmp/siebel_apply_swe_profile_$SIEBEL_VERSION.rsp
  sed -i -e "s,CHANGE_ME_SIEBEL_BASE,$SIEBEL_BASE," /tmp/siebel_apply_swe_profile_$SIEBEL_VERSION.rsp
  su -l siebel -c "cd $SIEBEL_BASE/eappweb/config; source $SIEBEL_BASE/eappweb/cfgenv.sh ; $SIEBEL_BASE/eappweb/config/config.sh -mode swse -responseFile /tmp/siebel_apply_swe_profile_$SIEBEL_VERSION.rsp"
}

ohs_reconfigure () {
  sed -i -e 's,LoadModule swe_module modules/libmod_swe.so,LoadModule swe_module ${ORACLE_HOME}/ohs/modules/libmod_swe.so,' $SIEBEL_BASE/ohs/Oracle_WT1/ohs/conf/httpd.conf
  chown root $SIEBEL_BASE/ohs/Oracle_WT1/ohs/bin/.apachectl
  chmod 6750 $SIEBEL_BASE/ohs/Oracle_WT1/ohs/bin/.apachectl
  sed -i -e "s,#set ulimit for OHS to dump core when it crashes,LD_LIBRARY_PATH=$SIEBEL_BASE/eappweb/bin/:$SIEBEL_BASE/eappweb/bin/enu ; export LD_LIBRARY_PATH\nRESOLV_MULTI=off ; export RESOLV_MULTI\n#set ulimit for OHS to dump core when it crashes," $SIEBEL_BASE/ohs/Oracle_WT1/ohs/bin/apachectl
  su -l siebel -c "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$SIEBEL_BASE/eappweb/bin; \
  export ORACLE_HOME=$SIEBEL_BASE/ohs/Oracle_WT1 ; \
  export ORACLE_INSTANCE=$SIEBEL_BASE/ohs/Oracle_WT1/instances/instance1 ; \
  $SIEBEL_BASE/ohs/Oracle_WT1/opmn/bin/opmnctl deleteinstance ; \
  $SIEBEL_BASE/ohs/Oracle_WT1/opmn/bin/opmnctl createinstance -adminRegistration OFF ;\
  $SIEBEL_BASE/ohs/Oracle_WT1/opmn/bin/opmnctl createcomponent -componentType OHS -componentName ohs1"
}

finish () {
  cp templates/siebel_services /etc/init.d/
  sed -i -e "s,CHANGE_ME_SIEBEL_BASE,$SIEBEL_BASE," /etc/init.d/siebel_services
  chkconfig --add siebel_services 
  /etc/init.d/siebel_services stop
  /etc/init.d/siebel_services start
}

#End of file
