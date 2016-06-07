Vectorwise.log parser and analyser
========

It analyses the contents of the Vector log file - vectorwise.log rather 
than LOG - for useful data, and then produces a CSV file summarising the queries.

Usage:
```
  analyse_vector_log.sh
   --vector_log_file     {full path to vector log file}. Defaults to local installation.
   --system              {II_SYSTEM}. Defaults to local value of $II_SYSTEM
   --log_db              {database} to load analysis data into. Defaults to imadb.
   --tmp_dir             {temporary directory}. Defaults to $TEMP if set, or /tmp if not.
   --noload              If supplied, don't load analysis data into database. Defaults to 0.
   --refresh             If supplied, delete all temp files and the database tables and start from scratch.
   --debug               If supplied, turns debug on. Defaults to off.

  analyse_log.sh --help
  analyse_log.sh --version  
```
