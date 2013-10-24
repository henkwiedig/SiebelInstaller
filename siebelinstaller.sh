#!/bin/bash

FULL_PATH=`readlink -f $0 ` 
SCRIPT_ROOT=`dirname $FULL_PATH`

source $SCRIPT_ROOT/config.defaults
source $SCRIPT_ROOT/` basename $0 .sh`_lib.sh

if [ -e $SCRIPT_ROOT/config.local ]
then
  source $SCRIPT_ROOT/config.local
fi

cd $SCRIPT_ROOT
PWD=`pwd` 
IS_ROOT=` echo $PWD | cut -c 2-5`
if [ x$IS_ROOT = xroot ]
then
  echo "Please do not run in /root."
  exit 1
fi

mkdir -p $SCRIPT_ROOT/log
mkdir -p $SCRIPT_ROOT/.status

#Run users pre install script
[ ! -e $SCRIPT_ROOT/.status/pre_install_script ] && [ -e $SCRIPT_ROOT/pre_install_script ] && sh pre_install_script && touch $SCRIPT_ROOT/.status/pre_install_script

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
