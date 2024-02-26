from boto3 import client as boto3_client
import json
import base64
import os

def lambda_handler(event, context):

    print(event)

    if event['isBase64Encoded'] == True:
        body = base64.b64decode(event['body']).decode('utf-8')
        event['body'] = body
        event['isBase64Encoded'] = False
    json_body = json.loads(event['body'])
    print(json_body)

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

        return {
            'statusCode': 202,
            'body': json.dumps(str('Compute node creation initiated'))
        }