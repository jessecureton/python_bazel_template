#!/bin/bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)"

usage() {
    cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-hr] project_name

Prepare the template repo for a new project, updating all relevant references in
the template to \${project_name}

Available options:

-h, --help      Print this help and exit
-r, --reverse   Untemplate the project back
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
    REVERSE=0

    while :; do
        case "${1-}" in
            -h | --help) usage && exit;;
            -r | --reverse) REVERSE=1;;
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

if [ $REVERSE -eq "1" ]; then
    msg "Reverse flag is set, untemplating project"
    SOURCE_ARG=${PROJECT_NAME}
    DEST_ARG="\${project}"
    SOURCE_FOLDER=${PROJECT_NAME}
    DEST_FOLDER="project"
else
    SOURCE_ARG="\${project}"
    DEST_ARG=${PROJECT_NAME}
    SOURCE_FOLDER="project"
    DEST_FOLDER=${PROJECT_NAME}
fi

if [ -d "${REPO_ROOT}/${SOURCE_FOLDER}" ]; then
    msg "Renaming directory ${SOURCE_FOLDER} to ${DEST_FOLDER}"
    mv ${REPO_ROOT}/${SOURCE_FOLDER} ${REPO_ROOT}/${DEST_FOLDER}
else
    msg "${REPO_ROOT}/${SOURCE_FOLDER} doesn't exist - likely already renamed"
fi

msg "Updating all references to ${SOURCE_ARG} to ${DEST_ARG}"
find ${REPO_ROOT} -type f -not -path "${REPO_ROOT}/.git/*" -not -path "${REPO_ROOT}/eject.sh" -exec sed -i "" -e "s/${SOURCE_ARG}/${DEST_ARG}/g" {} \;
