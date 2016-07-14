#!/bin/bash
#
# Copyright 2016 Actian Corporation
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
#
#   load_vector_log.sh
#
# Description:
#
#   This script analyses the contents of the Actian Vector log file,
#   vectorwise.log, for data related to query performance. 
#   This data is extracted and loaded into database tables in the specified 
#   database for later reporting.
#
#----------------------------------------------------------------------------

h_prog_name=`basename ${0}`
h_prog_version=v1.0

. common_functions.sh


#----------------------------------------------------------------------------
# Function:
#   INITIALIZE - set up local variables.
#----------------------------------------------------------------------------
function INITIALIZE()
{
    # Enviroment setup:

    CLF_SETUPCOMMONVARIABLES
    CLF_CREATELOGFILES

    # Create the CSV files to store query data extracted from the vectorwise.log

    export h_csv_x100_process_starting=$h_clv_tmp_dir/$h_prog_name.x100_process_starting.$h_clf_pid
    CLF_CREATEFILE $h_csv_x100_process_starting

    export h_csv_query_received=$h_clv_tmp_dir/$h_prog_name.query_received.$h_clf_pid
    CLF_CREATEFILE $h_csv_query_received

    export h_csv_query_finished=$h_clv_tmp_dir/$h_prog_name.query_finished.$h_clf_pid
    CLF_CREATEFILE $h_csv_query_finished
}


#----------------------------------------------------------------------------
# Function:
#   CREATE_LOG_SCHEMA
#     Create the analysis schema to support the query analysis.
#----------------------------------------------------------------------------
function CREATE_LOG_SCHEMA()
{
    CLF_MESSAGELOG Function: CREATE_LOG_SCHEMA

    # Check the supplied database exists and is accessible.

    ERRORS=`echo "create table log_test (col1 int);drop table log_test\g" | sql $h_clv_logdb | grep "E_" | wc -l`

    if [ "$ERRORS" -gt 0 ]
    then
        # The database is NOT accessible.                                               
        CLF_MESSAGELOG "Error attempting to access database $h_clv_logdb. Please correct and try again."
        return 1
    fi

    # Check if the analysis schema exists.

    ERRORS=`echo "SELECT COUNT(*) FROM vqat_last_load;\g" | sql $h_clv_logdb | grep "^E_" | wc -l`

    # Create the schema if it doesn't exist.
      
    if [ "$ERRORS" -ne 0 ]
    then
        CLF_MESSAGELOG "Schema to be created in database $h_clv_logdb."
        sql $h_clv_logdb < create_analysis_tables.sql >> $h_clf_message_log

        RETCODE=$?
        ERRORS=`grep "^E_" $h_clf_message_log | wc -l`

        if [ "$ERRORS" -gt 0 -o $RETCODE -gt 0 ]
        then
            # Errors found creating the schema, so exit
            CLF_MESSAGELOG "Errors creating schema in database $h_clv_logdb. Please correct and try again."
            CLF_MESSAGELOG "Check log file $h_clf_message_log for details of the errors."
            return 1
        fi
    fi

    CLF_MESSAGELOG "Schema created successfully."
}


#----------------------------------------------------------------------------
# Function:
#   VECTOR_LOG_EXTRACT
#     Extract new Vector log entries since the last run.
#     Only: X100 Starts, Query received and Query finished.
#----------------------------------------------------------------------------
function VECTOR_LOG_EXTRACT()
{
   CLF_MESSAGELOG Function: VECTOR_LOG_EXTRACT

    # Get the date/time of the last load

sql ${h_clv_logdb} > ${h_clv_tmp_dir}/${h_prog_name}.last_load.${h_clf_pid} <<EOF
    SELECT 'DATE', lastrun_timestamp FROM vqat_last_load\g
EOF

    export h_lastrun_timestamp=`cat ${h_clv_tmp_dir}/${h_prog_name}.last_load.${h_clf_pid} | grep 'DATE' | awk -F '|' '{print $3}' | sed "s/-//g;s/ //;s/://g"`

    CLF_MESSAGELOG "Last Load date : " ${h_lastrun_timestamp} 

    # Run the awk script to extract new log entries since the last run

    gawk -v h_awk_debug=$h_clv_debug \
         -v h_awk_single_quote=\' \
         -v h_awk_csv_logs=$h_csv_logs \
         -v h_awk_csv_query_type=$h_csv_query_type \
         -v h_awk_csv_x100_process_starting=$h_csv_x100_process_starting  \
         -v h_awk_csv_query_received=$h_csv_query_received \
         -v h_awk_csv_query_finished=$h_csv_query_finished \
         -v h_awk_lastrun_timestamp="$h_lastrun_timestamp" \
         -f parse_vector_log.awk $h_clv_vector_log_file

    return 0
}


#----------------------------------------------------------------------------
# Function:
#   LOAD_LOG_DATA
#     Load the extracted Vector log data into temporary tables.
#----------------------------------------------------------------------------
function LOAD_LOG_DATA()
{
    CLF_MESSAGELOG Function: LOAD_LOG_DATA

    # Check the supplied database exists and is accessible.

    ERRORS=`echo "create table log_test (col1 int);drop table log_test\g" | sql $h_clv_logdb | grep "E_" | wc -l`

    if [ "$ERRORS" -gt 0 ]
    then
        # The database is NOT accessible.                                               
        CLF_MESSAGELOG "Error in being able to write to database $h_clv_logdb. Please correct and try again."
        return 1
    fi

    # Run the script to load in all of the files created into temporary tables. 

    cat load_analysis_data.sql | envsubst | sql $h_clv_logdb >> $h_clf_message_log

    RETCODE=$?
    ERRORS=`grep "^E_" $h_clf_message_log | wc -l`

    if [ "$ERRORS" -gt 0 -o $RETCODE -gt 0 ]
    then
        # Errors found in loading data, so exit
        CLF_MESSAGELOG "Errors loading data to database $h_clv_logdb. Please correct and try again."
        CLF_MESSAGELOG "Check log file $h_clf_message_log for details of the errors."
        return 1
    fi
      
    CLF_MESSAGELOG "Analysis data loaded successfully to tables in $h_clv_logdb."
}


#----------------------------------------------------------------------------
# Function:
#   PROCESS_LOG_DATA
#     Consolidate the new Vector log data and merge with existing historic data.
#----------------------------------------------------------------------------
function PROCESS_LOG_DATA()
{
    CLF_MESSAGELOG Function: PROCESS_LOG_DATA

    # Run the script to process the temporary tables and update the analysis data.

    cat process_analysis_data.sql | envsubst | sql $h_clv_logdb >> $h_clf_message_log

    RETCODE=$?
    ERRORS=`grep "^E_" $h_clf_message_log | wc -l`

    if [ "$ERRORS" -gt 0 -o $RETCODE -gt 0 ]
    then
        # Errors found in processing data, so exit
        CLF_MESSAGELOG "Errors configuring data to database $h_clv_logdb. Please correct and try again."
        CLF_MESSAGELOG "Check log file $h_clf_message_log for details of the errors."
        return 1
    fi
      
    CLF_MESSAGELOG "Analysis data processed and merged successfully to tables in $h_clv_logdb."
}


#----------------------------------------------------------------------------
# Function:
#   PRINT_USAGE
#     Print out the usage and exit.
#----------------------------------------------------------------------------
function PRINT_USAGE()
{
    printf "%s\n" "Usage:"
    printf "%s\n" "  $h_prog_name"

    printf "%s\n" "   --vector_log_file     {full path to vector log file}. Defaults to local installation."
    printf "%s\n" "   --system              {II_SYSTEM}. Defaults to local value of \$II_SYSTEM"
    printf "%s\n" "   --debug               If supplied, turns debug on. Defaults to off."
    printf "%s\n" "   --tmp_dir             {temporary directory}. Defaults to \$TEMP."
    printf "%s\n" "   --log_db              {database} to load analysis data into. Mandatory."
    printf "%s\n" "   --refresh             If supplied, clear the database and start from scratch."

    printf "%s\n" ""
    printf "%s\n" "  $h_prog_name --help"
    printf "%s\n" "  $h_prog_name --version"
    printf "\n%s\n" "Vector query information is stored in a database for subsequent analysis."
}


#----------------------------------------------------------------------------
# MAIN PROGRAM
#----------------------------------------------------------------------------

INITIALIZE

CLF_MESSAGELOG Program Name: $h_prog_name Starting

# Set the various defaults (which may be overriden by the parameters).

h_clv_ii_system=$II_SYSTEM
h_clv_refresh=0
h_clv_debug=N

# Parameters passed.

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

    -h|--help)
       PRINT_HELP
       exit 0
       ;;
 
    -V|--version)
       PRINT_REVISION $h_prog_name $h_prog_version
       exit 0
       ;;

    *)
       CLF_MESSAGELOG "Invalid parameter: $1"
       PRINT_USAGE
       exit 1
       ;;

   esac
done

# Validation

if [ -z "$h_clv_ii_system" ]
then
    CLF_MESSAGELOG "II_SYSTEM not supplied and not in an existing installation."
    PRINT_USAGE
    exit 1
fi

if [ ! -d "$h_clv_ii_system" ]
then
    CLF_MESSAGELOG "II_SYSTEM value $h_clv_ii_system is not a directory."
    exit 1
fi

if [ -z "$h_clv_logdb" ]
then
    CLF_MESSAGELOG "Analysis log database not supplied."
    PRINT_USAGE
    exit 1
fi

if [ -z "$h_clv_debug" ]
then
    CLF_MESSAGELOG "Debug state not supplied - defaulting to off."
    h_clv_debug=N
fi

# Set up the paths now to get the default vectorwise.log location
# Wrap the value in quotes in case there's a space in the path, e.g. on Windows

CLF_SETUPPATHS "$h_clv_ii_system"

if [ -z "$h_clv_vector_log_file" ]
then
    h_clv_vector_log_file=$II_LOG/vectorwise.log
    CLF_MESSAGELOG "The Vector log file was not supplied - defaulting to local installation."
fi

if [ ! -f "$h_clv_vector_log_file" ]
then
    CLF_MESSAGELOG "Vector log file $h_clv_vector_log_file is not a file."
    exit 1
fi

# Check the installtion is correctly configured for this analysis

if [ "`grep '^default' ${II_LOG}/vwlog.conf | grep 'info' | wc -l`" -eq 0 -o \
     "`grep '^SYSTEM' ${II_LOG}/vwlog.conf | grep 'info' | wc -l`" -eq 0 ]     
then
    CLF_MESSAGELOG "The installtion ${II_SYSTEM} supplied is not configured for query analysis"
    exit 1
fi

# If a refresh delete ALL the schema tables.                                             

if [ "${h_clv_refresh}" -eq "1" ] 
then
    sql $h_clv_logdb < drop_analysis_tables.sql >/dev/null 2>&1
fi

# If the first run or a refresh create the schema

CREATE_LOG_SCHEMA || TERMINATE $?

# Extract new log data

VECTOR_LOG_EXTRACT || TERMINATE $?

# Load the new log data into the database

LOAD_LOG_DATA || TERMINATE $?

# Create query summary detail and load for later query analysis

PROCESS_LOG_DATA || TERMINATE $?

CLF_MESSAGELOG Program Name: $h_prog_name Finished Successfully

# Clean up all files created this run

CLF_TIDYUP 

exit 0


#------------------------------------------------------------------------------
# End of shell script
#------------------------------------------------------------------------------
