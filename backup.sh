#!/bin/bash

################# PARAMETERS ################
# WARNING! This script has not been fully tested, so keep an eye on it.
# source and destination usually is something like remote:path instead of the below local paths
source="$1"
dest="$2"

date_for_backup="$3" #two digit number ex. 01 for the first in each month to run the script
del_after="$4" # Will will delete everything older than x month in bckp

keep_mnt="$5" # Keep these backup months in the old_dir ex. 01 or 01,04,07,10(comma seperated)
del_all_after="$6" # Will delete everything older than x month in old_dir

job_name="$7"
################# SET VARS ##############

bckp="month_backup" # dir to stor monthly backups

old_dir="old_backups" # dir where to retain the old backups

email="yourmail@gmail.com" # To send allerts

path="$PWD"
log_file="${path}/all_backup_logs.log"
log_option="--log-file=$log_file"       # rclone log to log_file

################# FUNCTIONS #################

send_to_log()
{
    msg="$1"

    # set log - send msg to log
    echo "$msg" >> "$log_file"                             #log msg to log_file
    #printf "$msg" | systemd-cat -t RCLONE_JOBBER -p info   #log msg to systemd journal
}

send_mail()
{
msg="$1"
/usr/sbin/sendmail -i -- $email <<EOF
Subject: Backup Urgency - $job_name

$msg
EOF
}

print_message()
{
    urgency="$1"
    msg="$2"
    message="${urgency}: $job_name $msg"

    echo "$message"
    send_to_log "$(date +%F_%T) $message"
    send_mail "$msg"
}

conf_logging()
{
	exit_code="$1"
	if [ "$exit_code" -eq 0 ]; then            #if no errors
    		confirmation="$(date +%F_%T) completed $bckp"
    		echo "$confirmation"
    		send_to_log "$confirmation"
    		send_to_log ""
    	
	else
    		print_message "ERROR" "failed.  rclone exit_code=$exit_code"
    		send_to_log ""
    	exit 1
	fi
}


################# SCIRPT ################
log_option="--log-file=$log_file"
ifStart=`date '+%d'`
month=`date '+%m'`
timestamp="$(date +%F_%H%M%S)"

if [ $ifStart == $date_for_backup ]; then
	if echo "$keep_mnt" | grep -q "$month"; then
		cmd="rclone copy $source $dest/$old_dir/$timestamp $log_option"
		echo "$cmd"
		eval $cmd
		exit_code=$?
		conf_logging "$exit_code"
		cmd_purge="rclone delete --rmdirs $dest/$old_dir/* --min-age ${del_all_after}M $log_option" # you might turn on --dry-run to be sure that nothing is deleted that should not be deleted
		echo "$cmd_purge"
		eval $cmd_purge
		exit_code=$?
		if ! [ $exit_code == 3 ]; then 
			conf_logging "$exit_code"
		fi
	else
		cmd="rclone copy $source $dest/$bckp/$timestamp $log_option"
		echo "$cmd"
		eval $cmd
		exit_code=$?
		conf_logging "$exit_code"
		cmd_purge="rclone delete --rmdirs $dest/$bckp/* --min-age ${del_after}M $log_option" # you might want to dry-run this too.
		echo "$cmd_purge"
		eval $cmd_purge
		exit_code=$?
		if ! [ $exit_code == 3 ]; then 
			conf_logging "$exit_code"
		fi
	fi
fi
exit 0

