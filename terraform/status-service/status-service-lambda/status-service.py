from boto3 import client as boto3_client
import json
import base64
import os

dynamodb = boto3_client('dynamodb')

def lambda_handler(event, context):

    print(event)

    if event['isBase64Encoded'] == True:
        body = base64.b64decode(event['body']).decode('utf-8')
        event['body'] = body
        event['isBase64Encoded'] = False
    json_body = json.loads(event['body'])
    print(json_body)

    table_name = os.environ['STATUSES_TABLE']

    response = dynamodb.put_item(
            TableName=table_name,
            Item={
                "task_id": {'S':json_body['task_id']} ,
                "integration_id": {'S':json_body['integration_id']},
                "description": {'S':json_body['description']},
            }
        )

    print(response)

    return {
        'statusCode': 200,
        'body': json.dumps(str('Status updated'))
    }