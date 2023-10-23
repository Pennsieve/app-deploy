output "function_name" {
  description = "Name of the Lambda function."

  value = aws_lambda_function.application_gateway.function_name
}

output "base_url" {
  description = "Base URL for API Gateway stage."

  value = "${aws_apigatewayv2_stage.lambda.invoke_url}/run"
}

output "ecs_cluster" {
  description = "ECS cluster"

  value = aws_ecs_cluster.pipeline_cluster
}

output "fargate_task_definition" {
  description = "Fargate Task Definition"

  value = aws_ecs_task_definition.pipeline
}

output "computed_subnet_ids" {
  description = "az1"

  value = [aws_default_subnet.default_az1a.id, 
  aws_default_subnet.default_az1b.id,
  aws_default_subnet.default_az1c.id,
  aws_default_subnet.default_az1d.id,
  aws_default_subnet.default_az1e.id,
  aws_default_subnet.default_az1f.id]
}

output "subnet_ids" {
  description = "subnet ids comma separated string"

  value = split(",", "${aws_default_subnet.default_az1a.id},${aws_default_subnet.default_az1b.id},${aws_default_subnet.default_az1c.id},${aws_default_subnet.default_az1d.id},${aws_default_subnet.default_az1e.id},${aws_default_subnet.default_az1f.id}")
}

output "subnet_ids_str" {
  description = "subnet ids comma separated string"

  value = "${aws_default_subnet.default_az1a.id},${aws_default_subnet.default_az1b.id},${aws_default_subnet.default_az1c.id},${aws_default_subnet.default_az1d.id},${aws_default_subnet.default_az1e.id},${aws_default_subnet.default_az1f.id}"
}

output "default_vpc" {
  description = "default VPC"

  value = aws_default_vpc.default
}