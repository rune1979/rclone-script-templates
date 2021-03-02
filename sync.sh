#!/usr/bin/env sh

################################# parameters #################################
source="/home/pi/test_rclone_data"            #the directory to back up (without a trailing slash)
dest="/home/pi/test_data_backup"              #the directory to back up to (without a trailing slash or "last_snapshot") destination=$dest/last_snapshot
move_old_files_to="dated_directory" #move_old_files_to is one of:
                       # "dated_directory" - move old files to a dated directory (an incremental backup)
                       # "dated_files"     - move old files to old_files directory, and append move date to file names (an incremental backup)
                       # ""                - old files are overwritten or deleted (a plain one-way sync backup)
options="$1"           #rclone options like "--filter-from=filter_patterns --checksum --log-level="INFO" --dry-run"
                       #do not put these in options: --backup-dir, --suffix, --log-file
job_name="Nextcloud_user_data"          #job_name="$(basename $0)"
email="yourmail@gmail.com"
retention="30" # How many days do you want to retain old files for
################################ set variables ###############################
# $new is the directory name of the current snapshot
# $timestamp is time that old file was moved out of new (not time that file was copied from source)
new="last_snapshot"
#timestamp="$(date +%F_%T)"
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
# deleted or changed files are removed or moved, depending on value of move_old_files_to variable
# default move_old_files_to="" will remove deleted or changed files from backup
if [ "$move_old_files_to" = "dated_directory" ]; then
    # move deleted or changed files to archive/$(date +%Y)/$timestamp directory
    backup_dir="--backup-dir=$dest/archive/$(date +%Y)/$timestamp"
elif [ "$move_old_files_to" = "dated_files" ]; then
    # move deleted or changed files to old directory, and append _$timestamp to file name
    backup_dir="--backup-dir=$dest/old_files --suffix=_$timestamp"
elif [ "$move_old_files_to" != "" ]; then
    print_message "WARNING" "Parameter move_old_files_to=$move_old_files_to, but should be dated_directory or dated_files.\
  Moving old data to dated_directory."
    backup_dir="--backup-dir=$dest/$timestamp"
fi

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

############################ confirmation and logging ########################
if [ "$exit_code" -eq 0 ]; then            #if no errors
    confirmation="$(date +%F_%T) completed $job_name"
    echo "$confirmation"
    send_to_log "$confirmation"
    send_to_log ""
    exit 0
else
    print_message "ERROR" "failed.  rclone exit_code=$exit_code"
    send_to_log ""
    exit 1
fi
