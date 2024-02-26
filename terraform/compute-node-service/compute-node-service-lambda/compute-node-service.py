from boto3 import client as boto3_client
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
      
	print(event)
      
	if event['isBase64Encoded'] == True:
		body = base64.b64decode(event['body']).decode('utf-8')
		event['body'] = body
		event['isBase64Encoded'] = False
        
	json_body = json.loads(event['body'])
	print(json_body)

	account_id = json_body['accountId']

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
					        'name': 'ACCOUNT_ID',
					        'value': account_id
				        },                   
			     ],
		        },
	        ],
        })

		return {
            'statusCode': 202,
            'body': json.dumps(str('Compute node creation initiated'))
        }