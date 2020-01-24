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

case "$1" in
encrypt)
    cd ${BASEDIR}
    echo "Encrypt ${TARGET_FILES}..."

    ansible-vault encrypt --vault-password-file ${VAUL_PASSWORD_FILE} ${TARGET_FILES}
;;
decrypt)
    cd ${BASEDIR}
    echo "Decrypt ${TARGET_FILES}..."

    ansible-vault decrypt --vault-password-file ${VAUL_PASSWORD_FILE} ${TARGET_FILES}
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
    cd ${BASEDIR}
    echo "Check encryption ${TARGET_FILES}..."

    #FILES_PATTERN='.*vault.*\.*$|digital_ocean\.ini|do_env\.sh'
    REQUIRED='ANSIBLE_VAULT'
    EXIT_STATUS=0
    wipe="\033[1m\033[0m"
    yellow='\033[1;33m'
    # carriage return hack. Leave it on 2 lines.
    cr='
'
    for f in $(git diff --name-only | grep -E $TARGET_FILES_PATTERN)
    do
      # test for the presence of the required bit.
      MATCH=`head -n1 $f | grep --no-messages $REQUIRED`
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
;;
*)
    echo "Usage: $0 {encrypt|decrypt[check|encrypt_ssh|decrypt_ssh}"
    exit 0
esac