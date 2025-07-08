#!/bin/bash

set -e

BUCKET_NAME="siddhant-portfolio-2025"
AWS_REGION="ap-south-1"

echo "Checking if S3 bucket exists: $BUCKET_NAME..."
BUCKET_EXISTS=$(aws s3api head-bucket --bucket $BUCKET_NAME --region $AWS_REGION 2>&1)
echo "Bucket exists check: $BUCKET_EXISTS"

if [[ $BUCKET_EXISTS == *"Not Found"* ]]; then
  echo "Bucket does not exist. Creating S3 bucket: $BUCKET_NAME in region: $AWS_REGION..."
  
  # Create the S3 bucket with the specified region
  aws s3api create-bucket \
    --bucket $BUCKET_NAME \
    --region $AWS_REGION \
    --create-bucket-configuration LocationConstraint=$AWS_REGION
  echo "S3 bucket $BUCKET_NAME created successfully."

else
  echo "Bucket $BUCKET_NAME already exists. Skipping creation..."
fi

# Disable Block Public Access to allow public policies
echo "Disabling Block Public Access settings on the S3 bucket..."
aws s3api put-bucket-public-access-block \
  --bucket $BUCKET_NAME \
  --no-block-public-acls \
  --no-block-public-policy \
  --region $AWS_REGION
echo "Block Public Access disabled."

# Enabling static website hosting
echo "Enabling static website hosting..."
aws s3 website s3://$BUCKET_NAME/ \
  --index-document index.html \
  --error-document error.html
echo "Static website hosting enabled."

# Applying bucket policy
echo "Applying bucket policy..."
aws s3api put-bucket-policy \
  --bucket $BUCKET_NAME \
  --policy file://./infra/bucket-policy.json
echo "Bucket policy applied."

# Syncing website content
echo "Syncing website content from ./frontend to S3..."
aws s3 sync ./frontend s3://$BUCKET_NAME/ --delete
echo "Website content synced successfully."

echo "S3 website deployed at:"
echo "http://$BUCKET_NAME.s3-website-$AWS_REGION.amazonaws.com"

