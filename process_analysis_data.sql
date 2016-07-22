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
-- SQL Script to process the vectorwise.log data extracted this run and merge
-- into the historic query data for later analysis.         
------------------------------------------------------------------------------

\nocontinue

SET SESSION WITH ON_ERROR = ROLLBACK TRANSACTION;
\p\g\t

SET AUTOCOMMIT OFF;
\p\g\t

INSERT INTO 
    vqat_queries_temp
SELECT
    x1.log_timestamp,
    x1.process_id,
    x1.thread_id,
    x1.session_id,
    x1.database_name,
    x1.query_id,
    -1,
    -1,
    'N'
FROM
    vqat_query_received x1
WHERE
    query_type_id = 0
;
\p\g\t


UPDATE 
    vqat_queries_temp x1
FROM
    vqat_x100_process_starting x2
SET
    database_name = x2.database_name
WHERE
    x1.process_id = x2.process_id
;
\p\g\t


UPDATE 
    vqat_queries_temp x1
FROM
    vqat_query_finished x2
SET
    noof_rows     = x2.noof_rows,
    running_time  = x2.running_time
WHERE
    x1.process_id = x2.process_id
AND x1.thread_id  = x2.thread_id
AND x1.session_id = x2.session_id
AND x1.query_id   = x2.query_id
;
\p\g\t

DELETE FROM
    vqat_queries_temp
WHERE
    noof_rows    = -1
OR  running_time = -1 
;
\p\g\t

MODIFY 
    vqat_queries 
UNION 
    vqat_queries_temp TO COMBINE
;
\p\g\t

UPDATE
    vqat_last_load
SET
    lastrun_timestamp = (SELECT 
                             MAX(log_timestamp)
                         FROM
                             vqat_query_finished)
WHERE
    (SELECT COUNT(*) FROM vqat_query_finished) > 0
;
\p\g\t


COMMIT;
;
\p\g\t


--------------------------------------------------------------------------------
-- End of SQL script
--------------------------------------------------------------------------------
