#!/bin/bash

# Check if the script is run with sufficient arguments
if [ $# -lt 1 ]; then
    echo "Usage: $0 <MC_CONFIG_XML_FOLDER> -SOURCE <source_db> -SOURCE_PASS <source_password> -TARGET <target_db> [-TARGET_PASS <target_password>]"
    exit 1
fi

# Function to check the success of a command
check_success() {
    if [ $? -ne 0 ]; then
        echo "Error: $1"
        exit 1
    fi
}

# Variables
MC_CONFIG_XML_FOLDER="$1"
shift

SOURCE_DB=""
SOURCE_PASSWORD=""
TARGET_DB=""
TARGET_PASSWORD=""

# Parse command-line arguments
while [ $# -gt 0 ]; do
  case "$1" in
    -SOURCE)
      SOURCE_DB="$2"
      shift 2
      ;;
    -SOURCE_PASS)
      SOURCE_PASSWORD="$2"
      shift 2
      ;;
    -TARGET)
      TARGET_DB="$2"
      shift 2
      ;;
    -TARGET_PASS)
      TARGET_PASSWORD="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Validate required arguments
if [ -z "$MC_CONFIG_XML_FOLDER" ] || [ -z "$SOURCE_DB" ] || [ -z "$TARGET_DB" ]; then
  echo "Usage: $0 <MC_CONFIG_XML_FOLDER> -SOURCE <source_db> -SOURCE_PASS <source_password> -TARGET <target_db> -TARGET_PASS <target_password>"
  exit 1
fi

# File paths
SOURCE_XML="/opt/IBM/OMS10/resources/ydkresources/ydkprefs_IMPORT.xml"
TARGET_XML="/opt/IBM/OMS10/resources/ydkresources/ydkprefs.xml"
STERLING_CDT_TEMP_SCRIPT="/opt/IBM/OMS10/bin/cdtshell_template.sh"
STERLING_CDT_SCRIPT="/opt/IBM/OMS10/bin/cdtshell.sh"

# Check if MC_CONFIG_XML_FOLDER exists
if [ ! -d "$MC_CONFIG_XML_FOLDER" ]; then
    echo "Error: $MC_CONFIG_XML_FOLDER does not exist. Stopped the CDT IMPORT Process."
    exit 1
fi

# Step 1: Copy XML configuration
echo "Copying XML configuration..."
cp -f "$SOURCE_XML" "$TARGET_XML"
check_success "Failed to copy XML configuration from $SOURCE_XML to $TARGET_XML."

# Step 2: Update XML folder path
echo "Updating XML folder path in ydkprefs.xml..."
sed -i "s|xml_folder=\"ChangeMe\"|folder=\"${MC_CONFIG_XML_FOLDER}\"|g" "$TARGET_XML" || {
    echo "Failed to update XML folder path in $TARGET_XML."
    exit 1
}

# Step 3: Update Source and Target Entries in $STERLING_CDT_SCRIPT
echo "Copying the cdtshell.sh from template..."
cp -f "$STERLING_CDT_TEMP_SCRIPT" "$STERLING_CDT_SCRIPT"
check_success "Failed to copy template script."

echo "Updating Source and Target entries in $STERLING_CDT_SCRIPT..."
sed -i "s|SOURCE_DB=\"changeme\"|SOURCE_DB=\"${SOURCE_DB}\"|g" "$STERLING_CDT_SCRIPT" || {
    echo "Failed to update Source DB in $STERLING_CDT_SCRIPT."
    exit 1
}
sed -i "s|SOURCE_PASSWORD=\"changeme\"|SOURCE_PASSWORD=\"${SOURCE_PASSWORD}\"|g" "$STERLING_CDT_SCRIPT" || {
    echo "Failed to update Source Password in $STERLING_CDT_SCRIPT."
    exit 1
}
sed -i "s|TARGET_DB=\"changeme\"|TARGET_DB=\"${TARGET_DB}\"|g" "$STERLING_CDT_SCRIPT" || {
    echo "Failed to update Target DB in $STERLING_CDT_SCRIPT."
    exit 1
}
sed -i "s|TARGET_PASSWORD=\"changeme\"|TARGET_PASSWORD=\"${TARGET_PASSWORD}\"|g" "$STERLING_CDT_SCRIPT" || {
    echo "Failed to update Target Password in $STERLING_CDT_SCRIPT."
    exit 1
}

# Step 4: Execute CDT Process
echo "Executing CDT script..."
sh "$STERLING_CDT_SCRIPT"
check_success "Failed to execute the script $STERLING_CDT_SCRIPT."

echo "CDT IMPORT Process completed successfully."
