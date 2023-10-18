import json

def lambda_handler(event, context):
    
    print("Running application-gateway lambda")

    return {
        'statusCode': 202,
        'body': json.dumps('Accepted')
    }
    