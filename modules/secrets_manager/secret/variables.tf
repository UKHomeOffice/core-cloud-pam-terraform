variable "description" {
  description = "Description of the secret"
  type        = string
}

variable "name" {
  description = "Name of the secret"
  type        = string
}

variable "kms_key_id" {
  description = "ARN of the KMS key to encrypt the secret"
  type        = string
}

variable "secret_data" {
  description = "Secret value"
  type        = map(string)
  sensitive   = true
}
