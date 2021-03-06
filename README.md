[![Gitpod ready-to-code](https://img.shields.io/badge/Gitpod-ready--to--code-blue?logo=gitpod)](https://gitpod.io/#https://github.com/rune1979/rclone-script-templates)

# rclone-script-templates

Based on the the rclone_jobber.sh https://github.com/wolfv6/rclone_jobber this is 
modified script templates for sync with archive, retreival of files in archive
and backup (copy) of directories.

This repo basically consists of three files; **backup.sh**, **sync.sh** and **restore_from_sync_archive.sh**.
There are some examples of use in the **/example** dir.
Basic understanding of rclone is a good idea, and they have a really lightweight 
and easy to understand documentation: https://rclone.org/docs/

These scripts are made for my Raspberry Pi backup server. If you by some coincidence are interested
in trying to make a Raspberry Pi backup server. You may read more about it here: https://thehotelhero.com/rclone-setup-on-raspberry-pi 


## backup.sh
The backup can have 8 parameters for carrying out backups and removal of old backups. In contrast to 
the "sync.sh" this script will make a full copy of source on each backup. (costly on bandwidth and resources)
**The 8 parameters:**
* source: remote:source/path
* dest: remote:backup/path
* date_for_backup: day of the month to make a full backup ex. 01
* del_after: How many days back to keep monthly backups (delete everything older than x day ex. 90) except the below..
* keep_mnt: Keep these backup months in a dir called old_dir ex. 01 or 01,04,07,10(comma seperated)
* del_all_after: Will delete everything older than x days in the old_dir. Ex. 365
* job_name: The name of the current job
* option: Optional could be rclone hooks ex. --dry-run

**Remember to change the email address**

You need to update the default email address in the "set vars" section, to your own and you need the abillity to use sendmail (or you can change that part)

in the /example dir there is an example of setting up a backup job. Ususally you would then setup a cron job (crontab) to run this file once a day.

*There is no script for restore of a backup, as this is just a one line copy command in rclone.*

## sync.sh
sync.sh is an incremental backup and more light weight aproach to backup, it keeps track of changes in individual files and folders
and only backs up the the old versions of changed files. So, (depending on the "retention" time) if a employee
asks for a file version 20 days ago (they may have made unrecoverable changes or deleted the file) you can reestablish
the older version in their filesystem for them (with restore_from_sync_archive.sh).
**The sync.sh has 5 parameters:** 
* source: remote:source/path
* dest: remote:backup/path
* job_name: The name of the current job
* retention: How many days back to keep old files
* option: Optional could be rclone hooks ex. --dry-run

**remember to change the emaiil address**

*In the /example dir there is an example.*

## restore_from_sync_archive.sh
The restore sync script only has **four parameters:**
* list_source: In this case the backup dir is the source.
* pre_dest: Destination is where to recover the file to.
* job_name="file_recovery" # Change to some thing
* options="" # Set any rclone hooks 

*There is also an example of this scripts execution*