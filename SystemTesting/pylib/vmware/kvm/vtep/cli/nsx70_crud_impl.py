import vmware.kvm.ovs.bridge.cli.default_crud_impl as default_crud_impl
import vmware.common.global_config as global_config

pylogger = global_config.pylogger


class NSX70CRUDImpl(default_crud_impl.DefaultCRUDImpl):
    pass

    @classmethod
    def delete(cls, client_object, name=None):
        """
        Deletes the vtep on kvm host, this function will be achieved by
        deleting instance of OVS bridge on the host.

        @type client_object: BaseClient
        @param client_object: A CLI client that is used to pass the calls to
            the relevant host.
        """
        ret = {}
        ret['response_data'] = {}
        ret['response_data']['status_code'] = 200
        show_bridge_cmd = "ovs-vsctl iface-to-br %s" % name
        result = client_object.connection.request(show_bridge_cmd)
        if result.status_code:
            ret['response_data']['status_code'] = result.status_code
            pylogger.error('Failed to get bridge with iface id %r, received '
                           'error code %r: %r' % (name, result.status_code,
                                                  result.error))
        bridge_name = result.response_data.strip()
        ret = super(NSX70CRUDImpl, cls).delete(client_object, name=bridge_name)
        return ret
