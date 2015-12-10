import vmware.common.base_client as base_client
import vmware.kvm.ovs.bridge.bridge as bridge


class BridgeCLIClient(bridge.Bridge, base_client.BaseCLIClient):

    def __init__(self, name=None, **kwargs):
        super(BridgeCLIClient, self).__init__(**kwargs)
        self.name = name


if __name__ == "__main__":
    pass
