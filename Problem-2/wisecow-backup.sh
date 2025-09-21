#! /bin/bash

# Variables
LOG_FILE_PATH = "/var/log/wisecow-application.log"
S3_BUCKET_NAME = "wisecow-backup-bucket"
S3_PREFIX = "backups/logs"
TIMESTAMP = $(date +"%Y%m%d_%H%M%S")
BACKUP_NAME = "wisecow-logs-$TIMESTAMP.log"
TMP_BACKUP_PATH = "/tmp/$BACKUP_NAME"
REPORT_LOG = "/var/log/backup_report/log"

# Creating backup copy
echo "[$(date +"%Y-%m-%d %H:%M:%S")] Starting log backup process..." >> | tee -a $REPORT_LOG

if [ ! -f $LOG_FILE_PATH ]; then
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] ERROR: Log file $LOG_FILE_PATH does not exist." >> | tee -a $REPORT_LOG
    exit 1
fi

cp "$LOG_FILE_PATH" "$TMP_BACKUP_PATH"
if [ $? -ne 0 ]; then
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] ERROR: Failed to copy log file to temp location." >> | tee -a $REPORT_LOG
    exit 1
fi

# Uploading to S3
if [-n "$AWS_PROFILE"]; then
    aws s3 cp "$TMP_BACKUP_PATH" "s3://$S3_BUCKET_NAME/$S3_PREFIX/$BACKUP_NAME" --profile "$AWS_PROFILE"
else
    aws s3 cp "$TMP_BACKUP_PATH" "s3://$S3_BUCKET_NAME/$S3_PREFIX/$BACKUP_NAME"
fi

if [ $? -eq 0 ]; then
    echo "[$(date +"%Y-%m-%d %H:%M:%S")]  Sucess: Upload to S3." >> | tee -a $REPORT_LOG
else 
    echo 
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] ERROR: Failed to upload backup to S3." >> | tee -a $REPORT_LOG
    exit 1
fi

# Cleanup
rm "$TMP_BACKUP_PATH"
echo "[$(date +"%Y-%m-%d %H:%M:%S")] Temporary backup file removed." >> | tee -a $REPORT_LOG
echo "[$(date +"%Y-%m-%d %H:%M:%S")] Backup process completed." >> | tee -a $REPORT_LOG