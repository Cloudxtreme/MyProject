import vsm_client
import vmware.common.logger as logger


class VsmConfig(vsm_client.VSMClient):
    def __init__(self, vsm=None):
        """ Constructor to create IPSet object

        @param vsm object on which IPSet has to be configured
        """
        super(VsmConfig, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'vsmconfig_schema.VSMConfigSchema'
        self.set_connection(vsm.get_connection())
        conn = self.get_connection()
        conn.set_api_header("api/2.0")
        self.set_read_endpoint("services/vsmconfig")
        self.id = None
        self.update_as_post = False

    def get_uuid(self):
        schema_object = self.read()
        uuid = schema_object.biosUuid
        return uuid

    def get_node_id(self):
        schema_object = self.read()
        node_id = schema_object.nodeId
        return node_id

