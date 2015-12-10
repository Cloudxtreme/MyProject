import re


class DvsPortParser(object):
    """Parse net-dvs table and get logical port information."""

    @staticmethod
    def get_parsed_data(raw_data):
        r"""
        @param raw_data output from the CLI execution result

        @rtype: dict
        @return: a map of port data

        # net-dvs -l
        >>> import pprint
        >>> dvs_port_parser = DvsPortParser()
        >>> raw_data = ('switch b6 92 12 50 38 2c 99 5d-2a e4 56 c5 c6 fb e6 05 (etherswitch)\n'  # noqa
        ...     '        max ports: 1536\n'
        ...     '        global properties:\n'
        ...     '                com.vmware.common.alias = xxx ,         propType = CONFIG\n'  # noqa
        ...     '                com.vmware.common.version = 0x64. 0. 0. 0\n'
        ...     '                        propType = CONFIG\n'
        ...     '                com.vmware.common.opaqueDvs = true ,    propType = CONFIG\n'  # noqa
        ...     '                com.vmware.extraconfig.opaqueDvs.pnicZone = b2 92 12 50 38 2c 99 5d-2a e4 56 c5 c6 fb e6 03,b3 92 12 50 38 2c 99 5d-2a e4 56 c5 c6 fb e6 03,e3c0a389-6e5c-4398-a5a1-274a1061b2a4 ,      propType = CONFIG\n'  # noqa
        ...     '                com.vmware.extraconfig.opaqueDvs.status = up ,  propType = CONFIG\n'  # noqa
        ...     '                com.vmware.common.uplinkPorts:\n'
        ...     '                        uplink.1\n'
        ...     '                        propType = CONFIG\n'
        ...     '        host properties:\n'
        ...     '                com.vmware.common.host.portset = DvsPortset-0 ,         propType = CONFIG\n'  # noqa
        ...     '                com.vmware.common.host.volatile.status = green ,        propType = RUNTIME\n'  # noqa
        ...     '                com.vmware.common.portset.opaque = false ,      propType = RUNTIME\n'  # noqa
        ...     '                com.vmware.netoverlay.layer0 = vxlan ,  propType = CONFIG\n'  # noqa
        ...     '                com.vmware.common.host.uplinkPorts:\n'
        ...     '                        uplink1\n'
        ...     '                        propType = CONFIG\n'
        ...     '        port uplink1:\n'
        ...     '                com.vmware.common.port.alias = uplink.1 ,       propType = CONFIG\n'  # noqa
        ...     '                com.vmware.common.port.connectid = 0 ,  propType = CONFIG\n'  # noqa
        ...     '                com.vmware.common.port.volatile.status = free\n'  # noqa
        ...     '                com.vmware.common.port.volatile.vlan = VLAN 0\n'  # noqa
        ...     '                        propType = RUNTIME VOLATILE\n'
        ...     '                com.vmware.common.port.portgroupid =  ,         propType = CONFIG\n'  # noqa
        ...     '        port 00931351-392d-905d-2ae4-56c5c6fbe604:\n'
        ...     '                com.vmware.common.port.alias =  ,       propType = CONFIG\n'  # noqa
        ...     '                com.vmware.common.port.connectid = 10 ,         propType = CONFIG\n'  # noqa
        ...     '                com.vmware.common.port.volatile.vlan = VLAN 0\n'  # noqa
        ...     '                        propType = RUNTIME VOLATILE\n'
        ...     '                com.vmware.common.port.portgroupid =  ,         propType = CONFIG\n'  # noqa
        ...     '                com.vmware.etherswitch.port.lacp:\n'
        ...     '                        status = enabled\n'
        ...     '                        mode = active\n'
        ...     '                com.vmware.common.port.volatile.persist = /vmfs/volumes/a5c08a61-60834ec4/rhel6.1_32T3/.dvsData/b6 92 12 50 38 2c 99 5d-2a e4 56 c5 c6 fb e6 05/00931351-392d-905d-2ae4-56c5c6fbe604 ,    propType = CONFIG\n'  # noqa
        ...     '                com.vmware.port.extraConfig.vnic.external.id = 02931351-392d-905d-2ae4-56c5c6fbe604 ,   propType = CONFIG\n'  # noqa
        ...     '                com.vmware.port.opaque.network.id = b4 92 12 50 38 2c 99 5d-2a e4 56 c5 c6 fb e6 04 ,   propType = RUNTIME\n'  # noqa
        ...     '                com.vmware.port.opaque.network.type = nsx.LogicalSwitch ,       propType = RUNTIME\n'  # noqa
        ...     '                com.vmware.common.port.block = false ,  propType = CONFIG\n'  # noqa
        ...     '                com.vmware.common.port.ptAllowedRT = 0x 0. 0. 0. 0\n'  # noqa
        ...     '                        propType = RUNTIME\n'
        ...     '                com.vmware.common.port.ptAllowed = 0x 0. 0. 0. 0\n'  # noqa
        ...     '                        propType = CONFIG\n'
        ...     '                com.vmware.net.vxlan.cp = 0x 0. 0. 0. 1\n'
        ...     '                        propType = CONFIG POLICY\n'
        ...     '                com.vmware.net.vxlan.id = 0x 0. 0. 0.7f\n'
        ...     '                        propType = CONFIG POLICY\n'
        ...     '                com.vmware.common.port.dvfilteraltvmx = 0x31.3a.64.76.66.69.6c.74.65.72.2d.67.65.6e.65.72.69.63.2d.76.6d.77.61.72.65.2d.73.77.73.65.63.3a.66.61.69.6c.43.6c.6f.73.65.64\n'  # noqa
        ...     '                        propType = CONFIG POLICY\n'
        ...     '                dvfilter-generic-vmware-swsec.config = 0x 1.18. 0. 0. 0.20. 0. 0. 0. 0. 0. 0. 0. 0. 0. 0. 0. 0. 0. 0. 0. 0. 0. 0. 0. 0. 0. 0. 0\n'  # noqa
        ...     '                        propType = CONFIG POLICY\n'
        ...     '                com.vmware.common.port.shaper.input:\n'
        ...     '                        average bandwidth = 12500000 bytes/sec\n'  # noqa
        ...     '                        peak bandwidth = 25000000 bytes/sec\n'
        ...     '                        burst size = 128000 bytes\n'
        ...     '                        propType = CONFIG\n'
        ...     '                com.vmware.net.vxlan.traffic.marking = 0x 0.20. 5. 0\n'  # noqa
        ...     '                        propType = CONFIG POLICY\n'
        ...     '                com.vmware.common.port.volatile.status = inUse linkUp portID=50331653\n'  # noqa
        ...     '                        propType = RUNTIME\n'
        ...     '                com.vmware.common.port.volatile.ptstatus = noPassthruReason=4,  propType = RUNTIME\n'  # noqa
        ...     '                com.vmware.common.port.statistics:\n'
        ...     '                        pktsInUnicast = 0\n'
        ...     '                        bytesInUnicast = 0\n'
        ...     '                        pktsInMulticast = 6\n'
        ...     '                        bytesInMulticast = 468\n'
        ...     '                        pktsInBroadcast = 5\n'
        ...     '                        bytesInBroadcast = 1710\n'
        ...     '                        pktsOutUnicast = 0\n'
        ...     '                        bytesOutUnicast = 0\n'
        ...     '                        pktsOutMulticast = 0\n'
        ...     '                        bytesOutMulticast = 0\n'
        ...     '                        pktsOutBroadcast = 1\n'
        ...     '                        bytesOutBroadcast = 60\n'
        ...     '                        pktsInDropped = 0\n'
        ...     '                        pktsOutDropped = 0\n'
        ...     '                        pktsInException = 0\n'
        ...     '                        pktsOutException = 0\n'
        ...     '                        propType = RUNTIME')
        >>> pprint.pprint(dvs_port_parser.get_parsed_data(raw_data), width=72)
        {'table': [{'port': 'uplink1'},
                   {'average_bandwidth': '12500000',
                    'burst_size': '128000',
                    'class_of_service': '5',
                    'dscp': '20',
                    'external_id': '02931351-392d-905d-2ae4-56c5c6fbe604',
                    'mode': 'untrusted',
                    'network_id': 'b4 92 12 50 38 2c 99 5d-2a e4 56 c5 c6 ...',
                    'peak_bandwidth': '25000000',
                    'port': '00931351-392d-905d-2ae4-56c5c6fbe604'}]}
        """
        PORT = "port"
        PORT_RE = r"\s+port (\S+):.*"
        EXTERNAL_ID = "external_id"
        EXTERNAL_ID_RE = r"\s+com.vmware.port.extraConfig.vnic.external.id = (\S+) .*"  # noqa
        NETWORK_ID = "network_id"
        NETWORK_ID_RE = r"\s+com.vmware.port.opaque.network.id = (.+) , .*"
        SHAPER = "shaper"
        SHAPER_RE = r"\s+com.vmware.common.port.shaper.input:"
        AVG_BW = "average_bandwidth"
        AVG_BW_RE = r"\s+average bandwidth = (\d+) bytes/sec"
        PEAK_BW = "peak_bandwidth"
        PEAK_BW_RE = r"\s+peak bandwidth = (\d+) bytes/sec"
        BURST_SIZE = "burst_size"
        BURST_SIZE_RE = r"\s+burst size = (\d+) bytes"
        MARKING_RE = r"\s+com.vmware.net.vxlan.traffic.marking = 0x (.*)"
        TRUSTED_MODE = "mode"
        TRUSTED_MODES = {'0': 'untrusted', '1': 'trusted'}
        DSCP = "dscp"
        COS = "class_of_service"
        PROPTYPE_RE = r"\s+propType = (.*)"

        parsed_data = {}
        lines = raw_data.strip().split("\n")

        port_dicts = []
        port_dict = None
        port = None  # current record during parse
        state = PORT
        for line in lines:
            # Ignore all global, host, and other non-port properties. Include
            # all ports regardless of switch association.
            m = re.match(PORT_RE, line)
            if m:
                # New port match found, create new record.
                port = m.group(1)
                if port_dict:
                    port_dicts.append(port_dict)
                port_dict = {}
                port_dict[PORT] = port
                state = PORT
                continue
            # No port found, keep looking.
            if not port:
                continue
            if state == PORT:
                m = re.match(EXTERNAL_ID_RE, line)
                if m:
                    port_dict[EXTERNAL_ID] = m.group(1)
                    continue
                m = re.match(NETWORK_ID_RE, line)
                if m:
                    port_dict[NETWORK_ID] = m.group(1)
                    continue
                m = re.match(SHAPER_RE, line)
                if m:
                    state = SHAPER
                    continue
                m = re.match(MARKING_RE, line)
                if m:
                    data = m.group(1).split(".")
                    trusted_mode = data[0].strip()
                    if trusted_mode not in TRUSTED_MODES:
                        raise ValueError("Unknown DSCP Trust mode: %r" %
                                         trusted_mode)
                    else:
                        port_dict[TRUSTED_MODE] = TRUSTED_MODES[trusted_mode]
                    port_dict[DSCP] = data[1].strip()
                    port_dict[COS] = data[2].strip()
            elif state == SHAPER:
                m = re.match(AVG_BW_RE, line)
                if m:
                    port_dict[AVG_BW] = m.group(1)
                    continue
                m = re.match(PEAK_BW_RE, line)
                if m:
                    port_dict[PEAK_BW] = m.group(1)
                    continue
                m = re.match(BURST_SIZE_RE, line)
                if m:
                    port_dict[BURST_SIZE] = m.group(1)
                    continue
                m = re.match(PROPTYPE_RE, line)
                if m:
                    state = PORT
                    continue
        if port_dict:
            port_dicts.append(port_dict)

        parsed_data = {'table': port_dicts}
        return parsed_data


if __name__ == '__main__':
    import doctest
    doctest_opts = (doctest.ELLIPSIS | doctest.NORMALIZE_WHITESPACE)
    doctest.testmod(optionflags=doctest_opts)
