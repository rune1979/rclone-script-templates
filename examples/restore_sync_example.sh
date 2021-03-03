#!/bin/bash

# Our 2 sync parameters is set
source="${encrypt}:some_backup_name" # Path to backup archive
dest="${remote}:files/photos" # What ever path to send restored file
job_name="file_recovery" # Change to some thing
options="" # Set any rclone hooks 

full/path/to/restore_from_sync_archive.sh "$source" "$dest" "$job_name" "$options"
