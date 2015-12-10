import vmware.common.logger as logger
import neutron_client
import result

class ConfigSnapshot(neutron_client.NeutronClient):

    def __init__(self, neutron=None):
        """ Constructor to create ConfigSnapshot object

        @param neutron object on which ConfigSnapshot object has to be configured
        """
        super(ConfigSnapshot, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'neutron_backup_schema.ConfigSnapshotSchema'

        if neutron is not None:
            self.set_connection(neutron.get_connection())

        self.set_create_endpoint("/cluster/config-snapshot")
        self.set_content_type("application/octet-stream")
        self.id = None

    def update(self, filename):
        file = open(filename, 'rb')
        data = file.read()
        self.response = self.request('PUT', self.create_endpoint, data)
        result_obj = result.Result()
        self.set_result(self.response, result_obj)

        return result_obj

    def get(self, filename):
        result_object = super(ConfigSnapshot, self).get()
        data = result_object.response_data
        self.log.debug("backup file: %s" % filename)
        file = open(filename, 'wb')
        file.write(data)
        file.close()
        return result_object

if __name__ == '__main__':
    pass
