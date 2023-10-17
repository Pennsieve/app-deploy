import json

def lambda_handler(event, context):
    
    print("Hello from application gateway lambda")

    return {
        'statusCode': 202,
        'body': json.dumps('Accepted')
    }
    