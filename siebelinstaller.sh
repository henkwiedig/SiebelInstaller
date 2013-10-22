#!/bin/bash

SCRIPT_ROOT=`dirname $0`

source $SCRIPT_ROOT/config.defaults
source $SCRIPT_ROOT/` basename $0 .sh`_lib.sh

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

#install products
execute_once install_oracle "oracle_$ORACLE_VERSION"

echo "Done!"
