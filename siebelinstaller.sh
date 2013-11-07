#!/bin/bash -e

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
execute_once download_from_mos "oracle_client_$ORACLE_VERSION"
execute_once download_from_mos "siebel_linux_$SIEBEL_VERSION"
execute_once download_from_mos "siebel_windows_$SIEBEL_VERSION"
#execute_once download_from_mos "siebel_windows_8.1.1.0"
execute_once download_from_mos "ohs_$OHS_VERSION"
execute_once download_and_unpack "java_$JAVA_VERSION"

#unpack products
execute_once unpack_product "oracle_$ORACLE_VERSION"
execute_once unpack_product "oracle_client_$ORACLE_VERSION"
execute_once unpack_product "siebel_linux_$SIEBEL_VERSION"
execute_once unpack_product "siebel_windows_$SIEBEL_VERSION"
#execute_once unpack_product "siebel_windows_8.1.1.0"
execute_once unpack_product "ohs_$OHS_VERSION"
execute_once create_siebel_install_image "siebel_linux_$SIEBEL_VERSION"
execute_once create_siebel_install_image "siebel_windows_$SIEBEL_VERSION"

#install products
execute_once install_oracle "oracle_$ORACLE_VERSION"
execute_once install_siebel_enterprise_server "siebel_$SIEBEL_VERSION"
execute_once install_siebel_webserver_extention "siebel_$SIEBEL_VERSION"
execute_once install_oracle_client "oracle_client_$ORACLE_VERSION"

#configure products
execute_once configure_siebel_gateway "$SIEBEL_VERSION"
execute_once configure_siebel_enterprise "$SIEBEL_VERSION"
execute_once configure_siebel_swe_profile "$SIEBEL_VERSION"
execute_once create_siebel_database "$SIEBEL_VERSION"
execute_once configure_siebel_server "$SIEBEL_VERSION"
execute_once import_repository "$SIEBEL_VERSION"
execute_once install_orcale_ohs "$OHS_VERSION"
execute_once run_srvrmgr "basic_setup.in"
execute_once siebel_apply_swe_profile "$SIEBEL_VERSION"
execute_once ohs_reconfigure "$SIEBEL_VERSION"
exit
execute_once finish "installation"

echo "Done!"
#End of file
