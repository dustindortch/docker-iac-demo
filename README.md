# IaC demo-build container

This repository builds a rockylinux-based container for using the following infrastructure as code tooling:

* Hashicorp Terraform
* Hashicorp Packer
* Hashicorp Vault
* Red Hat Ansible

It contains three useful scripts:

* `./build.sh`            - Docker build script
* `./run.sh`              - Docker run script
* `./example_env_vars.sh` - Set environment variables script
* `./wkd/tf-run.sh`       - Terraform runner

## Docker build script

The build scripts accepts the following environment variables:

* `DOCKER_IMAGE_NAME` (default:demo-build) - the name to set for the image
* `DOCKER_IMAGE_TAG` (default:latest)      - the tag to set for the image

### Arguments

* `DOCKER_IMAGE_NAME` - overrides the default value or environment variable
* `DOCKER_IMAGE_TAG`  - overrides the default value or environment variable

### Usage

```bash
./build.sh [<DOCKER_IMAGE_NAME> [<DOCKER_IMAGE_TAG>]]
```

## Docker run script

The run scripts accepts the following environment variables:

* `DOCKER_IMAGE_NAME` (default:demo-build) - the name of the image
* `DOCKER_IMAGE_TAG` (default:latest)      - the tag of the image

Optional (required for Azure):

* `AZ_SUBSCRIPTION` - the name or subscription_id for the Azure subscription

Optional (required for AWS):

* `AWS_REGION` (default:us-east-1)          - the AWS region to authenticate and deploy (this is a minor limitation, fine for a lab)
* `AWS_SSO_START_URL`                       - the AWS SSO Start URL to authenticate
* `AWS_ROLE_NAME` (default:PowerUserAccess) - the AWS role name to assume
* `AWS_ACCOUNT_ID`                          - the AWS account ID to authenticate

### Arguments

* `interactive` - interactive launches the container
* `awsapply`    - executes the container automatically running `/wkd/tf-run.sh apply aws terraform_aws_tutorial`
* `awsdestroy`  - executes the container automatically running `/wkd/tf-run.sh destroy aws terraform_aws_tutorial`
* `azapply`     - executes the container automatically running `/wkd/tf-run.sh apply az terraform_azurerm_tutorial`
* `azdestroy`   - executes the container automatically running `/wkd/tf-run.sh destroy az terraform_azurerm_tutorial`

### Usage

```bash
./run.sh [<DOCKER_IMAGE_NAME> [<DOCKER_IMAGE_TAG>]] <interactive|awsapply|awsdestroy|azapply|azdestroy>
```

## Set environment variables script

Manually typing the environment variables can be tedious.  The following variables must be set as there is no default provided:

* `AWS_SSO_START_URL`
* `AWS_ACCOUNT_ID`
* `AZ_SUBSCRIPTION`

The `example_env_vars.sh` can be renamed to `set_my_env_vars.sh` and you can set these non-sensitive values.  It will automatically be dot-sourced within the `run.sh` if it exists.  Any of the environment variables can be set to override default values.

Setting the variable `DEBUG=1` in the `set_my_env_vars.sh` script will enable debugging output to validate settings stepping through the script.

## Terraform runner

The `./wkd/tf-run.sh` script is executed when the `./run.sh` script is not launched interactively.

### Arguments

Call:

* `apply`   - executes `terraform apply -auto-approve`
* `destroy` - executes `terraform destroy -auto-approve`

Cloud:

* `aws` - authenticates to the aws cli with `aws sso login` interactively (device code via browser)
* `az`  - authenticates to the azure cli with `az login` interactively (device code via browser) and sets the subscription

Tutorial:

* `terraform_aws_tutorial`     - changes directory to `/wkd/terraform_aws_tutorial` before executing Terraform workflow
* `terraform_azurerm_tutorial` - changes directory to `/wkd/terraform_azurerm_tutorial` before executing Terraform workflow

### Workflow

The script executes a series of commands and will exit if any of them fail.

Workflow:

* `terraform init`
* `terraform fmt -check`
* `terraform validate`
* `terraform <action> -auto-approve`

### Usage

```bash
/wkd/tf-run.sh <apply|destroy> <aws|az> <terraformRootModuleDirectory>
```
