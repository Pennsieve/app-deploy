#!/usr/bin/python3

from boto3 import client as boto3_client
# import modules used here -- sys is a very standard one
import sys
import os
import json
import requests

ecs_client = boto3_client("ecs", region_name=os.environ['REGION'])

# Gather our code in a main() function
def main():
    subnet_ids = os.environ['SUBNET_IDS']
    cluster_name = os.environ['CLUSTER_NAME']
    security_group = os.environ['SECURITY_GROUP_ID']
    pennsieve_host2 = os.environ['PENNSIEVE_API_HOST2']
    pennsieve_status_host = os.environ['PENNSIEVE_STATUS_HOST']

    inputDir = sys.argv[1]
    outputDir = sys.argv[2]
    integration_id = sys.argv[3]
    session_token = sys.argv[4]

    r = requests.get(f"{pennsieve_host2}/integrations/{integration_id}", headers={"Authorization": f"Bearer {session_token}"})
    r.raise_for_status()
    print(r.json())

    task_definition_name = r.json()["params"]["app_id"]
    container_name = r.json()["params"]["app_id"]

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
					        'name': 'INPUT_DIR',
					        'value': inputDir
				        },
                        {
					        'name': 'OUTPUT_DIR',
					        'value': outputDir
				        },             
                        
			     ],
		        },
	        ],
        })
        task_arn = response['tasks'][0]['taskArn']

        # POST at start of task - check (for success) if task_arn is present
        data = { 'task_id': task_arn, 'integration_id': integration_id, 'description': 'main'}
        r = requests.post(pennsieve_status_host, json=data)
        r.raise_for_status()
        print(r.json())

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