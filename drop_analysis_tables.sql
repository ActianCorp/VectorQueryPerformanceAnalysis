-- Drop all tables created and used by the analysis process

SET AUTOCOMMIT ON;

DROP TABLE IF EXISTS x100_process_starting;
DROP TABLE IF EXISTS query_received;
DROP TABLE IF EXISTS query_finished;

COMMIT;
\g

--------------------------------------------------------------------------------
-- End of SQL script
--------------------------------------------------------------------------------
