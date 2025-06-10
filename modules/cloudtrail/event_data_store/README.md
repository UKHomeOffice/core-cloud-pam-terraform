<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudtrail_event_data_store.team_data_store](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudtrail_event_data_store) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name"></a> [name](#input\_name) | Name of the Event Data Store | `string` | n/a | yes |
| <a name="input_organization_enabled"></a> [organization\_enabled](#input\_organization\_enabled) | Collects events logged for the whole organization | `bool` | n/a | yes |
| <a name="input_retention_period"></a> [retention\_period](#input\_retention\_period) | The retention period of the event data store, in days. | `number` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to assign to the resource | `map(string)` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->