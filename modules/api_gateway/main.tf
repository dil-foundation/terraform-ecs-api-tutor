# API Gateway REST API
resource "aws_api_gateway_rest_api" "api" {
  name        = var.name
  description = "API Gateway for ${var.tenant_name} file management service"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name        = var.name
    Environment = var.environment
    Tenant      = var.tenant_name
  }
}

# API Gateway Resource - /api
resource "aws_api_gateway_resource" "api" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "api"
}

# API Gateway Resource - /api/files
resource "aws_api_gateway_resource" "files" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.api.id
  path_part   = "files"
}

# API Gateway Resource - /api/files/upload
resource "aws_api_gateway_resource" "files_upload" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.files.id
  path_part   = "upload"
}

# API Gateway Resource for individual file
resource "aws_api_gateway_resource" "file_id" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.files.id
  path_part   = "{id}"
}

# API Gateway Resource - /api/health
resource "aws_api_gateway_resource" "health" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.api.id
  path_part   = "health"
}

# Only keeping APIs that are actually used by the frontend
# Removed unused APIs: auth, users, collections

# API Gateway Method - GET /api/files
resource "aws_api_gateway_method" "get_files" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.files.id
  http_method   = "GET"
  authorization = "NONE"
}

# API Gateway Method - POST /api/files
resource "aws_api_gateway_method" "post_files" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.files.id
  http_method   = "POST"
  authorization = "NONE"
}

# API Gateway Method - POST /api/files/upload
resource "aws_api_gateway_method" "post_files_upload" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.files_upload.id
  http_method   = "POST"
  authorization = "NONE"
}

# API Gateway Method - GET /api/files/{id}
resource "aws_api_gateway_method" "get_file" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.file_id.id
  http_method   = "GET"
  authorization = "NONE"
}

# API Gateway Method - DELETE /api/files/{id}
resource "aws_api_gateway_method" "delete_file" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.file_id.id
  http_method   = "DELETE"
  authorization = "NONE"
}

# API Gateway Method - GET /api/health
resource "aws_api_gateway_method" "get_health" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.health.id
  http_method   = "GET"
  authorization = "NONE"
}

# Removed unused methods for auth, users, and collections APIs

# API Gateway Integration - GET /api/files
resource "aws_api_gateway_integration" "get_files" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.files.id
  http_method = aws_api_gateway_method.get_files.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.api_proxy.arn}/invocations"
}

# API Gateway Integration - POST /api/files
resource "aws_api_gateway_integration" "post_files" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.files.id
  http_method = aws_api_gateway_method.post_files.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.api_proxy.arn}/invocations"
}

# API Gateway Integration - POST /api/files/upload
resource "aws_api_gateway_integration" "post_files_upload" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.files_upload.id
  http_method = aws_api_gateway_method.post_files_upload.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.api_proxy.arn}/invocations"
}

# API Gateway Integration - GET /api/files/{id}
resource "aws_api_gateway_integration" "get_file" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.file_id.id
  http_method = aws_api_gateway_method.get_file.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.api_proxy.arn}/invocations"
}

# API Gateway Integration - DELETE /api/files/{id}
resource "aws_api_gateway_integration" "delete_file" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.file_id.id
  http_method = aws_api_gateway_method.delete_file.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.api_proxy.arn}/invocations"
}

# API Gateway Integration - GET /api/health
resource "aws_api_gateway_integration" "get_health" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.health.id
  http_method = aws_api_gateway_method.get_health.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.api_proxy.arn}/invocations"
}

# Removed unused integrations for auth, users, and collections APIs

# Lambda function to proxy requests to ECS
resource "aws_lambda_function" "api_proxy" {
  filename      = "${path.module}/api_proxy.zip"
  function_name = "${var.tenant_name}-api-proxy"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "python3.9"
  timeout       = 30

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      ALB_DNS_NAME = var.alb_dns_name
    }
  }

  tags = {
    Name        = "${var.tenant_name}-api-proxy"
    Environment = var.environment
    Tenant      = var.tenant_name
  }
}

# Security group for Lambda function
resource "aws_security_group" "lambda_sg" {
  name_prefix = "${var.tenant_name}-lambda-sg"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.tenant_name}-lambda-sg"
    Environment = var.environment
    Tenant      = var.tenant_name
  }
}

# Lambda execution role
resource "aws_iam_role" "lambda_role" {
  name = "${var.tenant_name}-api-proxy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.tenant_name}-api-proxy-role"
    Environment = var.environment
    Tenant      = var.tenant_name
  }
}

# Lambda basic execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda VPC access policy
resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.get_files,
    aws_api_gateway_integration.post_files,
    aws_api_gateway_integration.post_files_upload,
    aws_api_gateway_integration.get_file,
    aws_api_gateway_integration.delete_file,
    aws_api_gateway_integration.get_health,
  ]

  rest_api_id = aws_api_gateway_rest_api.api.id

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway Stage
resource "aws_api_gateway_stage" "stage" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = var.stage_name

  tags = {
    Name        = "${var.tenant_name}-api-stage"
    Environment = var.environment
    Tenant      = var.tenant_name
  }
}

# API Gateway Method Settings for throttling
resource "aws_api_gateway_method_settings" "throttle_settings" {
  count = var.throttle_rate_limit > 0 ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.stage.stage_name
  method_path = "*/*"

  settings {
    throttling_rate_limit  = var.throttle_rate_limit
    throttling_burst_limit = var.throttle_burst_limit
  }
}

# CORS Configuration
resource "aws_api_gateway_method" "options_files" {
  count         = var.enable_cors ? 1 : 0
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.files.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "options_file_id" {
  count         = var.enable_cors ? 1 : 0
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.file_id.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_files" {
  count       = var.enable_cors ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.files.id
  http_method = aws_api_gateway_method.options_files[0].http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

resource "aws_api_gateway_integration" "options_file_id" {
  count       = var.enable_cors ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.file_id.id
  http_method = aws_api_gateway_method.options_file_id[0].http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

resource "aws_api_gateway_method_response" "options_files" {
  count       = var.enable_cors ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.files.id
  http_method = aws_api_gateway_method.options_files[0].http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_method_response" "options_file_id" {
  count       = var.enable_cors ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.file_id.id
  http_method = aws_api_gateway_method.options_file_id[0].http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "options_files" {
  count       = var.enable_cors ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.files.id
  http_method = aws_api_gateway_method.options_files[0].http_method
  status_code = aws_api_gateway_method_response.options_files[0].status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

resource "aws_api_gateway_integration_response" "options_file_id" {
  count       = var.enable_cors ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.file_id.id
  http_method = aws_api_gateway_method.options_file_id[0].http_method
  status_code = aws_api_gateway_method_response.options_file_id[0].status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# Lambda permission for API Gateway to invoke the function
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_proxy.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

# Data sources
data "aws_region" "current" {}
