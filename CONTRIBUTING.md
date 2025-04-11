# How to contribute

This is the contribution guide for core-cloud-pam-terraform. This guide will cover the primary way we
expect contributions to be made, which is updating AWS resource moduloes, however general advice can be applied to other types of contribution as well.

All of the files and directories listed in this guide can be found in the modules
directory.

## Submitting changes

When making a contribution you should start by creating a GitHub issue. Once the issue is created
you should then select the option to create a branch for the issue. Once this new branch has been
created and checked out you can start working on the changes.

Once you have made the changes you should commit them with an all lower case message describing the
changes made and prefixed by the type of change, for example, "feat: added new variable for
cloudtrail event data store". Below are the different types of changes:

- **feat**: New feature for the user, not a new feature for build script.
- **fix**: Bug fix for the user, not a fix to a build script.
- **docs**: Changes to the documentation.
- **style**: Formatting, missing semi colons, etcetera, no production code change.
- **refactor**: Refactoring production code, for example, renaming a variable.

Once the changes have been committed, push them to the origin and create a pull request. The
description of the pull request should include a link to the issue, which can be done by adding
\#x where x is the number of the issue.

The pull request must be reviewed by a member of our team and pass the checks in our pipelines
before it can be squashed and merged.

## Coding conventions

Please follow the style guide at https://developer.hashicorp.com/terraform/language/style when making
contributions to the Terraform code.
