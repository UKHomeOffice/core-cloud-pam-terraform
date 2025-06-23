<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 5.78.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.78.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_dynamodb_table_item.approvers](https://registry.terraform.io/providers/hashicorp/aws/5.78.0/docs/resources/dynamodb_table_item) | resource |
| [aws_dynamodb_table_item.eligibility](https://registry.terraform.io/providers/hashicorp/aws/5.78.0/docs/resources/dynamodb_table_item) | resource |
| [aws_dynamodb_table.approvers_table](https://registry.terraform.io/providers/hashicorp/aws/5.78.0/docs/data-sources/dynamodb_table) | data source |
| [aws_dynamodb_table.eligibility_table](https://registry.terraform.io/providers/hashicorp/aws/5.78.0/docs/data-sources/dynamodb_table) | data source |
| [aws_identitystore_group.approvers_group](https://registry.terraform.io/providers/hashicorp/aws/5.78.0/docs/data-sources/identitystore_group) | data source |
| [aws_identitystore_group.eligibility_group](https://registry.terraform.io/providers/hashicorp/aws/5.78.0/docs/data-sources/identitystore_group) | data source |
| [aws_ssoadmin_instances.this](https://registry.terraform.io/providers/hashicorp/aws/5.78.0/docs/data-sources/ssoadmin_instances) | data source |
| [aws_ssoadmin_permission_set.this](https://registry.terraform.io/providers/hashicorp/aws/5.78.0/docs/data-sources/ssoadmin_permission_set) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_approver_policies"></a> [approver\_policies](#input\_approver\_policies) | list of approval policies | `list` | n/a | yes |
| <a name="input_approvers_table_name"></a> [approvers\_table\_name](#input\_approvers\_table\_name) | Name of the Approvers Policy table | `string` | n/a | yes |
| <a name="input_eligibility_policies"></a> [eligibility\_policies](#input\_eligibility\_policies) | list of eligibility policies | `list` | n/a | yes |
| <a name="input_eligibility_table_name"></a> [eligibility\_table\_name](#input\_eligibility\_table\_name) | Name of the Eligibility Policy table | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_approvers_items_json"></a> [approvers\_items\_json](#output\_approvers\_items\_json) | n/a |
| <a name="output_eligibility_items_json"></a> [eligibility\_items\_json](#output\_eligibility\_items\_json) | n/a |
<!-- END_TF_DOCS -->