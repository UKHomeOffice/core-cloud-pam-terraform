data "aws_dynamodb_table" "eligibility_table" {
  name = var.eligibility_table_name
}

data "aws_dynamodb_table" "approvers_table" {
  name = var.approvers_table_name
}

data "aws_ssoadmin_instances" "this" {}

data "aws_organizations_organization" "this" {}

data "aws_organizations_organizational_units" "root_ous" {
  parent_id = data.aws_organizations_organization.this.roots[0].id
}

data "aws_organizations_organizational_units" "children_ous" {
  for_each  = { for ou in data.aws_organizations_organizational_units.root_ous.organizational_units : ou.id => ou }
  parent_id = each.key
}

locals {
  # Top-level OUs
  top_level_ous = [
    for ou in data.aws_organizations_organizational_units.root_ous.organizational_units : {
      ou_id = ou.id
      name  = ou.name
    }
  ]

  # Second-level OUs (children)
  second_level_ous = flatten([
    for parent_ou_id, ous in data.aws_organizations_organizational_units.children_ous : [
      for ou in ous.organizational_units : {
        ou_id = ou.id
        name  = "${lookup(
          { for ou in data.aws_organizations_organizational_units.root_ous.organizational_units : ou.id => ou.name },
          parent_ou_id,
          "UNKNOWN"
        )}/${ou.name}"
      }
    ]
  ])

  all_ous = concat(local.top_level_ous, local.second_level_ous)
}

output "all_out" {
  value = local.all_ous
}

data "aws_identitystore_group" "approvers_group" {
  # for_each = toset(var.approver_policies)
  for_each = { for policy in var.approvers_policies : policy.group_name => policy }

  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]

  alternate_identifier {
    unique_attribute {
      attribute_path  = "DisplayName"
      attribute_value = each.value.group_name
    }
  }
}

data "aws_identitystore_group" "eligibility_group" {
  for_each = { for policy in var.eligibility_policies : policy.group_name => policy }

  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]

  alternate_identifier {
    unique_attribute {
      attribute_path  = "DisplayName"
      attribute_value = each.value.group_name
    }
  }
}

data "aws_ssoadmin_permission_set" "this" {
  for_each = { for policy in var.eligibility_policies : policy.group_name => policy }

  instance_arn = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  name         = each.value.permissions
}

locals {
  eligibility_items = {
    for idx, policy in var.eligibility_policies : idx => jsonencode({
      id = {
        S = data.aws_identitystore_group.eligibility_group[policy.group_name].group_id
      },
      accounts = {
        L = [
          for account in policy.accounts : {
            M = {
              id   = { S = tostring(one([for acct in data.aws_organizations_organization.this.accounts : acct.id if acct.name == account.account_name])) },
              name = { S = account.account_name }
            }
          }
        ]
      },
      approvalRequired = {
        BOOL = policy.approval_required
      },
      createdAt = {
        S = "2025-06-24T09:00:00Z"
      },
      duration = {
        S = "${tostring(policy.duration)}"
      },
      modifiedBy = {
        S = "Terraform"
      },
      name = {
        S = "${data.aws_identitystore_group.eligibility_group[policy.group_name].display_name}"
      },
      ous = {
        L = []
      },
      permissions = {
        L = [
          {
            M = {
              id   = { S = data.aws_ssoadmin_permission_set.this[policy.group_name].id },
              name = { S = policy.permissions }
            }
          }
        ]
      }
      ticketNo = {
        S = "${policy.ticket_no}"
      },
      type = {
        S = "Group"
      },
      updatedAt = {
        S = "2025-06-24T09:00:00Z"
      },
      __typename = {
        S = "Eligibility"
      }
    })
  }
}

locals {
  approvers_items = {
    for i, policy in var.approvers_policies : i => jsonencode({
      id = {
        S = tostring(one([for acct in data.aws_organizations_organization.this.accounts : acct.id if acct.name == policy.account_name]))
      },
      approvers = {
        L = [
          { S = data.aws_identitystore_group.approvers_group[policy.group_name].display_name }
        ]
      },
      createdAt = {
        S = "2025-06-24T09:00:00Z"
      },
      groupIds = {
        L = [
          { S = data.aws_identitystore_group.approvers_group[policy.group_name].group_id }
        ]
      },
      modifiedBy = {
        S = "Terraform"
      },
      name = {
        S = policy.account_name
      },
      ticketNo = {
        S = policy.ticket_no
      },
      type = {
        S = "Account"
      },
      updatedAt = {
        S = "2025-06-24T09:00:00Z"
      },
      __typename = {
        S = "Approvers"
      }
    })
  }
}

resource "aws_dynamodb_table_item" "eligibility" {
  for_each = local.eligibility_items

  table_name = data.aws_dynamodb_table.eligibility_table.name
  hash_key   = data.aws_dynamodb_table.eligibility_table.hash_key
  item       = each.value
}

resource "aws_dynamodb_table_item" "approvers" {
  for_each = local.approvers_items

  table_name = data.aws_dynamodb_table.approvers_table.name
  hash_key   = data.aws_dynamodb_table.approvers_table.hash_key
  item       = each.value
}
