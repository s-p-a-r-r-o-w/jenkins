#!/bin/bash
#######################################################################################
# Source the Server List file

STERLING_DIR="/opt/IBM/OMS10"
LOG_DIR="/var/IBM/OMS10/logs"
#######################################################################################
if [ ! -d "$LOG_DIR" ]; then
    mkdir -p "$LOG_DIR"
fi
# Function to start a server with a given server name, server type, and JVM heap size
start_server() {
  server_name="$1"
  server_type=""
  jvm_heapsize=""
  script_name=""

# Identify the server type based on the server name
  if [ -n "${agentserver[$server_name]}" ]; then
    server_type="agent"
    jvm_heapsize="${agentserver[$server_name]}"
    if [ -n "${serverscript[$server_name]}" ]; then
      script_name="${serverscript[$server_name]}"
    else
      script_name="agentserver_orgname.sh"
    fi
  elif [ -n "${integrationserver[$server_name]}" ]; then
    server_type="integration"
    jvm_heapsize="${integrationserver[$server_name]}"
    if [ -n "${serverscript[$server_name]}" ]; then
      script_name="${serverscript[$server_name]}"
    else
      script_name="startIntegrationServer_orgname.sh"
    fi
  else
    echo "Error: Server $server_name not found in any server list."
    return
  fi

  echo "Starting an $server_type server: $server_name using $script_name with JVM heap size: $jvm_heapsize"
  
  # Start the server using the appropriate sh script
  nohup "$STERLING_DIR/bin/$script_name" "$server_name" "$jvm_heapsize" > "$LOG_DIR/TD_$server_name.log" 2>&1 &
  # For testing the variable values
  # echo """
  # nohup "$STERLING_DIR/bin/$script_name" "$server_name" "$jvm_heapsize" > "$LOG_DIR/TD_$server_name.log" 2>&1 &
  # nohup $STERLING_DIR/bin/$script_name $server_name $jvm_heapsize > "$LOG_DIR/TD_$server_name.log" 2>&1 &
  # """
  sleep 20  # Adjust sleep duration as needed
}

# Function to start all servers of a given server type
start_all_servers() {
    case "$1" in
        "agentserver")
            for server_name in "${!agentserver[@]}"; do
                start_server "$server_name"
            done
            ;;
        "integrationserver")
            for server_name in "${!integrationserver[@]}"; do
                start_server "$server_name"
            done
            ;;
        *)
            echo "Please mention a Server List"
            ;;
    esac
}

# Function to start the HealthMonitor
start_health_monitor() {
  server_name=$1
  echo "Starting Health Monitor server: $server_name"
  nohup $STERLING_DIR/bin/startHealthMonitor.sh > "$LOG_DIR/TD_$server_name.log" 2>&1 &
  sleep 20  # Adjust sleep duration as needed
}

case "$1" in
  "ALL")
    echo "Starting servers for integrationserver"
    start_all_servers "integrationserver" &&
    echo "Starting servers for agentserver"
    start_all_servers "agentserver"
    ;;
  "Agents")
    start_all_servers "agentserver"
    ;;
  "Integrations")
    start_all_servers "integrationserver"
    ;;
  "HealthMonitor")
    start_health_monitor "HealthMonitor"
    ;;
  *)
    if [ -z "$1" ]; then
      echo "Please provide a valid 'server name' or 'ALL' or 'Agents' or 'Integrations' or 'HealthMonitor'"
    else
      start_server "$1"
    fi
    ;;
esac
