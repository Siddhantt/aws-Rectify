import json
import boto3
from datetime import datetime

dynamo = boto3.resource('dynamodb')
table = dynamo.Table('ContactMessages')

def lambda_handler(event, context):
    try:
        # Handle preflight request (CORS)
        if event['httpMethod'] == 'OPTIONS':
            return {
                'statusCode': 200,
                'headers': {
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'POST,OPTIONS',
                    'Access-Control-Allow-Headers': '*'
                },
                'body': json.dumps({'message': 'CORS preflight success'})
            }

        # Parse request body
        body = json.loads(event.get('body', '{}'))
        name = body.get('name')
        email = body.get('email')
        message = body.get('message')

        if not name or not email or not message:
            return {
                'statusCode': 400,
                'headers': {
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Headers': '*'
                },
                'body': json.dumps({'error': 'Missing fields'})
            }

        # Save to DynamoDB
        table.put_item(Item={
            'email': email,
            'name': name,
            'message': message,
            'timestamp': datetime.utcnow().isoformat()
        })

        return {
        'statusCode': 200,
        'headers': {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
        'Access-Control-Allow-Methods': 'OPTIONS,POST'
    },
        'body': json.dumps({'message': 'Message saved successfully'})
}

    except Exception as e:
        print('Error:', str(e))
        return {
            'statusCode': 500,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': '*'
            },
            'body': json.dumps({'error': 'Internal Server Error'})
        }
