#!/usr/bin/env bash
# killport.sh - Kill processes listening on specified TCP ports (uses sudo if needed)
# Usage: killport.sh <port1> [port2] … or killport.sh <port1,port2,…>
# Author: zudsniper (Jason)

# --- Color codes ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Function: kill processes on a given port ---
kill_port_processes() {
  local port=$1

  # Validate port number
  if ! [[ "$port" =~ ^[0-9]+$ ]]; then
    echo -e "${YELLOW}⚠️  Skipping invalid port:${NC} $port${NC}"
    return
  fi

  # Find listening PIDs
  local pids
  pids=$(lsof -iTCP:"$port" -sTCP:LISTEN -P -n 2>/dev/null \
         | awk 'NR>1 {print $2}' \
         | grep -E '^[0-9]+$' \
         | sort -u)

  if [ -z "$pids" ]; then
    echo -e "${YELLOW}ℹ️  No process is listening on port ${BLUE}$port${NC}"
    return
  fi

  echo -e "${BLUE}🔪 Killing processes on port ${port}:${NC}"
  for pid in $pids; do
    # Skip if already gone
    if ! kill -0 "$pid" 2>/dev/null; then
      echo -e "  ${YELLOW}⚠️  PID ${pid} no longer exists, skipped${NC}"
      continue
    fi

    # Get command name and owner
    local cmd owner me kill_cmd note
    cmd=$(ps -p "$pid" -o comm= 2>/dev/null || echo "unknown")
    owner=$(ps -p "$pid" -o user= 2>/dev/null | awk '{print $1}')
    me=$(id -un)

    # Decide whether to prepend sudo
    if [ "$EUID" -ne 0 ] && [ "$owner" != "$me" ]; then
      kill_cmd="sudo kill -9 $pid"
      note="(using sudo)"
    else
      kill_cmd="kill -9 $pid"
      note=""
    fi

    # Report and execute
    echo -e "  • ${YELLOW}Killing PID ${pid}${NC} (${cmd}) ${note}"
    if $kill_cmd >/dev/null 2>&1; then
      echo -e "    ${GREEN}✅ PID ${pid} killed successfully${NC}"
    else
      echo -e "    ${RED}❌ Failed to kill PID ${pid} with '${kill_cmd}'${NC}"
    fi
  done
}

# --- Main entrypoint ---
if [ $# -eq 0 ]; then
  echo -e "${YELLOW}Usage:${NC} $(basename "$0") <port1> [port2] … or $(basename "$0") <port1,port2,…>"
  exit 1
fi

for arg in "$@"; do
  IFS=',' read -ra ports <<< "$arg"
  for port in "${ports[@]}"; do
    # Trim whitespace
    port="${port#"${port%%[![:space:]]*}"}"
    port="${port%"${port##*[![:space:]]}"}"
    kill_port_processes "$port"
  done
done
