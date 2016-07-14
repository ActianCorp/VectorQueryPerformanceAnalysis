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
#   report_vector_log.sh
#
# Description:
#
#   This script produces a CSV file performance analysis from the Vector 
#   query data collected by load_vector_log.sh.
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

    # Create script files

    export h_sql_script=$h_clv_tmp_dir/$h_prog_name.report_generated_sql.$h_clf_pid
    CLF_CREATEFILE $h_sql_script
   
    export h_csv_summary=$h_clv_tmp_dir/VECTOR_LOG_ANALYSIS.csv
    CLF_CREATEFILE $h_csv_summary
}


#----------------------------------------------------------------------------
# Function:
#   VECTOR_LOG_REPORT
#     Create a CSV query analysis summary for the date range supplied.
#----------------------------------------------------------------------------
function VECTOR_LOG_REPORT()
{
    CLF_MESSAGELOG Function: VECTOR_LOG_REPORT

    # Build the dynamic analysis SQL   

    echo "

        \nocontinue

        DROP TABLE IF EXISTS vqat_queries_summary;
        \p\g\t

        CREATE TABLE vqat_queries_summary
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
            vqat_queries sq 
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
                     vqat_queries
                 ) X
            GROUP BY 
                period, 
                percentile
            HAVING 
                percentile = 99
            ) Y
                ON date_format(log_timestamp, '%Y Wk %u Day %d Hr %H') = Y.period
        WHERE
            log_timestamp >= DATE('${h_clv_start_date}')
    " >> $h_sql_script


    if [ -z "$h_clv_end_date" ]
    then
        echo "
            AND log_timestamp <= DATE('NOW')
        " >> $h_sql_script
    else
        echo "
            AND log_timestamp <= DATE('${h_clv_end_date}')
        " >> $h_sql_script
    fi


    if [ "$h_clv_ignore" == 'Y' ]
    then
        echo "
            AND database_name != '${h_clv_logdb}'
        " >> $h_sql_script
    fi


    echo "
        GROUP BY 
            1, 2, 3, 4, 5, 6
        ORDER BY 
            database,
            period
        ;
        \p\g\t


        COPY vqat_queries_summary (
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


    if [ -z "$h_clv_end_date" ]
    then
        echo "
            UPDATE
                vqat_last_analysis
            SET
                lastrun_timestamp = DATE('NOW')
            ;
            \p\g\t
        " >> $h_sql_script
    else
        echo "
            UPDATE
                vqat_last_analysis
            SET
                lastrun_timestamp = DATE('${h_clv_end_date}')
            WHERE
                lastrun_timestamp <= DATE('${h_clv_end_date}')
            ;
            \p\g\t
        " >> $h_sql_script
    fi

    echo "
        COMMIT
        ;
        \p\g\t
    " >> $h_sql_script

    # Run the dynamic analysis SQL   
     
    cat $h_sql_script | envsubst | sql $h_clv_logdb >> $h_clf_message_log
    RETCODE=$?
    ERRORS=`grep "^E_" $h_clf_message_log | wc -l`

    # Check for any errors 

    if [ "$ERRORS" -gt 0 -o $RETCODE -gt 0 ]
    then
        # Errors found in processing data, so exit
        CLF_MESSAGELOG "Errors producing CSV report from database $h_clv_logdb. Please correct and try again."
        CLF_MESSAGELOG "Check log file $h_clf_message_log for details of the errors."
        return 1
    fi

    # Add a column header to the CSV file.

    { echo '"Database","Year","Week","Day","Hour","Total Queries","Max. Rows","Avg. Rows",'\
'"Std Deviation Rows","Mean Run Time","Min. Run Time","Max. Run Time",'\
'"Std Deviation Run Time","99 Percentile Run Time"' ; cat $h_csv_summary.temp; } > $h_csv_summary

    rm -f $h_csv_summary.temp

    CLF_MESSAGELOG "CSV Analysis Report sucessfully produced in file: ${h_csv_summary}."
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

    printf "%s\n" "   --system              {II_SYSTEM}. Defaults to local value of \$II_SYSTEM"
    printf "%s\n" "   --debug               If supplied, turns debug on. Defaults to off."
    printf "%s\n" "   --tmp_dir             {temporary directory}. Defaults to \$TEMP."
    printf "%s\n" "   --log_db              {database} to load analysis data into. Defaults to imadb."
    printf "%s\n" "   --start_date          Start date of the Vector query analysis (YYYY-MM-DD hh:mm:ss).  Defaults to last analysis end date."
    printf "%s\n" "   --end_date            End date of the Vector query analysis (YYYY-MM-DD hh:mm:ss).  Defaults to 'now'."
    printf "%s\n" "   --ignore_analysis_db  Ignore the queries from the analysis database. Defaults to No."

    printf "%s\n" ""
    printf "%s\n" "  $h_prog_name --help"
    printf "%s\n" "  $h_prog_name --version"
    printf "\n%s\n" "A query summary is produced for the start and end dates supplied "
    printf "%s\n" "called $h_csv_summary."
}


#----------------------------------------------------------------------------
# MAIN PROGRAM
#----------------------------------------------------------------------------

INITIALIZE

CLF_MESSAGELOG Program Name: $h_prog_name Starting

# Default II_SYSTEM to the current value if there is one
h_clv_ii_system=$II_SYSTEM

# Default the database to use for performance info to imadb, since this is always present.
h_clv_logdb=imadb
h_clv_debug=N
h_clv_ignore=N

# Parameters passed.

while [ -n "$1" ]
do
   case "$1" in

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

   --start_date)
      h_clv_start_date=$2
      shift
      shift
      ;;

   --end_date)
      h_clv_end_date=$2
      shift
      shift
      ;;

   --ignore_analysis_db)
      h_clv_ignore=Y
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


# Validation

if [ -z "$h_clv_ii_system" ]
then
    CLF_MESSAGELOG "II_SYSTEM not supplied and not in an existing installation."
    PRINT_USAGE
    exit 1
fi

if [ -z "$h_clv_start_date" ]
then
    # Get the date/time of the last vector log entries load

sql ${h_clv_logdb} > ${h_clv_tmp_dir}/${h_prog_name}.last_analysis.${h_clf_pid} <<EOF
    SELECT 'DATE', lastrun_timestamp FROM vqat_last_analysis\g
EOF
    export h_clv_start_date=`cat ${h_clv_tmp_dir}/${h_prog_name}.last_analysis.${h_clf_pid} | grep 'DATE' | awk -F '|' '{print $3}'`
    CLF_MESSAGELOG "Analysis start date not supplied. Defaulted to last analysis end date."
fi

if [ -z "$h_clv_end_date" ]
then
    CLF_MESSAGELOG "Analysis end date not supplied. Defaulted to 'now'."
fi

ERRORS=`echo "SELECT DATE('${h_clv_start_date}')\g" | sql ${h_clv_logdb} | grep "^E_" | wc -l`

if [ "$ERRORS" -gt 0 ]
then
    CLF_MESSAGELOG "Analysis start date incorrectly formatted."
    PRINT_USAGE
    exit 1
fi

ERRORS=`echo "SELECT DATE('${h_clv_end_date}')\g" | sql ${h_clv_logdb} | grep "^E_" | wc -l`

if [ "$ERRORS" -gt 0 ]
then
    CLF_MESSAGELOG "Analysis end date incorrectly formatted."
    PRINT_USAGE
    exit 1
fi


if [ ! -d "$h_clv_ii_system" ]
then
    CLF_MESSAGELOG "II_SYSTEM value $h_clv_ii_system is not a directory."
    exit 1
fi

if [ -z "$h_clv_debug" ]
then
    CLF_MESSAGELOG "Debug state not supplied - defaulting to off."
    h_clv_debug=N
fi

CLF_MESSAGELOG "Using database $h_clv_logdb for analysis data."

# Run the query analysis for the requested date range

VECTOR_LOG_REPORT || TERMINATE $?

# Clean up all files created this run

CLF_MESSAGELOG Program Name: $h_prog_name Finished Successfully

CLF_TIDYUP 

exit 0


#------------------------------------------------------------------------------
# End of shell script
#------------------------------------------------------------------------------
