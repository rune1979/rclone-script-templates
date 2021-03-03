#!/bin/bash

# Our 8 sync parameters is set
source="${remote}:files/photos"
dest="${encrypt}:some_backup_name"
move_old_files_to="dated_directory"
options="--filter-from=$rclone_jobber/examples/filter_rules"
monitoring_URL=""

$rclone_jobber/rclone_jobber.sh "$source" "$dest" "$move_old_files_to" "$options" "$(basename $0)" "$monitoring_URL"
