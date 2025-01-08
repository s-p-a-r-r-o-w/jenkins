#!/bin/bash

# Set Sterling directory path
STERLING_DIR="/opt/IBM/OMS10"
# Set source directory path
SOURCE_DIR="/home/omsadmin/devOps"
# Set JASPER Templates Directory
JASPER_DIR="/opt/IBM/JasperReports/templates"

# Function to handle errors and log them
log_error() {
    echo "$(date +%F_%T) : ERROR : $1" >&2
    exit 1
}

# Function to log success messages
log_success() {
    echo "$(date +%F_%T) : INFO : $1"
}

# Copy JAR files
copy_jars() {
    log_success "Copying JAR files [ CustomCode.jar, resources.jar, entities.jar ] into ${STERLING_DIR}/jar/{3rdparty-jars/1.0 | platform/10_0}/"
    # Copy CustomCode.jar
    cp -f "${SOURCE_DIR}/jars/CustomCode.jar" "${STERLING_DIR}/jar/3rdparty-jars/1.0/" || log_error "Failed to copy CustomCode.jar into ${STERLING_DIR}/jar/3rdparty-jars/1.0/"
    # Copy resources.jar
    cp -f "${SOURCE_DIR}/jars/resources.jar" "${STERLING_DIR}/jar/platform/10_0/" || log_error "Failed to copy resources.jar into ${STERLING_DIR}/jar/platform/10_0/"
    # Copy entities.jar
    cp -f "${SOURCE_DIR}/jars/entities.jar" "${STERLING_DIR}/jar/platform/10_0/" || log_error "Failed to copy entities.jar into ${STERLING_DIR}/jar/platform/10_0/"
    log_success "JAR files copied into Sterling [${STERLING_DIR}/jar/{3rdparty-jars/1.0/ | platform/10_0}/] directory successfully."

}

# Copy JAR files
copy_properties() {
    log_success "Copying Sterling Properties folder files into ${STERLING_DIR}/properties/"
    # Copy properties files
    cp -f ${SOURCE_DIR}/properties/* "${STERLING_DIR}/properties/" || log_error "Failed to copy Copying Sterling Properties folder files into ${STERLING_DIR}/properties/"
    log_success "Sterling Properties Folder files copied into Sterling [${STERLING_DIR}/properties/] directory successfully."

}

# Copy Extensions
copy_extensions() {
    log_success "Copying Extensions files and folders."
    # Unzip extensions
    cd "${SOURCE_DIR}/extensions/" && unzip -qo "${SOURCE_DIR}/extensions/extensions.zip" || log_error "Failed to unzip extensions.zip"
    log_success "Successfully extracted extensions.zip"
    # Copy global extensions
    cp -fr "${SOURCE_DIR}/extensions/global" "${STERLING_DIR}/extensions" || log_error "Failed to copy global extensions into ${STERLING_DIR}/extensions/global"
    # Copy ISCCS extensions
    cp -fr "${SOURCE_DIR}/extensions/isccs" "${STERLING_DIR}/extensions" || log_error "Failed to copy ISCCS extensions into ${STERLING_DIR}/extensions/isccs"
    # Copy WSC extensions
    #cp -fr "${SOURCE_DIR}/extensions/wsc" "${STERLING_DIR}/extensions" || log_error "Failed to copy WSC extensions into ${STERLING_DIR}/extensions/wsc"
    log_success "Extensions files and folders successfully copied to the Sterling [${STERLING_DIR}/extensions] directory."
}

# Copy Extensions
copy_jasper_templates() {
    log_success "Copying Jasper Template files into ${JASPER_DIR}/"
    # Unzip extensions
    cd "${SOURCE_DIR}/jasperreports/" && unzip -qo "${SOURCE_DIR}/jasperreports/jasperreports.zip" || log_error "Failed to unzip jasperreports.zip"
    log_success "Successfully extracted jasperreports.zip"
    # Copy global extensions
    cp -f ${SOURCE_DIR}/jasperreports/templates/* "${JASPER_DIR}/" || log_error "Failed to copy jasper template files into ${JASPER_DIR}/"
    log_success "Jasper Template files successfully copied to ${JASPER_DIR}/ directory."
}

#Copy EAR files
copy_ear_files() {
    log_success "Copying Sterling EAR files into ${STERLING_DIR}/external_deployments/"
    # Copy global extensions
    cp -f ${SOURCE_DIR}/ear/* "${STERLING_DIR}/external_deployments/" || log_error "Failed to copy EAR files into ${STERLING_DIR}/external_deployments/"
    log_success "Sterling EAR files successfully copied to ${STERLING_DIR}/external_deployments/ directory."

}

# Main function
main() {
    log_success "Starting the Agent Server Runtime setup."
    copy_jars
    copy_properties
    #copy_extensions
    copy_jasper_templates
    #copy_ear_files
    log_success "Agent Server Runtime setup completed successfully."
}

# Call the main function
main