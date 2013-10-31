#!/bin/bash

#remove oracle
rm -fr /u01/ /etc/oraInst.loc /etc/oratab 
userdel -f -r oracle
groupdel oinstall
groupdel dba 
groupdel oper
rm -f .status/download_from_mos_oracle_11.2.0.3 .status/install_oracle_oracle_11.2.0.3 .status/unpack_product_oracle_11.2.0.3

