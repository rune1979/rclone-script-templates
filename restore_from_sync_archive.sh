#!/usr/bin/env sh
#restore a file to it's original location

#################### PARAMETERS ####################
#source (backup location) and destination (original location) paths
list_source="$1"
pre_dest="$2"

#################### SCRIPT ####################
for entry in "$list_source"/*
do
  echo "$entry"
done
echo "\n>>>>>>>>>>>>>> Enter the name of the file to recover (*some_file.txt) <<<<<<<<<<<<<<<< "
read file
rclone ls --include $file $list_source

echo "\n>>>>>>>>>>>>>> Copy the above path for the file to recover <<<<<<<<<<<<<<<<<"
read old
source="$list_source/$old"
rm_year_dir="${old#*/}"
get_old_date="${rm_year_dir%%/*}"
rm_time_dir="${rm_year_dir#*/}"
dest="$pre_dest/$rm_time_dir-$get_old_date"

echo "\n copying from: $source"
echo "\n to: $dest"
printf "\n*** restoring old file in new dated directory ***\n"
rclone copy $source $dest
