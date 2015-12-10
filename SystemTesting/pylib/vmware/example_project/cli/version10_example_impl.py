import vmware.interfaces.example_interface as example_interface
import vmware.common.errors as errors
import vmware.common.global_config as global_config

pylogger = global_config.pylogger


class Version10ExampleImpl(example_interface.ExampleInterface):

    @classmethod
    def method01(cls, client_object):
        pylogger.info("method01(%r) called" % client_object)
        out = client_object.connection.request('ls /tmp').response_data
        # Assuming the command returned a status_code with 255
        status_code = 255
        if status_code:  # non-zero for cli
            raise errors.CLIError(status_code=status_code, reason=out)

    @classmethod
    def method02(cls, client_object, required_param=None, int_param=None):
        if required_param is None:
            raise ValueError("Need the required_param, but not provided")
        if type(int_param) is not int:
            raise TypeError("Need int for int_param, but provided %r" %
                            int_param)
        pylogger.info("method02(%r, required_param=%s, int_param=%s) called" %
                      (client_object, required_param, int_param))
