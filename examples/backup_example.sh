#!/bin/bash

# Our 8 sync parameters is set
source="${remote}:files/photos" # What ever path to source
dest="${encrypt}:some_backup_name" # Path to destination
date_for_backup="01" #two digit number ex. 01 for the first in each month to run the script
del_after="90" # Will will delete everything older than x days in bckp
keep_mnt="01,07" # Keep these backup months in the old_dir ex. 01 or 01,04,07,10(comma seperated)
del_all_after="365" # Will delete everything older than x days in old_dir
job_name="$(basename $0)" # This is the this files name, but you can change it to what ever you decide
options="--dry-run" # remove --dry-run hook when you have tested the file
email="" # your email


/full/path/to/backup.sh "$source" "$dest" "$date_for_backup" "$del_after" "$keep_mnt" "$del_all_after" "$job_name" "$options" "$email"
