#!/bin/bash
# Script description here

err() { cat <<< "$@" 1>&2; }

# Load parameters
NUMLINES=5
PROCESS=""
STATE=""
FIELD="^organization"
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -h|--help)
    echo "Usage: sudo $0 -p process_name_or_pid -n num_lines_to_output -s connection_state"
    exit
    ;;
    -p|--process)
    PROCESS="$2"
    shift
    shift
    ;;
    -n|--num-lines)
    NUMLINES="$2"
    shift
    shift
    ;;
    -s|--state)
    STATE="$2"
    shift
    shift
    ;;
    -f|--field)
    FIELD="$2"
    shift
    shift
    ;;
  esac
done


# Check parameters environment

if [ -z "$(which netstat)" ]; then
  errr "Please, install net-tools package."
  exit 1
fi

if [ -z "$(which whois)" ]; then
  err "Please, iinstall whois package."
  exit 1
fi

if [ "$EUID" -ne 0 ]; then
  err "Please, run as root."
  exit 1
fi


# Check parameters

if [ ! -z "$PROCESS" ]; then
  re='^[0-9]+$'
  if [[ "$PROCESS" =~ $re ]]; then
     PROCESS="[^0-9]${PROCESS}/"
  else
    PROCESS="/$PROCESS"
  fi
fi

re='^\^'
if [[ ! "$FIELD" =~ $re ]]; then
  FIELD="^$FIELD"
fi

if [ ! -z "$STATE" ]; then
  STATE=$(echo "$STATE" | tr a-z A-Z)
fi

re='^[0-9]+$'
if [[  ! "$NUMLINES" =~ $re ]]; then
  err "-n shoud be natural number"
  exit 1
fi


# fetch data

REMOTES="$(netstat -tunapl | awk 'NR>2 && $6~/^[^0-9]/ && $5~/^[1-9]/ {print $5, $6, $7}' | column -t)" 
REMOTES=$(echo "$REMOTES" | grep "$PROCESS")
REMOTES=$(echo "$REMOTES" | grep "$STATE")

if [ -z  "$REMOTES" ];then exit 0; fi

echo "CONNECTIONS:"
echo "$REMOTES"

echo $'\nWHOIS:'

IPS=$(echo "$REMOTES" | cut -d: -f1 | sort | uniq -c | sort | tail -n "$NUMLINES" | grep -oP '(\d+\.){3}\d+')

for ip in $IPS
do
  echo $ip $'\t' $(whois $ip | grep  -i "$FIELD")
done






