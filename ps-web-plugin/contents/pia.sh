#!/usr/bin/env bash
#===============================================================================
# vim: softtabstop=2 shiftwidth=2 expandtab fenc=utf-8 spelllang=en
#===============================================================================
#
#          FILE: pia.sh
#
#   DESCRIPTION: executes commands to control the pia
#
#===============================================================================

# Export the PMID in order to resolve an issue that Tuxedo has with long hostnames
PMID=$(hostname)
export PMID

domain=$1
action=$2

required_environment_variables=( PS_HOME PS_CFG_HOME PS_APP_HOME PS_PIA_HOME PS_CUST_HOME TUXDIR )
optional_environment_variables=( DM_HOME PS_DM_DATA_IN PS_DM_DATA_OUT PS_DM_SCRIPT PS_DM_LOG JAVA_HOME COBDIR PS_FILEDIR PS_SERVDIR ORACLE_HOME ORACLE_BASE TNS_ADMIN AGENT_HOME )

function echoinfo() {
  local GC="\033[1;32m"
  local EC="\033[0m"
  printf "${GC} ☆  INFO${EC}: %s\n" "$@";
}

function echoerror() {
  local RC="\033[1;31m"
  local EC="\033[0m"
  printf "${RC} ✖  ERROR${EC}: %s\n" "$@" 1>&2;
}

function set_required_environment_variables () {
  echoinfo "Setting required environment variables"
  for var in ${required_environment_variables[@]}; do
    rd_node_var=$( printenv RD_NODE_${var} )
    export $var=$rd_node_var
  done
}

function set_optional_environment_variables () {
  echoinfo "Setting optional environment variables"
  for var in ${optional_environment_variables[@]}; do
    if [[ `printenv RD_NODE_${var}` ]]; then
      rd_node_var=RD_NODE_${var}
      export $var=$( printenv $rd_node_var )
    fi
  done
}

function check_variables () {
  echoinfo "Checking variables"
  for var in ${required_environment_variables[@]}; do
    if [[ `printenv ${var}` = '' ]]; then
      echo "${var} is not set.  Please make sure this is set before continuing."
      exit 1
    fi
  done
}

function update_path () {
  echoinfo "Updating PATH"
  export PATH=$PATH:.
  export PATH=$TUXDIR/bin:$PATH
  [[ $COBDIR ]] && export PATH=$COBDIR/bin:$PATH
  [[ $ORACLE_HOME ]] && export PATH=$ORACLE_HOME/bin:$PATH
  [[ $AGENT_HOME ]] && export PATH=$AGENT_HOME/bin:$PATH
}

function update_ld_library_path () {
  echoinfo "Updating LD_LIBRARY_PATH"
  export LD_LIBRARY_PATH=$TUXDIR/lib:$LD_LIBRARY_PATH
  [[ $JAVA_HOME ]] && export LD_LIBRARY_PATH=$JAVA_HOME/lib:$LD_LIBRARY_PATH
  [[ $COBDIR ]] && export LD_LIBRARY_PATH=$COBDIR/lib:$LD_LIBRARY_PATH
  [[ $ORACLE_HOME ]] && export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$LD_LIBRARY_PATH
}

function source_psconfig () {
  echoinfo "Sourcing psconfig.sh"
  cd "$PS_HOME" && source "$PS_HOME"/psconfig.sh && cd - > /dev/null 2>&1 # Source psconfig.sh
}

# The new "psadmin -w" command syntax causes errors, which is why we're still
# using the *PIA.sh scripts
# https://support.oracle.com/epmos/faces/DocumentDisplay?id=1908227.1
function start_webserver () {
  echoinfo "Starting webserver"
  #"$PS_HOME"/bin/psadmin -w start -d "$domain"
  "$PS_PIA_HOME/webserv/$domain/bin/startPIA.sh"
}

function stop_webserver () {
  echoinfo "Stopping webserver"
  #"$PS_HOME"/bin/psadmin -w shutdown -d "$domain"
  "$PS_PIA_HOME/webserv/$domain/bin/stopPIA.sh"
}

function show_webserver_status () {
  echoinfo "Webserver status"
  "$PS_HOME"/bin/psadmin -w status -d "$domain"
}

function purge_webserver_cache () {
  echoinfo "Purging webserver cache"
  rm -rfv "$PS_PIA_HOME/webserv/$domain/applications/peoplesoft/PORTAL*/*/cache"
}

#######################
# Setup the environment
#######################

set_required_environment_variables
check_variables
source_psconfig
set_optional_environment_variables
update_path
update_ld_library_path

case $action in

  status)
    show_webserver_status
  ;;

  start)
    start_webserver
  ;;

  stop)
    stop_webserver
  ;;

  purge)
    purge_webserver_cache
  ;;

  restart)
    stop_webserver
    start_webserver
  ;;

  bounce)
    stop_webserver
    purge_webserver_cache
    start_webserver
  ;;

esac
