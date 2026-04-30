data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "lambda_execution_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}


resource "aws_iam_role_policy_attachment" "test_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "lambda_node" {
  type        = "zip"
  source_file = "./src/chewbacca-node-lambda.js"
  output_path = "./lambda/node.zip"
}

data "archive_file" "lambda_python" {
  type        = "zip"
  source_file = "./src/chewbacca-python-lambda.py"
  output_path = "./lambda/python.zip"
}

resource "aws_lambda_function" "node_function" {
  filename      = data.archive_file.lambda_node.output_path
  function_name = "my_node_function"
  role          = aws_iam_role.lambda_role.arn
  handler       = "chewbacca-node-lambda.handler"
  code_sha256   = data.archive_file.lambda_node.output_base64sha256

  runtime = "nodejs24.x"
}

resource "aws_lambda_function" "python_function" {
  filename      = data.archive_file.lambda_python.output_path
  function_name = "my_python_function"
  role          = aws_iam_role.lambda_role.arn
  handler       = "chewbacca-python-lambda.lambda_handler"
  code_sha256   = data.archive_file.lambda_python.output_base64sha256

  runtime = "python3.14"
}

# this is to give lambda permissions to invoke the function for python and node
resource "aws_lambda_permission" "python_lambda_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.python_function.function_name
  principal     = "apigateway.amazonaws.com"
}

resource "aws_lambda_permission" "node_lambda_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.node_function.function_name
  principal     = "apigateway.amazonaws.com"
}