#!/bin/bash

SCRIPT_LOCATION=$(dirname "$0")
BASEDIR=$(cd "$SCRIPT_LOCATION" && pwd)
VAUL_PASSWORD_FILE="${BASEDIR}/.local/vault-password"

# Target directory and files to encrypt
HOST_VARS_DIR="host_vars"
PLAYBOOK_DIR="playbook"
HOSTS_FILE="hosts.yml"
SSH_CFG_FILE="ssh.cfg"

TARGET_FILES="host_vars/*.yml playbook/*.yml hosts.yml ssh.cfg"
TARGET_FILES_PATTERN="host_vars/.*\.yml|playbook/.*\.yml|hosts\.yml|ssh\.cfg"

COMMAND=$1
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
GIT_MESSAGE=$2

usage() {
  echo "Usage: $0 <command> <options>"
    echo ""
    echo "Main commands:"
    echo " - encrypt:             Encrypt vault files"
    echo " - decrypt:             Decrypt vault files"
    echo " - commit <comments>:   Encrypt vault files, then commit changes"
    echo " - fetch:               Fetch remote changes, then decrypt vault files"
    echo ""
    echo " Other available commands:"
    echo "  - check:          Make sure vault file are encrypted, and exit with an error code if not"
    echo "  - encrypt_ssh:    Encrypt only SSL config files"
    echo "  - decrypt_ssh:    Decrypt only SSL config files"
}

encrypt() {
    cd "${BASEDIR}" || exit 1
    echo "Encrypt ${TARGET_FILES}..."
    # shellcheck disable=SC2086
    ansible-vault encrypt --vault-password-file "${VAUL_PASSWORD_FILE}" ${TARGET_FILES}
}
decrypt() {
    cd ${BASEDIR}
    echo "Decrypt ${TARGET_FILES}..."
    ansible-vault decrypt --vault-password-file "${VAUL_PASSWORD_FILE}" ${TARGET_FILES}
}

check_encrypted() {
  cd ${BASEDIR}

  #FILES_PATTERN='.*vault.*\.*$|digital_ocean\.ini|do_env\.sh'
  REQUIRED='ANSIBLE_VAULT'
  EXIT_STATUS=0
  wipe="\033[1m\033[0m"
  yellow='\033[1;33m'
  # carriage return hack. Leave it on 2 lines.
  cr='
'
  for f in $(git diff --name-only | grep -E "$TARGET_FILES_PATTERN")
  do
    # test for the presence of the required bit.
    MATCH=$(head -n1 $f | grep --no-messages $REQUIRED)
    if [ ! $MATCH ] ; then
      # Build the list of unencrypted files if any
      UNENCRYPTED_FILES="$f$cr$UNENCRYPTED_FILES"
      EXIT_STATUS=1
    fi
  done
  if [ ! $EXIT_STATUS = 0 ] ; then
    echo '# COMMIT REJECTED'
    echo '# Looks like unencrypted ansible-vault files are part of the commit:'
    echo '#'
    while read -r line; do
      if [ -n "$line" ]; then
        echo -e "#\t${yellow}unencrypted:   $line${wipe}"
      fi
    done <<< "$UNENCRYPTED_FILES"
    echo '#'
    echo "# Please encrypt them with 'ansible-vault encrypt <file>'"
    echo "#   (or force the commit with '--no-verify')."
    exit $EXIT_STATUS
  fi
  exit $EXIT_STATUS
}

commit() {
  cd "${BASEDIR}" || exit 1
  echo "Commit with message: '$GIT_MESSAGE'"
  # Encrypt
  ENCRYPT=$(encrypt)
  if [[ $? -ne 0 ]]; then
    echo "Encryption failed. Checking all files encrypted..."
    check_encrypted || exit 1
  fi
  # Add all files
  echo "Adding missing file to git..."
  git add -A || exit 1
  # Commit
  git commit --no-verify -m ''"$GIT_MESSAGE"'' || exit 1
  echo "-- Successfully committed to ${GIT_BRANCH}"
}

push() {
  cd ${BASEDIR}
  check_master
  echo "Pushing changes to master..."

}

### Control that the script is run on `master` branch
check_master() {
  cd ${BASEDIR}
  echo "GIT branch: $GIT_BRANCH"
  if [[ ! "$GIT_BRANCH" = "master" ]];
  then
    echo ">> This script must be run under a master branch"
    exit 1
  fi
}

case "$COMMAND" in
encrypt)
    encrypt
;;
decrypt)
  decrypt
;;
encrypt_ssh)
    cd ${BASEDIR}
    echo "Encrypt ${SSH_CFG_FILE}..."
    ansible-vault encrypt --vault-password-file ${VAUL_PASSWORD_FILE} ${SSH_CFG_FILE}
;;
decrypt_ssh)
    cd ${BASEDIR}
    echo "Decrypt ${SSH_CFG_FILE}..."
    ansible-vault decrypt --vault-password-file ${VAUL_PASSWORD_FILE} ${SSH_CFG_FILE}
;;
check)
  echo "Check encryption ${TARGET_FILES}..."
  check_encrypted
;;

commit)
  commit
;;

fetch)
  fetch
;;

push)
  push
;;

help)
  usage
;;

*)
    echo "ERROR: missing <command> argument"
    usage
    exit 1
esac

