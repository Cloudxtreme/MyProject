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


class KVM(hypervisor.Hypervisor):
    _os_map = {'RedHatEnterpriseServer6.4': 'RHEL64',
               'Ubuntu12.04': 'Ubuntu1204',
               'Ubuntu14.04': 'Ubuntu1404'}
    _os_type_map = dict(RHEL64='RHELKVM', Ubuntu1204='UbuntuKVM',
                        Ubuntu1404='UbuntuKVM')
    _os_version = None
    _kvm = None
    _lock = None
    TMP_DIR = '/tmp'

    # OVSDB interaction
    DB_CLIENT = 'ovsdb-client'
    VSCTL = 'ovs-vsctl'
    version_tree = dict(
        RHEL64='Default',
        RHEL70='RHEL64',
        Ubuntu1204='Default',
        Ubuntu1404='Ubuntu1204',
        )

    def __init__(self, parent=None, **kwargs):
        super(KVM, self).__init__(parent=parent, **kwargs)
        self.parent = parent
        self.ovsdb = ovsdb.OVSDB(self)

    def req_call(self, cmd, **kwargs):
        return self.connection.request(cmd).response_data

    def get_version(self):
        return dict(os_version=self.os_version)

    def set_version(self, version_info):
        if version_info is None:
            version_info = {}
        self._os_version = version_info.get('os_version')

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
        return 'kvm-%s' % self.ip.replace('.', '-')

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
    def kvm(self):
        if not self._kvm:
            if self._lock is None:
                lockname = "kvm-%s.lock" % self.ip
                self._lock = lockutils.FileBasedLock(
                    global_config.get_base_log_dir(), lockname)
            try:
                self._lock.acquire()
                self._kvm = self.setup_3rd_party_library()
            finally:
                self._lock.release()
        return self._kvm

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

    @auto_resolve(labels.VERIFICATION)
    def start_capture(self, tool=None, **kwargs):
        """Starts the capture process."""
        pass

    @auto_resolve(labels.VERIFICATION)
    def stop_capture(self, tool=None, **kwargs):
        """Stops the capture process."""
        pass

    @auto_resolve(labels.VERIFICATION)
    def extract_capture_results(self, tool=None, **kwargs):
        """Extracts the captured data."""
        pass

    @auto_resolve(labels.VERIFICATION)
    def get_ipfix_capture_data(self, tool=None, **kwargs):
        """Gets IPFIX capture data."""
        pass

    @auto_resolve(labels.VERIFICATION)
    def get_capture_data(self, tool=None, **kwargs):
        """Gets captured traffic data using a user specified tool."""
        pass
