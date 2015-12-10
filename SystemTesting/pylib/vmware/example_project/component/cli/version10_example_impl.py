import vmware.common.base_client as base_client
import vmware.common.global_config as global_config
import vmware.interfaces.example_interface as example_interface

pylogger = global_config.pylogger


class Version10ExampleImpl(example_interface.ExampleInterface):

    @classmethod
    def method01(cls, client_object):
        result = client_object.connection.request("ls /tmp").response_data
        pylogger.info("Result for command: %s" % result)

    @classmethod
    def method02(cls, client_object, component=None):
        if not isinstance(component, base_client.BaseClient):
            raise AssertionError("component is not client object")
