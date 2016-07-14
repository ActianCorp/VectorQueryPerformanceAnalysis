Vectorwise.log parser and analyser
==================================

The load_vector_log script in this package extracts basic query performance data from 
the Vector log file; vectorwise.log rather than LOG.
The data collected is accumulated in a Vector database for later reporting by script
report_vector_log.

It is an essential requirement that the logging level in the Vector installation is 
set to 'info' for 'Default' and 'SYSTEM' to provide the neccessary level of detail for 
analysis. Be aware that this can result in considerable growth of the vectorwise.log 
and this should be taken into account in your housekeeping.

The required configuration changes are made to the error log configuration file. This by 
default is $II_CONFIG/vwlog.conf.
The Vector installation restarted or the changes can be implemented dynamically for 
the default error log configuration file using command:

    CALL VECTORWISE(VWLOG_RELOAD);


load_vector_log.sh

Usage:
```
   --vector_log_file     {full path to vector log file}. Defaults to local installation.
   --system              {II_SYSTEM}. Defaults to local value of $II_SYSTEM
   --log_db              {database} to load analysis data into. Defaults to imadb.
   --tmp_dir             {temporary directory}. Defaults to $TEMP if set, or /tmp if not.
   --refresh             If supplied, clear the database tables and start from scratch.
   --debug               If supplied, turns debug on. Defaults to off.

  load_vector_log.sh --help
  load_vector_log.sh --version  
```

report_vector_log.sh

Usage:
```
   --system              {II_SYSTEM}. Defaults to local value of $II_SYSTEM
   --log_db              {database} to load analysis data into. Defaults to imadb.
   --tmp_dir             {temporary directory}. Defaults to $TEMP if set, or /tmp if not.
   --start_date          Start date of the Vector query analysis (YYYY-MM-DD hh:mm:ss). Defaults to last analysis end date.
   --end_date            End date of the Vector query analysis (YYYY-MM-DD hh:mm:ss). Defaults to 'now'.
   --ignore_analysis_db  Ignore the queries from the analysis database. Defaults to No.
   --debug               If supplied, turns debug on. Defaults to off.

  report_vector_log.sh --help
  report_vector_log.sh --version  
```

