import json

def lambda_handler(event, context):
    print("El watchdog se ha ejecutado correctamente")

    return {
        'statusCode': 200,
        'body': json.dumps('Hola desde lambda, despliegue exitoso')
    }
    