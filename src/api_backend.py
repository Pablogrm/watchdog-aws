import json
import os
import boto3
import logging
from decimal import Decimal
from boto3.dynamodb.conditions import Key
from botocore.exceptions import ClientError

# Connection to our DynamoDB databases
dynamodb = boto3.resource('dynamodb')
TABLE_INVENTORY = dynamodb.Table(os.environ['TABLE_INVENTORY']) # We use the environment variable to get the inventory table name
TABLE_LOGS = dynamodb.Table(os.environ['TABLE_LOGS'])           # and convert it to a DynamoDB table object to perform CRUD operations

# Configure logger for CloudWatch Logs
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Class to teach json.dumps how to handle DynamoDB numbers (convert Decimal to int or float as appropriate)
class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            # If it has no decimals, return it as int (e.g. 200)
            if obj % 1 == 0:
                return int(obj)
            # If it has decimals, return it as float (e.g. 45.5)
            else:
                return float(obj)
        return super(DecimalEncoder, self).default(obj)


def lambda_handler(event, context):
    http_method = event.get('httpMethod')
    path = event.get('resource')

    # Extract URL parameters (e.g. ?url=... or ?status=...)
    query_params = event.get('queryStringParameters') or {}

    # Read frontend URL from environment variables to configure CORS, if not defined we allow all URLs (using '*').
    frontend_url = os.environ['FRONTEND_URL']

    headers = {
        'Access-Control-Allow-Origin': frontend_url,
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        'Access-Control-Allow-Methods': 'OPTIONS,POST,GET,DELETE'
    }

    claims = event.get('requestContext', {}).get('authorizer', {}).get('claims', {})
    user_sub = claims.get('sub')
    user_email = claims.get('email')

    logger.info(f"Authenticated user: {user_email} - {user_sub}")

    # Handle CORS OPTIONS request first
    if http_method == 'OPTIONS':
        return {
            'statusCode': 200,
            'headers': headers,
            'body': ''
        }
    
    try:
        # ROUTE: /webs (Inventory Management)
        if path == '/webs':

            # 1. GET: List all websites
            if http_method == 'GET':
                return {
                    'statusCode': 200,
                    'headers': headers,
                    'body': json.dumps(TABLE_INVENTORY.scan().get('Items', []), cls=DecimalEncoder)
                }
            
            # 2. POST: Add a new website
            elif http_method == 'POST':
                body = json.loads(event.get('body', '{}'))
                TABLE_INVENTORY.put_item(Item={'url': body['url'], 'nombre': body['nombre']})
                return {
                    'statusCode': 201,
                    'headers': headers,
                    'body': json.dumps({'msg': 'Website added'})
                }
            
            # 3. DELETE: Delete a website from inventory
            elif http_method == 'DELETE':
                url_to_delete = query_params.get('url')
                if not url_to_delete:
                    return {
                        'statusCode': 400,
                        'headers': headers, 
                        'body': json.dumps({'error': 'Missing URL to delete'})
                    }
                
                TABLE_INVENTORY.delete_item(Key={'url': url_to_delete})
                logger.info(f"Website {url_to_delete} deleted from inventory.")
                return {
                    'statusCode': 200,
                    'headers': headers,
                    'body': json.dumps({'msg': f'Website {url_to_delete} deleted'})
                }
                
        
        # ROUTE: /logs (Display and Filters with GSI)
        elif path == '/logs':

            # 1. GET
            if http_method == 'GET':
                url_filter = query_params.get('url')
                status_filter = query_params.get('health_status') # Can be 'OK' or 'ERROR'

                # CASE 1: Filter by health_status, using GSI (StatusIndex)
                if status_filter: # If a status filter has been specified, it will be 'ERROR' because in the frontend we only show that option, but we leave it open in case in the future we want to filter by 'OK' as well
                    logger.info(f"Filtering logs by health_status (OK/ERROR): {status_filter} using GSI.")
                    response = TABLE_LOGS.query(
                        IndexName='StatusIndex',
                        KeyConditionExpression=Key('health_status').eq(status_filter)
                    )

                # CASE 2: If there is no filter, return all logs
                else:
                    logger.info(f"Returning all logs...")
                    response = TABLE_LOGS.scan()

                return {
                    'statusCode': 200,
                    'headers': headers,
                    'body': json.dumps(response.get('Items', []), cls=DecimalEncoder)
                }
        

        # ROUTE: /interval (Monitoring Interval Configuration)
        elif path == '/interval':
            if http_method == 'GET':
                # Read the dynamically injected variable (If it doesn't exist, return '5')
                intervalo = os.environ.get('WATCHDOG_INTERVAL', '5')
                
                return {
                    'statusCode': 200,
                    'headers': headers,
                    'body': json.dumps({'intervalo': intervalo})
                }

        # ROUTE: Does not exist (e.g. /users)
        return {
            'statusCode': 404, 
            'headers': headers, 
            'body': json.dumps({'error': 'Not Found'})}

    except ClientError as e:
        error_code = e.response['Error']['Code']
        error_msg = e.response['Error']['Message']
        logger.error(f"Amazon DynamoDB failure. Code: {error_code} - {error_msg}")
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error': 'Database failure'})
        }

    except Exception as e:
        # logger.exception displays the full error trace (line of code that fails, etc.)
        logger.exception(f"Internal code error: {e}")
        return {'statusCode': 500,
                'headers': headers,
                'body': json.dumps({'error': 'Internal error'})
        }

