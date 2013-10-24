#!/bin/bash

prepare_host ()
{
  yum -y install zip unzip
}

download_from_mos ()
{
  #Adaped from MOS wget script
 
  OLD_LANG=$LANG
  LANG=C
  export LANG

  if [ x"$MOS_PASSWORD " = x"CHANGE_ME" ] && [ x"$MOS_USERNAME" = x"foo@bar.com" ]
  then
    echo "Please set MOS_PASSWORD and MOS_USERNAME in config.local file"
   exit
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
    $1 "$2" && touch $SCRIPT_ROOT/.status/$1_$2
  else
    echo "Skipping execution of : $1 \"$2\" please remove $SCRIPT_ROOT/.status/$1_$2 if this is incorrect"
  fi
}

install_oracle ()
{
  #see http://www.oracle-base.com/articles/11g/oracle-db-11gr2-installation-on-oracle-linux-5.php

  cat $SCRIPT_ROOT/templates/oracle_sysctl_$ORACLE_VERSION.conf >> /etc/sysctl.conf
  /sbin/sysctl -p
  cat $SCRIPT_ROOT/templates/oracle_limits_$ORACLE_VERSION.conf >> /etc/security/limits.conf
  yum -y install binutils compat-libstdc++-33 compat-libstdc++-33 elfutils-libelf gcc gcc-c++ glibc glibc-common glibc-devel glibc-headers ksh libaio libaio-devel libgomp libgcc libstdc++ libstdc++-devel make sysstat unixODBC unixODBC-devel numactl-devel xorg-x11-utils xauth elfutils-libelf-devel pdksh compat-libcap1
  groupadd oinstall
  groupadd dba
  groupadd oper

  useradd -g oinstall -G dba,oper oracle
  sed -i -e 's/^SELINUX=.*$/SELINUX=permissive/' /etc/selinux/config
  service iptables stop
  chkconfig iptables off
  mkdir -p /u01/app/oracle/product/11.2.0/db_1
  chown -R oracle:oinstall /u01
#  chmod -R o+r,o+x /root/SiebelInstaller/unpack/*
  chmod -R 775 /u01
  cat >/home/oracle/.bash_profile <<EOF
# Oracle Settings
TMP=/tmp; export TMP
TMPDIR=\$TMP; export TMPDIR

ORACLE_HOSTNAME=localhost.localdomain; export ORACLE_HOSTNAME
ORACLE_UNQNAME=orcl; export ORACLE_UNQNAME
ORACLE_BASE=/u01/app/oracle; export ORACLE_BASE
ORACLE_HOME=\$ORACLE_BASE/product/11.2.0/db_1; export ORACLE_HOME
ORACLE_SID=orcl; export ORACLE_SID
PATH=/usr/sbin:\$PATH; export PATH
PATH=\$ORACLE_HOME/bin:\$PATH; export PATH

LD_LIBRARY_PATH=\$ORACLE_HOME/lib:/lib:/usr/lib; export LD_LIBRARY_PATH
CLASSPATH=\$ORACLE_HOME/jlib:\$ORACLE_HOME/rdbms/jlib; export CLASSPATH
EOF
  sed -i -e 's/^CV_ASSUME_DISTID=OEL4*$/CV_ASSUME_DISTID=OEL6/' $SCRIPT_ROOT/unpack/oracle_$ORACLE_VERSION/database/stage/cvu/cv/admin/cvu_config

  #TODO: fix response file
  su -l oracle -c "$SCRIPT_ROOT/unpack/oracle_11.2.0.3/database/runInstaller -silent -waitforcompletion -responseFile $SCRIPT_ROOT/templates/oracle_runInstaller_$ORACLE_VERSION.rsp"
  /u01/app/oraInventory/orainstRoot.sh
  /u01/app/oracle/product/11.2.0/db_1/root.sh


}
