#!/bin/bash

# Function to check the success of a command
check_success() {
    if [ $? -ne 0 ]; then
        echo "Error: $1"
        exit 1
    fi
}

# Default values (optional, in case arguments are missing)
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

# Ensure that the required arguments are provided (allow empty TARGET_PASS)
if [ -z "$SOURCE_DB" ] || [ -z "$TARGET_DB" ]; then
  echo "Usage: $0 -SOURCE <source_db> -SOURCE_PASS <source_password> -TARGET <target_db> -TARGET_PASS <target_password>"
  exit 1
fi

# Variables
SOURCE_XML="/opt/IBM/OMS10/resources/ydkresources/ydkprefs_EXPORT.xml"
TARGET_XML="/opt/IBM/OMS10/resources/ydkresources/ydkprefs.xml"
STERLING_CDT_TEMP_SCRIPT="/opt/IBM/OMS10/bin/cdtshell_template.sh"
STERLING_CDT_SCRIPT="/opt/IBM/OMS10/bin/cdtshell.sh"
XML_CDT_FOLDER="/home/omsadmin/CDT/EXPORT/PROD_CDT_LATEST"
DATE_BACKUP="/home/omsadmin/CDT/EXPORT/PROD_CDT_$(date +%d%b%Y)"

# Step 1: Copy XML configuration
echo "Copying XML configuration..."
cp -f "$SOURCE_XML" "$TARGET_XML"
check_success "Failed to copy XML configuration from $SOURCE_XML to $TARGET_XML."

# Step 2: Update XML folder path
echo "Updating XML folder path in ydkprefs.xml..."
sed -i "s|xml_folder=\"ChangeMe\"|folder=\"${XML_CDT_FOLDER}\"|g" "${TARGET_XML}"
check_success "Failed to update XML folder path in $TARGET_XML."

# Step 3: Handle existing XML_CDT_FOLDER directory
if [ -d "$XML_CDT_FOLDER" ]; then
    echo "Deleting existing directory: $XML_CDT_FOLDER"
    rm -rf "$XML_CDT_FOLDER"
    check_success "Failed to delete existing directory: $XML_CDT_FOLDER."
fi

# Ensure the folder exists before trying to create it
mkdir -p "$XML_CDT_FOLDER"
check_success "Failed to create directory: $XML_CDT_FOLDER."

# Step 4: Change Source and Target Entries in $STERLING_CDT_SCRIPT
echo "Copying the cdtshell.sh from template..."
cp -f "${STERLING_CDT_TEMP_SCRIPT}" "${STERLING_CDT_SCRIPT}"
echo "Updating Source and Target Entries in $STERLING_CDT_SCRIPT "
sed -i "s|SOURCE_DB=\"changeme\"|SOURCE_DB=\"${SOURCE_DB}\"|g" "$STERLING_CDT_SCRIPT"
check_success "Failed to update Source DB in $STERLING_CDT_SCRIPT"
sed -i "s|SOURCE_PASSWORD=\"changeme\"|SOURCE_PASSWORD=\"${SOURCE_PASSWORD}\"|g" "$STERLING_CDT_SCRIPT"
check_success "Failed to update Source Password in $STERLING_CDT_SCRIPT"
sed -i "s|TARGET_DB=\"changeme\"|TARGET_DB=\"${TARGET_DB}\"|g" "$STERLING_CDT_SCRIPT"
check_success "Failed to update Target DB in $STERLING_CDT_SCRIPT"
sed -i "s|TARGET_PASSWORD=\"changeme\"|TARGET_PASSWORD=\"${TARGET_PASSWORD}\"|g" "$STERLING_CDT_SCRIPT"
check_success "Failed to update Target Password in $STERLING_CDT_SCRIPT"

sh $STERLING_CDT_SCRIPT
check_success "Failed to execute the script $STERLING_CDT_SCRIPT."

# Step 5: Handle existing DATE_BACKUP directory
if [ -d "$DATE_BACKUP" ]; then
    echo "Deleting existing directory: $DATE_BACKUP"
    rm -rf "$DATE_BACKUP"
    check_success "Failed to delete existing directory: $DATE_BACKUP."
fi

# Step 6: Create the DATE_BACKUP directory
echo "Creating directory: $DATE_BACKUP"
mkdir -p "$DATE_BACKUP"
check_success "Failed to create directory: $DATE_BACKUP."

# Step 7: Copy files from XML_CDT_FOLDER to DATE_BACKUP
if [ -d "$XML_CDT_FOLDER" ]; then
    echo "Copying files from $XML_CDT_FOLDER to $DATE_BACKUP"
    cp -r "$XML_CDT_FOLDER/"* "$DATE_BACKUP/"
    check_success "Failed to copy files from $XML_CDT_FOLDER to $DATE_BACKUP."
else
    echo "Error: $XML_CDT_FOLDER does not exist. No files to copy."
fi

# Step 8: Zip the contents of PROD_CDT_LATEST directory
if [ -d "$XML_CDT_FOLDER" ]; then
    cd /home/omsadmin/CDT/EXPORT/ || exit 1
    [ -f PROD_CDT_LATEST.zip ] && rm -f PROD_CDT_LATEST.zip
    echo "Zipping the MC CDT Exported XMLs into PROD_CDT_LATEST.zip"
    zip -rq PROD_CDT_LATEST.zip ./PROD_CDT_LATEST
    check_success "Failed to complete the zipping process of the MC CDT Exported XMLs into PROD_CDT_LATEST.zip"
else 
    echo "Error: $XML_CDT_FOLDER does not exist. No zipping process of the MC CDT Exported XMLs into PROD_CDT_LATEST.zip"
fi

echo "CDT Export Process completed successfully."
