from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError
from datetime import datetime
from botocore.exceptions import ClientError
import time
import boto3
import logging
import os

# Conexion a nuestras bases de datos DynamoDB
dynamodb = boto3.resource('dynamodb')
TABLE_LOGS = dynamodb.Table('websites_logs')
TABLE_INVENTORY = dynamodb.Table('websites_inventory')

# Conexion a SNS
sns_client = boto3.client('sns')

# Configurar el logger para Cloudwatch Logs
logger = logging.getLogger()
logger.setLevel(logging.INFO)



# Funcion que realiza un ping a una web
def check_website(url, name):
    actual_time = datetime.now(datetime.timezone.utc).isoformat()

    # Calculamos el TTL (7 días en el futuro en formato Unix Epoch): 7 días * 24h * 60m * 60s = 604800 segundos
    expiration_date = int(time.time()) + 604800

    # Empezamos a contar el tiempo de latencia
    start_time = time.perf_counter()
    req = Request(url)  
    try:
        # Intento de llegar al endpoint con timeout = 5 segundos
        response = urlopen(req, timeout=5)
        end_time = time.perf_counter()
        
        # Se calcula la latencia en ms y se redondea al entero mas proximo para evitar tener muchos decimales
        latency_ms = round((end_time - start_time) * 1000)
        
        # Recuperamos el codigo HTTP y la respuesta
        code = response.getcode()
        reason = response.reason

        # CASO EXITO (e.g., 200 OK)
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
        # CASO ERROR DE SERVIDOR (e.g., 404 Not Found, 500 Internal Server Error)
        # El servidor responde pero con error
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
        # CASO ERROR DE RED (e.g., DNS failure, connection timeout)
        # No hay respuesta HTTP, forzamos status a 0
        end_time = time.perf_counter()
        latency_ms = round((end_time - start_time) * 1000)
        return {
            "url": url,
            "timestamp": actual_time,
            "nombre": name,
            "status": 0,
            "latencia": latency_ms,
            "mensaje_http": f"Conexion fallida: {e.reason}",
            "expiration": expiration_date,
            "health_status": "ERROR"
        }



# Función para guardar el ping realizado por lambda cuando EventBridge la despierta
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

        # Éxito, la web se ha guardado correctamente con sus nuevos valores
        logger.info(f"Exito: {data['nombre']} guardado correctamente.")
        return True
    
    # Error de AWS
    except ClientError as e:
        error_code = e.response['Error']['Code']
        error_msg = e.response['Error']['Message']
        
        logger.error(f"Fallo de AWS al intentar guardar {data['nombre']}. Código: {error_code} - {error_msg}")
        return False
    
    # Error genérico
    except Exception as e:
        # Intentamos sacar el nombre. Si no existe, usamos "la web" por defecto.
        nombre_web = data.get('nombre', 'la web')
        # logger.exception muestra debajo toda la traza del error (linea de codigo donde falla, etc)
        logger.exception(f"Error interno en el código. No se pudo procesar {nombre_web}.")
        return False


# Función para enviar una notificación a un tema de SNS
def send_alert(nombre_web, mensaje_error, topic_arn):
    try:
        mensaje = (
            f"Alerta del Watchdog\n"
            f"Se ha detectado un problema con la web: {nombre_web}\n"
            f"Detalle del error: {mensaje_error}\n"
            f"Revisa el panel de control de informacion para mas informacion."
        )

        response = sns_client.publish(
            TopicArn=topic_arn,
            Message=mensaje,
            Subject=f"CAÍDA DETECTADA: {nombre_web}" # El asunto del correo
        )

        logger.info(f"Exito: Alerta SNS enviada para {nombre_web}. ID: {response['MessageId']}.")
        return True
    
    except ClientError as e:
        # Errores donde AWS rechaza la petición
        error_code = e.response['Error']['Code']
        error_msg = e.response['Error']['Message']
        logger.error(f"AWS rechazó enviar alerta SNS para {nombre_web}. Código: {error_code} - {error_msg}.")
        return False
        
    except Exception as e:
        # Cualquier otro error (fallos de red, variables nulas...)
        logger.exception(f"Error interno en el código. No se pudo enviar la alerta SNS para {nombre_web}.")
        return False
    


# Función para escanear la base de datos y coger las urls que hay que checkear
def get_websites_to_check():
    try:
        # Escaneamos la Tabla Inventario (con solo una aparición por url)
        response = TABLE_INVENTORY.scan()
        items = response.get('Items', [])

        webs = []

        # Formateamos la salida por si alguna web no tuviese nombre
        for item in items:
            if 'url' in item:
                webs.append({
                    'url': item['url'],
                    'nombre': item.get('nombre', 'Web sin nombre')
                })
            else:
                logger.warning(f"Se encontró un registro sin url en la base de datos: {item}.")
        
        logger.info(f"Se han obtenido {len(webs)} de la base de datos para revisar.")
        return webs
    
    except ClientError as e:
        error_code = e.response['Error']['Code']
        error_msg = e.response['Error']['Message']
        logger.error(f"Fallo de AWS al hacer scan en la tabla de inventario. Código: {error_code} - {error_msg}.")
        return []
        
    except Exception as e:
        logger.exception("Fallo interno al procesar las webs de la base de datos.")
        return []



# Función principal, recorre la base de datos y chequea las webs enviando alerta si alguna ha caído
def lambda_handler(event, context):
    
    logger.info("Iniciando ejecución del Watchdog...")
    
    # Recuperamos el ARN del tema SNS desde las variables de entorno
    topic_arn = os.environ.get('SNS_TOPIC_ARN')
    if not topic_arn:
        logger.warning("No se encontró la variable de entorno SNS_TOPIC_ARN. Las alertas no se enviarán.")

    websites_to_check = get_websites_to_check()

    for web in websites_to_check:

        logger.info(f"Chequeando: {web['nombre']}...")

        # Hacemos el ping
        result = check_website(web['url'], web['nombre'])

        # Guardamos en dynamodb
        saved = save_to_dynamodb(result)

        status_http = result.get('status')

        if status_http != 200:
            logger.warning(f"¡Caída detectada en {web['nombre']}! Status: {status_http}")

            if topic_arn:
                error_msg = result.get('mensaje_http', f"Código HTTP inesperado: {status_http}")
                send_alert(web['nombre'], error_msg, topic_arn)
    
    logger.info("Ejecucion del Watchdog finalizada correctamente.")

    # Para que AWS marqué la ejecución de la lambda como exitosa en las métricas
    return {
        'statusCode': 200,
        'body': 'Chequeo de webs completado.'
    }



    