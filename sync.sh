#!/bin/bash
#This script is based on the rclone_jobber.sh at https://github.com/wolfv6/rclone_jobber


################################# parameters #################################
source="$1"    #the directory to back up (without a trailing slash)
dest="$2"      #the directory to back up to (without a trailing slash or "last_snapshot") destination=$dest/last_snapshot
job_name="$3"          #job_name="$(basename $0)"
retention="$4" # How many days do you want to retain old files for
options="$5"           #rclone options like "--filter-from=filter_patterns --checksum --log-level="INFO" --dry-run"
                       #do not put these in options: --backup-dir, --suffix, --log-file

################################ other variables ###############################
email="your_email@some_mail.com" # the admin email
# $new is the directory name of the current snapshot
# $timestamp is time that old file was moved out of new (not time that file was copied from source)
new="last_snapshot"
timestamp="$(date +%F_%H%M%S)"  #time w/o colons if thumb drive is FAT format, which does not allow colons in file name

# set log_file path
#path="$(realpath "$0")"                 #this will place log in the same directory as this script
path="$PWD"
log_file="${path}/all_backup_logs.log"               #replace path extension with "log"
#log_file="${path%.*}.log"               #replace path extension with "log"
#log_file="/var/log/rclone_jobber.log"  #for Logrotate

# set log_option for rclone
log_option="--log-file=$log_file"       #log to log_file
#log_option="--syslog"                  #log to systemd journal

################################## functions #################################
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

# print message to echo, log, and popup
print_message()
{
    urgency="$1"
    msg="$2"
    message="${urgency}: $job_name $msg"

    echo "$message"
    send_to_log "$(date +%F_%T) $message"
    send_mail "$msg"
}

# confirmation and logging
conf_logging() {
    exit_code="$1"
    if [ "$exit_code" -eq 0 ]; then            #if no errors
        confirmation="$(date +%F_%T) completed $job_name"
        echo "$confirmation"
        send_to_log "$confirmation"
        send_to_log ""
    else
        print_message "ERROR" "failed.  rclone exit_code=$exit_code"
        send_to_log ""
        exit 1
    fi
}
################################# range checks ################################
# if source is empty string
if [ -z "$source" ]; then
    print_message "ERROR" "aborted because source is empty string."
    exit 1
fi

# if dest is empty string
if [ -z "$dest" ]; then
    print_message "ERROR" "aborted because dest is empty string."
    exit 1
fi

# if source is empty
if ! test "rclone lsf --max-depth 1 $source"; then  # rclone lsf requires rclone 1.40 or later
    print_message "ERROR" "aborted because source is empty."
    exit 1
fi

# if job is already running (maybe previous run didn't finish)
# https://github.com/wolfv6/rclone_jobber/pull/9 said this is not working in macOS
if pidof -o $PPID -x "$job_name"; then
    print_message "WARNING" "aborted because it is already running."
    exit 1
fi

############################### move_old_files_to #############################
backup_dir="--backup-dir=$dest/sync_archive/$timestamp"

################################### back up ##################################
cmd="rclone sync $source $dest/$new $backup_dir $log_option $options"

# progress message
echo "Back up in progress $timestamp $job_name"
echo "$cmd"

# set logging to verbose
#send_to_log "$timestamp $job_name"
#send_to_log "$cmd"

eval $cmd
exit_code=$?
conf_logging "$exit_code"

################################### clean up old function ##################################
delete_dir() {
    dir="$1"
    cmd_delete="rclone purge $dest/sync_archive/$dir $log_option $options" # you might want to dry-run this.
    echo "Removing old synced files $timestamp $job_name"
    echo "$cmd_delete"
    eval $cmd_delete
    exit_code=$?
    if ! [ $exit_code == 3 ]; then # We don't want any alerts on 3 (no directories found)
            conf_logging "$exit_code"
    fi
}

CMD_LSD="rclone lsd --max-depth 1 $dest/sync_archive/"
mapfile -t dir_array < <(eval $CMD_LSD)
DATE=$(date -d "$now - $days days" +'%Y-%m-%d')
for i in "${!dir_array[@]}"; do
        dir_path="${dir_array[i]}"
        dir_date=$(echo ${dir_path##* })
        dir_date2=$(echo ${dir_date%_*})        
        conv_date=$(date -d "$dir_date2" +'%Y-%m-%d')
        if [[ $conv_date < $DATE ]];then
                delete_dir "$dir_date"
        fi
done

exit 0