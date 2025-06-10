resource "aws_cloudtrail_event_data_store" "team_data_store" {
  name                           = var.name
  organization_enabled           = var.organization_enabled
  retention_period               = var.retention_period
  tags                           = var.tags
  termination_protection_enabled = true
}
