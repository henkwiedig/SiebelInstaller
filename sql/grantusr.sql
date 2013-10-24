create role sse_role;
grant create session to sse_role;

create role tblo_role;
grant ALTER SESSION, CREATE CLUSTER, CREATE DATABASE LINK, CREATE INDEXTYPE,
  CREATE OPERATOR, CREATE PROCEDURE, CREATE SEQUENCE, CREATE SESSION,
  CREATE SYNONYM, CREATE TABLE, CREATE TRIGGER, CREATE TYPE, CREATE VIEW,
  CREATE DIMENSION, CREATE MATERIALIZED VIEW, QUERY REWRITE, ON COMMIT REFRESH
to tblo_role;

create user SIEBEL identified by siebel;
grant tblo_role to SIEBEL;
grant sse_role to SIEBEL;
alter user SIEBEL quota 0 on SYSTEM quota 0 on SYSAUX;
alter user SIEBEL default tablespace SDATA;
alter user SIEBEL temporary tablespace TEMP;
alter user SIEBEL quota unlimited on SDATA;
alter user SIEBEL quota unlimited on SINDEX;

create user SADMIN identified by sadmin;
grant sse_role to SADMIN;
alter user SADMIN default tablespace SDATA;
alter user SADMIN temporary tablespace TEMP;
/
exit
/
