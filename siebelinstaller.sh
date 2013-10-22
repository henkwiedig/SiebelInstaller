#!/bin/bash

SCRIPT_ROOT=`dirname $0`

source $SCRIPT_ROOT/config.defaults

if [ -e $SCRIPT_ROOT/config.local ]
then
  source $SCRIPT_ROOT/config.local
else 
  echo "Please create $SCRIPT_ROOT/config.local and set MOS_PASSWORD and MOS_USERNAME"
  exit 1
fi

cd $SCRIPT_ROOT

mkdir -p $SCRIPT_ROOT/log
mkdir -p $SCRIPT_ROOT/.status

if [ x"$MOS_PASSWORD " = x"CHANGE_ME" ] && [ x"$MOS_USERNAME" = x"foo@bar.com" ]
then
 echo "Please set MOS_PASSWORD and MOS_USERNAME in config.local file"
 exit
fi

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

#Run users pre install script
[ ! $SCRIPT_ROOT/.status/pre_install_script ] && sh $PRE_INSTALL_SCRIPT && touch $SCRIPT_ROOT/.status/pre_install_script

#prepare host
execute_once prepare_host prepare_host

#download
execute_once download_from_mos "oracle_$ORACLE_VERSION"
execute_once download_from_mos "siebel_$SIEBEL_VERSION"
execute_once download_from_mos "ohs_$OHS_VERSION"

#unpack products
execute_once unpack_product "oracle_$ORACLE_VERSION"
execute_once unpack_product "siebel_$SIEBEL_VERSION"

echo "Done!"
