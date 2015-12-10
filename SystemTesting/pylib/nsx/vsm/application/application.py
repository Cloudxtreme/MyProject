import vsm_client
import vmware.common.logger as logger
import application_schema
from vsm import VSM

UNIVERSAL_SCOPE = 'universal'


class Application(vsm_client.VSMClient):

    def __init__(self, vsm=None, scope=None):
        """ Constructor to create application object

        @param vsm object on which application object has to be configured
        """
        super(Application, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'application_schema.ApplicationSchema'
        self.set_connection(vsm.get_connection())
        if UNIVERSAL_SCOPE == scope:
            self.set_create_endpoint("/services/application/universalroot-0")
        else:
            self.set_create_endpoint("/services/application/globalroot-0")
        self.set_read_endpoint("/services/application")
        self.set_delete_endpoint("/services/application")
        self.id = None

if __name__ == '__main__':
    import base_client
    var = """
    <application>
        <revision>1</revision>
        <name>New-Application-Auto-1</name>
        <inheritanceAllowed>false</inheritanceAllowed>
    </application>
    """
    log = logger.setup_logging('Application-Test')
    vsm_obj = VSM("10.110.25.146", "admin", "default", "")
    application_client = Application(vsm_obj, 'universal')

    #Create New Application
    py_dict1 = {'name':'application-auto-1012', 'element':{'applicationprotocol':'TCP', 'value':'1001'}}
    py_dict1 = {'name':'application-auto-1013', 'element':{'applicationprotocol':'TCP', 'value':''}}
    result_objs = base_client.bulk_create(application_client, [py_dict1])
    print result_objs[0][0].status_code
    print application_client.id

    #Update Application
    py_dict1 = {'name': 'new-application-auto-1', 'revision': '2'}
    response_status = application_client.update(py_dict1)
    print response_status

    #Delete Application
    response_status = application_client.delete(None)
    print response_status