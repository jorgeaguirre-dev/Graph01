provider "aws" {
  region = "us-east-1"
}

# 1. Tabla de DynamoDB
resource "aws_dynamodb_table" "api_table" {
  name           = "MiTablaGraphene"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

# 2. Rol de IAM con permisos de ejecución básica y DynamoDB
resource "aws_iam_role" "lambda_role" {
  name = "graphene_lambda_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "dynamo_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

# 3. La Función Lambda (Graphene)
resource "aws_lambda_function" "graphql_api" {
  filename      = "function.zip"
  function_name = "graphene_api_lambda" # Nombre actualizado
  role          = aws_iam_role.lambda_role.arn
  handler       = "app.handler"        # Apunta al Mangum(app) en app.py
  runtime       = "python3.11"

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.api_table.name
    }
  }
}

# 4. URL Pública para la Lambda (Para entrar desde el navegador)
resource "aws_lambda_function_url" "api_url" {
  function_name      = aws_lambda_function.graphql_api.function_name
  authorization_type = "NONE" # Para pruebas, permite acceso público
}


# Devuelve la URL pública para probar en el navegador
output "graphql_api_url" {
  description = "URL para acceder al explorador de Graphene"
  value       = aws_lambda_function_url.api_url.function_url
}

# Devuelve el nombre de la tabla de DynamoDB
output "dynamodb_table_name" {
  value = aws_dynamodb_table.api_table.name
}

# Devuelve el ARN de la Lambda
output "lambda_arn" {
  value = aws_lambda_function.graphql_api.arn
}