#!/usr/bin/python3

from boto3 import client as boto3_client
# import modules used here -- sys is a very standard one
import sys
import os
import json

ecs_client = boto3_client("ecs", region_name=os.environ['REGION'])

# Gather our code in a main() function
def main():
    print('Hello there', sys.argv[1])

    task_definition_name = os.environ['TASK_DEFINITION_NAME_POST']
    subnet_ids = os.environ['SUBNET_IDS']
    cluster_name = os.environ['CLUSTER_NAME']
    security_group = os.environ['SECURITY_GROUP_ID']
    container_name = os.environ['CONTAINER_NAME_POST']
    api_key = os.environ['PENNSIEVE_API_KEY']
    api_secret = os.environ['PENNSIEVE_API_SECRET']
    pennsieve_agent_home = os.environ['PENNSIEVE_AGENT_HOME']
    pennsieve_upload_bucket = os.environ['PENNSIEVE_UPLOAD_BUCKET']
    environment = os.environ['ENVIRONMENT']
    pennsieve_host = os.environ['PENNSIEVE_API_HOST']
    pennsieve_host2 = os.environ['PENNSIEVE_API_HOST2']
    integration_id = os.environ['INTEGRATION_ID']
    session_token = os.environ['SESSION_TOKEN'] # should get new session token now that an orchestrator calls the post processor

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
					        'name': 'PENNSIEVE_API_KEY',
					        'value': api_key
				        },
                        {
					        'name': 'PENNSIEVE_API_SECRET',
					        'value': api_secret
				        },
                        {
					        'name': 'PENNSIEVE_AGENT_HOME',
					        'value': pennsieve_agent_home
				        },
                        {
					        'name': 'PENNSIEVE_UPLOAD_BUCKET',
					        'value': pennsieve_upload_bucket
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
					        'name': 'SESSION_TOKEN',
					        'value': session_token
				        },
                        {
					        'name': 'ENVIRONMENT',
					        'value': environment
				        },
                        {
					        'name': 'REGION',
					        'value': os.environ['REGION']
				        },               
                        
			     ],
		        },
	        ],
        })
        task_arn = response['tasks'][0]['taskArn']

        waiter = ecs_client.get_waiter('tasks_stopped')
        waiter.wait(
            cluster=cluster_name,
            tasks=[task_arn],
        )

        print("Fargate Task has stopped" + task_definition_name)


# Standard boilerplate to call the main() function to begin
# the program.
if __name__ == '__main__':
    main()