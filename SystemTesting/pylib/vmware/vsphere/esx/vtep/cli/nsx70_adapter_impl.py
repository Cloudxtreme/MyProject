import json

import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.interfaces.adapter_interface as adapter_interface
import vmware.vsphere.esx.vtep.cli.nsx70_crud_impl as nsx70_crud_impl

pylogger = global_config.pylogger


class NSX70AdapterImpl(adapter_interface.AdapterInterface):

    @classmethod
    def get_adapter_ip(cls, client_object):
        """
        Returns the IP address of the adapter.
        """
        parsed_data = nsx70_crud_impl.NSX70CRUDImpl.get_adapter_info(
            client_object)
        for record in parsed_data['table']:
            if record['interface'] == client_object.id_:
                return record['ip']
        pylogger.warning('Did not find IP address for VTEP %r on %r' %
                         (client_object.id_, client_object.ip))

    @classmethod
    def get_adapter_mac(cls, client_object):
        """
        Returns the MAC address of the adapter.
        """
        parsed_data = nsx70_crud_impl.NSX70CRUDImpl.get_adapter_info(
            client_object)
        for record in parsed_data['table']:
            if record['interface'] == client_object.id_:
                return record['mac']
        pylogger.warning('Did not find a MAC address for VTEP %r on %r' %
                         (client_object.id_, client_object.ip))

    @classmethod
    def set_adapter_mtu(cls, client_object, mtu=1500):
        """
        Returns the MTU address of the adapter.
        """
        command = ("esxcli network ip interface set --mtu %s "
                   "--interface-name %s" % (mtu, client_object.id_))
        pylogger.info("setting vtep mtu command %s" % command)
        raw_data = client_object.connection.request(command).response_data
        raw_data = raw_data.strip()
        # successfully executed command output should return nothing
        if raw_data != "":
            pylogger.error("Error in setting vtep mtu command %s" % command)
            return constants.Result.FAILURE.upper()

        result = cls.get_adapter_mtu(client_object)
        if mtu != result:
            pylogger.error("Getting MTU %s is not same as setted MTU %s" %
                           (result, mtu))
            return constants.Result.FAILURE.upper()
        return constants.Result.SUCCESS.upper()

    @classmethod
    def get_adapter_mtu(cls, client_object):
        """
        Returns the MTU address of the adapter.
        """
        parsed_data = nsx70_crud_impl.NSX70CRUDImpl.get_adapter_info(
            client_object)
        for record in parsed_data['table']:
            if record['interface'] == client_object.id_:
                return record['mtu']
        pylogger.error('Did not find a MTU for VTEP %r on %r' %
                       (client_object.id_, client_object.ip))
        return constants.Result.FAILURE.upper()

    @classmethod
    def get_adapter_netstack(cls, client_object):
        """
        Returns the name of the adapter's netstack.
        """
        parsed_data = nsx70_crud_impl.NSX70CRUDImpl.get_adapter_info(
            client_object)
        for record in parsed_data['table']:
            if record['interface'] == client_object.id_:
                return record['netstack']
        pylogger.error('Did not find netstack for VTEP %r on %r' %
                       (client_object.id_, client_object.ip))
        return constants.Result.FAILURE.upper()

    @classmethod
    def get_port(cls, client_object):
        """
        Method to get the port to which vtep is connected
        """
        command = "esxcli --debug --formatter=json network ip interface \
                   list -N vxlan"
        vtep_list = client_object.connection.request(command).response_data
        vteps = json.loads(vtep_list)
        for vtep in vteps:
            if vtep['Name'] == client_object.id_:
                port = vtep['PortID']
                portset = vtep['Portset']
                pylogger.debug("portset for vtep %s is %s"
                               % (client_object.id_, portset))
                pylogger.debug("port id for vtep %s is %s"
                               % (client_object.id_, port))
                return portset, port
            else:
                continue
        pylogger.error("failed to get portID for vtep %s" % client_object.id_)
        return constants.Result.FAILURE.upper()

    @classmethod
    def get_team_pnic(cls, client_object, get_team_pnic=None):
        """
        Method to get the active pnic to which vtep is pinned
        """
        portset, port = cls.get_port(client_object)
        vsi = "/net/portsets/%s/ports/%s/teamUplink" % (portset, port)
        command = "vsish -e get %s" % (vsi)
        pnic = client_object.connection.request(command).response_data
        if pnic == "":
            pylogger.error("Failed to get teamuplink for port %s and vtep"
                           % (port, client_object.id_))
            return constants.Result.FAILURE.upper()
        py_dict = {'expected_pnic': pnic.rstrip()}
        return py_dict

    @classmethod
    def get_dvport(cls, client_object):
        """
        Returns the dv port of the vtep
        """
        parsed_data = nsx70_crud_impl.NSX70CRUDImpl.get_adapter_info(
            client_object)
        for record in parsed_data['table']:
            if record['interface'] == client_object.id_:
                return record['dvport']
        pylogger.warning('Did not find a dvport for VTEP %r on %r' %
                         (client_object.id_, client_object.ip))
