#!/bin/bash

################# PARAMETERS ################
# WARNING! This script has not been fully tested, so keep an eye on it.
# source and destination usually is something like remote:path instead of the below local paths
source="$1"
dest="$2"

date_for_backup="$3" #two digit number ex. 01 for the first in each month to run the script
del_after="$4" # Will will delete everything older than x days in bckp ex. 30

keep_mnt="$5" # Keep these backup months in the old_dir ex. 01 or 01,04,07,10(comma seperated)
del_all_after="$6" # Will delete everything older than x days in old_dir ex. 365

job_name="$7"
option="$8" # optinal rclone hooks ex. --dry-run

################# SET VARS ##############
email="yourmail@gmail.com" # To send allerts

bckp="month_backup" # dir to stor monthly backups
old_dir="old_backups" # dir where to retain the old backups

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

delete_dir() {
    dir="$1"
    archive="$2"
    if [ $archive == "old" ];then
        cmd_delete="rclone purge $dest/$old_dir/$dir $log_option $options" # you might want to dry-run this.
    else
        cmd_delete="rclone purge $dest/$bckp/$dir $log_option $options" # you might want to dry-run this.
    fi
    echo "Removing old archive backups $timestamp $job_name"
    echo "$cmd_delete"
    eval $cmd_delete
    exit_code=$?
    if ! [ $exit_code == 3 ]; then # We don't want any alerts on 3 (no directories found)
            conf_logging "$exit_code"
    fi
}


################# SCRIPT ################
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
        CMD_LSD="rclone lsd --max-depth 1 $dest/$old_dir/"
        mapfile -t dir_array < <(eval $CMD_LSD)
        DATE=$(date -d "$now - $del_all_after days" +'%Y-%m-%d')
        for i in "${!dir_array[@]}"; do
            dir_path="${dir_array[i]}"
            dir_date=$(echo ${dir_path##* })
            dir_date2=$(echo ${dir_date%_*})        
            conv_date=$(date -d "$dir_date2" +'%Y-%m-%d')
            if [[ $conv_date < $DATE ]];then
                delete_dir "$dir_date" "old"
            fi
        done
	else
		cmd="rclone copy $source $dest/$bckp/$timestamp $log_option"
		echo "$cmd"
		eval $cmd
		exit_code=$?
		conf_logging "$exit_code"
		CMD_LSD="rclone lsd --max-depth 1 $dest/$bckp/"
        mapfile -t dir_array < <(eval $CMD_LSD)
        DATE=$(date -d "$now - $del_after days" +'%Y-%m-%d')
        for i in "${!dir_array[@]}"; do
            dir_path="${dir_array[i]}"
            dir_date=$(echo ${dir_path##* })
            dir_date2=$(echo ${dir_date%_*})        
            conv_date=$(date -d "$dir_date2" +'%Y-%m-%d')
            if [[ $conv_date < $DATE ]];then
                delete_dir "$dir_date" "mnt"
            fi
        done
	fi  
fi
exit 0

