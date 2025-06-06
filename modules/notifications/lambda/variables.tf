variable "function_name" {
  description = "Lambda function name"
  type        = string
}

variable "lambda_permission_sid" {
  description = "Statement ID of the Lambda permission"
  type        = string
}

variable "policy_name" {
  description = "Name of the policy attached to the Lambda execution role"
  type        = string
}

variable "role_name" {
  description = "Name of the Lambda execution role"
  type        = string
}

variable "sns_topic_name" {
  description = "Name of the SNS topic (created by TEAM installation)"
  type        = string
}

variable "source_file" {
  description = "Path to the lambda source file"
  type        = string
}
