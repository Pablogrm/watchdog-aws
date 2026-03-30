from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError
from datetime import datetime
import time
import boto3

dynamodb = boto3.resource('dynamodb')

TABLE = dynamodb.table

def check_website(url, name):
    actual_time = datetime.now(datetime.timezone.utc).isoformat()
    # We start the time before the request
    start_time = time.perf_counter()
    req = Request(url)  
    try:
        # Attempt to reach the endpoint with a 5-second timeout
        response = urlopen(req, timeout=5)
        end_time = time.perf_counter()
        
        # Calculate latency in milliseconds and round to nearest integer
        latency_ms = round((end_time - start_time) * 1000)
        
        # Extract HTTP status code and reason phrase
        code = response.getcode()
        reason = response.reason

        # SUCCESS CASE (e.g., 200 OK)
        return{
            "url": url,
            "timestamp": actual_time,
            "nombre": name,
            "status": code,
            "latencia": latency_ms,
            "mensaje_http": f"{code} {reason}"
        }
    
    except HTTPError as e:
        # SERVER ERROR CASE (e.g., 404 Not Found, 500 Internal Server Error)
        # The server responded, but with an error code.
        end_time = time.perf_counter()
        latency_ms = round((end_time - start_time) * 1000)
        return {
            "url": url,
            "timestamp": actual_time,
            "nombre": name,
            "status": e.code,
            "latencia": latency_ms,
            "mensaje_http": f"{e.code} {e.reason}"
        }

    except URLError as e:
        # NETWORK ERROR CASE (e.g., DNS failure, connection timeout)
        # No HTTP response was received. Status is set to 0.
        end_time = time.perf_counter()
        latency_ms = round((end_time - start_time) * 1000)
        return {
            "url": url,
            "timestamp": actual_time,
            "nombre": name,
            "status": 0,
            "latencia": latency_ms,
            "mensaje_http": f"Conexion fallida: {e.reason}"
        }
        

def update_dynamodb(results):
