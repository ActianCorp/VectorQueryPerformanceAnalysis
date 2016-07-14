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
#   parse_vector_log.awk 
#
# Description:
#
#   This script parses the contents of the main Vector log file vectorwise.log
#   to extract data related to query execution performance.
#   It outputs that filtered data into a CSV file for subsequent loading into  
#   a database for analysis.
#
#----------------------------------------------------------------------------

BEGIN {
    h_awk_input_line_count = 0

    h_awk_noof_pid = 0
    h_awk_noof_pid_tid = 0
    h_awk_noof_pid_tid_sid = 0
    h_awk_noof_pid_tid_sid_txid = 0

    h_awk_noof_databases = 0

    h_awk_query_type_id_idx = 0
    queries = 0
}


#----------------------------------------------------------------------------
# Main Program
#----------------------------------------------------------------------------
{
    #----------------------------------------------------------------------------
    # Set input_line to be the current line being read from vectorwise.log
    #----------------------------------------------------------------------------
    
    h_awk_input_line = $0

    #----------------------------------------------------------------------------
    # Increment the line count
    #----------------------------------------------------------------------------
    
    h_awk_input_line_count++

    #----------------------------------------------------------------------------
    # Split the line into words
    #----------------------------------------------------------------------------
    
    FS=" "
    h_awk_input_line_noof_words = split( h_awk_input_line, ha_awk_input_line )

    #----------------------------------------------------------------------------
    # Pull out the date and time from the record
    #----------------------------------------------------------------------------

    h_awk_log_record_year  = substr( ha_awk_input_line[1], 1, 4 )
    h_awk_log_record_month = substr( ha_awk_input_line[1], 6, 2 )
    h_awk_log_record_day   = substr( ha_awk_input_line[1], 9, 2 )

    h_awk_log_record_hour = substr( ha_awk_input_line[2], 1, 2 )
    h_awk_log_record_min  = substr( ha_awk_input_line[2], 4, 2 )
    h_awk_log_record_sec  = substr( ha_awk_input_line[2], 7, 2 )

    #----------------------------------------------------------------------------
    # Depending on the vwlog.conf settings, the log date and time may be reported
    # down to seconds, or milli seconds.
    # If we have ms, then pull these out, otherwise set ms to zero.
    #----------------------------------------------------------------------------
    
    if ( length(ha_awk_input_line[2]) > 8 ) {
        h_awk_log_record_ms = substr( ha_awk_input_line[2], 10, 6 )
    } else h_awk_log_record_ms = 0

    #----------------------------------------------------------------------------
    # Not that it really has to be done, convert the month number into a string.
    #----------------------------------------------------------------------------
    
    h_awk_log_record_month_name = ""

    if ( h_awk_log_record_month == "01" )        h_awk_log_record_month_name = "Jan"
    if ( h_awk_log_record_month == "02" )        h_awk_log_record_month_name = "Feb"
    if ( h_awk_log_record_month == "03" )        h_awk_log_record_month_name = "Mar"
    if ( h_awk_log_record_month == "04" )        h_awk_log_record_month_name = "Apr"
    if ( h_awk_log_record_month == "05" )        h_awk_log_record_month_name = "May"
    if ( h_awk_log_record_month == "06" )        h_awk_log_record_month_name = "Jun"
    if ( h_awk_log_record_month == "07" )        h_awk_log_record_month_name = "Jul"
    if ( h_awk_log_record_month == "08" )        h_awk_log_record_month_name = "Aug"
    if ( h_awk_log_record_month == "09" )        h_awk_log_record_month_name = "Sep"
    if ( h_awk_log_record_month == "10" )        h_awk_log_record_month_name = "Oct"
    if ( h_awk_log_record_month == "11" )        h_awk_log_record_month_name = "Nov"
    if ( h_awk_log_record_month == "12" )        h_awk_log_record_month_name = "Dec"

    #----------------------------------------------------------------------------
    # Build a string to contain the log date and time.  This will be used in
    # just about every CSV file.
    #----------------------------------------------------------------------------

    h_awk_log_timestamp =  h_awk_log_record_day "-" h_awk_log_record_month_name "-" h_awk_log_record_year " " h_awk_log_record_hour ":" h_awk_log_record_min ":" h_awk_log_record_sec "." h_awk_log_record_ms

    #----------------------------------------------------------------------------
    # Ignore entries older than the last run date/time.                           
    #----------------------------------------------------------------------------

    h_awk_log_datetime =  h_awk_log_record_year h_awk_log_record_month h_awk_log_record_day h_awk_log_record_hour h_awk_log_record_min h_awk_log_record_sec "." h_awk_log_record_ms

#    printf ("Log Date/time : " h_awk_log_datetime ", Last Date/Time : " h_awk_lastrun_timestamp "\n")

    if ( h_awk_log_datetime <= h_awk_lastrun_timestamp ) {
        next
    }

    #----------------------------------------------------------------------------
    #    Pull out the PID
    #                                          
    #    This will indicated by the label " PID " followed by an integer in the
    #    4th word of the input line terminated by a colon.
    #    For example: 2015-12-04 17:10:23 PID 30136:TID 
    #----------------------------------------------------------------------------

    h_awk_index = index ( h_awk_input_line, " PID " )

    if ( h_awk_index != 0 ) {
    
        FS=":"
        h_awk_split_count = split( ha_awk_input_line[4], ha_awk_split_word )

        h_awk_pid = ha_awk_split_word[1]
    }


    #----------------------------------------------------------------------------
    #    Pull out the TID
    #                                          
    #    This will indicated by the label ":TID " followed by an integer in the
    #    5th word of the input line terminated by a colon.
    #    For example: 2015-12-01 14:31:59 PID 59519:TID 140519298610944:SID 
    #----------------------------------------------------------------------------

    h_awk_index = index ( h_awk_input_line, ":TID " )

    if ( h_awk_index != 0 ) {
    
        FS=":"
        h_awk_split_count = split( ha_awk_input_line[5], ha_awk_split_word )

        h_awk_tid = ha_awk_split_word[1]
    }


    #----------------------------------------------------------------------------
    #    Pull out the SID
    #                                          
    #    This will indicated by the label ":SID " followed by an integer in the
    #    6th word of the input line terminated by a colon.
    #    For example: 2015-12-01 14:31:59 PID 59519:TID 140519298610944:SID 3:
    #----------------------------------------------------------------------------

    h_awk_index = index ( h_awk_input_line, ":SID " )

    if ( h_awk_index != 0 ) {
    
        FS=":"
        h_awk_split_count = split( ha_awk_input_line[6], ha_awk_split_word )

        h_awk_sid = ha_awk_split_word[1]
    }


    #----------------------------------------------------------------------------
    #    Pull out the TXID
    #                                          
    #    This will indicated by the label ":TXID " followed by an integer in the
    #    6th word of the input line terminated by a colon.
    #    For example: 2015-12-01 14:31:59 PID 59519:TID 140519298610944:SID 3:TXID 487:
    #----------------------------------------------------------------------------

    h_awk_index = index ( h_awk_input_line, ":TXID " )

    if ( h_awk_index != 0 ) {

        FS=":"
        h_awk_split_count = split( ha_awk_input_line[7], ha_awk_split_word )

        h_awk_txid = ha_awk_split_word[1]
    }


    #----------------------------------------------------------------------------
    #    Is this an X100 process starting?
    #                                          
    #    The database for which the x100 process is being started is the 9th
    #    word.  The database name is enclosed in single quotes - which we need
    #    to remove.
    #    For example: INFO:SYSTEM:Started for database 'mercdb1' in
    #----------------------------------------------------------------------------

    h_awk_index = index ( h_awk_input_line, "Started for database " )

    if ( h_awk_index != 0 ) {
        h_awk_database = ha_awk_input_line[9]

        gsub( h_awk_single_quote, "", h_awk_database )

        printf ( h_awk_log_timestamp  "\t" NR "\t" h_awk_pid "\t" h_awk_tid "\t" h_awk_database "\n" ) >> h_awk_csv_x100_process_starting

        next
    }


    #----------------------------------------------------------------------------
    #    Is this a query received.                                    
    #                                          
    #    Note that I have started to attempt to try and work out what type of query this
    #    is.  This is by no means complete (nor possibly the best way of achieving this)
    #    but its a start.
    #    This is being done simply by searching for strings in the query and assigning
    #    a "query type id" to any matches.  Please also note that some of the queries 
    #    are appearing in slightly different styles (e.g. "Sys" and "sys").  Where possible
    #    these are being treated the same.
    #    In due course (not currently being done) there is supposed to be another lookup
    #    table (query_type) which will be populated by this script with a code (ID) and
    #    description.
    #    For example: :TXID 716818: INFO:X100SERVER:Query received: [commit(true)] query_id=27
    #----------------------------------------------------------------------------

    h_awk_index = index ( h_awk_input_line, "Query received: ")
    h_awk_start_of_string = h_awk_index

    if ( h_awk_index != 0 ) {

        queries++

        h_awk_query_type_id = 0

        h_awk_index = index ( h_awk_input_line, "get_transaction_id" )

        if ( h_awk_index != 0 )          h_awk_query_type_id = 1

        h_awk_index = index ( h_awk_input_line, "set_read_only" )

        if ( h_awk_index != 0 )          h_awk_query_type_id = 2

        h_awk_index = index ( h_awk_input_line, "exchange_session_ids" )

        if ( h_awk_index != 0 )          h_awk_query_type_id = 3

        h_awk_index = index ( h_awk_input_line, "[commit(true)]" )

        if ( h_awk_index != 0 )          h_awk_query_type_id = 4

        h_awk_index = index ( h_awk_input_line, "[Commit(true)]" )

        if ( h_awk_index != 0 )          h_awk_query_type_id = 4

        h_awk_index = index ( h_awk_input_line, "[abort]" )

        if ( h_awk_index != 0 )          h_awk_query_type_id = 5

        h_awk_index = index ( h_awk_input_line, "[Savepoint" )

        if ( h_awk_index != 0 )          h_awk_query_type_id = 6

        h_awk_index = index ( h_awk_input_line, "[sys(getconf" )

        if ( h_awk_index != 0 )          h_awk_query_type_id = 7

        h_awk_index = index ( h_awk_input_line, "[Sys(getconf" )

        if ( h_awk_index != 0 )          h_awk_query_type_id = 7

        h_awk_index = index ( h_awk_input_line, "[sys(setconf" )

        if ( h_awk_index != 0 )          h_awk_query_type_id = 8

        h_awk_index = index ( h_awk_input_line, "[Sys(setconf" )

        if ( h_awk_index != 0 )           h_awk_query_type_id = 8

        h_awk_index = index ( h_awk_input_line, "[commit]" )

        if ( h_awk_index != 0 )           h_awk_query_type_id = 9

        h_awk_partial_line = substr( h_awk_input_line, h_awk_start_of_string + 16, length(h_awk_input_line) )

        h_awk_index = index ( h_awk_partial_line, " query_id=")

        h_awk_query = substr( h_awk_partial_line, 1, h_awk_index )

        gsub( "%", "%%", h_awk_query )

        h_query_id_string = substr( h_awk_partial_line, h_awk_index, length(h_awk_partial_line) )

        FS="="

        h_awk_split_count = split( h_query_id_string, ha_awk_split_word )
        h_awk_query_id = ha_awk_split_word[2]

        gsub( "\t", " ", h_awk_query )

        if ( length(h_awk_query) > 10000 ) {
            h_awk_query = substr( h_awk_query, 1, 10000 )
            h_awk_query_truncated = "Y"
        } else h_awk_query_truncated = "N"

        #----------------------------------------------------------------------------
        # During testing, it was discovered that one of the CSV files generated
        # managed to fail to load (even though there was an "on error=continue" in
        # the COPY statement.
        # It transpired that the problem was caused by a SINGLE query that was over
        # 51K in size!
        # It was thus decided to truncate any lines longer than the 10K which have
        # been provided for, and include a TRUNCATE flag set to Y or N.
        #
        # TODO: re-address this to be able to load queries of arbitrary size.
        #----------------------------------------------------------------------------

        printf ( h_awk_log_timestamp  "\t" NR "\t" h_awk_pid "\t" h_awk_tid "\t" h_awk_sid "\t" "unknown" "\t" h_awk_query_id "\t" h_awk_query_truncated "\t" h_awk_query_type_id "\n" ) >> h_awk_csv_query_received

        next
    }


    #----------------------------------------------------------------------------
    #    Is this a query finished 
    #----------------------------------------------------------------------------

    h_awk_index = index ( h_awk_input_line, "Query finished with error")

    if ( h_awk_index != 0 ) {
        next
    }

    h_awk_index = index ( h_awk_input_line, "Query finished")

    if ( h_awk_index != 0 ) {

        h_awk_index = index ( h_awk_input_line, ":TXID " )

        # Transaction query - 0 or more rows.      
        if ( h_awk_index != 0 ) {
        
            h_awk_noof_rows = ha_awk_input_line[11]

            h_awk_running_time = ha_awk_input_line[14]
            gsub( ")", "", h_awk_running_time )
            gsub( "s", "", h_awk_running_time )
            gsub( ",", "", h_awk_running_time )
        }

        # Non-transaction query
        if ( h_awk_index = 0 ) {

            h_awk_noof_rows = ha_awk_input_line[10]

            h_awk_running_time = ha_awk_input_line[13]
            gsub( ")", "", h_awk_running_time )
            gsub( "s", "", h_awk_running_time )
            gsub( ",", "", h_awk_running_time )
        }

        h_qry_index = index( h_awk_input_line, "query_id=" )

        if ( h_qry_index != 0 ) {

            h_qry_details = substr( h_awk_input_line, h_qry_index )
            FS=" "
            h_awk_count = split( h_qry_details, ha_qry_details )
            FS="="
            h_awk_count = split( ha_qry_details[1], ha_qry_parts )

            h_awk_query_id = ha_qry_parts[2]

        } else next


        printf ( h_awk_log_timestamp  "\t" NR "\t" h_awk_pid "\t" h_awk_tid "\t" h_awk_sid "\t" "unknown" "\t" h_awk_running_time "\t" h_awk_query_id "\t" h_awk_noof_rows "\n" ) >> h_awk_csv_query_finished

        next
    }

	next
}


END {
    printf ("Processed " h_awk_input_line_count " log records in total and found " queries " queries.\n")
    if ( queries == 0 ) {
        printf ("No queries usually means that the vectorwise log level is not set to INFO in\n")
        printf ("vectorwise.conf. Please change this and restart to gather query performance data.\n")
    }
}


#------------------------------------------------------------------------------
# End of awk script
#------------------------------------------------------------------------------
