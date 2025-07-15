# Step 1: Set vars
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="siddhant-portfolio-${ACCOUNT_ID}"

# Step 2: Create policy JSON
cat <<EOF > /tmp/bucket-policy.json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "PublicReadGetObject",
    "Effect": "Allow",
    "Principal": "*",
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::$BUCKET_NAME/*"
  }]
}
EOF

# Step 3: Apply policy
aws s3api put-bucket-policy \
  --bucket "$BUCKET_NAME" \
  --policy file:///tmp/bucket-policy.json

