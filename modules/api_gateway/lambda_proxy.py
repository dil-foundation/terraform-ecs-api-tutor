import json
import urllib3
import os
import base64

def handler(event, context):
    """
    Lambda function to proxy API Gateway requests to ECS Fargate service
    """
    
    # Get ALB DNS name from environment variables
    alb_dns_name = os.environ.get('ALB_DNS_NAME')
    if not alb_dns_name:
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
            },
            'body': json.dumps({'error': 'ALB_DNS_NAME not configured'})
        }
    
    # Extract request information
    http_method = event.get('httpMethod', 'GET')
    path = event.get('path', '')
    query_params = event.get('queryStringParameters') or {}
    headers = event.get('headers') or {}
    body = event.get('body', '')
    
    # Strip /api prefix from path for backend forwarding
    if path.startswith('/api/'):
        backend_path = path[4:]  # Remove '/api' prefix
    elif path.startswith('/api'):
        backend_path = path[4:]  # Remove '/api' prefix
    else:
        backend_path = path
    
    # Build target URL
    target_url = f"http://{alb_dns_name}{backend_path}"
    
    # Add query parameters if any
    if query_params:
        query_string = '&'.join([f"{k}={v}" for k, v in query_params.items()])
        target_url += f"?{query_string}"
    
    # Prepare headers for the target request
    target_headers = {
        'Content-Type': headers.get('Content-Type', 'application/json'),
        'User-Agent': headers.get('User-Agent', 'API-Gateway-Proxy'),
    }
    
    # Add authorization header if present
    if 'Authorization' in headers:
        target_headers['Authorization'] = headers['Authorization']
    
    # Create HTTP client
    http = urllib3.PoolManager()
    
    try:
        # Make request to ECS service
        if http_method in ['GET', 'DELETE']:
            response = http.request(
                http_method,
                target_url,
                headers=target_headers,
                timeout=30
            )
        else:  # POST, PUT, PATCH
            response = http.request(
                http_method,
                target_url,
                body=body,
                headers=target_headers,
                timeout=30
            )
        
        # Get response headers
        response_headers = dict(response.headers)
        
        # Prepare response headers for API Gateway
        gateway_headers = {
            'Content-Type': response_headers.get('content-type', 'application/json'),
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
            'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
        }
        
        # Add other important headers
        if 'content-length' in response_headers:
            gateway_headers['Content-Length'] = response_headers['content-length']
        
        # Handle binary content
        response_body = response.data
        is_base64_encoded = False
        
        # Check if content is binary
        content_type = response_headers.get('content-type', '').lower()
        if any(binary_type in content_type for binary_type in ['image/', 'application/pdf', 'application/octet-stream']):
            response_body = base64.b64encode(response.data).decode('utf-8')
            is_base64_encoded = True
        
        return {
            'statusCode': response.status,
            'headers': gateway_headers,
            'body': response_body,
            'isBase64Encoded': is_base64_encoded
        }
        
    except urllib3.exceptions.TimeoutError:
        return {
            'statusCode': 504,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
            },
            'body': json.dumps({'error': 'Request timeout'})
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
            },
            'body': json.dumps({'error': f'Internal server error: {str(e)}'})
        }
