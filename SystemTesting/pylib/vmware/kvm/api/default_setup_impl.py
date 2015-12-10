import lib.kvm as kvm
import lib.hypervisor as hypervisor
import vmware.interfaces.setup_interface as setup_interface
import vmware.common.global_config as global_config

pylogger = global_config.pylogger
kvm_objs = {}
REQUIRED_OVS_PKGS = ["openvswitch", "kmod-openvswitch"]


class DefaultSetupImpl(setup_interface.SetupInterface):
    # TODO(salmanm): This should be sourced from the user input yaml.
    DEFAULT_KVM_TEMPLATE = "template_kvm_debian"

    @classmethod
    def setup_3rd_party_library(cls, client_object=None):
        """
        Method to initilize mh qe/lib.

        @return kvm_obj: obj of the kvm host with client_object.ip
        """
        global kvm_objs
        if client_object.ip in kvm_objs:
            return kvm_objs[client_object.ip]
        kvm.Kvm.default_vm_template = cls.DEFAULT_KVM_TEMPLATE
        pylogger.debug("setup_3rd_party_library for %s %s %s " %
                       (client_object.ip, client_object.username,
                        client_object.password))
        host_keys_file = global_config.get_host_keys_file()
        pylogger.debug("Loading ssh known_hosts key from %r" % host_keys_file)
        kvm_obj = hypervisor.Hypervisor.get_hypervisor(
            client_object.ip, user=client_object.username,
            passwd=client_object.password, known_hosts_file=host_keys_file)
        kvm_obj.connect(user=client_object.username,
                        passwd=client_object.password,
                        sync_br_external_ids=False,
                        expected_ovs_pkgs=REQUIRED_OVS_PKGS, no_verify=True)
        kvm_objs[client_object.ip] = kvm_obj
        return kvm_obj
