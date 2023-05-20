#!/bin/bash

function debug_msg() {
  if [ ! -z ${DEBUG+x} ] ; then
    echo "DEBUG - ${1}: ${!1}"
  fi
}

function usage_exit() {
  if [ ! -z ${1+x} ] ; then
    echo "${1}"
  fi

  echo "Usage: ${0} [<DOCKER_IMAGE_NAME> [<DOCKER_IMAGE_TAG>]] <interactive|awsapply|awsdestroy|azapply|azdestroy>"
  exit 1
}

if [ $# -lt 1 ] || [ $# -gt 4 ] ; then
  usage_exit "Wrong number of arguments: $#"
fi

DOCKER_ENV_FILE="./DOCKER_ENV_FILE.ini"
if [ -f "${DOCKER_ENV_FILE}" ] ; then
  rm -f "${DOCKER_ENV_FILE}"
fi
debug_msg "DOCKER_ENV_FILE"

function append_docker_env_file() {
  debug_msg "${1}"
  echo "${1}=${!1}" >> "${DOCKER_ENV_FILE}"
}

env_vars_file="./set_my_env_vars.sh"
if [ -f "${env_vars_file}" ] ; then
  debug_msg "${env_vars_file}"
  . "${env_vars_file}"
fi

while [ $# -gt 1 ] ; do
  case $# in
    3)
      DOCKER_IMAGE_NAME=${1}
      ;;
    2)
      if [ ! -z ${DOCKER_IMAGE_NAME+x} ] ; then
        DOCKER_IMAGE_TAG=${1}
        break
      fi
      DOCKER_IMAGE_NAME=${1}
      ;;
  esac
  shift
done

export DOCKER_IMAGE_NAME=${DOCKER_IMAGE_NAME:-demo-build}
export DOCKER_IMAGE_TAG=${DOCKER_IMAGE_TAG:-latest}

debug_msg "DOCKER_IMAGE_NAME"
debug_msg "DOCKER_IMAGE_TAG"

case ${@: -1} in
  "interactive")
    it="-it"
    ;;
  "aws"*)
    if [ -z ${AWS_REGION+x} ] ; then
      default_aws_region=us-east-1
      read -p "Enter AWS region [${default_aws_region}]: " AWS_REGION
      AWS_REGION=${AWS_REGION:-${default_aws_region}}
    fi
    append_docker_env_file "AWS_REGION"

    if [ -z ${AWS_SSO_START_URL+x} ] ; then
      read -p "Enter the AWS SSO Start URL [none]: " AWS_SSO_START_URL # AWS SSO Start URL if environment variable not set
      AWS_SSO_START_URL=${AWS_SSO_START_URL}
    fi
    append_docker_env_file "AWS_SSO_START_URL"

    if [ -z ${AWS_ROLE_NAME+x} ] ; then
      default_aws_role_name=PowerUserAccess
      read -p "Enter AWS role name [${default_aws_role_name}]: " AWS_ROLE_NAME
      AWS_ROLE_NAME=${AWS_ROLE_NAME:-${default_aws_role_name}} # Default AWS role name if environment variable not set
    fi
    append_docker_env_file "AWS_ROLE_NAME"

    if [ -z ${AWS_ACCOUNT_ID+x} ] ; then
      read -p "Enter the AWS Account ID [none]: " AWS_ACCOUNT_ID # AWS Account ID if environment variable not set
      AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID}
    fi
    append_docker_env_file "AWS_ACCOUNT_ID"

    call=apply
    if [ $1 == "awsdestroy" ] ; then
      call=destroy
    fi

    cloud=aws
    tutorial=terraform_aws_tutorial
    ;;

  "az"*)
    if [ -z ${AZ_SUBSCRIPTION+x} ] ; then
      default_az_subscription="Azure subscription"
      read -p "Enter the Azure subscription name or ID [${default_az_subscription}]: " AZ_SUBSCRIPTION # Azure subscription name or ID if environment variable not set
      AZ_SUBSCRIPTION=${AZ_SUBSCRIPTION:-"${default_az_subscription}"}
    fi
    append_docker_env_file "AZ_SUBSCRIPTION"

    call=apply
    if [ $1 == "azdestroy" ] ; then
      call=destroy
    fi

    cloud=az
    tutorial=terraform_azurerm_tutorial
    ;;

  *)
    usage_exit
    ;;
esac

if [ -f "${DOCKER_ENV_FILE}" ] ; then
  env_file="--env-file ${DOCKER_ENV_FILE}"
  debug_msg "env_file"
fi

if [ -z $it ] ; then
  run_cmd="/wkd/tf-run.sh ${call} ${cloud} ${tutorial}"
  debug_msg "call"
  debug_msg "cloud"
  debug_msg "tutorial"
  debug_msg "run_cmd"
fi

docker run $env_file --cap-add=CAP_IPC_LOCK $it --rm --volume "${PWD}/wkd:/wkd"  "${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}" /bin/bash $run_cmd