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

  echo "Usage: ${0} [<DOCKER_IMAGE_NAME> [<DOCKER_IMAGE_TAG>]]"
  exit 1
}

env_vars_file="./set_my_env_vars.sh"
if [ -f "${env_vars_file}" ] ; then
  debug_msg "${env_vars_file}"
  . "${env_vars_file}"
fi

if [ $# -lt 0 ] || [ $# -gt 2 ] ; then
  usage_exit "Wrong number of arguments: $#"
fi

if [ -z ${DOCKER_IMAGE_NAME+x} ] ; then
  DOCKER_IMAGE_NAME=${1:-demo-build}
fi
debug_msg "DOCKER_IMAGE_NAME"

if [ -z ${DOCKER_IMAGE_TAG+x} ] ; then
  DOCKER_IMAGE_TAG=${2:-latest}
fi
debug_msg "DOCKER_IMAGE_TAG"

docker build -t ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} .