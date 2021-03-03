#!/bin/bash

# Our 8 sync parameters is set
source="${remote}:files/photos" # What ever path to source
dest="${encrypt}:some_backup_name" # Path to destination
job_name="$(basename $0)" # This is the this files name, but you can change it to what ever you decide
retention="30" # How many days back in time, to collect old files
options="--dry-run" # remove --dry-run hook when you have tested the file

full/path/to/sync.sh "$source" "$dest" "$job_name" "$retention" "$options"
