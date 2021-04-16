#!/bin/bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)"

usage() {
	cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] project_name

Prepare the template repo for a new project, updating all relevant references in
the template to \${project_name}

Available options:

-h, --help      Print this help and exit
EOF
}

msg() {
	echo >&2 -e "${1-}"
}

die() {
	local msg=$1
	local code=${2-1} # default exit status 1
	msg "$msg"
	exit "$code"
}

parse_params() {
	# default values of variables set from params
	flag=0
	param=''

	while :; do
		case "${1-}" in
			-h | --help) usage && exit;;
			-?*) die "Unknown option: $1" ;;
			*) break ;;
			esac
		shift
	done

	args=("$@")

	[[ ${#args[@]} -eq 0 ]] && usage && die "Missing script argument"

	return 0
}

validate_name() {
	if [[ ! ${1} =~ ^([[:alnum:]_]+)$ ]]; then
		die "Project name contains invalid characters, must contain only unicode alphanumerics or an underscore"
	fi
	PROJECT_NAME=${1}
}

parse_params "$@"
validate_name "${args[*]-}"

if [ -d "${REPO_ROOT}/project" ]; then
	msg "Renaming template project directory to ${PROJECT_NAME}"
	mv ${REPO_ROOT}/project ${REPO_ROOT}/${PROJECT_NAME}
fi

msg "Updating all references to template project to ${PROJECT_NAME}"
find ${REPO_ROOT} -type f -not -path "${REPO_ROOT}/.git/*" -not -path "${REPO_ROOT}/eject.sh" -exec sed -i "" -e "s/\${project}/${PROJECT_NAME}/g" {} \;
