def lambda_handler(event, context):

    print(event)

    return {
        'statusCode': 200,
        'body': 'status_service'
    }