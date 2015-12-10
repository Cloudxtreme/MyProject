import json
import time

import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.interfaces.adapter_interface as adapter_interface

pylogger = global_config.pylogger


class Error(Exception):
    """General local error"""
    pass


class ESX55AdapterImpl(adapter_interface.AdapterInterface):

    @classmethod
    def set_device_status(cls, client_object, status="up"):
        command = "esxcli network nic %s -n %s" % (status, client_object.name)
        print 'command before strip %s' % command
        command = command.strip('\n')
        print 'command after strip %s' % command
        pylogger.debug("command to set is %s" % command)
        result = client_object.connection.request(command).response_data
        if result != "":
            pylogger.error("Error while setting %s status to %s"
                           % (client_object.name, status))
            return constants.Result.FAILURE.upper()

        retry = 0
        while retry < 5:
            time.sleep(1)
            device_status = cls.get_device_status(client_object)
            pylogger.info("return device status is %s" % device_status)
            if status == device_status:
                return constants.Result.SUCCESS.upper()
            retry = retry + 1

        pylogger.error("Setting device status to %s failed \
                        current device status %s for adapter %s"
                       % (status, device_status, client_object.name))
        return constants.Result.FAILURE.upper()

    @classmethod
    def get_device_status(cls, client_object):
        command = "esxcli --debug --formatter=json network \
                   nic get -n %s" % (client_object.name)
        status = "Unknown"
        adapter = (client_object.connection.request(command).response_data)
        if adapter == "":
            pylogger.error("Error while getting the adapter status \
                            for %s" % (adapter))
        adapter = json.loads(adapter)
        if adapter['LinkDetected'] is False:
            status = "down"
        elif adapter['LinkDetected'] is True:
            status = "up"
        return status

    # VLAN Tx capability setting. When using hardware the VLAN header will be
    # stripped at driver level. If a test needs host packet capture including
    # VLAN header use software to avoid stripping the header and use pktcap-uw
    # with UplinkSnd capture point on Tx direction to see VLAN header.
    # TODO(jschmidt): Need a better location for product constants.
    CAP_VLAN_TX_SOFTWARE = 0
    CAP_VLAN_TX_HARDWARE = 1

    @classmethod
    def _get_cap_vlan_tx(cls, client_object):
        """Get the CAP_VLAN_TX hwCapabilities setting."""
        nic = client_object.name
        vsi_node = "/net/pNics/%s/hwCapabilities/CAP_VLAN_TX" % nic
        cmd = "vsish -e get %s" % vsi_node
        result = client_object.connection.request(cmd)
        cap_vlan_tx = result.response_data.strip()
        return cap_vlan_tx

    @classmethod
    def set_cap_vlan_tx(cls, client_object, enable=None):
        """
        Set the CAP_VLAN_TX hwCapabilities setting.

        @type enable: string
        @param enable: If 'true' or None, enable hardware VLAN capability.
            If 'false', use software emulation. Otherwise raise exception.
        @rtype: string
        @return: The CAP_VLAN_TX set by this method.
        """
        if enable is None or enable.lower() == 'true':
            value = cls.CAP_VLAN_TX_HARDWARE
        elif enable.lower() == 'false':
            value = cls.CAP_VLAN_TX_SOFTWARE
        else:
            raise Error("'enable' setting must be string 'true' or 'false', "
                        "got: %r" % enable)
        # Inspect the current value first. Setting to hardware again triggers a
        # command error. Setting to software multiple times does not yield a
        # command error.
        if ((value == cls.CAP_VLAN_TX_HARDWARE and
             cls._get_cap_vlan_tx(client_object) == str(value))):
            pylogger.debug("CAP_VLAN_TX capability already enabled")
        else:
            nic = client_object.name
            vsi_node = "/net/pNics/%s/hwCapabilities/CAP_VLAN_TX" % nic
            cmd = "vsish -e set %s %s" % (vsi_node, value)
            client_object.connection.request(cmd)
        return str(value)
