--
-- Copyright 2016 Actian Corporation
--
-- Program Ownership and Restrictions.
--
-- This Program/Script provided hereunder is licensed, not sold, and all
-- intellectual property rights and title to the Program shall remain with Actian
-- and Our suppliers and no interest or ownership therein is conveyed to you.
--
-- No right to create a copyrightable work, whether joint or unitary, is granted
-- or implied; this includes works that modify (even for purposes of error
-- correction), adapt, or translate the Program or create derivative works, 
-- compilations, or collective works therefrom, except as necessary to configure
-- the Program using the options and tools provided for such purposes and
-- contained in the Program. 
--
-- The Program is supplied directly to you for use as defined by the controlling
-- documentation e.g. a Consulting Agreement and for no other reason.  
--
-- You will treat the Program as confidential information and you will treat it
-- in the same manner as you would to protect your own confidential information,
-- but in no event with less than reasonable care.
--
-- The Program shall not be disclosed to any third party (except solely to
-- employees, attorneys, and consultants, who need to know and are bound by a
-- written agreement with Actian to maintain the confidentiality of the Program
-- in a manner consistent with this licence or as defined in any other agreement)
-- or used except as permitted under this licence or by agreement between the
-- parties.
--

------------------------------------------------------------------------------
-- SQL Script to create the temporary tables for the vector log data extracted 
-- this run and populate from that data.
--
-- Note that in its current form a very small percentage (<1%) of rows being
-- written to the CSV files may be incorrectly formed.
--
-- To prevent the COPY statements from failing and rolling back (the default
-- in SQL), an 'on_error = continue' is being defined and a log file created
-- to capture these failing rows.
--
-- In due course, these failing rows should be examined such that this code
-- can be modified such that the rows are correctly formed when being written
-- to the CSV files.
------------------------------------------------------------------------------

\nocontinue

SET AUTOCOMMIT ON;

-- Create the temporary load tables.

DROP TABLE IF EXISTS vqat_query_received;

CREATE TABLE vqat_query_received (
    log_timestamp       TIMESTAMP      NOT NULL NOT DEFAULT,
    log_record_number   INTEGER8       NOT NULL NOT DEFAULT,
    process_id          INTEGER8       NOT NULL NOT DEFAULT,
    thread_id           INTEGER8       NOT NULL NOT DEFAULT,
    session_id          INTEGER8       NOT NULL NOT DEFAULT,
    database_name       VARCHAR(32)    NOT NULL NOT DEFAULT,
    query_id            INTEGER8       NOT NULL NOT DEFAULT,
    query_truncated     CHAR(1)        NOT NULL NOT DEFAULT,
    query_type_id       INTEGER2       NOT NULL NOT DEFAULT
    )
WITH STRUCTURE = VECTORWISE, NOPARTITION
;
\p\g\t

GRANT ALL ON vqat_query_received TO PUBLIC;
\p\g\t


DROP TABLE IF EXISTS vqat_query_finished;

CREATE TABLE vqat_query_finished (
    log_timestamp       TIMESTAMP     NOT NULL NOT DEFAULT,
    log_record_number   INTEGER8      NOT NULL NOT DEFAULT,
    process_id          INTEGER8      NOT NULL NOT DEFAULT,
    thread_id           INTEGER8      NOT NULL NOT DEFAULT,
    session_id          INTEGER8      NOT NULL NOT DEFAULT,
    database_name       VARCHAR(32)   NOT NULL NOT DEFAULT,
    running_time        DECIMAL(20,6) NOT NULL NOT DEFAULT,
    query_id            INTEGER8      NOT NULL NOT DEFAULT,
    noof_rows           INTEGER8      NOT NULL NOT DEFAULT
    )
WITH STRUCTURE = VECTORWISE, NOPARTITION
;
\p\g\t

GRANT ALL ON vqat_query_finished TO PUBLIC;
\p\g\t


DROP TABLE IF EXISTS vqat_queries_temp;

CREATE TABLE vqat_queries_temp (
    log_timestamp                  TIMESTAMP     NOT NULL WITH DEFAULT,
    process_id                     INTEGER8      NOT NULL WITH DEFAULT,
    thread_id                      INTEGER8      NOT NULL WITH DEFAULT,
    session_id                     INTEGER8      NOT NULL WITH DEFAULT,
    database_name                  CHAR(24)      NOT NULL WITH DEFAULT,
    query_id                       INTEGER8      NOT NULL WITH DEFAULT,
    noof_rows                      INTEGER8      NOT NULL NOT DEFAULT,
    running_time                   DECIMAL(20,6) NOT NULL NOT DEFAULT,
    transaction_aborted            CHAR(1)       NOT NULL WITH DEFAULT
    )
WITH STRUCTURE = VECTORWISE, NOPARTITION
;
\p\g\t

GRANT ALL ON vqat_queries_temp TO PUBLIC;
\p\g\t


-- Copy in the query data extracted from the logs this run.

COPY vqat_x100_process_starting (
    log_timestamp           = c0tab,
    log_record_number       = c0tab,
    process_id              = c0tab,
    thread_id               = c0tab,
    database_name           = c0nl
    )
FROM 
    '$h_csv_x100_process_starting'
WITH
    LOG = '$h_csv_x100_process_starting.error_log',
    ON_ERROR = continue
    ;
\p\g\t

COPY vqat_query_received (
    log_timestamp           = c0tab,
    log_record_number       = c0tab,
    process_id              = c0tab,
    thread_id               = c0tab,
    session_id              = c0tab,
    database_name           = c0tab,
    query_id                = c0tab,
    query_truncated         = c0tab,
    query_type_id           = c0nl
    )
FROM '$h_csv_query_received'
WITH
    LOG = '$h_csv_query_received.error_log',
    ON_ERROR = continue
    ;
\p\g\t

COPY vqat_query_finished (
    log_timestamp           = c0tab,
    log_record_number       = c0tab,
    process_id              = c0tab,
    thread_id               = c0tab,
    session_id              = c0tab,
    database_name           = c0tab,
    running_time            = c0tab,
    query_id                = c0tab,
    noof_rows               = c0nl
    )
FROM '$h_csv_query_finished'
WITH
    LOG = '$h_csv_query_finished.error_log',
    ON_ERROR = continue
    ;
\p\g\t


--------------------------------------------------------------------------------
-- End of SQL script
--------------------------------------------------------------------------------
