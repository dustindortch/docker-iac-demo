#!/bin/bash

if [ $# -lt 1 ] ; then
  echo "You must supply more than $# arguments"
  exit 1
fi

if [ "$1" != "apply" ] && [ "$1" != "destroy" ] || [ "$2" != "aws" ] && [ "$2" != "az" ] ; then
  echo "Usage: ${0} [apply|destroy] [aws|az] <terraformRootModuleDirectory>"
  exit 1
fi

case $2 in
  "az")
    if [ -z ${AZ_SUBSCRIPTION+x} ] ; then
      echo "You must set the AZ_SUBSCRIPTION environment variable."
      exit 1
    fi
    az login
    az account set --subscription="${AZ_SUBSCRIPTION}"
    ;;
  "aws")
    if [ -z ${AWS_REGION+x} ] ; then
      # us-east-1
      echo "You must set the AWS_REGION environment variable."
      exit 1
    fi

    if [ -z ${AWS_SSO_START_URL+x} ] ; then
      # https://d-9067094949.awsapps.com/start
      echo "You must set the AWS_SSO_START_URL environment variable."
      exit 1
    fi

    if [ -z ${AWS_ROLE_NAME+x} ] ; then
      # PowerUserAccess
      echo "You must set the AWS_ROLE_NAME environment variable."
      exit 1
    fi

    if [ -z ${AWS_ACCOUNT_ID+x} ] ; then
      # 709143748493
      echo "You must set the AWS_ACCOUNT_ID environment variable."
      exit 1
    fi

    AWS_CONFIG_DIR="/root/.aws"
    AWS_CONFIG="${AWS_CONFIG_DIR}/config"
    mkdir -p "$AWS_CONFIG_DIR"
    cat > $AWS_CONFIG << EOF
[default]
sso_region = ${AWS_REGION}
sso_start_url = ${AWS_SSO_START_URL}
sso_role_name = ${AWS_ROLE_NAME}
sso_account_id = ${AWS_ACCOUNT_ID}
region = ${AWS_REGION}

[profile ${AWS_ROLE_NAME}-${AWS_ACCOUNT_ID}]
sso_session = my-sso
sso_account_id = ${AWS_ACCOUNT_ID}
sso_role_name = ${AWS_ROLE_NAME}
region = ${AWS_REGION}
output = table

[sso-session my-sso]
sso_start_url = ${AWS_SSO_START_URL}
sso_region = ${AWS_REGION}
so_registration_scopes = sso:account:access
EOF
    aws sso login
    ;;
esac

if [ ! -d "$3" ] ; then
  echo "The specified Terraform root module directory '$3' does not exist."
  exit 1
fi

cd "$3"

commands=("terraform init" "terraform fmt -check" "terraform validate" "terraform $1 -auto-approve")
for i in "${commands[@]}" ; do
  $i

  if [ $? != 0 ] ; then
    echo "Error running: $i"
    exit $?
  fi
done
