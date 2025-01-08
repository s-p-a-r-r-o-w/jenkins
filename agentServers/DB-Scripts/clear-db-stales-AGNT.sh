#!/bin/bash

# Load configuration from the file
source /home/omsinst1/sqllib/db2profile
source ~/scripts/clear-heartbeat/.config.cfg

# Function to perform the operations
clear_db_individual() {
    serverName="$1"
    # Establish the database connection outside the loop
    db2 connect to $DB_NAME user $DB_USER using $DB_PASSWORD

    # Get the initial count
    initial_count=$(db2 -x "SELECT COUNT(*) FROM OMSINST1.YFS_HEARTBEAT WHERE SERVER_TYPE='INTEGRATION' AND SERVER_NAME='$serverName'")
    initial_count=$(echo "$initial_count" | sed -e 's/^[[:space:]]*//')
    echo """
===================================================================
*******************************************************************
Initial count of entries for $serverName Server: $initial_count
*******************************************************************
===================================================================
"""
    # '01' entries are present, delete them
    db2 "DELETE FROM OMSINST1.YFS_HEARTBEAT WHERE SERVER_TYPE='INTEGRATION' AND SERVER_NAME='$serverName'"

    # Get the count after deletion
    count_after_deletion=$(db2 -x "SELECT COUNT(*) FROM OMSINST1.YFS_HEARTBEAT WHERE SERVER_TYPE='INTEGRATION' AND SERVER_NAME='$serverName'")
    count_after_deletion=$(echo "$count_after_deletion" | sed -e 's/^[[:space:]]*//')
    echo """
===================================================================
*******************************************************************
Deleted $initial_count entries for $serverName Servers
*******************************************************************
Count of $serverName Servers after deletion : $count_after_deletion
*******************************************************************
===================================================================
"""

    # Disconnect from the database outside the loop
    db2 connect reset
}

clear_db_host() {
    hostName="$1"
    # Establish the database connection outside the loop
    db2 connect to $DB_NAME user $DB_USER using $DB_PASSWORD

    # Get the initial count
    initial_count=$(db2 -x "SELECT COUNT(*) FROM OMSINST1.YFS_HEARTBEAT WHERE SERVER_TYPE='INTEGRATION' AND HOST_NAME='$hostName'")
    initial_count=$(echo "$initial_count" | sed -e 's/^[[:space:]]*//')
    echo """
===================================================================
*******************************************************************
Initial count of entries for Integrations[$hostName]: $initial_count
*******************************************************************
===================================================================
"""
    # '01' entries are present, delete them
    db2 "DELETE FROM OMSINST1.YFS_HEARTBEAT WHERE SERVER_TYPE='INTEGRATION' AND HOST_NAME='$hostName'"

    # Get the count after deletion
    count_after_deletion=$(db2 -x "SELECT COUNT(*) FROM OMSINST1.YFS_HEARTBEAT WHERE SERVER_TYPE='INTEGRATION' AND HOST_NAME='$hostName'")
    count_after_deletion=$(echo "$count_after_deletion" | sed -e 's/^[[:space:]]*//')
    echo """
===================================================================
*******************************************************************
Deleted $initial_count entries for Integration Servers[$hostName]
*******************************************************************
Count of Integration Servers[$hostName] after deletion: $count_after_deletion
*******************************************************************
===================================================================
"""

    # Disconnect from the database outside the loop
    db2 connect reset
}

clear_db_all() {
    # Establish the database connection outside the loop
    db2 connect to $DB_NAME user $DB_USER using $DB_PASSWORD

    # Get the initial count
    initial_count=$(db2 -x "SELECT COUNT(*) FROM OMSINST1.YFS_HEARTBEAT WHERE SERVER_TYPE='INTEGRATION'")
    initial_count=$(echo "$initial_count" | sed -e 's/^[[:space:]]*//')
    echo """
===================================================================
*******************************************************************
Initial count of entries for Integration Servers: $initial_count
*******************************************************************
===================================================================
"""
    # '01' entries are present, delete them
    db2 "DELETE FROM OMSINST1.YFS_HEARTBEAT WHERE SERVER_TYPE='INTEGRATION'"

    # Get the count after deletion
    count_after_deletion=$(db2 -x "SELECT COUNT(*) FROM OMSINST1.YFS_HEARTBEAT WHERE SERVER_TYPE='INTEGRATION'")
    count_after_deletion=$(echo "$count_after_deletion" | sed -e 's/^[[:space:]]*//')
    echo """
===================================================================
*******************************************************************
Deleted $initial_count entries for Integration Servers
*******************************************************************
Count of Integration Servers after deletion: $count_after_deletion
*******************************************************************
===================================================================
"""

    # Disconnect from the database outside the loop
    db2 connect reset
}

# Main script logic to parse command-line arguments
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <ALL | HOST hostname | SERVER servername>"
    exit 1
fi

case "$1" in
    ALL)
        clear_db_all
        ;;
    HOST)
        if [[ $# -eq 2 ]]; then
            clear_db_host "$2"
        else
            echo "Usage: $0 HOST hostname"
            exit 1
        fi
        ;;
    SERVER)
        if [[ $# -eq 2 ]]; then
            clear_db_individual "$2"
        else
            echo "Usage: $0 SERVER servername"
            exit 1
        fi
        ;;
    *)
        echo "Usage: $0 <ALL | HOST hostname | SERVER servername>"
        exit 1
        ;;
esac

exit 0
