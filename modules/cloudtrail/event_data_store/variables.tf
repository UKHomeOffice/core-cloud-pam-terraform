variable "name" {
  description = "Name of the Event Data Store"
  type        = string
}

variable "organization_enabled" {
  description = "Collects events logged for the whole organization"
  type        = bool
}

variable "retention_period" {
  description = "The retention period of the event data store, in days."
  type        = number
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
}
