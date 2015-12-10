#!/usr/bin/env python
import vmware.common.base_client as base_client
import vmware.common.global_config as global_config
import vmware.kvm.ovs.bridge.bridge as bridge

pylogger = global_config.pylogger


class BridgeAPIClient(bridge.Bridge, base_client.BaseAPIClient):

    def __init__(self, parent=None, name=None, **kwargs):
        super(BridgeAPIClient, self).__init__(parent=parent, **kwargs)
        self.name = name
        self.parent = parent
        self.kvm = self.parent.kvm

    def get_bridge(self):
        return self.kvm.network.check_create(self.name, set_external_id=False)
