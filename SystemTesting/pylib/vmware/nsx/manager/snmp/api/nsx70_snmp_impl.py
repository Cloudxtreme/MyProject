import vmware.common.global_config as global_config
import vmware.interfaces.snmp_interface as snmp_interface
import pysnmp.entity.rfc3413.oneliner.cmdgen as cmdgen

pylogger = global_config.pylogger


class NSX70SNMPImpl(snmp_interface.SnmpInterface):

    @classmethod
    def _fetch_snmp_data(self, nsx_mgr_ip, community_string, mib_string, port):
        cmdGen = cmdgen.CommandGenerator()

        if mib_string == 'HOST-RESOURCES-MIB':
            error_indication, error_status, error_index, var_binds = \
                cmdGen.getCmd(
                    cmdgen.CommunityData(community_string),
                    cmdgen.UdpTransportTarget((nsx_mgr_ip, port)),
                    cmdgen.MibVariable(mib_string, 'hrSystemUptime', '0'),
                    cmdgen.MibVariable(mib_string, 'hrSystemDate', '0'),
                    cmdgen.MibVariable(mib_string, 'hrSystemInitialLoadDevice',
                                       '0'),
                    cmdgen.MibVariable(mib_string,
                                       'hrSystemInitialLoadParameters', '0'),
                    cmdgen.MibVariable(mib_string, 'hrSystemNumUsers', '0'),
                    cmdgen.MibVariable(mib_string, 'hrSystemProcesses', '0'),
                    cmdgen.MibVariable(mib_string, 'hrSystemMaxProcesses',
                                       '0'),
                    cmdgen.MibVariable(mib_string, 'hrMemorySize', '0'),
                    lookupNames=True, lookupValues=True)
            self._print_mib_info(error_indication, error_status, var_binds)
            return var_binds

        elif mib_string == 'SNMPv2-MIB':
            error_indication, error_status, error_index, var_binds = \
                cmdGen.getCmd(
                    cmdgen.CommunityData(community_string),
                    cmdgen.UdpTransportTarget((nsx_mgr_ip, port)),
                    cmdgen.MibVariable(mib_string, 'sysDescr', 0),
                    cmdgen.MibVariable(mib_string, 'sysObjectID', 0),
                    cmdgen.MibVariable(mib_string, 'sysUpTime', 0),
                    cmdgen.MibVariable(mib_string, 'sysContact', 0),
                    cmdgen.MibVariable(mib_string, 'sysName', 0),
                    cmdgen.MibVariable(mib_string, 'sysLocation', 0),
                    cmdgen.MibVariable(mib_string, 'sysServices', 0),
                    lookupNames=True, lookupValues=True)
            self._print_mib_info(error_indication, error_status, var_binds)
            return var_binds

        elif mib_string == 'IF-MIB':
            error_indication, error_status, error_index, var_binds = \
                cmdGen.getCmd(
                    cmdgen.CommunityData(community_string),
                    cmdgen.UdpTransportTarget((nsx_mgr_ip, port)),
                    cmdgen.MibVariable(mib_string, 'ifNumber', 0),
                    cmdgen.MibVariable(mib_string, 'ifDescr', 1),
                    cmdgen.MibVariable(mib_string, 'ifDescr', 2),
                    cmdgen.MibVariable(mib_string, 'ifDescr', 3),
                    cmdgen.MibVariable(mib_string, 'ifType', 1),
                    cmdgen.MibVariable(mib_string, 'ifType', 2),
                    cmdgen.MibVariable(mib_string, 'ifType', 3),
                    cmdgen.MibVariable(mib_string, 'ifMtu', 1),
                    cmdgen.MibVariable(mib_string, 'ifMtu', 2),
                    cmdgen.MibVariable(mib_string, 'ifMtu', 3),
                    cmdgen.MibVariable(mib_string, 'ifSpeed', 1),
                    cmdgen.MibVariable(mib_string, 'ifSpeed', 2),
                    cmdgen.MibVariable(mib_string, 'ifSpeed', 3),
                    cmdgen.MibVariable(mib_string, 'ifPhysAddress', 1),
                    cmdgen.MibVariable(mib_string, 'ifPhysAddress', 2),
                    cmdgen.MibVariable(mib_string, 'ifPhysAddress', 3),
                    cmdgen.MibVariable(mib_string, 'ifAdminStatus', 1),
                    cmdgen.MibVariable(mib_string, 'ifAdminStatus', 2),
                    cmdgen.MibVariable(mib_string, 'ifAdminStatus', 3),
                    cmdgen.MibVariable(mib_string, 'ifOperStatus', 1),
                    cmdgen.MibVariable(mib_string, 'ifOperStatus', 2),
                    cmdgen.MibVariable(mib_string, 'ifOperStatus', 3),
                    cmdgen.MibVariable(mib_string, 'ifLastChange', 1),
                    cmdgen.MibVariable(mib_string, 'ifLastChange', 2),
                    cmdgen.MibVariable(mib_string, 'ifLastChange', 3),
                    cmdgen.MibVariable(mib_string, 'ifInOctets', 1),
                    cmdgen.MibVariable(mib_string, 'ifInOctets', 2),
                    cmdgen.MibVariable(mib_string, 'ifInOctets', 3),
                    cmdgen.MibVariable(mib_string, 'ifInUcastPkts', 0),
                    cmdgen.MibVariable(mib_string, 'ifInNUcastPkts', 0),
                    cmdgen.MibVariable(mib_string, 'ifInDiscards', 0),
                    cmdgen.MibVariable(mib_string, 'ifInErrors', 0),
                    cmdgen.MibVariable(mib_string, 'ifInUnknownProtos', 0),
                    cmdgen.MibVariable(mib_string, 'ifOutOctets', 0),
                    cmdgen.MibVariable(mib_string, 'ifOutUcastPkts', 0),
                    cmdgen.MibVariable(mib_string, 'ifOutNUcastPkts', 0),
                    cmdgen.MibVariable(mib_string, 'ifOutDiscards', 0),
                    cmdgen.MibVariable(mib_string, 'ifOutErrors', 0),
                    cmdgen.MibVariable(mib_string, 'ifOutQLen', 0),
                    cmdgen.MibVariable(mib_string, 'ifSpecific', 0),
                    cmdgen.MibVariable(mib_string, 'ifOutDiscards', 0),
                    cmdgen.MibVariable(mib_string, 'ifOutDiscards', 0),
                    cmdgen.MibVariable(mib_string, 'ifOutDiscards', 0),
                    lookupNames=True, lookupValues=True)
            self._print_mib_info(error_indication, error_status, var_binds)
            return var_binds

    @classmethod
    def _print_mib_info(cls, error_indication, error_status, var_binds):
        if error_indication:
            print(error_indication)
        elif error_status:
            print(error_status)
        else:
            for name, val in var_binds:
                print('%s = %s' % (name.prettyPrint(), val.prettyPrint()))

    @classmethod
    def get_system_mib(cls, client_object, manager_ip,
                       **kwargs):
        result_system = cls.\
            _fetch_snmp_data(manager_ip, 'public', 'SNMPv2-MIB', 161)
        result_dict = dict()
        result_dict["snmp_response"] = dict()
        for name, value in result_system:
            result_dict["snmp_response"][name.prettyPrint()] \
                = value.prettyPrint()
        return result_dict

    @classmethod
    def get_hostresources_mib(cls, client_object, manager_ip,
                              **kwargs):
        result_hostresource = cls.\
            _fetch_snmp_data(manager_ip, 'public', 'HOST-RESOURCES-MIB', 161)
        result_dict = dict()
        result_dict["snmp_response"] = dict()
        for name, value in result_hostresource:
            result_dict["snmp_response"][name.prettyPrint()] \
                = value.prettyPrint()
        return result_dict

    @classmethod
    def get_interfaces_mib(cls, client_object, manager_ip,
                           **kwargs):
        result_interfaces = cls.\
            _fetch_snmp_sata(manager_ip, 'public', 'IF-MIB', 161)
        result_dict = dict()
        result_dict["snmp_response"] = dict()
        for name, value in result_interfaces:
            result_dict["snmp_response"][name.prettyPrint()] \
                = value.prettyPrint()
        return result_dict