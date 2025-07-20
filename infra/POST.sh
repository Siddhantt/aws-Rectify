#!/bin/bash

# ✅ Set variables
API_NAME="ContactAPI"
RESOURCE_PATH="contact"
LAMBDA_NAME="contact-api-handler"
REGION="ap-south-1"

# ✅ Get API ID
REST_API_ID=$(aws apigateway get-rest-apis \
  --query "items[?name=='$API_NAME'].id" \
  --output text)

# ✅ Get Root Resource ID (usually "/")
PARENT_RESOURCE_ID=$(aws apigateway get-resources \
  --rest-api-id "$REST_API_ID" \
  --query "items[?path=='/'].id" \
  --output text)

# ✅ Create '/contact' resource under root
CONTACT_RESOURCE_ID=$(aws apigateway create-resource \
  --rest-api-id "$REST_API_ID" \
  --parent-id "$PARENT_RESOURCE_ID" \
  --path-part "$RESOURCE_PATH" \
  --query 'id' \
  --output text)

# ✅ Create POST method on /contact
aws apigateway put-method \
  --rest-api-id "$REST_API_ID" \
  --resource-id "$CONTACT_RESOURCE_ID" \
  --http-method POST \
  --authorization-type "NONE"

# ✅ Set Lambda URI (use actual region + Lambda ARN)
LAMBDA_ARN=$(aws lambda get-function --function-name "$LAMBDA_NAME" \
  --query 'Configuration.FunctionArn' --output text)

LAMBDA_URI="arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/$LAMBDA_ARN/invocations"

# ✅ Integrate POST method with Lambda
aws apigateway put-integration \
  --rest-api-id "$REST_API_ID" \
  --resource-id "$CONTACT_RESOURCE_ID" \
  --http-method POST \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri "$LAMBDA_URI"

# ✅ Add Lambda invoke permission (if not already)
aws lambda add-permission \
  --function-name "$LAMBDA_NAME" \
  --statement-id "apigateway-invoke-post" \
  --action lambda:InvokeFunction \
  --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:$REGION:*:$REST_API_ID/*/POST/$RESOURCE_PATH" \
  2>/dev/null || echo "✅ Permission already exists."

# ✅ Deploy the API (create a stage)
aws apigateway create-deployment \
  --rest-api-id "$REST_API_ID" \
  --stage-name prod

echo "✅ POST /contact method created and integrated with Lambda"
