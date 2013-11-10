#!/bin/bash

FULL_PATH=`readlink -f $0 ` 
SCRIPT_ROOT=`dirname $FULL_PATH`

source $SCRIPT_ROOT/../config.defaults

if [ -e $SCRIPT_ROOT/../config.local ]
then
  source $SCRIPT_ROOT/../config.local
fi


#del oracle
chkconfig --del dbora
rm -fr $ORACLE_BASE /etc/oraInst.loc /etc/oratab /etc/init.d/dbora
userdel -f -r oracle
groupdel oinstall
groupdel dba 
groupdel oper
rm -f .status/download_from_mos_oracle_11.2.0.3 .status/install_oracle_oracle_11.2.0.3 .status/unpack_product_oracle_11.2.0.3

#del siebel
chkconfig --del siebel_services 
rm /etc/init.d/siebel_services
rm -rf $SIEBEL_BASE
userdel -f -r siebel
groupdel siebel
rm -f .status/*siebel*

rm -rf .status/
