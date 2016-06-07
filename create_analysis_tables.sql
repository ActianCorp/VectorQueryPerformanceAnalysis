-- SQL script to create all tables needed for vectorwise.log data

SET AUTOCOMMIT ON;


CREATE TABLE x100_process_starting (
    log_timestamp       TIMESTAMP   NOT NULL NOT DEFAULT,
    log_record_number   INTEGER8    NOT NULL NOT DEFAULT,
    process_id          INTEGER8    NOT NULL NOT DEFAULT,
    thread_id           INTEGER8    NOT NULL NOT DEFAULT,
    database_name       VARCHAR(32) NOT NULL NOT DEFAULT
    );
\p\g\t

GRANT ALL ON x100_process_starting TO PUBLIC;
\p\g\t


CREATE TABLE query_received (
    log_timestamp       TIMESTAMP      NOT NULL NOT DEFAULT,
    log_record_number   INTEGER8       NOT NULL NOT DEFAULT,
    process_id          INTEGER8       NOT NULL NOT DEFAULT,
    thread_id           INTEGER8       NOT NULL NOT DEFAULT,
    session_id          INTEGER8       NOT NULL NOT DEFAULT,
    database_name       VARCHAR(32)    NOT NULL NOT DEFAULT,
    query               VARCHAR(10000) NOT NULL NOT DEFAULT,
    query_id            INTEGER8       NOT NULL NOT DEFAULT,
    query_truncated     CHAR(1)        NOT NULL NOT DEFAULT,
    query_type_id       INTEGER2       NOT NULL NOT DEFAULT
    );
\p\g\t

GRANT ALL ON query_received TO PUBLIC;
\p\g\t


CREATE TABLE query_finished (
    log_timestamp       TIMESTAMP     NOT NULL NOT DEFAULT,
    log_record_number   INTEGER8      NOT NULL NOT DEFAULT,
    process_id          INTEGER8      NOT NULL NOT DEFAULT,
    thread_id           INTEGER8      NOT NULL NOT DEFAULT,
    session_id          INTEGER8      NOT NULL NOT DEFAULT,
    database_name       VARCHAR(32)   NOT NULL NOT DEFAULT,
    running_time        DECIMAL(20,6) NOT NULL NOT DEFAULT,
    query_id            INTEGER8      NOT NULL NOT DEFAULT,
    noof_rows           INTEGER8      NOT NULL NOT DEFAULT
    );
\p\g\t

GRANT ALL ON query_finished TO PUBLIC;
\p\g\t

--------------------------------------------------------------------------------
-- End of SQL script
--------------------------------------------------------------------------------
