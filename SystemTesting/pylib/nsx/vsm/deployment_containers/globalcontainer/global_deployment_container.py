import connection
from deployment_container_schema import DeploymentContainerSchema
from vsm import VSM
import vsm_client


class GlobalDeploymentContainer(vsm_client.VSMClient):
    def __init__(self, vsm):
        """ Constructor to create GlobalDeploymentContainer managed object

        @param vsm object on which global deployment container has to be configured
        """
        super(GlobalDeploymentContainer, self).__init__()
        self.schema_class = 'deployment_container_schema.DeploymentContainerSchema'
        oldConn = vsm.get_connection()

        conn = connection.Connection(oldConn.ip, oldConn.username, oldConn.password, "api/4.0", "https")

        self.set_connection(conn)
        self.set_create_endpoint("/services/deploymentcontainers/globalcontainer")
        self.id = None

    def delete(self, schema_object=None):
        id = self.id
        self.id = None
        result = super(GlobalDeploymentContainer, self).delete()
        self.id = id
        return result

if __name__ == '__main__':
    var = """
    <deploymentContainer>
        <name>nsx-dc</name>
        <description>nsx-dc</description>
        <hypervisorType>vsphere</hypervisorType>
        <keyValue>
            <key>computeResource</key>
            <value>domain-c23</value>
        </keyValue>
         <keyValue>
            <key>storageResource</key>
            <value>datastore-15</value>
        </keyValue>
    </deploymentContainer>
    """
    vsm_obj = VSM("10.67.120.30:443", "admin", "default", "", version="4.0")
    gdc_obj = GlobalDeploymentContainer(vsm_obj)
    py_dict = dict(name='nsx-dc', description='nsx-dc', hypervisortype='vsphere',
                   keyvaluearray=[{'key': 'computeResource', 'value': 'domain-c23'}, {'key': 'storageResource', 'value': 'datastore-15'}])
    gdc_schema = DeploymentContainerSchema(py_dict)
    print gdc_schema.get_data('xml')
    result = gdc_obj.create(gdc_schema)
    print result.__dict__
