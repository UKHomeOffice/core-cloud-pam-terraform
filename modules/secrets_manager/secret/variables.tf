variable "name" {
  description = "Name of the secret"
  type = string
}

variable "kms_key_id" {
  description = "ARN of the KMS key to encrypt the secret"
  type = string
}