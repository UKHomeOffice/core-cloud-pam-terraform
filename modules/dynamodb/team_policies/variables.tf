variable "approver_policies" {
  description = "list of approval policies"
  type        = list
}

variable "approvers_table_name" {
  description = "Name of the Approvers Policy table"
  type        = string
}

variable "eligibility_policies" {
  description = "list of eligibility policies"
  type        = list
}

variable "eligibility_table_name" {
  description = "Name of the Eligibility Policy table"
  type        = string
}
