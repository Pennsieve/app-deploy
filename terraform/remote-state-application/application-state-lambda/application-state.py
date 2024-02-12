from boto3 import client as boto3_client
from boto3 import resource as boto3_resource
import json
import os
import base64

s3 = boto3_client('s3')

    
def lambda_handler(event, context):

    print(event)
    table_name = os.environ['APPLICATIONS_TABLE']

    if ('Records' in event):
        dynamodb = boto3_client('dynamodb')
        s3Object = event['Records'][0]['s3']['object']
        bucket = event['Records'][0]['s3']['bucket']
        
        content_object = s3.get_object(Bucket=bucket['name'], Key=s3Object['key'])['Body']
        # Read the contents of the StreamingBody as a bytes object
        bytes_obj = content_object.read()
        # Decode the bytes object to a string using the appropriate encoding
        string_obj = bytes_obj.decode('utf-8')

        json_content = json.loads(string_obj)
        outputs = json_content['outputs']
        print(outputs)

        response = dynamodb.put_item(
            TableName=table_name,
            Item={
                "app_id": {'S':outputs['app_id']['value']} ,
                "app_ecr_repository": {'S':outputs['app_ecr_repository']['value']},
                "app_name": {'S':outputs['app_name']['value']},
                "app_git_url": {'S':outputs['app_git_url']['value']},
            }
        )

        print(response)

        return {
            'statusCode': 200,
            'body': 'State'
        }
    
    dynamodb = boto3_resource('dynamodb')
    if event['isBase64Encoded'] == True:
        body = base64.b64decode(event['body']).decode('utf-8')
        event['body'] = body
        event['isBase64Encoded'] = False
    json_body = json.loads(event['body'])
    app_id = json_body['app_id']

    item_key = {'app_id': app_id}
    response = dynamodb.Table(table_name).get_item(Key=item_key)
    item = response.get('Item')

    return {
        'statusCode': 200,
        'body': item
    }