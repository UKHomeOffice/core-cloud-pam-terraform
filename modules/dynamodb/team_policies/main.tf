data "aws_dynamodb_table" "eligibility_table" {
  name = var.eligibility_table_name
}

data "aws_dynamodb_table" "approvers_table" {
  name = var.approvers_table_name
}

data "aws_ssoadmin_instances" "this" {}
data "aws_organizations_organization" "this" {}

data "aws_organizations_organizational_units" "level1_ous" {
  parent_id = data.aws_organizations_organization.this.roots[0].id
}

data "aws_organizations_organizational_units" "level2_ous" {
  for_each  = { for ou in data.aws_organizations_organizational_units.level1_ous.children : ou.id => ou }
  parent_id = each.key
}

data "aws_organizations_organizational_units" "level3_ous" {
  for_each = merge([
    for parent in data.aws_organizations_organizational_units.level2_ous :
    { for child in parent.children : child.id => child }
  ]...)
  parent_id = each.key
}

data "aws_organizations_organizational_units" "level4_ous" {
  for_each = merge([
    for parent in data.aws_organizations_organizational_units.level3_ous :
    { for child in parent.children : child.id => child }
  ]...)
  parent_id = each.key
}

locals {
  root_ou = [{
    id   = data.aws_organizations_organization.this.roots[0].id
    name = "Root"
  }]

  top_level_ous = [
    for ou in data.aws_organizations_organizational_units.level1_ous.children :
    { id = ou.id, name = ou.name }
  ]

  second_level_ous = flatten([
    for parent_id, ous in data.aws_organizations_organizational_units.level2_ous : [
      for ou in ous.children :
      { id = ou.id, name = "${lookup({ for x in local.top_level_ous : x.id => x.name }, parent_id)}/${ou.name}" }
    ]
  ])

  third_level_ous = flatten([
    for parent_id, ous in data.aws_organizations_organizational_units.level3_ous : [
      for ou in ous.children :
      { id = ou.id, name = "${lookup({ for x in local.second_level_ous : x.id => x.name }, parent_id)}/${ou.name}" }
    ]
  ])

  fourth_level_ous = flatten([
    for parent_id, ous in data.aws_organizations_organizational_units.level4_ous : [
      for ou in ous.children :
      { id = ou.id, name = "${lookup({ for x in local.third_level_ous : x.id => x.name }, parent_id)}/${ou.name}" }
    ]
  ])

  all_ous = concat(
    local.root_ou,
    local.top_level_ous,
    local.second_level_ous,
    local.third_level_ous,
    local.fourth_level_ous
  )
}

locals {
  unique_eligibility_groups = toset([for p in var.eligibility_policies : p.group_name])
  unique_approver_groups    = toset(flatten([for p in var.approvers_policies : p.approvers_groups]))
  unique_permission_sets    = toset(flatten([for p in var.eligibility_policies : p.permissions]))
}

data "aws_identitystore_group" "eligibility" {
  for_each = local.unique_eligibility_groups

  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]

  alternate_identifier {
    unique_attribute {
      attribute_path  = "DisplayName"
      attribute_value = each.value
    }
  }
}

data "aws_identitystore_group" "approvers" {
  for_each = local.unique_approver_groups

  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]

  alternate_identifier {
    unique_attribute {
      attribute_path  = "DisplayName"
      attribute_value = each.value
    }
  }
}

data "aws_ssoadmin_permission_set" "this" {
  for_each = local.unique_permission_sets

  instance_arn = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  name         = each.value
}

locals {
  invalid_ticket_numbers = [
    for i, p in var.eligibility_policies :
    i if p.ticket_no == null || trim(p.ticket_no) == ""
  ]

  invalid_permission_sets = flatten([
    for p in var.eligibility_policies : [
      for perm in p.permissions :
      perm if !contains(keys(data.aws_ssoadmin_permission_set.this), perm)
    ]
  ])
}

resource "null_resource" "validation_guard" {
  count = (
    length(local.invalid_ticket_numbers) > 0 ||
    length(local.invalid_permission_sets) > 0
  ) ? 1 : 0

  provisioner "local-exec" {
    command = <<EOT
echo "Validation failed"
echo "Invalid ticket numbers at indices: ${join(",", local.invalid_ticket_numbers)}"
echo "Invalid permission sets: ${join(",", distinct(local.invalid_permission_sets))}"
exit 1
EOT
  }
}

locals {
  eligibility_items = {
    for i, policy in var.eligibility_policies : i => jsonencode({

      id = { S = data.aws_identitystore_group.eligibility[policy.group_name].group_id }

      ticketNo = { S = policy.ticket_no }
      type     = { S = "Group" }

      approvalRequired = { BOOL = policy.approval_required }
      duration         = { S = tostring(policy.duration) }

      createdAt  = { S = "2025-06-24T09:00:00Z" }
      updatedAt  = { S = "2025-06-24T09:00:00Z" }
      modifiedBy = { S = "Terraform" }
      __typename = { S = "Eligibility" }

    })
  }
}

resource "aws_dynamodb_table_item" "eligibility" {
  for_each = local.eligibility_items

  table_name = data.aws_dynamodb_table.eligibility_table.name
  hash_key   = data.aws_dynamodb_table.eligibility_table.hash_key
  item       = each.value

  depends_on = [null_resource.validation_guard]
}
