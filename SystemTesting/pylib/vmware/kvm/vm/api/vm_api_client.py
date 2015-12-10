#!/usr/bin/env python
import mh.lib.lockutils as lockutils
import vmware.common.base_client as base_client
import vmware.common.global_config as global_config
import vmware.kvm.vm.vm as vm

pylogger = global_config.pylogger


class VMAPIClient(vm.VM, base_client.BaseAPIClient):
    _vm = None
    _lock = None

    @property
    def vm(self):
        if self._lock is None:
            lockname = "kvm-vm-%s.lock" % self.name
            self._lock = lockutils.FileBasedLock(
                global_config.get_base_log_dir(), lockname)
        try:
            self._lock.acquire()
            if self._vm is None:
                # name is set for action call,
                # not set in case of create call.
                if self.name:
                    vms = self.kvm.VM.get_by_name_match(self.name)
                    if len(vms) > 1:
                        pylogger.warning("Found multiple vms with name %s, "
                                         "grabbing the first one" % self.name)
                    vm = vms[0]
                    if not self.password:
                        pylogger.warning("Password for VM was not set, cannot "
                                         "enable password-less access")
                    elif vm.is_running():
                        host_keys_file = global_config.get_host_keys_file()
                        pylogger.debug("Loading ssh known_hosts key from %r" %
                                       host_keys_file)
                        vm.host.known_hosts_file = host_keys_file
                        vm.host.perm_auth_expect(passwd=self.password)
                    self._vm = vm
                else:
                    pylogger.error("Name needs to be set to fetch VM from KVM")
        finally:
            self._lock.release()
        return self._vm

    @property
    def kvm(self):
        return self.parent.kvm
