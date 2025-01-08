# Define the application name, EAR file location, and cluster name [DEV OMS 10]
appName = 'SterlingApplication'
earFileLocation = '/opt/IBM/OMS10/external_deployments/smcfs.ear'
clusterName = 'OMS_CLUSTER'
dmgeCellName = 'OMS10DEVAPPMC01Cell01'
dmgrNodeName = 'OMS10DEVAPPMC01_Node'
webserver = 'oms-webserver'

# Update the application and save configuration
def updateApp():
    try:
        print("----------------------------------- Updating the application on master repository [DMGR] -----------------------------------")
        AdminApp.update(appName, 'app', '[ -operation update -contents ' + earFileLocation +
                ' -nopreCompileJSPs -distributeApp -nouseMetaDataFromBinary -deployejb -createMBeansForResources ' +
                '-noreloadEnabled -deployws -validateinstall warn -noprocessEmbeddedConfig ' +
                '-filepermission .*\\.dll=755#.*\\.so=755#.*\\.a=755#.*\\.sl=755 ' +
                '-noallowDispatchRemoteInclude -noallowServiceRemoteInclude ' +
                '-asyncRequestDispatchType DISABLED -nouseAutoLink -noenableClientModule -clientMode isolated -novalidateSchema ' +
                '-MapModulesToServers [[ smcfsejb.jar smcfsejb.jar,META-INF/ejb-jar.xml WebSphere:cell=' + dmgeCellName + ',cluster=' + clusterName +
                '+WebSphere:cell=' + dmgeCellName + ',node=' + dmgrNodeName + ',server=' + webserver + ' ]' +
                '[ smcfs.war smcfs.war,WEB-INF/web.xml WebSphere:cell=' + dmgeCellName + ',cluster=' + clusterName +
                '+WebSphere:cell=' + dmgeCellName + ',node=' + dmgrNodeName + ',server=' + webserver + ' ]' +
                '[ wsc.war wsc.war,WEB-INF/web.xml WebSphere:cell=' + dmgeCellName + ',cluster=' + clusterName +
                '+WebSphere:cell=' + dmgeCellName + ',node=' + dmgrNodeName + ',server=' + webserver + ' ]' +
                '[ sbc.war sbc.war,WEB-INF/web.xml WebSphere:cell=' + dmgeCellName + ',cluster=' + clusterName +
                '+WebSphere:cell=' + dmgeCellName + ',node=' + dmgrNodeName + ',server=' + webserver + ' ]' +
                '[ isccs.war isccs.war,WEB-INF/web.xml WebSphere:cell=' + dmgeCellName + ',cluster=' + clusterName +
                '+WebSphere:cell=' + dmgeCellName + ',node=' + dmgrNodeName + ',server=' + webserver + ' ]' +
                '[ "HTTP router for smcfsejb.jar" yantrawebservices.war,WEB-INF/web.xml WebSphere:cell=' + dmgeCellName + ',cluster=' + clusterName +
                '+WebSphere:cell=' + dmgeCellName + ',node=' + dmgrNodeName + ',server=' + webserver + ' ]]]')
        AdminConfig.save()
        app_cmd = "[-ApplicationNames "+ appName +"]"
        AdminTask.updateAppOnCluster(app_cmd)
        print("----------------------------------- Application updated and configuration saved -----------------------------------")
    except Exception as e:
        print("*********************************** An error occurred while updating the application: {} ***********************************".format(e))


updateApp()
