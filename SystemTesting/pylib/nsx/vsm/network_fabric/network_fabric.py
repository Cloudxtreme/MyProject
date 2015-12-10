import vsm_client
import connection
from job_poll_status import JobPollStatus
from nwfabric_feature_config_schema import NwFabricFeatureConfigSchema
import time
from vsm import VSM
from vsmversion import VsmVersion
import time

class NetworkFabric(vsm_client.VSMClient):
    def __init__(self, vsm=None, **kwargs):
        super(NetworkFabric, self).__init__()
        self.version = VsmVersion(vsm).get_version()
        self.schema_class = 'nwfabric_feature_config_schema.NwFabricFeatureConfigSchema'
        self.set_connection(vsm.get_connection())
        conn = vsm.get_connection()
        conn.set_api_header("/api/2.0")
        self.set_create_endpoint("/nwfabric/configure")
        self.vsm = vsm
        self.id = None

    def read_upgrade_status(self):
        """ Returns upgrade status of vdn cluster

        """
        temp_id = self.id
        self.id = None
        temp_ep = self.read_endpoint
        self.log.debug("resource id %s" % temp_id)
        self.read_endpoint = "/nwfabric/status?resource=" + str(temp_id)
        temp_schema = self.schema_class
        self.schema_class = 'resource_statuses_schema.ResourceStatusesSchema'
        status_obj = self.read()
        self.id = temp_id
        self.read_endpoint = temp_ep
        self.schema_class = temp_schema
        return status_obj

    def get_upgrade_response_dict(self):
        """ Returns upgrade status of vdn cluster in py_dict form

        """
        return self.read_upgrade_status().get_py_dict_from_object()

    def update(self, py_dict):
        """ Upgrades vdn cluster

        @param py_dict dictionary containing hash of required upgrade payload

        """
        temp_id = self.id
        self.id = None
        result = super(NetworkFabric, self).update(py_dict, True)
        self.id = temp_id
        return result

    def create(self, schema_object):
        result_obj = None
        job_id = None
        retry = 1
        while job_id == None and retry < 10:
            try:
                result_obj = super(NetworkFabric, self).create(schema_object)
                job_id = self.get_id()
            except:
                self.log.debug("*** ADDING TEMPORARY WORKAROUND for PR1081139 ***")
                time.sleep(10)
                result_obj = super(NetworkFabric, self).create(schema_object)
                job_id = self.get_id()
                retry = retry + 1

        job_status = JobPollStatus(self.vsm)
        job_status.set_job_id(job_id)
        status = job_status.poll_jobs('COMPLETED', 300) # timeout in seconds
        self.log.debug("Network fabric install status %s" % status)

        #### Fix me: hard code 6.1.2 here
        #### Skip feature check if the vsm build no greater than 6.1.2
        if self.version <= '6.1.2':
            self.log.info("The vsm version is %s, skipping host feature check" % self.version)
            return result_obj
        else:
            self.log.info("The vsm version is %s, about to start host feature check" % self.version)

        ### Verification for host prep: feature status check
        num_schema = len(schema_object)
        index = num_schema - 1
        self.log.debug("Number of schema objects %d" % num_schema)
        while index >= 0:
            # Increase the TIMEOUT if there are more clusters to prep
            # as VSM might take more time
            if num_schema < 5:
                timeout = 600
            else:
                timeout = 600 * num_schema
            red_status = 0
            green_status = 0
            # Set the cluster id
            self.id = schema_object[index]['resourceconfig'][1]['resourceid']
            while green_status < 4  and timeout > 0:
                green_status = 0
                unknown_status = 0
                red_status = 0
                status_obj = self.read_upgrade_status().get_py_dict_from_object()
                #self.log.debug("status_obj %s" % status_obj)
                num_features = 6
                # Returned status_obj is array of dicts but the first 2 dicts have
                # featureId set to None
                while num_features >= 2:
                    if status_obj['resourceStatus'][num_features]['status'] == 'GREEN':
                        self.log.debug("Feature %s prep passed" %
                            status_obj['resourceStatus'][num_features]['featureId'])
                        green_status += 1
                    elif status_obj['resourceStatus'][num_features]['status'] == 'RED':
                        self.log.debug("Feature %s prep failed" %
                            status_obj['resourceStatus'][num_features]['featureId'])
                        red_status += 1
                    elif status_obj['resourceStatus'][num_features]['status'] == 'UNKNOWN':
                        self.log.debug("Feature %s prep status is UNKNOWN" %
                            status_obj['resourceStatus'][num_features]['featureId'])
                        unknown_status += 1
                    elif status_obj['resourceStatus'][num_features]['status'] == 'YELLOW':
                        self.log.debug("Feature %s prep status is in progress" %
                            status_obj['resourceStatus'][num_features]['featureId'])
                    else:
                        pass
                    num_features -= 1
                # In the returned status object com.vmware.vshield.vsm.vdr_mon feature
                # has status 'UNKNOWN' but the remaing 4 features should be RED or GREEN
                # These are the features...
                # com.vmware.vshield.vsm.messagingInfra
                # com.vmware.vshield.vsm.vdr_mon
                # com.vmware.vshield.firewall
                # com.vmware.vshield.vsm.nwfabric.hostPrep
                # com.vmware.vshield.vsm.vxlan
                if green_status != 4:
                    self.log.debug("*** Sleeping for 30 sec ***")
                    time.sleep(30)
                    timeout -= 30
            if red_status > 0 or timeout == 0:
                self.log.debug("Network fabric prep failed for %s" % self.id)
                result_obj[index].set_status_code('400')
            else:
                self.log.debug("Network fabric prep passed for %s" % self.id)
            index -= 1
        return result_obj

    def delete(self, py_dict):
        schema_object = NwFabricFeatureConfigSchema(py_dict)
        self.id = None
        result_obj = super(NetworkFabric, self).delete(schema_object)
        job_id = self.get_id()
        job_status = JobPollStatus(self.vsm)
        job_status.set_job_id(job_id)
        status = job_status.poll_jobs('COMPLETED', 300) # timeout in seconds
        self.log.debug("Network fabric unconfigure/uninstall status %s" % status)
        self.log.debug("*** Sleeping for 90 sec due to PR 1043761 Takes time to remove vmknics from hosts ***")
        time.sleep(90)
        return result_obj

if __name__ == '__main__':
    import base_client
    vsm_obj = VSM("10.110.28.44:443", "admin", "default")
    nwFabric = NetworkFabric(vsm=vsm_obj)
    switch = {'objectId': 'switch-1'}
    py_dict = {'featureid': 'com.vmware.vshield.vsm.vxlan',
               'resourceconfig': [{'resourceId': 'vds-7',
                                   'configspec': {'switch': {
                                   'objectid': 'switch-1'
                                   },
                                                  'mtu': '1600'
                                   },
                                   'configspecclass': "VDSContext"
                                  }, \
                                  {'resourceid': 'cluster-1',
                                   'configspec': {'switch': switch,
                                                  'vlanid': '100',
                                                  'vmkniccount': '1'
                                   },
                                   'configspecclass': 'ClusterMappingSpec'
                                  }
               ]
    }
    base_client.bulk_create(nwFabric, [py_dict])
