output "function_qualified_arn" {
  value = aws_lambda_function.lambda.qualified_arn
}

output "iam_role_id" {
  value = aws_iam_role.lambda.id
}

output "iam_role_arn" {
  value = aws_iam_role.lambda.arn
}

