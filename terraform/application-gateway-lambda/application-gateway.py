from boto3 import client as boto3_client
from datetime import datetime
import json
import base64
import os

ecs_client = boto3_client("ecs", region_name=os.environ['REGION'])

def lambda_handler(event, context):
    cluster_name = os.environ['CLUSTER_NAME']
    task_definition_name = os.environ['TASK_DEFINITION_NAME']
    container_name = os.environ['CONTAINER_NAME']
    security_group = os.environ['SECURITY_GROUP_ID']
    subnet_ids = os.environ['SUBNET_IDS']
    # post_processor_invoke_arn = os.environ['POST_PROCESSOR_INVOKE_ARN']
    task_definition_name_post = os.environ['TASK_DEFINITION_NAME_POST']
    container_name_post = os.environ['CONTAINER_NAME_POST']
    api_key = os.environ['PENNSIEVE_API_KEY']
    api_secret = os.environ['PENNSIEVE_API_SECRET']
    pennsieve_host = os.environ['PENNSIEVE_API_HOST']
    pennieve_agent_home = os.environ['PENNSIEVE_AGENT_HOME']
    
    
    if cluster_name != "":
        print("running Fargate task")
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
					        'value': '1'
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
					        'name': 'PENNSIEVE_AGENT_HOME',
					        'value': pennieve_agent_home
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
			     ],
		        },
	        ],
        })
        return {
            'statusCode': 202,
            'body': json.dumps(str(response))
        }
