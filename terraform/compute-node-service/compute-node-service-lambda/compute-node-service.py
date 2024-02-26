from boto3 import client as boto3_client
import boto3
import json
import base64
import os
import time
from botocore.exceptions import ClientError

ecs_client = boto3_client("ecs", region_name=os.environ['REGION'])
iam_resource = boto3.resource("iam")

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

	# create user and role
	user = None
	username = f"deploy-user-{account_id}"
	if user_exists(username):
		print("user already exists")
	else:		
		try:
			try:
				user = iam_resource.create_user(UserName=username)
				print(f"Created user {user.name}.")
			except ClientError as error:
				print(
            	f"Couldn't create a user. Here's why: "
            	f"{error.response['Error']['Message']}"
        		)
				raise
	
			try:
				user_key = user.create_access_key_pair()
				print(f"Created access key pair for user.")
			except ClientError as error:
				print(
            	f"Couldn't create access keys for user {user.name}. Here's why: "
            	f"{error.response['Error']['Message']}"
        		)
				raise

			time.sleep(10) # wait for user to be created
			
			try:
				sts_client = boto3_client(
				"sts", aws_access_key_id=user_key.id, aws_secret_access_key=user_key.secret
				)
				deploy_account_id = sts_client.get_caller_identity()["Account"]
				print(f"deploy_account_id: {deploy_account_id}")
				role_arn = f"arn:aws:iam::{account_id}:role/ROLE-{deploy_account_id}"

				user.create_policy(
					PolicyName=f"deploy-user-policy-{account_id}",
					PolicyDocument=json.dumps(
						{
							"Version": "2012-10-17",
							"Statement": [
								{
									"Effect": "Allow",
									"Action": "sts:AssumeRole",
									"Resource": role_arn,
								}
							],
						}
					),
				)
				print(
					f"Created an inline policy for {user.name} that lets the user assume "
					f"the role."
				)
			except ClientError as error:
				print(
					f"Couldn't create an inline policy for user {user.name}. Here's why: "
            		f"{error.response['Error']['Message']}"
        		)
				raise

			time.sleep(10) # wait
		except Exception:
			print("something went terribly wrong!")		

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
	
def user_exists(user_name):
    try:
        iam_resource.get_user(UserName=user_name)
        return True
    except Exception:
        return False	