#!/bin/bash
#
# Copyright 2014 Actian Corporation
#
# Program Ownership and Restrictions.
#
# This Program/Script provided hereunder is licensed, not sold, and all
# intellectual property rights and title to the Program shall remain with Actian
# and Our suppliers and no interest or ownership therein is conveyed to you.
#
# No right to create a copyrightable work, whether joint or unitary, is granted
# or implied; this includes works that modify (even for purposes of error
# correction), adapt, or translate the Program or create derivative works, 
# compilations, or collective works therefrom, except as necessary to configure
# the Program using the options and tools provided for such purposes and
# contained in the Program. 
#
# The Program is supplied directly to you for use as defined by the controlling
# documentation e.g. a Consulting Agreement and for no other reason.  
#
# You will treat the Program as confidential information and you will treat it
# in the same manner as you would to protect your own confidential information,
# but in no event with less than reasonable care.
#
# The Program shall not be disclosed to any third party (except solely to
# employees, attorneys, and consultants, who need to know and are bound by a
# written agreement with Actian to maintain the confidentiality of the Program
# in a manner consistent with this licence or as defined in any other agreement)
# or used except as permitted under this licence or by agreement between the
# parties.
#

#----------------------------------------------------------------------------
#
# Name:
#   analyse_vector_log.sh
#
# Description:
#   This script analyses the contents of the main Actian Vector log file,
#   vectorwise.log, for data related to query performance. This data is extracted,
#   summarised and loaded into database tables in the specified database.
#   These tables are dropped and re-created every time this program is executed.
#   A CSV file summarising the data is also produced, and placed in the temp folder.
#
#----------------------------------------------------------------------------
h_prog_name=`basename ${0}`
h_prog_version=v1.3
#----------------------------------------------------------------------------
#

#----------------------------------------------------------------------------
# Function:
#   TERMINATE - Exit the program 
#----------------------------------------------------------------------------
TERMINATE()
{
   CLF_MESSAGELOG Function: TERMINATE

   CLF_TIDYUP 1

   exit 0
}


#----------------------------------------------------------------------------
# Function:
#   INITIALIZE - set up local variables 
#----------------------------------------------------------------------------
INITIALIZE()
{
    # Enviroment setup:

    CLF_SETUPCOMMONVARIABLES
    CLF_CREATELOGFILES

    # Create any test-specific files

    h_vector_log_analysis=$h_clv_tmp_dir/$h_prog_name.vector_log_analysis.$h_clf_pid
    CLF_CREATEFILE $h_vector_log_analysis

    # Create a number of CSV files to store data extracted from the vectorwise.log
    # file(s).  These will in turn be loaded into an Ingres/Vector database for
    # subsequent analysis.
    # Have to export them to make them visible to the sub-scripts.

     export h_csv_x100_process_starting=$h_clv_tmp_dir/$h_prog_name.x100_process_starting.$h_clf_pid
     CLF_CREATEFILE $h_csv_x100_process_starting

     export h_csv_query_received=$h_clv_tmp_dir/$h_prog_name.query_received.$h_clf_pid
     CLF_CREATEFILE $h_csv_query_received

     export h_csv_query_finished=$h_clv_tmp_dir/$h_prog_name.query_finished.$h_clf_pid
     CLF_CREATEFILE $h_csv_query_finished

     export h_sql_script="${TEMP}/create_output_csv.sql"
     CLF_CREATEFILE $h_sql_script
   
     export h_csv_summary="${TEMP}/VECTOR_LOG_ANALYSIS.csv"
     CLF_CREATEFILE $h_csv_summary
}


#----------------------------------------------------------------------------
# Function:
#   CLF_SETUPCOMMONVARIABLES
#      Setup variables used by most (if not all) DBM scripts
#----------------------------------------------------------------------------
function CLF_SETUPCOMMONVARIABLES
{
    # PID of current process used amongst other things for naming temporary files
    export h_clf_pid=$$

    # To ensure consistency when writing out data files, set II_DATE_FORMAT to
    # multinational4
    export II_DATE_FORMAT=MULTINATIONAL4

    return 0
}


#----------------------------------------------------------------------------
# Function:
#   CLF_CURDATETIME
#      Setup the current date and time                                       
#----------------------------------------------------------------------------

function CLF_CURDATETIME
{
    #   Get the current system date / time

    h_clf_cur_date=`date +"%d/%m/%Y"`
    h_clf_cur_time=`date +"%H:%M:%S"`
    h_clf_cur_yyyy=`date +"%Y"`

    h_clf_cur_moy=`date +"%m"`
    h_clf_cur_dom=`date +"%d"`
    h_clf_cur_yy=`date +"%y"`
    h_clf_cur_abbrev_month=`date +"%b"`
    h_clf_cur_full_month=`date +"%B"`
    h_clf_cur_abbrev_dow=`date +"%a"`
    h_clf_cur_full_dow=`date +"%A"`

    h_clf_cur_yyyymmddhhmmss=`date +"%Y%m%d%H%M%S"`

    h_clf_cur_datetime=`date +"%d/%m/%Y %H:%M:%S"`

    return 0
}


#----------------------------------------------------------------------------
# Function:
#   CLF_CREATEFILE
#     Create a given file name
#----------------------------------------------------------------------------
function CLF_CREATEFILE
{
    h_clf_create_filename=$1

    if [ -f "$h_clf_create_filename" ]
    then
        rm $h_clf_create_filename 2> /dev/null

        CLF_CHECKCMD $? "Y" "attempting to remove $h_clf_create_filename"
    fi

    touch $h_clf_create_filename

    CLF_CHECKCMD $? "Y" "attempting to touch $h_clf_create_filename"

    chmod 777 $h_clf_create_filename

    CLF_CHECKCMD $? "Y" "attempting to chmod $h_clf_create_filename"

    return 0
}


#----------------------------------------------------------------------------
# Function:
#   CLF_CHK_CMD   
#     Check whether the command executed has worked
#----------------------------------------------------------------------------
function CLF_CHECKCMD
{
    h_clf_return_code=$1
    shift

    h_clf_critical=$1
    shift

    h_clf_command=$*

    if [ "$h_clf_return_code" != 0 ]
    then
        CLF_MESSAGELOG "++ Failed to run command ++"
        CLF_MESSAGELOG $h_clf_command

        if [ "$h_clf_critical" = "Y" ]
        then
            printf "%s\n" "Failed to run command: $h_clf_command"
            exit 1
        fi
    fi

    return 0
}


#----------------------------------------------------------------------------
# Function:
#   CLF_MESSAGELOG   
#     Log a message to the default log file for this run
#----------------------------------------------------------------------------
function CLF_MESSAGELOG
{
   h_clf_message=$*

   echo `date +"%d/%m/%Y %H:%M:%S"` "$h_clf_message" >> $h_clf_message_log
   echo `date +"%d/%m/%Y %H:%M:%S"` "$h_clf_message" 

   return 0
}


#----------------------------------------------------------------------------
# Function:
#   CLF_CREATELOGFILES   
#                                                            
#----------------------------------------------------------------------------
function CLF_CREATELOGFILES
{
    # Create TEMP location if it does not already exist
    if [ ! -d "$h_clv_tmp_dir" ]
    then
        mkdir -p $h_clv_tmp_dir

        if [ $? -ne 0 ]
        then
            printf "Unable to create temporary directory: $h_clv_tmp_dir\n"
            exit 1
        fi
    fi

    # Write to log
    h_clf_message_log=$h_clv_tmp_dir/$h_prog_name.LOG.$h_clf_pid

    if [ -f $h_clf_message_log ]
    then
        printf "\n"  >> $h_clf_message_log
        printf "------------------------------------------------\n" >> $h_clf_message_log
        printf "\n"  >> $h_clf_message_log
    else
        CLF_CREATEFILE $h_clf_message_log
    fi

    return 0
}


#----------------------------------------------------------------------------
# Function:
#   CLF_TIDYUP             
#                                                            
#----------------------------------------------------------------------------
function CLF_TIDYUP
{
    # Quit if not all required variables
    if [ -z "$h_prog_name" -o -z "$h_clf_pid" -o -z "$h_clv_tmp_dir" ]
    then
        return 0
    fi

    # Non "temporary" files (e.g. log files) can be retained for a number of days
    # as defined by the supplied parameter.
    if [ $# != 1 ]
    then
        printf "Parameter Error. Usage: $0 [No of days to keep log files]"
        return 1
    fi

    h_clf_no_of_days=$1

    # Delete all TMP and LOG files created from this run...
    rm $h_clv_tmp_dir/$h_prog_name*.TMP.$h_clf_pid 2>/dev/null
    rm $h_clv_tmp_dir/$h_prog_name*.LOG.$h_clf_pid 2>/dev/null

    return 0
}


#----------------------------------------------------------------------------
# Function:
#   CLF_SETUPPATHS   
#                                                            
#----------------------------------------------------------------------------
function CLF_SETUPPATHS
{
    # Using the supplied II_SYSTEM parameter, set up the Ingres PATHS

    export II_SYSTEM="$1"

    # Do some basic sanity checking on the value supplied for II_SYSTEM...

    if [ ! -d "$II_SYSTEM" ]
    then
        printf "\$II_SYSTEM $II_SYSTEM is not a directory\n"
        exit 1
    fi

    if [ ! -f "$II_SYSTEM/ingres/files/config.dat" ]
    then
        printf "$II_SYSTEM does not seem to contain an Ingres installation\n"
        exit 1
    fi

    # Setup some PATHs

    export PATH="$II_SYSTEM/ingres/bin:$II_SYSTEM/ingres/utility:$PATH"

    if [ "$LD_LIBRARY_PATH" ] ; then
        LD_LIBRARY_PATH=/usr/local/lib:$II_SYSTEM/ingres/lib:$II_SYSTEM/ingres/lib/lp32:$LD_LIBRARY_PATH
    else
        LD_LIBRARY_PATH=/lib:/usr/lib:/usr/local/lib:$II_SYSTEM/ingres/lib:$II_SYSTEM/ingres/lib/lp32
    fi
    export LD_LIBRARY_PATH

    export `ingprenv |grep II_LOG`

    return 0
}


#----------------------------------------------------------------------------
# Function:
#   ANALYSE_VECTOR_LOG
#                                                            
#----------------------------------------------------------------------------
ANALYSE_VECTOR_LOG()
{
   CLF_MESSAGELOG Function: ANALYSE_VECTOR_LOG

   gawk -v h_awk_debug=$h_clv_debug \
        -v h_awk_single_quote=\' \
        -v h_awk_csv_logs=$h_csv_logs \
        -v h_awk_csv_query_type=$h_csv_query_type \
        -v h_awk_csv_x100_process_starting=$h_csv_x100_process_starting  \
        -v h_awk_csv_query_received=$h_csv_query_received \
        -v h_awk_csv_query_finished=$h_csv_query_finished \
        -f parse_vector_log.awk $h_clv_vector_log_file

   return 0
}


#----------------------------------------------------------------------------
# Function:
#   load_analysis_data
#                                                            
#----------------------------------------------------------------------------
LOAD_ANALYSIS_DATA()
{
    CLF_MESSAGELOG Function: LOAD_ANALYSIS_DATA

    # First have to check the supplied database exists and is writable by us.
    ERRORS=`echo "create table log_test (col1 int);drop table log_test\g" | sql $h_clv_logdb | grep "E_" | wc -l`

    if [ "$ERRORS" -gt 0 ]
    then
        # Something went wrong in accessing the database so flag this and exit.
        CLF_MESSAGELOG "Error in being able to write to database $h_clv_logdb. Please correct and try again."
        return 1
    fi

    # Next have to see if the schema has already been created. Don't attempt to check schema versions
    # and handle upgrades or anything too clever - just forget schema creation if the first table is there.
    # Rely on a name collision error for this user to detect if schema is there.
    ERRORS=`echo "SELECT COUNT(*) FROM logs;\g" | sql $h_clv_logdb | grep "^E_" | wc -l`

    # If the schema is already there then don't attempt to create it.
    # Otherwise, create the schema
      
    if [ "$ERRORS" -eq 0 ]
    then
        # Nothing went wrong in getting data from the first analysis table, so assume that the 
        # schema is already there.
        CLF_MESSAGELOG "Schema already exists in $h_clv_logdb, so not reloading. Continuing on to load data."
    else
        CLF_MESSAGELOG "Schema does not already exist in $h_clv_logdb so creating it now as current user."
        sql $h_clv_logdb < create_analysis_tables.sql >> $h_clv_tmp_dir/$h_prog_name.log.$h_clf_pid
        RETCODE=$?

        ERRORS=`grep "^E_" $h_clv_tmp_dir/$h_prog_name.LOG.$h_clf_pid | wc -l`

        if [ "$ERRORS" -gt 0 -o $RETCODE -gt 0 ]
        then
            # Some errors found in creating schema, so flag this and exit
            CLF_MESSAGELOG "Errors found in creating schema in database $h_clv_logdb. Please correct and try again."
            CLF_MESSAGELOG "Check error log file $h_clv_tmp_dir/$h_prog_name.LOG.$h_clf_pid for details of the errors."
            return 1
        fi
    fi

    # So now run the COPY script to load in all of the files we've created. 
    # Pass the SQL script through envsubst along the way to ensure that path variables
    # get substituted with the real values.
    # ./testing.sh >> $h_clv_tmp_dir/$h_prog_name.LOG.$h_clf_pid
    cat load_analysis_data.sql | envsubst | sql $h_clv_logdb >> $h_clv_tmp_dir/$h_prog_name.log.$h_clf_pid
    RETCODE=$?
    ERRORS=`grep "^E_" $h_clv_tmp_dir/$h_prog_name.LOG.$h_clf_pid | wc -l`

    if [ "$ERRORS" -gt 0 -o $RETCODE -gt 0 ]
    then
        # Some errors found in loading data, so flag this and exit
        CLF_MESSAGELOG "Errors found in loading data to database $h_clv_logdb. Please correct and try again."
        CLF_MESSAGELOG "Check error log file $h_clv_tmp_dir/$h_prog_name.LOG.$h_clf_pid for details of the errors."
        return 1
    fi
      
    CLF_MESSAGELOG "Analysis data loaded successfully to tables in $h_clv_logdb."
}


#----------------------------------------------------------------------------
# Function:
#   PRODUCE_SUMMARY
#     Produce the CSV file summary output
#----------------------------------------------------------------------------
PRODUCE_SUMMARY()
{
  echo "
      DROP TABLE IF EXISTS queries;
      \p\g\t


      CREATE TABLE queries (
          log_timestamp                  TIMESTAMP     NOT NULL WITH DEFAULT,
          log_date                       TIMESTAMP     NOT NULL WITH DEFAULT,
          log_date_hh                    TIMESTAMP     NOT NULL WITH DEFAULT,
          log_date_hhmm                  TIMESTAMP     NOT NULL WITH DEFAULT,
          log_date_hhmmss                TIMESTAMP     NOT NULL WITH DEFAULT,
          process_id                     INTEGER8      NOT NULL WITH DEFAULT,
          thread_id                      INTEGER8      NOT NULL WITH DEFAULT,
          session_id                     INTEGER8      NOT NULL WITH DEFAULT,
          database_name                  CHAR(24)      NOT NULL WITH DEFAULT,
          query_id                       INTEGER8      NOT NULL WITH DEFAULT,
          noof_rows                      INTEGER8      NOT NULL NOT DEFAULT,
          running_time                   DECIMAL(20,6) NOT NULL NOT DEFAULT,
          transaction_aborted            CHAR(1)       NOT NULL WITH DEFAULT
          )
      ;
      \p\g\t


      INSERT INTO queries
      SELECT
          x1.log_timestamp,
          DATE_TRUNC('DAY',x1.log_timestamp),
          DATE_TRUNC('HOUR',x1.log_timestamp),
          DATE_TRUNC('MINUTE',x1.log_timestamp),
          DATE_TRUNC('SECOND',x1.log_timestamp),
          x1.process_id,
          x1.thread_id,
          x1.session_id,
          x1.database_name,
          x1.query_id,
          -1,
          -1,
          'N'
      FROM
          query_received x1
      WHERE
          query_type_id = 0
      ;
      \p\g\t


      UPDATE 
          queries x1
      FROM
          x100_process_starting x2
      SET
          database_name = x2.database_name
      WHERE
          x1.process_id = x2.process_id
      ;
      \p\g\t


      UPDATE 
          queries x1
      FROM
          query_finished x2
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
          queries
      WHERE
         noof_rows    = -1
      OR running_time = -1 
      ;
      \p\g\t


      DROP TABLE IF EXISTS queries_summary;
      \p\g\t

      CREATE TABLE queries_summary
      AS SELECT 
          database_name                    AS database,
          DATE_FORMAT(log_timestamp, '%Y Wk %u Day %d Hr %H') 
                                           AS period, 
          DATE_FORMAT(log_timestamp, '%Y') AS year,
          DATE_FORMAT(log_timestamp, '%u') AS week,
          DATE_FORMAT(log_timestamp, '%d') AS day,
          DATE_FORMAT(log_timestamp, '%H') AS hour,
          COUNT(noof_rows)                 AS tot_queries,
          MAX(noof_rows)                   AS max_rows, 
          AVG(noof_rows)                   AS avg_rows, 
          STDDEV_POP(noof_rows)            AS std_dev_rows, 
          AVG(running_time)                AS mean_run_time, 
          MIN(running_time)                AS min_run_time, 
          MAX(running_time)                AS max_run_time, 
          STDDEV_POP(running_time)         AS std_dev_run_time, 
          IFNULL(MAX(Y.qtime_pct),0)       AS per_99_run_time
      FROM 
          queries sq 
          LEFT JOIN (SELECT
              period, 
              MAX(running_time) AS qtime_pct
           FROM 
              (SELECT 
                   DATE_FORMAT(log_timestamp, '%Y Wk %u Day %d Hr %H') AS period, 
                   running_time,
                   NTILE(100) OVER 
                       (PARTITION BY DATE_FORMAT(log_timestamp, '%y Wk %u Day %d Hr %H') 
                           ORDER BY running_time) AS percentile
               FROM 
                   queries
               ) X
          GROUP BY 
              period, 
              percentile
          HAVING 
              percentile = 99
          ) Y
              ON date_format(log_timestamp, '%Y Wk %u Day %d Hr %H') = Y.period
      GROUP BY 
          1, 2, 3, 4, 5, 6
      ORDER BY 
          database,
          period
      ;
      \p\g\t


      COPY queries_summary (
          database         = c0comma,
          year             = c0comma,
          week             = c0comma,
          day              = c0comma,
          hour             = c0comma,
          tot_queries      = c0comma,
          max_rows         = c0comma,
          avg_rows         = c0comma,
          std_dev_rows     = c0comma,
          mean_run_time    = c0comma,
          min_run_time     = c0comma,
          max_run_time     = c0comma,
          std_dev_run_time = c0comma,
          per_99_run_time  = c0nl
          )
      INTO 
          '$h_csv_summary.temp'
      ;
      \p\g\t


  " >> $h_sql_script
     
  sql $h_clv_logdb < $h_sql_script >> $h_clv_tmp_dir/$h_prog_name.log.$h_clf_pid

  { echo '"Database","Year","Week","Day","Hour","Total Queries","Max. Rows","Avg. Rows",'\
'"Std Deviation Rows","Mean Run Time","Min. Run Time","Max. Run Time",'\
'"Std Deviation Run Time","99 Percentile Run Time"' ; cat $h_csv_summary.temp; } > $h_csv_summary

  rm -f $h_csv_summary.temp
}


#----------------------------------------------------------------------------
# Function:
#   PRINT_USAGE
#     Print out the usage and exit
#----------------------------------------------------------------------------
PRINT_USAGE()
{
    printf "%s\n" "Usage:"
    printf "%s\n" "  $h_prog_name"

    printf "%s\n" "   --vector_log_file     {full path to vector log file}. Defaults to local installation."
    printf "%s\n" "   --system              {II_SYSTEM}. Defaults to local value of \$II_SYSTEM"
    printf "%s\n" "   --debug               If supplied, turns debug on. Defaults to off."
    printf "%s\n" "   --tmp_dir             {temporary directory}. Defaults to \$TEMP."
    printf "%s\n" "   --log_db              {database} to load analysis data into. Defaults to imadb."
    printf "%s\n" "   --noload              If supplied, don't load analysis data into database. Defaults to 0."
    printf "%s\n" "   --refresh             If supplied, delete all temp files and the database and start from scratch."

    printf "%s\n" ""
    printf "%s\n" "  $h_prog_name --help"
    printf "%s\n" "  $h_prog_name --version"
    printf "\n%s\n" "Output data is written to database tables named queries and query_summary"
    printf "%s\n" "In addition, a summarising CSV file is written to the temporary directory, and is"
    printf "%s\n" "called $h_csv_summary."
}


#----------------------------------------------------------------------------
# Function:
#   PRINT_HELP
#     Print out the help and exit
#----------------------------------------------------------------------------
PRINT_HELP()
{
    PRINT_REVISION
    printf "\n"
    PRINT_USAGE
    printf "\n"
}


#----------------------------------------------------------------------------
# Function:
#   PRINT_REVISION
#     Print out the programs revision number
#----------------------------------------------------------------------------
PRINT_REVISION()
{
    printf "Program Name...: $h_prog_name\n"
    printf "Revision.......: $h_prog_version\n"
    printf "\n"
}


#----------------------------------------------------------------------------
# MAIN PROGRAM
#----------------------------------------------------------------------------

# Default II_SYSTEM to the current value if there is one
h_clv_ii_system=$II_SYSTEM

# Default the database to use for performance info to imadb, since this is always present.
h_clv_logdb=imadb
h_clv_noload=0
h_clv_refresh=0
h_clv_debug=N


while [ -n "$1" ]
do
   case "$1" in

   --vector_log_file)
      h_clv_vector_log_file=$2
      shift
      shift
      ;;

   --system)
      h_clv_ii_system=$2
      shift
      shift
      ;;

   --debug)
      h_clv_debug=Y
      shift
      ;;

   --tmp_dir)
      h_clv_tmp_dir=$2
      shift
      shift
      ;;

   --log_db)
      h_clv_logdb=$2
      shift
      shift
      ;;

   --refresh)
      h_clv_refresh=1
      shift
      ;;

   --noload)
      h_clv_noload=1
      shift
      ;;

    -h|--help)
       PRINT_HELP
       exit 0
       ;;
 
    -V|--version)
       PRINT_REVISION $h_prog_name $h_prog_version
       exit 0
       ;;

    *)
       printf "%s\n" "Invalid parameter: $1"
       PRINT_USAGE
       exit 1
       ;;

   esac
done


# Validate CLV

if [ -z "$h_clv_ii_system" ]
then
    printf "%s\n" "II_SYSTEM not supplied and not in an existing installation."
    PRINT_USAGE
    exit 1
fi

if [ ! -d "$h_clv_ii_system" ]
then
    printf "%s\n" "II_SYSTEM value $h_clv_ii_system is not a directory."
    exit 1
fi

if [ -z "$h_clv_debug" ]
then
    printf "%s\n" "Debug state not supplied - defaulting to off."
    h_clv_debug=N
fi

# Default a TEMP location if one is not supplied
if [ ! -d $TEMP ]
then
    # Take a guess at a reasonable temp folder location if none given.
    export TEMP=/tmp
fi

if [ -z "$h_clv_tmp_dir" ]
then
    h_clv_tmp_dir=$TEMP
    printf "Temporary directory not supplied, so using $TEMP\n"
fi

if [ ! -d "$h_clv_tmp_dir" ]
then
    printf "TEMP folder $h_clv_tmp_dir is not a directory"
    exit 1
fi

# Need to set up the paths now to get the default vectorwise.log location
# Need to wrap the value in quotes in case there's a space in the path, e.g. on Windows
CLF_SETUPPATHS "$h_clv_ii_system"

if [ -z "$h_clv_vector_log_file" ]
then
    h_clv_vector_log_file=$II_LOG/vectorwise.log
    printf "The Vector log file was not supplied - defaulting to local installation.\n"
fi

if [ ! -f "$h_clv_vector_log_file" ]
then
    printf "Vector log file $h_clv_vector_log_file is not a file.\n"
    exit 1
fi

printf "Using database $h_clv_logdb for analysis data.\n"


# Processing starts here.

INITIALIZE

CLF_MESSAGELOG Program Name: $h_prog_name Starting

# If told to start from scratch, try to delete all tables and temp files first.
# Just ignore any errors that might arise from there not being anything there though.
if [ "${h_clv_refresh}" -eq "1" ] 
then
    sql $h_clv_logdb < drop_analysis_tables.sql >/dev/null 2>&1
fi

ANALYSE_VECTOR_LOG || TERMINATE $?

# Unless told otherwise, load the data into the analysis database.
# May just want to process the files for loading elsewhere, in which case
# don't tidy up the files produced either.

if [ "$h_clv_noload" == 0 ] 
then
    LOAD_ANALYSIS_DATA || TERMINATE $?

    # If we have loaded the data, then analyse it as well.

    PRODUCE_SUMMARY
    echo Completed summarising queries - please review summarise_queries.log for details, or check
    echo $h_csv_summary for a summary of query data. 
    echo Raw query data is stored in tables 'queries' and 'queries_summary' in database $h_clv_logdb.
else
    # Clean up all files we produced if everything went fine.
    # Assume we don't want to keep the files around.
    CLF_TIDYUP 0
fi

TERMINATE 0


#------------------------------------------------------------------------------
# End of script
#------------------------------------------------------------------------------
