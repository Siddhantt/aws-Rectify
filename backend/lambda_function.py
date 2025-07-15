import json
import boto3
from datetime import datetime

# DynamoDB setup
dynamo = boto3.resource('dynamodb')
table = dynamo.Table('ContactMessages')

# CORS headers
CORS_HEADERS = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST,OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'
}

def lambda_handler(event, context):
    print("📥 Event received:", json.dumps(event))

    # === Handle CORS preflight
    if event.get('httpMethod') == 'OPTIONS':
        return {
            'statusCode': 200,
            'headers': CORS_HEADERS,
            'body': json.dumps({'message': 'CORS preflight passed'})
        }

    try:
        body = json.loads(event.get('body', '{}'))

        name = (body.get('name') or '').strip()
        email = (body.get('email') or '').strip()
        message = (body.get('message') or '').strip()

        # === Validate input
        if not name or not email or not message:
            return {
                'statusCode': 400,
                'headers': CORS_HEADERS,
                'body': json.dumps({'error': 'Missing name, email, or message'})
            }

        # === Save to DynamoDB
        table.put_item(Item={
            'email': email,
            'name': name,
            'message': message,
            'timestamp': datetime.utcnow().isoformat()
        })

        return {
            'statusCode': 200,
            'headers': {
                **CORS_HEADERS,
                'Content-Type': 'application/json'
            },
            'body': json.dumps({'message': '✅ Message saved successfully'})
        }

    except Exception as e:
        print("❌ Error during Lambda execution:", str(e))
        return {
            'statusCode': 500,
            'headers': CORS_HEADERS,
            'body': json.dumps({'error': 'Internal Server Error'})
        }
