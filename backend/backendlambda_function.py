import json
import boto3
from datetime import datetime

# Initialize DynamoDB client
dynamo = boto3.resource('dynamodb')
table = dynamo.Table('ContactMessages')

def lambda_handler(event, context):
    try:
        # Parse JSON body
        body = json.loads(event.get('body', '{}'))
        name = body.get('name')
        email = body.get('email')
        message = body.get('message')

        # Validate fields
        if not name or not email or not message:
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'Missing fields in request'})
            }

        # Put item into DynamoDB
        item = {
            'email': email,
            'name': name,
            'message': message,
            'timestamp': datetime.utcnow().isoformat()
        }

        table.put_item(Item=item)

        # Return success response
        return {
            'statusCode': 200,
            'body': json.dumps({'success': True, 'message': 'Message saved'})
        }

    except Exception as e:
        print('Error:', str(e))
        return {
            'statusCode': 500,
            'body': json.dumps({'error': 'Internal Server Error'})
        }

