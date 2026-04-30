# I referenced the aws api gate rest api that way it will output the information for the rest api.
# The value in the string needed to represent the invoke url for the execute api, the region as well.
# The aws api stage was also included in the value, this was done for reusability in the code. 
# I also decided to hardcode the python and node resource to invoke both of the lambda functions and make them
# into two lambda endpoints for python and node.




output "python_api_url" {
  value = "https://${aws_api_gateway_rest_api.rest_api.id}.execute-api.us-east-1.amazonaws.com/${aws_api_gateway_stage.stage_production.stage_name}/python?name=myself"
}

output "node_api_url" {
  value = "https://${aws_api_gateway_rest_api.rest_api.id}.execute-api.us-east-1.amazonaws.com/${aws_api_gateway_stage.stage_production.stage_name}/node?name=malgus"
}