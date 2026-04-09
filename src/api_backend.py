import json
import boto3
import logging
from boto3.dynamodb.conditions import Key
from botocore.exceptions import ClientError

# Conexion a nuestras bases de datos DynamoDB
dynamodb = boto3.resource('dynamodb')
TABLE_LOGS = dynamodb.Table('websites_logs')
TABLE_INVENTORY = dynamodb.Table('websites_inventory')

# Configurar el logger para Cloudwatch Logs
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    http_method = event.get('httpMethod')
    path = event.get('resource')

    # Extraemos los parámetros de la URL (ej. ?url=... o ?status=...)
    query_params = event.get('queryStringParameters') or {}

    headers = {
        'Access-Control-Allow-Origin': '*', # Poner la url del frontend una vez se implemente
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Allow-Methods': 'OPTIONS,POST,GET,DELETE'
    }

    try:
        # RUTA: /webs (Gestión de Inventario)
        if path == '/webs':

            # 1. GET: Listar todas las webs
            if http_method == 'GET':
                return {
                    'statusCode': 200,
                    'headers': headers,
                    'body': json.dumps(TABLE_INVENTORY.scan().get('Items', []))
                }
            
            # 2. POST: Añadir una web nueva
            elif http_method == 'POST':
                body = json.loads(event.get('body', '{}'))
                TABLE_INVENTORY.put_item(Item={'url': body['url'], 'nombre': body['nombre'], 'activa': True})
                return {
                    'statusCode': 201,
                    'headers': headers,
                    'body': json.dumps({'msg': 'Web añadida'})
                }
            
            # 3. DELETE: Eliminar una web del inventario
            elif http_method == 'DELETE':
                url_to_delete = query_params.get('url')
                if not url_to_delete:
                    return {'statusCode': 400,
                            'headers': headers, 
                            'body': json.dumps({'error': 'Falta la URL a borrar'})
                    }
                
                TABLE_INVENTORY.delete_item(Key={'url': url_to_delete})
                logger.info(f"Web {url_to_delete} eliminada del inventario.")
                return {'statusCode': 200,
                        'headers': headers,
                        'body': json.dumps({'msg': f'Web {url_to_delete} eliminada'})
                }
                

        
        # RUTA: /logs (Visualización y Filtros con GSI)
        elif path == '/logs':

            # 1. GET
            if http_method == 'GET':
                url_filter = query_params.get('url')
                status_filter = query_params.get('status')

                # CASO 1: Filtrando por URL específica
                if url_filter:
                    logger.info(f"Filtrando logs de la url {url_filter}.")
                    response = TABLE_LOGS.query(
                        KeyConditionExpression=Key('url').eq(url_filter)
                    )

                # CASO 2: Filtrando por status, usamos el GSI (StatusIndex)
                elif status_filter:
                    logger.info(f"Filtrando logs por status {status_filter} usando GSI.")
                    response = TABLE_LOGS.query(
                        IndexName='StatusIndex',
                        KeyConditionExpression=Key('status').eq(int(status_filter))
                    )

                # CASO 3: Si no hay filtro devolvemos todos los logs
                else:
                    logger.info(f"Devolviendo todos los logs...")
                    response = TABLE_LOGS.scan()

                return {
                    'statusCode': 200,
                    'headers': headers,
                    'body': json.dumps(response.get('Items', []))
                }
        
        # RUTA: No existe (ej. /usuarios)
        return {
            'statusCode': 404, 
            'headers': headers, 
            'body': json.dumps({'error': 'Not Found'})}

    except ClientError as e:
        error_code = e.response['Error']['Code']
        error_msg = e.response['Error']['Message']
        logger.error(f"Fallo de Amazon DynamoDB. Código: {error_code} - {error_msg}")
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error': 'Fallo en base de datos'})
        }

    except Exception as e:
        # logger.exception muestra debajo toda la traza del error (linea de codigo donde falla, etc)
        logger.exception(f"Error interno en el código: {e}")
        return {'statusCode': 500,
                'headers': headers,
                'body': json.dumps({'error': 'Error interno'})
        }

