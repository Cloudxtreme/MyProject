import base_client
import vmware.common.logger as logger
import neutron_client
import string
import time


class OperatingMode(neutron_client.NeutronClient):

    def __init__(self, neutron=None):
        """ Constructor to create OperatingMode object

        @param neutron object on which OperatingMode object has to be configured
        """
        super(OperatingMode, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'neutron_operating_mode_schema.OperatingModeSchema'

        if neutron is not None:
            self.set_connection(neutron.get_connection())

        self.set_create_endpoint("/cluster/operatingmode")
        self.id = None

    def update(self, py_dict):

        result = super(OperatingMode, self).update(py_dict, False)

        # Polling the operating mode to check if it becomes the desired state.
        # Polling is done for a maximum of 100 secs.
        if ('operating_mode' in py_dict):
            count = 0
            while 1:
                omr = self.read()
                time.sleep(10)
                if str(omr.operating_mode) == py_dict['operating_mode']:
                    break
                if count > 10:
                    break
                count = count + 1

        return result

if __name__ == '__main__':
    pass
