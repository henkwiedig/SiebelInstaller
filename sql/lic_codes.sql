insert into siebel.s_app_key (
 ROW_ID,
 CREATED,
 CREATED_BY,
 LAST_UPD,
 LAST_UPD_BY,
 MODIFICATION_NUM,
 CONFLICT_ID,
 APP_KEY_DT,
 DB_LAST_UPD,
 APP_KEY,
 DB_LAST_UPD_SRC) values (&2,current_timestamp,'0-1',current_timestamp,'0-1','0','0',current_timestamp,current_timestamp, '&1','sqlpus')
/
commit
/
exit
/
