import vmware.common.base_client as base_client
import vmware.common.global_config as global_config
import vmware.vsphere.vc.vc_soap_util as vc_soap_util

pylogger = global_config.pylogger


class VSphereCLIClient(base_client.BaseCLIClient):
    pass


class VSphereCMDClient(base_client.BaseCMDClient):
    pass


class VSphereAPIClient(base_client.BaseAPIClient):

    def __init__(self, ip=None, username=None, password=None,
                 parent=None):
        super(VSphereAPIClient, self).__init__(ip=ip,
                                               username=username,
                                               password=password,
                                               parent=parent)

    def get_parent(self):
        content = self.parent.connection.anchor.RetrieveContent()
        search = content.searchIndex
        return search.FindByIp(ip=self.parent.ip, vmSearch=False)

    def create_api(self, schema=None, command=None):
        parent = self.get_parent()
        request = self.connection.request(
            parent, self.create_command_api, schema)
        id_string = request.response_data
        self.populateid_(id_string, schema, command)
        return id_string

    def populate_id(self, response, schema=None, command=None):
        self.id_ = str(response).split(':')[1]
        self.id_ = self.id_.replace('\'', "").split(',')[0]

    def read_api(self, schema=None, command=None):
        pass

    def get_api(self, schema=None, command=None):
        parent = self.get_parent()
        for vm in parent.vm:
            id_ = vm._moId
            if str(self.id_) == str(id_):
                return vm

    def update_api(self, schema=None, command=None):
        pass

    def delete_api(self, schema=None, command=None):
        entity = self.get()
        x = getattr(entity, self.delete_command_api)
        y = x()
        if str(self.create_command_api).find("_Task") != -1:
            vc_soap_util.wait_for_task_completion(y)
        self.id_ = None

    def action_api(self, action_name, schema=None, client=None):
        method = getattr(self, action_name)
        args = {"client": client}
        if schema:
            args = {args.items(), schema.get_command_args().items()}
        method(**args)

    def query_api(self, schema=None, command=None):
        return getattr(self.parent, self.query_command_api)

    def get_current_path_element(self):
        return ""

if __name__ == "__main__":
    pass
