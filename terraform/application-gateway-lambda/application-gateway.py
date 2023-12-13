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
    cluster_name = os.environ['CLUSTER_NAME']
    task_definition_name = os.environ['TASK_DEFINITION_NAME']
    container_name = os.environ['CONTAINER_NAME']
    security_group = os.environ['SECURITY_GROUP_ID']
    subnet_ids = os.environ['SUBNET_IDS']
    task_definition_name_post = os.environ['TASK_DEFINITION_NAME_POST']
    container_name_post = os.environ['CONTAINER_NAME_POST']
    pennsieve_host = os.environ['PENNSIEVE_API_HOST']
    pennsieve_host2 = os.environ['PENNSIEVE_API_HOST2']
    pennieve_agent_home = os.environ['PENNSIEVE_AGENT_HOME']
    pennsieve_upload_bucket = os.environ['PENNSIEVE_UPLOAD_BUCKET']
    environment = os.environ['ENVIRONMENT']

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
    
    # start Fargate task
    if cluster_name != "":
        print("Starting Fargate task")
        response = ecs_client.run_task(
            cluster = cluster_name,
            launchType = 'FARGATE',
            taskDefinition=task_definition_name,
            count = 1,
            platformVersion='LATEST',
            networkConfiguration={
            'awsvpcConfiguration': {
                'subnets': subnet_ids.split(","),
                'assignPublicIp': 'ENABLED',
                'securityGroups': [security_group]
                }   
            },
            overrides={
	        'containerOverrides': [
		        {
		            'name': container_name,
			        'environment': [
				        {
					        'name': 'INTEGRATION_ID',
					        'value': integration_id
				        },
                        {
					        'name': 'BASE_DIR',
					        'value': '/mnt/efs'
				        },
                        {
					        'name': 'TASK_DEFINITION_NAME_POST',
					        'value': task_definition_name_post
				        },
                        {
					        'name': 'CONTAINER_NAME_POST',
					        'value': container_name_post
				        }, 
                        {
					        'name': 'PENNSIEVE_API_KEY',
					        'value': api_key
				        },
                        {
					        'name': 'PENNSIEVE_API_SECRET',
					        'value': api_secret
				        },
                        {
					        'name': 'PENNSIEVE_API_HOST',
					        'value': pennsieve_host
				        },
                                                {
					        'name': 'PENNSIEVE_API_HOST2',
					        'value': pennsieve_host2
				        },
                        {
					        'name': 'PENNSIEVE_AGENT_HOME',
					        'value': pennieve_agent_home
				        },
                        {
					        'name': 'PENNSIEVE_UPLOAD_BUCKET',
					        'value': pennsieve_upload_bucket
				        },    
                        {
					        'name': 'CLUSTER_NAME',
					        'value': cluster_name
				        },
                        {
					        'name': 'SECURITY_GROUP_ID',
					        'value': security_group
				        }, 
                        {
					        'name': 'SUBNET_IDS',
					        'value': subnet_ids
				        },
                        {
					        'name': 'SESSION_TOKEN',
					        'value': session_token
				        },
                        {
					        'name': 'ENVIRONMENT',
					        'value': environment
				        },                   
                        
			     ],
		        },
	        ],
        })
        print("Fargate task started")
        return {
            'statusCode': 202,
            'body': json.dumps(str(response))
        }
