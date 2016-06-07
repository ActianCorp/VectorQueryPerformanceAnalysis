------------------------------------------------------------------------------
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

SET AUTOCOMMIT ON;
--help $h_csv_logs;\p\g

COPY x100_process_starting (
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

COPY query_received (
    log_timestamp           = c0tab,
    log_record_number       = c0tab,
    process_id              = c0tab,
    thread_id               = c0tab,
    session_id              = c0tab,
    database_name           = c0tab,
    query                   = c0tab,
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

COPY query_finished (
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
