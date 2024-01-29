from boto3 import client as boto3_client
from boto3 import session as boto3_session
from botocore.exceptions import ClientError
from datetime import datetime
import json
import base64
import os
import requests

ecs_client = boto3_client("ecs", region_name=os.environ['REGION'])

def lambda_handler(event, context):
    pennsieve_host = os.environ['PENNSIEVE_API_HOST']
    sqs_url = os.environ['SQS_URL']
    # gets api key secrets
    secret_name = os.environ['API_KEY_SM_NAME']
    region_name = os.environ['REGION']

    # Create a Secrets Manager client
    session = boto3_session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except ClientError as e:
        raise e

    # Decrypts secret using the associated KMS key.
    secret = get_secret_value_response['SecretString']
    d = json.loads(secret)
    api_key, api_secret = list(d.items())[0]

    if event['isBase64Encoded'] == True:
        body = base64.b64decode(event['body']).decode('utf-8')
        event['body'] = body
        event['isBase64Encoded'] = False
    json_body = json.loads(event['body'])
    integration_id = json_body['integrationId']

    # get session_token
    r = requests.get(f"{pennsieve_host}/authentication/cognito-config")
    r.raise_for_status()

    cognito_app_client_id = r.json()["tokenPool"]["appClientId"]
    cognito_region = r.json()["region"]

    cognito_idp_client = boto3_client(
    "cognito-idp",
    region_name=cognito_region,
    aws_access_key_id="",
    aws_secret_access_key="",
    )
            
    login_response = cognito_idp_client.initiate_auth(
    AuthFlow="USER_PASSWORD_AUTH",
    AuthParameters={"USERNAME": api_key, "PASSWORD": api_secret},
    ClientId=cognito_app_client_id,
    )

    session_token = login_response["AuthenticationResult"]["AccessToken"]

    r = requests.get(f"{pennsieve_host}/user", headers={"Authorization": f"Bearer {session_token}"})
    r.raise_for_status()
    print(r.json())

    message_group_id = 'pipeline-message-group'
    message = {"integrationId": integration_id, "api_key": api_secret, "api_secret" : api_secret, "session_token" : session_token}
    sqs = boto3_client('sqs')
    response = sqs.send_message(
    QueueUrl=sqs_url,
    MessageGroupId=message_group_id,
    MessageBody=json.dumps(message)
    )
    
    print("Pipeline started for ", integration_id)
    return {
        'statusCode': 202,
        'body': json.dumps(str(response))
    }
