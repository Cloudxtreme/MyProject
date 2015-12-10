import vmware.interfaces.crud_interface as crud_interface
import vmware.common.global_config as global_config
import vmware.common.constants as constants
import pyVmomi as pyVmomi

pylogger = global_config.pylogger
vim = pyVmomi.vim


class VC55CRUDImpl(crud_interface.CRUDInterface):

    @classmethod
    def create(cls, client_object, datacenter=None,
               hostname=None, schema_object=None):
        """
        Creates a host profile.

        @type client_object: ProfileAPIClient instance
        @param client_object: ProfileAPIClient instance
        @type schema_object: profile_schema.ProfileSchema instance
        @param schema_object: Schema object for profile
        @type hostname: str
        @param hostname: Hostname
        @type datacenter: str
        @param datacenter: Datacenter name

        @rtype: str
        @return: Profile name
        """
        host_mor = client_object.parent.get_host_mor(
            hostname, datacenter)
        profile_mor = client_object.host_profile_manager_mor
        spec = client_object.get_profile_spec(
            host_mor=host_mor,
            name=client_object.name, enabled=schema_object.enabled,
            annotation=schema_object.annotation)
        try:
            result = profile_mor.CreateProfile(spec)
            client_object.hostprofile_mor = result
            return result.name
        except Exception as e:
            raise Exception("Could not create host profile", e)

    @classmethod
    def delete(cls, client_object):
        """
        Destroys the host profile associated with the client_object.

        @type client_object: ProfileAPIClient instance
        @param client_object: ProfileAPIClient instance

        @rtype: str
        @return: Success if the operation is successful
        """
        for profile in client_object.host_profile_manager_mor.profile:
            if profile.name == client_object.name:
                try:
                    profile.DestroyProfile()
                    return constants.Result.SUCCESS
                except Exception as e:
                    raise Exception("Could not destroy profile %r"
                                    % (client_object.name), e)

    @classmethod
    def _vswitch(cls, client_object, schema_object,
                 profile_config, profile):
        # This is where profile for vswitch will be created
        raise NotImplementedError

    @classmethod
    def update(cls, client_object, schema_object=None):
        category = schema_object.category
        network_device = schema_object.network_device
        profile_mor = client_object.host_profile_manager_mor
        for profile in profile_mor.profile:
            if profile.name == client_object.name:
                network = profile.config.applyProfile.network
                component = getattr(network, category)
                for device in component:
                    if device.name == network_device:
                        for policy in device.policy:
                            if policy.id == schema_object.policy_id:
                                method = getattr(cls, "_" + category)
                                method(client_object, schema_object,
                                       profile.config, policy)
                                # call the private method _category eg _vswitch
                                # implement logic there
        pylogger.error("Policy %r not found" % client_object.name)
