#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/.." && pwd)"

host_pattern="${1}"
command_args="${2}"

export ANSIBLE_ROLES_PATH="${script_dir}/roles${ANSIBLE_ROLES_PATH:+:${ANSIBLE_ROLES_PATH}}"

exec ansible \
  "${host_pattern}" \
  --inventory "${script_dir}/inventory.ini" \
  --module-name "command" \
  -a "${command_args}" \
  "${@:3}"