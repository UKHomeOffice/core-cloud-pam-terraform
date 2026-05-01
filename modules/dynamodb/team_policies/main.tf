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
    for ou in data.aws_organizations_organizational_units.level1_ous.children : {
      id   = ou.id
      name = ou.name
    }
  ]

  second_level_ous = flatten([
    for parent_id, ous in data.aws_organizations_organizational_units.level2_ous : [
      for ou in ous.children : {
        id   = ou.id
        name = "${lookup({ for x in local.top_level_ous : x.id => x.name }, parent_id)}/${ou.name}"
      }
    ]
  ])

  third_level_ous = flatten([
    for parent_id, ous in data.aws_organizations_organizational_units.level3_ous : [
      for ou in ous.children : {
        id   = ou.id
        name = "${lookup({ for x in local.second_level_ous : x.id => x.name }, parent_id)}/${ou.name}"
      }
    ]
  ])

  fourth_level_ous = flatten([
    for parent_id, ous in data.aws_organizations_organizational_units.level4_ous : [
      for ou in ous.children : {
        id   = ou.id
        name = "${lookup({ for x in local.third_level_ous : x.id => x.name }, parent_id)}/${ou.name}"
      }
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
  unique_approvers_group_names = toset(flatten([
    for p in var.approvers_policies : p.approvers_groups
  ]))

  unique_eligibility_group_names = toset([
    for p in var.eligibility_policies : p.group_name
  ])

  unique_permission_set_names = toset(flatten([
    for p in var.eligibility_policies : p.permissions
  ]))
}

data "aws_identitystore_group" "approvers_group" {
  for_each = local.unique_approvers_group_names

  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]

  alternate_identifier {
    unique_attribute {
      attribute_path  = "DisplayName"
      attribute_value = each.value
    }
  }
}

data "aws_identitystore_group" "eligibility_group" {
  for_each = local.unique_eligibility_group_names

  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]

  alternate_identifier {
    unique_attribute {
      attribute_path  = "DisplayName"
      attribute_value = each.value
    }
  }
}

data "aws_ssoadmin_permission_set" "this" {
  for_each = local.unique_permission_set_names

  instance_arn = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  name         = each.value
}

locals {
  invalid_ous = flatten([
    for p in var.eligibility_policies : [
      for ou in p.ous :
      ou if !contains([for o in local.all_ous : o.name], ou)
    ]
  ])

  invalid_accounts = flatten([
    for p in var.eligibility_policies : [
      for acct in p.accounts :
      acct if !contains(
        [for a in data.aws_organizations_organization.this.accounts : a.name],
        acct
      )
    ]
  ])
}

resource "null_resource" "validation_guard" {
  count = (
    length(local.invalid_ous) > 0 ||
    length(local.invalid_accounts) > 0
  ) ? 1 : 0

  triggers = {
    invalid_ous      = join(",", distinct(local.invalid_ous))
    invalid_accounts = join(",", distinct(local.invalid_accounts))
  }

  provisioner "local-exec" {
    command = <<EOT
echo "❌ Validation failed"
echo "Invalid OUs: ${self.triggers.invalid_ous}"
echo "Invalid Accounts: ${self.triggers.invalid_accounts}"
exit 1
EOT
  }
}

locals {
  eligibility_items = {
    for i, policy in var.eligibility_policies : i => jsonencode({

      id = {
        S = tostring(
          data.aws_identitystore_group.eligibility_group[policy.group_name].group_id
        )
      }

      accounts = {
        L = [
          for account in policy.accounts : {
            M = {
              id = {
                S = tostring(one([
                  for a in data.aws_organizations_organization.this.accounts :
                  a.id if a.name == account
                ]))
              }
              name = { S = account }
            }
          }
        ]
      }

      approvalRequired = {
        BOOL = policy.approval_required
      }

      createdAt  = { S = "2025-06-24T09:00:00Z" }
      updatedAt  = { S = "2025-06-24T09:00:00Z" }
      modifiedBy = { S = "Terraform" }

      duration = { S = tostring(policy.duration) }

      name = {
        S = data.aws_identitystore_group.eligibility_group[policy.group_name].display_name
      }

      ous = {
        L = [
          for ou in policy.ous : {
            M = {
              id = {
                S = tostring(one([
                  for org in local.all_ous :
                  org.id if org.name == ou
                ]))
              }
              name = {
                S = element(split("/", ou), length(split("/", ou)) - 1)
              }
            }
          }
        ]
      }

      permissions = {
        L = [
          for p in policy.permissions : {
            M = {
              id   = { S = data.aws_ssoadmin_permission_set.this[p].id }
              name = { S = p }
            }
          }
        ]
      }

      ticketNo  = { S = policy.ticket_no }
      type      = { S = "Group" }
      __typename = { S = "Eligibility" }

    })
  }
}

locals {
  approvers_items = {
    for i, policy in var.approvers_policies : i => jsonencode({

      id = {
        S = (
          lower(policy.type) == "account"
          ? tostring(one([
              for a in data.aws_organizations_organization.this.accounts :
              a.id if a.name == policy.name
            ]))
          : tostring(one([
              for ou in local.all_ous :
              ou.id if ou.name == policy.name
            ]))
        )
      }

      approvers = {
        L = [
          for g in policy.approvers_groups :
          { S = data.aws_identitystore_group.approvers_group[g].display_name }
        ]
      }

      groupIds = {
        L = [
          for g in policy.approvers_groups :
          { S = data.aws_identitystore_group.approvers_group[g].group_id }
        ]
      }

      name = {
        S = lower(policy.type) == "account"
          ? policy.name
          : element(split("/", policy.name), length(split("/", policy.name)) - 1)
      }

      type      = { S = lower(policy.type) == "account" ? "Account" : "OU" }
      ticketNo  = { S = policy.ticket_no }
      createdAt = { S = "2025-06-24T09:00:00Z" }
      updatedAt = { S = "2025-06-24T09:00:00Z" }
      modifiedBy = { S = "Terraform" }
      __typename = { S = "Approvers" }
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

resource "aws_dynamodb_table_item" "approvers" {
  for_each = local.approvers_items

  table_name = data.aws_dynamodb_table.approvers_table.name
  hash_key   = data.aws_dynamodb_table.approvers_table.hash_key
  item       = each.value

  depends_on = [null_resource.validation_guard]
}
