import vmware.common.base_client as base_client


class VCCLIClient(base_client.BaseClient):

    def __init__(self, ip=None, username=None, password=None, parent=None):
        super(VCCLIClient, self).__init__(
            ip=ip, username=username, password=password,
            parent=parent)
