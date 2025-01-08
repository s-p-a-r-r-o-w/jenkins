#!/bin/sh
# Licensed Materials - Property of IBM
# IBM Sterling Order Management (5725-D10), IBM Order Management (5737-D18)
# (C) Copyright IBM Corp. 2001, 2020 All Rights Reserved.
# US Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
. /opt/IBM/OMS10/bin/tmp.sh


#Set the YFS_HOME directory below to point to your installation directory
YFS_HOME=${INSTALL_DIR}
export YFS_HOME

#If you have extended application tables, specify the full path name to the jar file
#containing the generated database classes below
DB_EXTN_JAR=${INSTALL_DIR}/repository/entities.jar
export DB_EXTN_JAR

#Set the name of the source database that you have defined
#in ${INSTALL_DIR}/resources/ydkprefs.xml
SOURCE_DB="changeme"
export SOURCE_DB

#Specify the password required for the source database. This parameter is not
#required to be set if the source is an XML folder, unless that XML folder
#contains encrypted resources.
SOURCE_PASSWORD="changeme"
export SOURCE_PASSWORD

#Set the name of the target database that you have defined
#in ${INSTALL_DIR}/resources/ydkprefs.xml
TARGET_DB="changeme"
export TARGET_DB

#Specify the password required for the target database. This parameter is not
#required to be set if the target is an XML folder, unless that XML folder
#contains encrypted resources.
TARGET_PASSWORD="changeme"
export TARGET_PASSWORD

#Specify the password required to refresh the cache of the target database. This
#parameter is not required if there is no target cache to refresh.
TARGET_HTTP_PASSWORD=
export TARGET_HTTP_PASSWORD

# Other options available to the ConfigDeployMain class:
# Set these options by modifying the script below. They cannot be passed as
# command line parameters.
#
# -MODE <mode>
#    The MODE may be one of several options to affect the type of operation.
#    Each mode has its own set of options.

# ----------------------------------------------
# -MODE Deploy [this is default]
#    Deploy changes from source to target database.
#    There are several optional options available:
# -ExportDir <directory>
#    The given directory will be created, and the results of the comparison
#    will be written to it.
# -ExportPassphrase <password>
#    The given password is used to encrypt supported Import/Export data when
#    exporting results. This is only applicable when ExportDir is given.
# -ImportDir <directory>
#    The given directory should contain an export. Rather than compare the
#    source and target databases, this export will be loaded. When this
#    argument is present, the Source database properties are not used.
# -ImportPassphrase <password>
#    The given password is used to decrypt data from the import files as
#    needed, and should match the password given to create the export.
# -DoNotSynchronize <Y|N>
#    If passed as Y, only the comparison will take place; nothing will be
#    deployed. By default, results are automatically deployed.
# -ColonyId <ColonyId>
#    ColonyId to filter data with when in a multi-schema environment. By
#    default, all data in the affected tables will be processed.
# -Compare<Type> <CompareValue>
#    Filter results by the given CompareValue, as defined in the config-db.xml.
#    If the option is not given, the corresponding filter will not be used.
#    Consult the product documentation for all supported options.
# -AppendOnly <Y|N>
#    Pass Y to treat all tables as if they were configured to be Append-Only
#    within the CDT preferences.
# -IgnoreMissingTables <Y|N>
#    Pass Y to ignore tables that are missing in the source or target databases.
# -LabelId <LabelId>
#    The given value will be used to create labels BEGIN_<LabelId> and
#    END_<LabelId> before and after the deployment, respectively. If the option
#    is not given, no labels will be created.
# -ShowAbandoned <Y|N>
#    Pass Y to not ignore Abandoned records

# ----------------------------------------------
# -MODE LABELDEPLOY
#    Deploy audit changes between two version labels.
#    There are two available options:
# -FromLabel <LabelID to start from>
# -ToLabel <LabelID to end with>

# Disable HEAP_FLAGS for container support for CDT
if [ -f /.dockerenv ] ; then
  echo -n "&DISABLE_CDT_HEAP_FLAGS_FOR_CONTAINER_SUPPORT;" > cdtshell_dchffcs.txt
  if [ $(cat cdtshell_dchffcs.txt) = "true" ] ; then
    HEAP_FLAGS=
  fi
  rm cdtshell_dchffcs.txt
fi

# Setting jvm arguments from command line. If jvm arguments to be overidden it must be passed as the first argument pair (i.e. -jvmargs <jvm overidden params> )
for e in "$@";do
        if [ "$e" = -jvmargs ];then
                jvm_args_passed=y
        shift
        continue
        elif [ "${jvm_args_passed}" = y ];then
        JVM_ARGS=$e
                HEAP_FLAGS="${HEAP_FLAGS} ${JVM_ARGS}"
        shift
        break
        else
                break
        fi
done
export HEAP_FLAGS

export CDT_ARGS=
if [ ! -z ${SOURCE_DB} ];then
        CDT_ARGS="${CDT_ARGS} -Source ${SOURCE_DB}"
fi
if [ ! -z ${TARGET_DB} ];then
        CDT_ARGS="${CDT_ARGS} -Target ${TARGET_DB}"
fi
if [ ! -z ${SOURCE_PASSWORD} ];then
        CDT_ARGS="${CDT_ARGS} -SourcePassword ${SOURCE_PASSWORD}"
fi
if [ ! -z ${TARGET_PASSWORD} ];then
        CDT_ARGS="${CDT_ARGS} -TargetPassword ${TARGET_PASSWORD}"
fi
if [ ! -z ${TARGET_HTTP_PASSWORD} ];then
        CDT_ARGS="${CDT_ARGS} -TargetHTTPPassword ${TARGET_HTTP_PASSWORD}"
fi

set -x

dstamp=`date '+%Y%m%d%H%M%S'`

${JAVA} ${HEAP_FLAGS} ${LOG_FLAGS} -classpath /opt/IBM/OMS10/jar/bootstrapper.jar:/opt/IBM/OMS10\resources\ydkresources -Dvendor=shell -DvendorFile=/opt/IBM/OMS10/properties/servers.properties -DUseEntitiesFromClasspath=Y -DDISABLE_DS_EXTENSIONS=Y -DDISABLE_EXTENSIONS=Y -DYFS_HOME=/opt/IBM/OMS10 com.sterlingcommerce.woodstock.noapp.NoAppLoader -class com.yantra.tools.ydk.config.ConfigDeployMain -p /opt/IBM/OMS10/resources/ydkresources -f /opt/IBM/OMS10/properties/dynamicclasspath.cfg -invokeargs ${CDT_ARGS} "$@" 2>&1 | tee /opt/IBM/OMS10/logs/cdtshell.${dstamp}.log
exit ${PIPESTATUS[0]}
