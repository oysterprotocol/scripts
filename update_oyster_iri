#!/usr/bin/env bash

set -euo pipefail

readonly SYSTEMD_CONFIG="/lib/systemd/system/iota.service"
readonly SCRIPT_NAME=$(basename $0)

function get_latest_github_release {
  curl -s https://api.github.com/repos/oysterprotocol/iri/releases/latest | awk '/tag_name/{print $2}' | tr -d '"v,'
}

log() {
  echo "$@"
  logger -p user.notice -t $SCRIPT_NAME "$@"
}

function get_installed_version {
  grep -v "^#" $SYSTEMD_CONFIG | grep -v "^$" | grep -o -P '(?<=iri-).*(?=.jar)'
}

function update_iri {
  log "New IRI release $latest detected! Updating installed version $installed to the latest release $latest"
  systemctl stop iota &&
  sh -c "sudo -u iota wget -qO /home/iota/node/iri-$latest.jar https://github.com/oysterprotocol/iri/releases/download/v$latest/iri-$latest.jar" &&
  sed -i -e "s/$installed/$latest/" $SYSTEMD_CONFIG &&
  systemctl daemon-reload &&
  systemctl start iota
}

function v_is_digit {
  tr -cd 0-9 <<<"$@"
}

function main {
  local latest="$(get_latest_github_release)"
  local installed="$(get_installed_version)"

  if [ "$latest" != "$installed" ] && [ $(v_is_digit ${latest}) ] && [ $(v_is_digit ${installed}) ]; then
    update_iri
  fi
}

main
