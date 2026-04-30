resource "aws_api_gateway_rest_api" "rest_api" {
  name = "terraform_rest_api"
}

# Resources
resource "aws_api_gateway_resource" "python_resource" {
  parent_id   = aws_api_gateway_rest_api.rest_api.root_resource_id
  path_part   = "python"
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
}

resource "aws_api_gateway_resource" "node_resource" {
  parent_id   = aws_api_gateway_rest_api.rest_api.root_resource_id
  path_part   = "node"
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
}

# Method
resource "aws_api_gateway_method" "python_method" {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.python_resource.id
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
}

resource "aws_api_gateway_method" "node_method" {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.node_resource.id
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
}

# Integration
resource "aws_api_gateway_integration" "python_integration" {
  http_method             = aws_api_gateway_method.python_method.http_method
  resource_id             = aws_api_gateway_resource.python_resource.id
  rest_api_id             = aws_api_gateway_rest_api.rest_api.id
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.python_function.invoke_arn
}

resource "aws_api_gateway_integration" "node_integration" {
  http_method             = aws_api_gateway_method.node_method.http_method
  resource_id             = aws_api_gateway_resource.node_resource.id
  rest_api_id             = aws_api_gateway_rest_api.rest_api.id
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.node_function.invoke_arn
}

#Deployment
resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id

# I added the triggers block for any changes in the scirpt to be able to 
# recreate the resources.
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.python_resource.id,
      aws_api_gateway_resource.node_resource.id,
      aws_api_gateway_method.python_method.id,
      aws_api_gateway_method.node_method.id,
      aws_api_gateway_integration.python_integration.id,
      aws_api_gateway_integration.node_integration.id,
    ]))
  }

# This block is required due to remote API limitations for Terraform to create a replacement
# resource before destroying the current resource.
  lifecycle {
    create_before_destroy = true
  }
}

#Stage
resource "aws_api_gateway_stage" "stage_production" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  stage_name    = "prod"
}