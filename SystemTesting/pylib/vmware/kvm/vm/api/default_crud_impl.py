import vmware.common.global_config as global_config
import vmware.interfaces.crud_interface as crud_interface

pylogger = global_config.pylogger


class DefaultCRUDImpl(crud_interface.CRUDInterface):
    """Impl class for VM related CRUD operations."""

    @classmethod
    def create(cls, client_object, template=None, name=None,
               linked_clone=None):
        ''' Method to create/clone a VM on the kvm host

        @type template: string
        @param template: name of the VM template image
        @type name: string
        @param name: name of the VM to be cloned
        @type linked_clone: boolean
        @param linked_clone: Flag to use qcow2 for linked clones or just raw
                             disk images for full clones
        '''

        kvm = client_object.kvm
        kvm.default_vm_template = template
        pylogger.info("Cloning %s from template %s" % (name,
                      kvm.default_vm_template))
        # XXX(salmanm): Disabling addition of iptables rule to enable vnc
        # access for the VM so as to allow parallel deployment. Since vdnet's
        # setup script disables the host firewall anyway, we don't need a rule.
        ret = kvm.VM.check_clone(template, name=name, add_vnc_rule=False,
                                 linked_clone=linked_clone)
        pylogger.info("vm obj is %r" % ret)
        return ret

    @classmethod
    def read(cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def update(cls, client_object, schema=None, **kwargs):
        raise NotImplementedError

    @classmethod
    def delete(cls, client_object):
        return client_object.vm.destroy()
