import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.vsphere.esx.esx as esx
import vmware.vsphere.vsphere_client as vsphere_client
import vmware.common.connections.soap_connection as soap_connection

import pyVmomi as pyVmomi
import ssl

pylogger = global_config.pylogger
vim = pyVmomi.vim


class ESXAPIClient(esx.ESX, vsphere_client.VSphereAPIClient):

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API

    def __init__(self, ip=None, username=None, password=None, parent=None):
        ssl._create_default_https_context = ssl._create_unverified_context
        super(ESXAPIClient, self).__init__(
            ip=ip, username=username, password=password, parent=parent)
        self.host_mor = self.get_host_mor()

    def get_connection(self):
        return soap_connection.SOAPConnection(self.ip, self.username,
                                              self.password)

    def get_host_mor(self):
        content = self.connection.anchor.RetrieveContent()
        search = content.searchIndex
        return search.FindByIp(ip=self.ip, vmSearch=False)

    def get_network_system(self):
        host_mor = self.get_host_mor()
        return host_mor.configManager.networkSystem
