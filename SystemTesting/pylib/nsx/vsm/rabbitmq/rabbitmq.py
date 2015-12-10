from expect_client import ExpectClient
from vmware.common.global_config import pylogger
from vsm import VSM
import vsm_client


class RabbitMQ(vsm_client.VSMClient):

    rabbitmq_commands = {
        'stop': {
            'command': 'rabbitmqctl stop',
            'expect_prompt': 'done.+root@',
        },
        'start': {
            'command': '/etc/rc.d/init.d/rabbitmqserver start 2>&1 &',
            'expect_prompt': 'done.+created succesfully',
        }
    }

    def __init__(self, vsm=None):
        """ Constructor to create application object

        @param vsm object on which application object has to be configured
        """
        super(RabbitMQ, self).__init__()
        self.set_connection(vsm.get_connection())
        self.id = None

    def execute_command(self, vsm, ste_password, command):
        pylogger.info("STE Password - %s" % ste_password)
        pylogger.info("Execute command - %s" % command)

        expect_client = ExpectClient()
        expect_conn = vsm.get_expect_connection()
        expect_client.set_connection(expect_conn)

        expect_client.set_schema_class('no_stdout_schema.NoStdOutSchema')
        expect_client.set_create_endpoint('st e')
        expect_client.set_expect_prompt('Password:')
        expect_client.read()

        expect_client.set_schema_class('no_stdout_schema.NoStdOutSchema')
        expect_client.set_create_endpoint(ste_password)
        expect_client.set_expect_prompt("#")
        cli_data = expect_client.read()

        expect_client.set_schema_class('no_stdout_schema.NoStdOutSchema')
        expect_client.set_create_endpoint(self.rabbitmq_commands[command]['command'])
        expect_client.set_expect_prompt(self.rabbitmq_commands[command]['expect_prompt'])
        expect_client.read()

        vsm.terminate_expect_connection(expect_conn)

        return 'SUCCESS'

if __name__ == '__main__':
    vsm_obj = VSM("10.110.29.222", "admin", "default", "")
    rmq = RabbitMQ(vsm_obj)
    rmq.execute_command(vsm_obj, 'default', 'stop')
    rmq.execute_command(vsm_obj, 'default', 'start')