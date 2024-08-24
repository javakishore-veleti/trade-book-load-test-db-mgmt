#!/bin/bash
# Script to rollback Liquibase changes

# Check for environment argument
if [ -z "$1" ]; then
  echo "Please provide an environment (e.g., local-dev, dev, qa, prod-us, etc.)"
  exit 1
fi

ENV=$1
PROPERTIES_FILE="properties/liquibase-$ENV.properties"

# Check if the properties file exists
if [ ! -f "$PROPERTIES_FILE" ]; then
  echo "Properties file for environment '$ENV' does not exist."
  exit 1
fi

# Define AWS S3 bucket name
S3_BUCKET="trade-book-crud-load-test-2024-08-24-1557-est"

# If the environment is not local-dev or dev, perform the AWS S3 check
if [[ "$ENV" != "local-dev" && "$ENV" != "dev" ]]; then
  # Define S3 object key
  S3_OBJECT_KEY="$ENV/liquibase-script-exec-allowed.txt"

  # Check if the file exists in the S3 bucket
  if aws s3 ls "s3://$S3_BUCKET/$S3_OBJECT_KEY" --profile your-aws-profile > /dev/null 2>&1; then
    echo "S3 file found. Checking script execution window..."

    # Download the file
    aws s3 cp "s3://$S3_BUCKET/$S3_OBJECT_KEY" ./ --profile your-aws-profile

    # Read start and end times from the file
    START_TIME=$(head -n 1 liquibase-script-exec-allowed.txt)
    END_TIME=$(tail -n 1 liquibase-script-exec-allowed.txt)

    # Convert times to seconds since epoch
    START_EPOCH=$(date -d "$START_TIME" +%s)
    END_EPOCH=$(date -d "$END_TIME" +%s)
    CURRENT_EPOCH=$(date +%s)

    # Check if current time is within the allowed execution window
    if [[ $CURRENT_EPOCH -ge $START_EPOCH && $CURRENT_EPOCH -le $END_EPOCH ]]; then
      echo "Current time is within the allowed execution window. Proceeding with Liquibase rollback..."
    else
      echo "Current time is outside the allowed execution window. Exiting."
      exit 1
    fi
  else
    echo "S3 file '$S3_OBJECT_KEY' not found or access denied. Exiting."
    exit 1
  fi
fi

# Execute Liquibase rollback command
liquibase --defaultsFile="$PROPERTIES_FILE" rollbackCount 1
