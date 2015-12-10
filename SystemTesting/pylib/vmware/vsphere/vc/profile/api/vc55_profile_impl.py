import vmware.interfaces.profile_interface as profile_interface
import vmware.vsphere.vc.vc_soap_util as vc_soap_util
import vmware.common.global_config as global_config
import vmware.common.constants as constants
import vmware.schema.profile.profile_schema as profile_schema
import vmware.schema.policy_schema as policy_schema
import pyVmomi as pyVmomi

vim = pyVmomi.vim
pylogger = global_config.pylogger
ProfileSchema = profile_schema.ProfileSchema
PolicySchema = policy_schema.PolicySchema

CLUSTER = "cluster"
Success_lower = "success"


class VC55ProfileImpl(profile_interface.ProfileInterface):

    @classmethod
    def check_compliance(cls, client_object, profile=None, entity=None):
        """
        Checks if the entity is compliant against the profile.

        @type client_object: ProfileAPIClient instance
        @param client_object: ProfileAPIClient instance
        @type profile: str
        @param profile: Checks compliance of entity against a profile.
            Defaults to hostprofile.
        @type entity: ManagedObject instance
        @param entity: Entity to be checked

        @rtype: str
        @return: Status of the operation
        """
        manager = client_object.get_profile_compliance_manager()
        host_profile = client_object.get_host_profile_manager_mor()
        content = host_profile.profile
        if profile is not None:
            for content in host_profile.profile:
                if content.name == client_object.name:
                    content = [content]
        try:
            task = manager.CheckCompliance_Task(
                content, entity)
            return vc_soap_util.get_task_state(task)
        except Exception as e:
            raise Exception("Could not check profile compliance", e)

    @classmethod
    def associate_profile(cls, client_object, entity_type=None,
                          hostname=None, datacenter=None, enable=None):
        """
        Associates or disassociates a host profile from an entity.

        @type client_object: ProfileAPIClient instance
        @param client_object: ProfileAPIClient instance
        @type entity_type: str
        @param entity_type: Can be cluster. Default is host.
        @type hostname:str
        @param hostname: Hostname
        @type datacenter: str
        @param datacenter: Datacenter Name
        @type enable: bool
        @param enable: True to associate, False to dissociate profile

        @rtype: str
        @return: Success if operation is successful
        """
        if enable is None:
            pylogger.error("Please provide vlaue for enable")
            return
        host_mor = client_object.parent.get_host_mor(
            hostname, datacenter)
        entity = host_mor
        if entity_type == CLUSTER:
            if isinstance(host_mor.parent, vim.ClusterComputeResource):
                entity = host_mor.parent
        profile_mor = client_object.host_profile_manager_mor
        for component in profile_mor.profile:
            if component.name == client_object.name:
                try:
                    if enable is True:
                        component.AssociateProfile([entity])
                    if enable is False:
                        component.DissociateProfile([entity])
                    return constants.Result.SUCCESS
                except Exception as e:
                    raise Exception("Could not associate profile", e)
        else:
            pylogger.error("Could not find specified profile")

    @classmethod
    def get_profile_info(cls, client_object, subprofile=None,
                         hostname=None, datacenter=None):
        """
        Returns information about the host's subprofile.

        @type client_object: ProfileAPIClient instance
        @param client_object: ProfileAPIClient instance
        @type subprofile: str
        @param subprofile: Name of the subprofile

        @rtype: ProfileSchema instance
        @return: Schema object
        """
        profile_mor = client_object.host_profile_manager_mor
        for profile in profile_mor.profile:
            if profile.name == client_object.name:
                component = getattr(profile.config.applyProfile, subprofile)
                return ProfileSchema(name=component.profileTypeName)
        pylogger.error("Profile not found")

    @classmethod
    def get_network_policy_info(cls, client_object, category=None,
                                network_device=None):
        """
        Returns network policy information for the desired device.

        @type client_object: ProfileAPIClient instance
        @param client_object: ProfileAPIClient instance
        @type category: str
        @param category: Network profile category. Can be:
            dnsConfig, consoleIpRouteConfig, dvsHostNic, dvsServiceConsoleNic,
            dvswitch, hostPortGroup, ipRouteConfig, netStackInstance, pnic,
            vmPortGroup, vswitch
        @type network_device: str
        @param network_device: Name of the device in the specified
            category

        @rtype: PolicySchema instance
        @return: Schema object containing requested policy information
        """
        # TODO: Currently returning a list of schema objects
        # Caller would have to iterate through list to examine object
        policy_objects = []
        profile_mor = client_object.host_profile_manager_mor
        for profile in profile_mor.profile:
            if profile.name == client_object.name:
                network = profile.config.applyProfile.network
                component = getattr(network, category)
                for device in component:
                    if device.name == network_device:
                        for policy in device.policy:
                            obj = PolicySchema(
                                policy_id=policy.id,
                                policy_option_id=policy.policyOption.id)
                            policy_objects.append(obj)
                return policy_objects
        pylogger.error("Policy %r not found" % client_object.name)

    @classmethod
    def apply_profile(cls, client_object, hostname=None,
                      datacenter=None, parameter_id=None,
                      policy_id=None, profile_path=None,
                      parameter_keys=None, parameter_values=None):
        """
        Applies a host profile to a host.

        @type client_object: ProfileAPIClient instance
        @param client_object: ProfileAPIClient instance
        @type hostname: str
        @param hostname: Hostname
        @type datacenter: str
        @param datacenter: Datacenter name
        @type parameter_id: str
        @param parameter_id: Key for a parameter in the policy specified
            by policyId
        @type policy_id: str
        @param policy_id: Policy option identifier.
        @type profile_path: str
        @param profile_path: Complete path to the leaf profile, relative
            to the root of the host profile document. Eg for vswitch policy,
            profile path is network.vswitch
        @type parameter_keys: list
        @param parameter_keys: List of keys for policy parameters
        @type parameter_values: list
        @param parameter_values: List of values for policy parameters

        @rtype: str
        @return: Status of the operation
        """
        deferred_param_list = []
        host_mor = client_object.parent.get_host_mor(hostname, datacenter)
        profile_mor = client_object.host_profile_manager_mor
        deferred_param = client_object.get_deferred_policy_option(
            parameter_id=parameter_id, policy_id=policy_id,
            profile_path=profile_path, parameter_keys=parameter_keys,
            parameter_values=parameter_values)
        deferred_param_list.append(deferred_param)
        for profile in profile_mor.profile:
            if profile.name == client_object.name:
                result = profile.ExecuteHostProfile(
                    host_mor, deferred_param_list)
                if result.status == constants.Result.SUCCESS.lower():
                    task = host_mor.EnterMaintenanceMode_Task(
                        timeout=120)
                    if vc_soap_util.get_task_state(task) == Success_lower:
                        task = profile_mor.ApplyHostConfig_Task(
                            host_mor, result.configSpec)
                        return vc_soap_util.get_task_state(task)
                    else:
                        pylogger.error("Host could not enter maintenance mode")
                        return
                else:
                    pylogger.error("Execute profile operation failed: ",
                                   result.error)
        pylogger.error("Could not apply profile")

    @classmethod
    def export_answer_file(cls, client_object, hostname=None,
                           datacenter=None):
        """
        Exports a host's answer file in a serialized form.

        @type client_object: ProfileAPIClient instance
        @param client_object: ProfileAPIClient instance
        @type hostname: str
        @param hostname: Hostname
        @type datacenter: str
        @param datacenter: Datacemter name

        @rtype: str
        @return: Serialized form of the answer file
        """
        host_mor = client_object.parent.get_host_mor(
            hostname, datacenter)
        profile_mor = client_object.host_profile_manager_mor
        task = profile_mor.ExportAnswerFile_Task(host_mor)
        result = vc_soap_util.get_task_state(task)
        if result == constants.Result.SUCCESS.lower():
            return task.info.result
        else:
            pylogger.error("Could not successfully export answer file")

    @classmethod
    def import_answer_file(cls, client_object, hostname=None,
                           datacenter=None, answer_file=None):
        """
        Imports the answer file to the host.

        @type client_object: ProfileAPIClient instance
        @param client_object: ProfileAPIClient instance
        @type hostname: str
        @param hostname: Hostname
        @type datacenter: str
        @param datacenter: Datacenter name
        @type answer_file: str
        @param answer_file: Serialized answer file to be imported

        @rtype: str
        @return: Status of the operation
        """
        host_mor = client_object.parent.get_host_mor(
            hostname, datacenter)
        profile_mor = client_object.host_profile_manager_mor
        spec = vim.profile.host.ProfileManager.AnswerFileSerializedCreateSpec()
        spec.answerFileConfigString = answer_file
        task = profile_mor.UpdateAnswerFile_Task(host_mor, spec)
        return vc_soap_util.get_task_state(task)

    @classmethod
    def update_answer_file(cls, client_object, hostname=None,
                           datacenter=None, parameter_id=None,
                           policy_id=None, profile_path=None,
                           parameter_keys=None,
                           parameter_values=None):
        """
        Updates the answer file.

        @type client_object: ProfileAPIClient instance
        @param client_object: ProfileAPIClient instance
        @type hostname: str
        @param hostname: Hostname
        @type datacenter: str
        @param datacenter: Datacenter name
        @type parameter_id: str
        @param parameter_id: Key for a parameter in the policy specified
            by policyId
        @type policy_id: str
        @param policy_id: Policy option identifier
        @type profile_path: str
        @param profile_path: Complete path to the leaf profile, relative to
            the root of the host profile document
        @type parameter_keys: list
        @param parameter_keys: keys of the parameter for the policy
        @type parameter_values: list
        @param parameter_values: Values corresponding to parameter_keys

        @rtype: str
        @return: Status of the operation
        """
        spec = client_object.get_answer_file_option_create(
            parameter_id=parameter_id, policy_id=policy_id,
            profile_path=profile_path,
            parameter_keys=parameter_keys,
            parameter_values=parameter_values)
        host_mor = client_object.parent.get_host_mor(
            hostname, datacenter)
        profile_mor = client_object.host_profile_manager_mor
        task = profile_mor.UpdateAnswerFile_Task(host_mor,
                                                 spec)
        return vc_soap_util.get_task_state(task)

    @classmethod
    def get_answer_file(cls, client_object,
                        hostname=None, datacenter=None):
        """
        Retrieves the host's answer file.

        @type client_object: ProfileAPIClient instance
        @param client_object: ProfileAPIClient instance
        @type hostname: str
        @param hostname: Hostname
        @type datacenter: str
        @param datacenter: Datacenter name

        @rtype: AnswerFile instance
        @return: Answer file
        """
        host_mor = client_object.parent.get_host_mor(
            hostname, datacenter)
        profile_mor = client_object.host_profile_manager_mor
        return profile_mor.RetrieveAnswerFile(host_mor)
