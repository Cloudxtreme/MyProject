import vsm_client
from job_poll_status import JobPollStatus
import result
from vdn_scope_schema import VDNScopeSchema
from vsm import VSM
import vmware.common.logger as logger

class VDNScope(vsm_client.VSMClient):
    """ Class to create vdn Scope"""
    def __init__(self, vsm=None, scope=None):
        """ Constructor to create VDNScope managed object

        @param vsm object over which vdn scope has to be created
        """
        super(VDNScope, self).__init__()
        self.schema_class = 'vdn_scope_schema.VDNScopeSchema'
        self.set_connection(vsm.get_connection())
        if scope is None or scope is "":
            self.set_create_endpoint("/vdn/scopes")
        else:
            self.set_create_endpoint("/vdn/scopes?isUniversal=true")
            self.set_read_endpoint("/vdn/scopes")
            self.set_delete_endpoint("/vdn/scopes")
        self.update_as_post = True
        self.id = None

    def execute_action(self, action, py_dict):
        self.log.debug("execute_action %s on this vdnScope" % action)
        self.set_create_endpoint("vdn/scopes/" + self.id + "?action=" + action)
        schema_object = self.get_schema_object(py_dict)
        result_obj = super(VDNScope, self).create(schema_object)
        self.set_create_endpoint("vdn/scopes")
        job_id = self.get_id()
        job_status = JobPollStatus(self)
        job_status.set_job_id(job_id)
        self.log.debug("Waiting for task %s to complete in 60s" % job_id)
        status = job_status.poll_jobs('COMPLETED', 600) # timeout in seconds
        self.log.debug("status of action on vdn_scope %s" % status)
        if status == 'FAILURE':
           #TODO: Temp status code until we standardize it
           result_obj[0].set_status_code('400')
           return result_obj
        location_header = self.location_header
        if location_header is not None:
           self.id = location_header.split('/')[-1]
           result_obj[0].set_response_data(self.id)
        return result_obj

    def get_name(self):
        vdn_scope_object = super(VDNScope, self).read()
        return vdn_scope_object.name

    def get_universalRevision(self):
        vdn_scope_object = super(VDNScope, self).read()
        return vdn_scope_object.universalRevision

    def get_vdnscope(self):
        vdn_scope_object = super(VDNScope, self).read()
        return vdn_scope_object

    def get_vdnscope_id(self):
        vdn_scope_object = super(VDNScope, self).read()
        return vdn_scope_object.id

if __name__=='__main__':
    import base_client
    var = """
    <vdnScope>
        <name>vdn-21</name>
        <clusters>
            <cluster>
                <cluster><objectId>domain-c59</objectId></cluster>
            </cluster>
        </clusters>
    </vdnScope>
    """
    log = logger.setup_logging('VDNScopeTest')
    vsm_obj = VSM("10.110.28.44:443", "admin", "default", "")
    #vdnData = VDNScopeSchema()
    #vdnData.name = 'vdn-1'
    #clusterSchema = ClusterSchema()
    #clusterSchema.objectId = 'domain-c7'
    #vdnData.clusters.cluster.append(clusterSchema)
    #vdnScope.create(vdnData)

    #response = vdnScope.query()
    #vdnData.setData_xml(response)
    py_dict1 = {'name': 'vdn-28', 'clusters': {'cluster': [{'objectId': 'domain-c7'}]}}
    py_dict2 = {'name': 'vdn-29', 'clusters': {'cluster': [{'objectId': 'domain-c7'}]}}
    py_dict3 = {'clusters': {'cluster': [{'objectid': 'domain-c7'}, {'objectid': 'domain-c22'}]}, 'name': 'network-scope-1-20600'}
    vdn_scope = VDNScope(vsm_obj)
    array_of_network_scope = base_client.bulk_create(vdn_scope, [py_dict3])
    log.info(array_of_network_scope)
    #ipamObj.id = arrayOfIPAM[0]
    #vdnScope.create([pyDict1, pyDict2])
    #py_dict1 = {'name': 'VCDN-1', 'clusters': {'cluster': [{'objectId': 'domain-c596'}]}}
    result = base_client.bulk_verify(vdn_scope, [array_of_network_scope[0].get_response_data()], [py_dict1, py_dict2])
    log.info(result)
