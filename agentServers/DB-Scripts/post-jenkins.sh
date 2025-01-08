#!/bin/bash

# Find the process ID(s) of processes with 'clear-db-stales-APP.sh' in the command
pids=$(pgrep -f "clear-db-stales-APP.sh")

if [ -z "$pids" ]; then
  echo "No process found with 'clear-db-stales-APP.sh'."
else
  echo "Killing the following process(es): $pids"
  # Kill the processes
  kill -9 $pids
  echo "Process(es) killed."
fi
