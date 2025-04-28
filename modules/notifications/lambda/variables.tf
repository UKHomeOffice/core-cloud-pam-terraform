variable "function_name" {
  description = "Lambda function name"
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
