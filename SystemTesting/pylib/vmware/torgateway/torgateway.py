#!/usr/bin/env python
import mh.lib.lockutils as lockutils
import ovsdb.ovsdb as ovsdb
import vmware.base.hypervisor as hypervisor
import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.common.utilities as utilities
import vmware.common.connections.ssh_connection as ssh_connection
import vmware.interfaces.labels as labels

auto_resolve = base_facade.auto_resolve
pylogger = global_config.pylogger


class TORGateway(hypervisor.Hypervisor):
    _os_map = {'RedHatEnterpriseServer6.4': 'RHEL64',
               'Ubuntu12.04': 'Ubuntu1204'}
    _os_type_map = dict(RHEL64='RHELKVM', Ubuntu1204='UbuntuKVM')
    _os_version = None
    _torgateway = None
    _lock = None
    TMP_DIR = '/tmp'

    # OVSDB interaction
    DB_CLIENT = 'ovsdb-client'
    VSCTL = 'ovs-vsctl'

    def __init__(self, parent=None, **kwargs):
        super(TORGateway, self).__init__(parent=parent, **kwargs)
        self.parent = parent
        self.ovsdb = ovsdb.OVSDB(self)

    def req_call(self, cmd, **kwargs):
        return self.connection.request(cmd).response_data

    @property
    def os_version(self):
        if self._os_version:
            return self._os_version
        connection = ssh_connection.SSHConnection(
            ip=self.ip, username=self.username, password=self.password)
        connection.create_connection()
        raw_data = connection.request('lsb_release -a').response_data
        connection.close()
        lsb_info = utilities.procinfo_to_dict(raw_data)
        os_key = '%s%s' % (lsb_info['Distributor ID'], lsb_info['Release'])
        self._os_version = self._os_map.get(os_key, None)
        if not self._os_version:
            raise ValueError('%r (Host: %s) is not supported KVM platform' %
                             (os_key, self.ip))
        return self._os_version

    @auto_resolve(labels.SERVICE, execution_type=constants.ExecutionType.CMD)
    def get_nsx_switch_service_name(self):
        pass

    def get_impl_version(self, execution_type=None, interface=None):
        return self.os_version

    def get_account_name(self):
        # FIXME(salmanm/miriyalak): Fix once product support is available
        return 'torgateway-%s' % self.ip.replace('.', '-')

    def get_os_type(self):
        return self._os_type_map.get(self.os_version)

    def get_ip_addresses(self):
        # TODO(gjayavelu): returning tuple isn't working
        # where it gets converted into string at workloads.
        # Using list for now.
        return [self.ip]

    @auto_resolve(labels.SETUP, execution_type=constants.ExecutionType.API)
    def setup_3rd_party_library(self, execution_type=None):
        pass

    @property
    def torgateway(self):
        if not self._torgateway:
            if self._lock is None:
                lockname = "torgateway-%s.lock" % self.ip
                self._lock = lockutils.FileBasedLock(
                    global_config.get_base_log_dir(), lockname)
            try:
                self._lock.acquire()
                self._torgateway = self.setup_3rd_party_library()
            finally:
                self._lock.release()
        return self._torgateway

    @auto_resolve(labels.ADAPTER)
    def set_adapter_mtu(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.ADAPTER, execution_type=constants.ExecutionType.CMD)
    def persist_iface_config(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.TROUBLESHOOT)
    def collect_logs(self, execution_type=None, **kwargs):
        pass

    def get_mgmt_ip(self):
        return self.ip
