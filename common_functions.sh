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
#   common_functions.sh
#
# Description:
#
#   This script contains the common functions utilised by the other scripts.
#
#----------------------------------------------------------------------------


#----------------------------------------------------------------------------
# Function:
#   TERMINATE 
#     Exit the program.
#----------------------------------------------------------------------------
function TERMINATE()
{

    if [ "$1" != 0 ]
    then
        CLF_MESSAGELOG Program Name: $h_prog_name FAILED. Please check the logs in $h_clv_tmp_dir
        exit 1
    fi

    exit 0
}


#----------------------------------------------------------------------------
# Function:
#   CLF_SETUPCOMMONVARIABLES
#      Setup variables used by most (if not all) scripts.
#----------------------------------------------------------------------------
function CLF_SETUPCOMMONVARIABLES
{
    # PID of current process
    
    export h_clf_pid=$$

    # To ensure consistency when writing out data files, set II_DATE_FORMAT to
    # MULTINATIONAL4
    
    export II_DATE_FORMAT=MULTINATIONAL4

    # Default a TEMP location if one is not supplied

    if [ -z $TEMP ]
    then
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

    return 0
}


#----------------------------------------------------------------------------
# Function:
#   CLF_CURDATETIME
#      Setup the current date and time.
#----------------------------------------------------------------------------
function CLF_CURDATETIME
{
    # Setup the current system date and time

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
#     Create a supplied file name.
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
#     Check whether the command executed has worked.
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
#     Log a message to the default log file and console for this run.
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
#     Create the log file for output and messages.
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
    h_clf_message_log=$h_clv_tmp_dir/$h_prog_name.log.$h_clf_pid

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
#     Tidy temporary files created this run.                 
#----------------------------------------------------------------------------
function CLF_TIDYUP
{
    # Quit if all required variables not set (unlikely)

    if [ -z "$h_prog_name" -o -z "$h_clf_pid" -o -z "$h_clv_tmp_dir" ]
    then
        return 0
    fi

    # Delete all TMP and LOG files created from this run.

    rm -f $h_clv_tmp_dir/$h_prog_name.*.$h_clf_pid 2>/dev/null

    return 0
}


#----------------------------------------------------------------------------
# Function:
#   CLF_SETUPPATHS   
#     Set the essential Vector environment variables.        
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

    # Setup Vector PATHs

    export PATH="$II_SYSTEM/ingres/bin:$II_SYSTEM/ingres/utility:$PATH"

    if [ "$LD_LIBRARY_PATH" ] ; then
        LD_LIBRARY_PATH=/usr/local/lib:$II_SYSTEM/ingres/lib:$II_SYSTEM/ingres/lib/lp32:$LD_LIBRARY_PATH
    else
        LD_LIBRARY_PATH=/lib:/usr/lib:/usr/local/lib:$II_SYSTEM/ingres/lib:$II_SYSTEM/ingres/lib/lp32
    fi
    export LD_LIBRARY_PATH

    export `ingprenv |grep II_LOG` > /dev/null

    if [ -z $II_LOG ]
    then
        export II_LOG=$II_SYSTEM/ingres/files
    fi

    return 0
}


#----------------------------------------------------------------------------
# Function:
#   PRINT_HELP
#     Print out the help and exit.
#----------------------------------------------------------------------------
function PRINT_HELP()
{
    PRINT_REVISION
    printf "\n"
    PRINT_USAGE
    printf "\n"
}


#----------------------------------------------------------------------------
# Function:
#   PRINT_REVISION
#     Print out the programs revision number.
#----------------------------------------------------------------------------
function PRINT_REVISION()
{
    printf "Program Name...: $h_prog_name\n"
    printf "Revision.......: $h_prog_version\n"
    printf "\n"
}


#------------------------------------------------------------------------------
# End of shell script
#------------------------------------------------------------------------------
