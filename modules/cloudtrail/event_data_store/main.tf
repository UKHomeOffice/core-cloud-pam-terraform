resource "aws_cloudtrail_event_data_store" "team_data_store" {
  name                           = var.name
  termination_protection_enabled = true
}
