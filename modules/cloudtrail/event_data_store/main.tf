resource "aws_cloudtrail_event_data_store" "team_data_store" {
  name                           = var.name
  organization_enabled           = var.organization_enabled
  retention_period               = var.retention_period
  termination_protection_enabled = true
  tags = merge(
    var.tags,
    {
      cost-centre  = "1709144"
      account-code = "521835"
      portfolio-id = "cto"
      project-id   = "cc"
      service-id   = "core-platform"
      environment-type = "prod"
      owner-business = "cc-andromeda"
      budget-holder = "corecloud@homeoffice.gov.uk"
    }
  )
}
