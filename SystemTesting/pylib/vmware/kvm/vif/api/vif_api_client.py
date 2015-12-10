#!/usr/bin/env python
import vmware.common.base_client as base_client
import vmware.common.global_config as global_config
import vmware.kvm.vif.vif as vif

pylogger = global_config.pylogger


class VIFAPIClient(vif.VIF, base_client.BaseAPIClient):
    _vif = None

    def __init__(self, parent=None, name=None):
        super(VIFAPIClient, self).__init__(parent=parent, name=name)

    @property
    def vif(self):
        # name is set for action call, and is not set in case of
        # create call.
        if self._vif is None:
            if self.name:
                for vif_obj in self.parent.vm.VIFs:
                    if vif_obj.kvm_device == self.name:
                        pylogger.debug("Successfully found a VIF with name %r "
                                       "on vm %r on host %r" %
                                       (self.name, self.parent.vm.unique_name,
                                        self.parent.kvm.ip))
                        self._vif = vif_obj
                        break
                else:
                    pylogger.warn("VIF with name %r not found on vm %r on "
                                  "host %r" % (self.name,
                                               self.parent.vm.unique_name,
                                               self.parent.kvm.ip))
            else:
                pylogger.error("Name needs to be set to fetch the VIF from VM")
        return self._vif
