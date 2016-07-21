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

--------------------------------------------------------------------------------
-- SQL script to create permanent tables needed for vectorwise.log analysis.
--------------------------------------------------------------------------------

\nocontinue

SET AUTOCOMMIT ON;

CREATE TABLE vqat_queries (
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

GRANT ALL ON vqat_queries TO PUBLIC;
\p\g\t


CREATE TABLE vqat_last_load (
    lastrun_timestamp              TIMESTAMP     NOT NULL WITH DEFAULT
    )
WITH STRUCTURE = VECTORWISE, NOPARTITION
;
\p\g\t

INSERT INTO vqat_last_load VALUES ('01/01/2016')
;
\p\g\t

GRANT ALL ON vqat_last_load TO PUBLIC;
\p\g\t


CREATE TABLE vqat_last_analysis (
    lastrun_timestamp              TIMESTAMP     NOT NULL WITH DEFAULT
    )
WITH STRUCTURE = VECTORWISE, NOPARTITION
;
\p\g\t

INSERT INTO vqat_last_analysis VALUES ('01/01/2016')
;
\p\g\t

GRANT ALL ON vqat_last_analysis TO PUBLIC;
\p\g\t


CREATE TABLE vqat_x100_process_starting (
    log_timestamp       TIMESTAMP   NOT NULL NOT DEFAULT,
    log_record_number   INTEGER8    NOT NULL NOT DEFAULT,
    process_id          INTEGER8    NOT NULL NOT DEFAULT,
    thread_id           INTEGER8    NOT NULL NOT DEFAULT,
    database_name       VARCHAR(32) NOT NULL NOT DEFAULT
    )
WITH STRUCTURE = VECTORWISE, NOPARTITION
;
\p\g\t

GRANT ALL ON vqat_x100_process_starting TO PUBLIC;
\p\g\t


--------------------------------------------------------------------------------
-- End of SQL script
--------------------------------------------------------------------------------
