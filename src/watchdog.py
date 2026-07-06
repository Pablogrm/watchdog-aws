from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError
from datetime import datetime, timezone
from botocore.exceptions import ClientError
import http.client
import time
import boto3
import logging
import os

# Connection to our DynamoDB databases
dynamodb = boto3.resource('dynamodb')
TABLE_INVENTORY = dynamodb.Table(os.environ.get('TABLE_INVENTORY')) # We use the environment variable to get the inventory table name
TABLE_LOGS = dynamodb.Table(os.environ.get('TABLE_LOGS'))           # and convert it to a DynamoDB table object to perform CRUD operations

# Connection to SNS
sns_client = boto3.client('sns')

# Configure logger for CloudWatch Logs
logger = logging.getLogger()
logger.setLevel(logging.INFO)



# Function that pings a website
def check_website(url, name):
    actual_time = datetime.now(timezone.utc).isoformat()

    # Calculate TTL (7 days in the future in Unix Epoch format): 7 days * 24h * 60m * 60s = 604800 seconds
    expiration_date = int(time.time()) + 604800

    # Start counting latency time
    start_time = time.perf_counter()

    # Add a fake User-Agent to impersonate Google Chrome on Windows
    headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'}
    req = Request(url, headers=headers)
  
    try:
        # Attempt to reach the endpoint with timeout = 7 seconds
        response = urlopen(req, timeout=7)
        end_time = time.perf_counter()
        
        # Calculate latency in ms and round to nearest integer to avoid many decimals
        latency_ms = round((end_time - start_time) * 1000)
        
        # Get HTTP code and response
        code = response.getcode()
        reason = response.reason

        # SUCCESS CASE (e.g. 200 OK)
        return{
            "url": url,
            "timestamp": actual_time,
            "nombre": name,
            "status": code,
            "latencia": latency_ms,
            "mensaje_http": f"{code} {reason}",
            "expiration": expiration_date,
            "health_status": "OK"
        }
    
    except HTTPError as e:
        # SERVER ERROR CASE (e.g. 404 Not Found, 500 Internal Server Error)
        # Server responds but with error
        end_time = time.perf_counter()
        latency_ms = round((end_time - start_time) * 1000)
        return {
            "url": url,
            "timestamp": actual_time,
            "nombre": name,
            "status": e.code,
            "latencia": latency_ms,
            "mensaje_http": f"{e.code} {e.reason}",
            "expiration": expiration_date,
            "health_status": "ERROR"
        }

    except URLError as e:
        # ROUTING FAILURE CASE (e.g. DNS Failure, Wrong URL, Connection Timeout or Connection Refused)
        # No HTTP response, force status to 0
        end_time = time.perf_counter()
        latency_ms = round((end_time - start_time) * 1000)
        return {
            "url": url,
            "timestamp": actual_time,
            "nombre": name,
            "status": 0,
            "latencia": latency_ms,
            "mensaje_http": f"Connection failed: {e.reason}",
            "expiration": expiration_date,
            "health_status": "ERROR"
        }
    
    except http.client.RemoteDisconnected as e:
        # REMOTE DISCONNECTION ERROR CASE (e.g. server closes connection before responding)
        end_time = time.perf_counter()
        latency_ms = round((end_time - start_time) * 1000)
        return {
            "url": url,
            "timestamp": actual_time,
            "nombre": name,
            "status": 0,
            "latencia": latency_ms,
            "mensaje_http": f"Remote disconnection: {str(e)}",
            "expiration": expiration_date,
            "health_status": "ERROR"
        }

    except Exception as e:
        # UNKNOWN ERROR CASE: Catches any other Python error so Lambda never hangs
        end_time = time.perf_counter()
        latency_ms = round((end_time - start_time) * 1000)
        return {
            "url": url,
            "timestamp": actual_time,
            "nombre": name,
            "status": 0,
            "latencia": latency_ms,
            "mensaje_http": f"Unexpected internal error: {str(e)}",
            "expiration": expiration_date,
            "health_status": "ERROR"
        }



# Function to save the ping performed by lambda when EventBridge wakes it up
def save_to_dynamodb(data):
    try:
        response = TABLE_LOGS.put_item(
            Item={
            'url': data['url'],
            'timestamp': data['timestamp'],
            'nombre': data['nombre'],
            'status': data['status'],
            'latencia': data['latencia'],
            'mensaje_http': data['mensaje_http'],
            'health_status': data['health_status']
            }
        )

        # Success, the website has been saved correctly with its new values
        logger.info(f"web: {data['nombre']} - Saved correctly in database.")
        return True
    
    # AWS error
    except ClientError as e:
        error_code = e.response['Error']['Code']
        error_msg = e.response['Error']['Message']
        
        logger.error(f"AWS failure when trying to save {data['nombre']}. Code: {error_code} - {error_msg}")
        return False
    
    # Generic error
    except Exception as e:
        # Try to get the name. If it doesn't exist, use "the website" by default.
        nombre_web = data.get('nombre', 'the website')
        # logger.exception displays the full error trace (line of code that fails, etc.)
        logger.exception(f"Internal code error. Could not process {nombre_web}.")
        return False


# Function to send a notification to an SNS topic
def send_alert(nombre_web, mensaje_error, topic_arn):
    try:
        mensaje = (
            f"Watchdog Alert\n"
            f"A problem has been detected with the website: {nombre_web}\n"
            f"Error detail: {mensaje_error}\n"
            f"Check the control panel for more information."
        )

        response = sns_client.publish(
            TopicArn=topic_arn,
            Message=mensaje,
            Subject=f"DOWNTIME DETECTED: {nombre_web}" # Email subject
        )

        logger.info(f"Success: SNS alert sent for {nombre_web}. ID: {response['MessageId']}.")
        return True
    
    except ClientError as e:
        # Errors where AWS rejects the request
        error_code = e.response['Error']['Code']
        error_msg = e.response['Error']['Message']
        logger.error(f"AWS rejected sending SNS alert for {nombre_web}. Code: {error_code} - {error_msg}.")
        return False
        
    except Exception as e:
        # Any other error (network failures, null variables...)
        logger.exception(f"Internal code error. Could not send SNS alert for {nombre_web}.")
        return False
    


# Function to scan the database and get the URLs to check
def get_websites_to_check():
    try:
        # Scan the Inventory Table (with only one occurrence per URL)
        response = TABLE_INVENTORY.scan()
        items = response.get('Items', [])

        webs = []

        # Format the output in case any website doesn't have a name
        for item in items:
            if 'url' in item:
                webs.append({
                    'url': item['url'],
                    'nombre': item.get('nombre', 'Website without name')
                })
            else:
                logger.warning(f"Found a record without url in the database: {item}.")
        
        logger.info(f"Retrieved {len(webs)} websites from the database for review.")
        return webs
    
    except ClientError as e:
        error_code = e.response['Error']['Code']
        error_msg = e.response['Error']['Message']
        logger.error(f"AWS failure when scanning inventory table. Code: {error_code} - {error_msg}.")
        return []
        
    except Exception as e:
        logger.exception("Internal failure when processing websites from database.")
        return []



# Main function, iterates through the database and checks websites, sending alert if any has fallen
def lambda_handler(event, context):
    
    logger.info("Starting Watchdog execution...")
    
    # Get SNS topic ARN from environment variables
    topic_arn = os.environ.get('SNS_TOPIC_ARN')
    if not topic_arn:
        logger.warning("SNS_TOPIC_ARN environment variable not found. Alerts will not be sent.")

    websites_to_check = get_websites_to_check()

    for web in websites_to_check:

        logger.info(f"Checking: {web['nombre']}...")

        # Do the ping
        result = check_website(web['url'], web['nombre'])

        # Save to dynamodb
        saved = save_to_dynamodb(result)

        current_status = result.get('health_status')

        if current_status == 'ERROR':
            logger.warning(f"Downtime detected in {web['nombre']}!")

            if topic_arn:
                error_msg = result.get('mensaje_http', f"Unexpected HTTP code: {current_status}")
                send_alert(web['nombre'], error_msg, topic_arn)
    
    logger.info("Watchdog execution completed successfully.")

    # For AWS to mark lambda execution as successful in metrics
    return {
        'statusCode': 200,
        'body': 'Website check completed.'
    }



    