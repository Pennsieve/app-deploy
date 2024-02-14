from boto3 import client as boto3_client
import json
import base64

dynamodb = boto3_client('dynamodb')

def lambda_handler(event, context):

    print(event)

    if event['isBase64Encoded'] == True:
        body = base64.b64decode(event['body']).decode('utf-8')
        event['body'] = body
        event['isBase64Encoded'] = False
    json_body = json.loads(event['body'])
    print(json_body)

    return {
        'statusCode': 200,
        'body': 'status_service'
    }