import vmware.common.base_client as base_client
import vmware.common.constants as constants
import vmware.kvm.ovs.port.port as port

CLI = constants.ExecutionType.CLI


class PortCLIClient(port.Port, base_client.BaseCLIClient):

    @property
    def bridge_name(self):
        return self.parent.name


if __name__ == "__main__":
    pass
