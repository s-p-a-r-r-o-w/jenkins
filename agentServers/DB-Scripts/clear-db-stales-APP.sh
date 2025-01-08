#!/bin/bash

# Load configuration from the file
source /home/omsinst1/sqllib/db2profile
source ~/scripts/clear-heartbeat/.config.cfg # Access 600 

# Funtion to Get the Initial Server Entries Before Restart process # Perfect Alignment for Jenkins Condole Output
check_initial_server_entry(){
    # Connect to the database
    db2 connect to $DB_NAME user $DB_USER using $DB_PASSWORD >/dev/null 2>&1
    echo "-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
    echo "|                                            $(date +'%Y-%m-%d | %H:%M:%S') : Database Heartbeat Table Output                                               |" 
    # Print the table header
    echo "-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
    echo "| SERVER_TYPE |        SERVER_ID       | STATUS |                  CREATETS                 |                  MODIFYTS                 |"
    echo "-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"

    # Fetch server entries and format the output line-by-line
    db2 -x "SELECT SERVER_TYPE, SERVER_ID, STATUS, CREATETS, MODIFYTS FROM OMSINST1.YFS_HEARTBEAT WHERE SERVER_TYPE='APPSERVER'" | \
    awk '{ printf "| %-10s | %-10s | %-5s | %-25s | %-25s |\n", "  " $1 "  ", "    " $2 "   ", "     " $3 "     ", $4 " ", $5 " " }'

    # Print the table footer
    echo "-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"

    # Disconnect from the database
    db2 connect reset >/dev/null 2>&1
}

# Function to check count of '00' entries
check_count_00() {
    echo "$(date +'%Y-%m-%d | %H:%M:%S') : Waiting for the All [Count : $ACTIVE_APP_SERVERS] Servers to come online"
    while true; do
        db2 connect to $DB_NAME user $DB_USER using $DB_PASSWORD >/dev/null 2>&1
        COUNT_00=$(db2 -x "SELECT COUNT(*) FROM OMSINST1.YFS_HEARTBEAT WHERE SERVER_TYPE='APPSERVER' AND STATUS='00'")
        db2 connect reset >/dev/null 2>&1
        COUNT_00=$(echo "$COUNT_00" | sed -e 's/^[[:space:]]*//')
        COUNT_00=$((COUNT_00))
        # echo "$(date +'%Y-%m-%d | %H:%M:%S') : Currently $COUNT_00 Servers - up and running."
        if [ $COUNT_00 -eq $ACTIVE_APP_SERVERS ]; then
            check_initial_server_entry
            echo "$(date +'%Y-%m-%d | %H:%M:%S') : Completed the DB Handling for the Servers restart process. Active Servers Count : $COUNT_00"
            break
        fi
        sleep 10
    done
}

#Get the active AppServer List

check_initial_server_entry
db2 connect to $DB_NAME user $DB_USER using $DB_PASSWORD >/dev/null 2>&1
ACTIVE_APP_SERVERS=$(db2 -x "SELECT COUNT(*) FROM OMSINST1.YFS_HEARTBEAT WHERE SERVER_TYPE='APPSERVER' AND STATUS='00'")
db2 "DELETE FROM OMSINST1.YFS_HEARTBEAT WHERE SERVER_TYPE='APPSERVER' AND STATUS IN ('01', '02')" >/dev/null 2>&1
echo "$(date +'%Y-%m-%d | %H:%M:%S') : Deleted the Server Entries which have the status 01 and 02"
db2 connect reset >/dev/null 2>&1
ACTIVE_APP_SERVERS=$(echo "$ACTIVE_APP_SERVERS" | sed -e 's/^[[:space:]]*//')
ACTIVE_APP_SERVERS=$((ACTIVE_APP_SERVERS))
echo "$(date +'%Y-%m-%d | %H:%M:%S') : Total count of Active Servers before restart process : $ACTIVE_APP_SERVERS"
# Counter for '01' entries cleared
cleared_count=0

while true; do
    # Check if the desired count of '01' entries has been cleared
    if [ $cleared_count -ge $((ACTIVE_APP_SERVERS)) ]; then
        # Call function to check count of '00' entries
        check_count_00
        break
    fi
    # Establish the database connection
    db2 connect to $DB_NAME user $DB_USER using $DB_PASSWORD >/dev/null 2>&1
    # Check if '01' entries are present
    # Get the initial count
    initial_count=$(db2 -x "SELECT COUNT(*) FROM OMSINST1.YFS_HEARTBEAT WHERE SERVER_TYPE='APPSERVER' AND STATUS='01'")
    server_name=$(db2 -x "SELECT SERVER_NAME FROM OMSINST1.YFS_HEARTBEAT WHERE SERVER_TYPE='APPSERVER' AND STATUS='01'")
    initial_count=$(echo "$initial_count" | sed -e 's/^[[:space:]]*//')
    server_name=$(echo "$server_name" | sed -e 's/^[[:space:]]*//')
    initial_count=$((initial_count))
    if [ $initial_count -gt 0 ]; then
        # Sleep for 10 seconds before deleting '01' entries are present
        sleep 5
        db2 "DELETE FROM OMSINST1.YFS_HEARTBEAT WHERE SERVER_TYPE='APPSERVER' AND STATUS='01' AND SERVER_NAME='$server_name'" >/dev/null 2>&1
        count_after_deletion=$(db2 -x "SELECT COUNT(*) FROM OMSINST1.YFS_HEARTBEAT WHERE SERVER_TYPE='APPSERVER' AND STATUS='01' AND SERVER_NAME='$server_name'")
        count_after_deletion=$(echo "$count_after_deletion" | sed -e 's/^[[:space:]]*//')
        count_after_deletion=$((count_after_deletion))
        if [ $count_after_deletion -eq 0 ]; then
            ((cleared_count++))
            echo "$(date +'%Y-%m-%d | %H:%M:%S') : Deleted a stale entry [STATUS='01'] for the server $server_name"
            check_initial_server_entry #Gives HeartBeat Table Output after every 01 Deletion.
        fi
    fi
    db2 connect reset >/dev/null 2>&1
    # Sleep for 10 seconds before checking the next server
    sleep 10
done