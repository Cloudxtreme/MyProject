import vmware.vsphere.vc.profile.profile as profile
import vmware.vsphere.vsphere_client as vsphere_client

import pyVmomi as pyVmomi

vim = pyVmomi.vim
vmodl = pyVmomi.vmodl


class ProfileAPIClient(profile.Profile, vsphere_client.VSphereAPIClient):

    def __init__(self, name, parent=None):
        super(ProfileAPIClient, self).__init__(parent=parent)
        self.name = name
        self.parent = parent
        self.hostprofile_mor = None
        self.host_profile_manager_mor = self.get_host_profile_manager_mor()

    def get_host_profile_manager_mor(self):
        content = self.connection.anchor.RetrieveContent()
        return content.hostProfileManager

    def get_profile_compliance_manager(self):
        content = self.connection.anchor.RetrieveContent()
        return content.complianceManager

    def get_profile_spec(self, **kwargs):
        spec = vim.profile.host.HostProfile.HostBasedConfigSpec()
        spec.host = kwargs.get('host_mor')
        spec.useHostProfileEngine = True
        if kwargs.get('annotation') is not None:
            spec.annotation = kwargs.get('annotation')
        if kwargs.get('enabled') is not None:
            spec.enabled = kwargs.get('enabled')
        if kwargs.get('name') is not None:
            spec.name = kwargs.get('name')
        return spec

    def get_answer_file_option_create(self, **kwargs):
        spec = vim.profile.host.ProfileManager.AnswerFileOptionsCreateSpec()
        deferred_policy = self.get_deferred_policy_option(**kwargs)
        if deferred_policy is not None:
            spec.userInput = [deferred_policy]
        return spec

    def get_deferred_policy_option(self, **kwargs):
        profile_property = vim.profile.ProfilePropertyPath()
        if kwargs.get('parameter_id') is not None:
            profile_property.profilePath = kwargs.get('parameter_id')
        if kwargs.get('policy_id') is not None:
            profile_property.policyId = kwargs.get('policy_id')
        profile_property.profilePath = kwargs.get('profile_path')
        deferred_policy = vim.profile.DeferredPolicyOptionParameter()
        deferred_policy.inputPath = profile_property
        if(kwargs.get('parameter_keys') is not None and
           kwargs.get('parameter_values') is not None):
            keys = kwargs.get('parameter_keys')
            values = kwargs.get('parameter_values')
            pairs = []
            for i in xrange(len(keys)):
                pair = vmodl.KeyAnyValue()
                pair.key = keys[i]
                pair.value = values[i]
                pairs.append(pair)
            deferred_policy.parameter = pairs
        return deferred_policy
