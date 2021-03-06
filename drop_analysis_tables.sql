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
-- SQL Script to drop all tables created and used by the analysis process.
--------------------------------------------------------------------------------

\nocontinue

SET AUTOCOMMIT ON;

DROP TABLE IF EXISTS vqat_queries;
DROP TABLE IF EXISTS vqat_last_load;
DROP TABLE IF EXISTS vqat_last_analysis;
DROP TABLE IF EXISTS vqat_queries_temp;
DROP TABLE IF EXISTS vqat_queries_summary;
DROP TABLE IF EXISTS vqat_x100_process_starting;
DROP TABLE IF EXISTS vqat_query_received;
DROP TABLE IF EXISTS vqat_query_finished;

\p\g\t


--------------------------------------------------------------------------------
-- End of SQL script
--------------------------------------------------------------------------------
