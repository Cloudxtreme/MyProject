import vmware.common.global_config as global_config
import vmware.common.utilities as utilities
import vmware.interfaces.traffic_verification_interface as \
    traffic_verification_interface
import vmware.linux.cmd.linux_adapter_impl as linux_adapter_impl
import vmware.linux.linux_helper as linux_helper
import vmware.parsers.horizontal_table_parser as horizontal_table_parser

pylogger = global_config.configure_logger()
TSHARK = 'tshark'
# This is a workaround/hack to add appropriate TShark paths by sourcing the
# environment file, until we either add the hardcoded path in the VM template
# as other tools, or figure something else.
SOURCE_ENV_CMD = 'source /automation/main/environment >> /dev/null 2>&1'


class TSharkTrafficVerificationImpl(
        traffic_verification_interface.TrafficVerificationInterface):

    @classmethod
    def build_tool_command(cls, client_object, **kwargs):
        """
        Returns a working TShark binary from toolchain.
        To test that the binary is working, we just use a dummy command to
        print options using -h.

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host.
        @rtype: string
        @return: Path to a working TShark binary file if found, or None.
        """
        cmd = '%s; %s -h' % (SOURCE_ENV_CMD, TSHARK)
        if cls._run_command(client_object, cmd):
            return TSHARK
        else:
            pylogger.error('Failed to get TShark binary.')
            return None

    @classmethod
    def generate_capture_file_name(cls, client_object, **kwargs):
        """
        Returns a radom filename with a prefix tshark which will be used as
        a capture file.

        @rtype: string
        @return: A filename with prefix tshark.
        """
        return linux_helper.Linux.tempfile(prefix=TSHARK)

    @classmethod
    def start_capture(cls, client_object, file_name, adapter_name=None,
                      adapter_ip=None, capture_filter=None):
        """
        Starts the TShark capture process. The packets will be captured on the
        interface specified by adapter_name. If the adapter name is not
        specified, the adapter IP will be used to fetch the adapter name and
        the packets will be captured on the fetched interface. The method
        does not support providing both adapter IP and adapter name as input
        and considers it as an invalid input.
        Steps:
        1) Get path to a valid TShark binary on toolchain.
        2) Create a file on the host with the given filename/path.
        3) Create the command with the given options.
        4) Run the command to start the process.
        5) Return the result object.

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host.
        @type file_name: string
        @param file_name: Name/path of the capture file.
        @type adapter_name: string
        @param adapter_name: Interface to run the capture process.
        @type adapter_ip: string
        @param adapter_ip: Interface ip.
        @type capture_filter: string
        @param capture_filter: Capture filter to be used.
        @rtype: result.Result
        @return: Returns the Result object.
        """
        # Get TShark binary.
        tshark_bin = cls.build_tool_command(client_object)
        if not tshark_bin:
            return False
        # Create the capture file.
        linux_helper.Linux.create_file(client_object, file_name,
                                       overwrite=True)
        # Try to fetch the adapter name from adapter ip only if adapter name
        # is not specified and adapter ip is specified.
        if adapter_ip and adapter_name:
            raise AssertionError('Starting capture requires adapter name or '
                                 'IP, got both: name: %r, IP: %r' %
                                 (adapter_ip, adapter_name))
        if adapter_ip:
            ret = linux_adapter_impl.LinuxAdapterImpl.get_single_adapter_info(
                client_object, adapter_ip=adapter_ip)
            if 'name' in ret:
                adapter_name = ret['name']
        pylogger.info("TShark process will use %r as capture interface"
                      % adapter_name)
        # Create the command to start TShark.
        command = "%s; %s -i %s -w %s -n" % (SOURCE_ENV_CMD, tshark_bin,
                                             adapter_name, file_name)
        if capture_filter:
            command = "%s %s" % (command, capture_filter)
        # XXX(gangarm) Hack to run command in background using paramiko.
        command = "%s > /dev/null 2>&1 &" % command
        # Run the command and return the result.
        return cls._run_command(client_object, command)

    @classmethod
    def stop_capture(cls, client_object):
        """
        Kills TShark process.

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host.
        @rtype: bool
        @return: True if TShark killed successfully, else False.
        """
        # XXX(gangarm) Figure out how to obtain PIDs and use it to kill rather
        # than name. This will kill all tshark processes if multiple exist.
        return client_object.kill_processes_by_name(process_name=TSHARK)

    @classmethod
    def extract_capture_results(cls, client_object, file_name=None,
                                read_filter=None, **kwargs):
        """
        Extract the data captured by TShark.

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host.
        @type file_name: string
        @param file_name: Name/path of the capture file.
        @type read_filter: string
        @param read_filter: Read filter to use while reading the captured file.
        @rtype: Raw data if operation successful, can be None as well if there
                is no data.
        """
        command = "%s; %s -r %s -n" % (SOURCE_ENV_CMD, TSHARK, file_name)
        if read_filter:
            command = "%s %s" % (command, read_filter)
        res = client_object.connection.request(command, strict=False)
        if res.status_code:
            pylogger.error('Failure to run command: %s' % command)
            pylogger.error('Error: %s' % res.error)
            return False
        pylogger.info("Command %s ran successfully." % command)
        return res.response_data.strip()

    @classmethod
    def get_captured_packet_count(cls, client_object, file_name=None,
                                  stop_capture=None, **kwargs):
        """
        Determine the number of packets captured in a file.

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host.
        @type file_name: string
        @param file_name: Name/path of the capture file.
        @type stop_capture: boolean
        @param stop_capture: Flag indicating whether an attempt should be made
            to stop the capture process first.
        @rtype: dict
        @return: {'pktcount': <number of packets captured in given file>}
        """
        if stop_capture:
            if not cls.stop_capture(client_object):
                pylogger.error('Failed to stop TShark capture process.')
        raw_data = cls.extract_capture_results(client_object,
                                               file_name=file_name, **kwargs)
        return {'pktcount': len(raw_data.strip().splitlines())}

    @classmethod
    def delete_capture_file(cls, client_object, file_name=None):
        """
        Deletes the file created while capturing data.

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host.
        @type file_name: string
        @param file_name: Name/path of the capture file.
        @rtype: bool
        @return: True if file deleted successfully, else False.
        """
        return linux_helper.Linux.delete_file(client_object, file_name)

    @classmethod
    def _run_command(cls, client_object, command, strict=None):
        """
        Helper method to run given command.

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host.
        @type command: string
        @param command: Command to be executed.
        @rtype: bool
        @return: True if command executed successfully, else False.
        """
        if not strict:
            strict = False
        res = client_object.connection.request(command, strict=strict)
        if res.status_code:
            pylogger.error('Failure to run command: %s' % command)
            pylogger.error('Error: %s' % res.error)
            return False
        pylogger.info("Command %s ran successfully." % command)
        return True

    @classmethod
    def get_ipfix_capture_data(cls, client_object, file_name=None,
                               read_filter=None, port=None, stop_capture=None,
                               **kwargs):
        """
        Fetches the IPFIX data captured by TShark.

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host.
        @type file_name: string
        @param file_name: Name/path of the capture file.
        @type read_filter: string
        @param read_filter: Read filter to use while reading the captured file.
        @type port: integer
        @param port: port for which captured traffic will be decoded as cflow.
        @type stop_capture: boolean
        @param stop_capture: Flag indicating whether an attempt should be made
            to stop the capture process first.
        """
        attribute_map = {'cflow.od_id': 'domain_id',
                         'cflow.packets64': 'pktcount',
                         'cflow.srcmac': 'src_mac',
                         'cflow.dstmac': 'dst_mac',
                         'cflow.dstaddr': 'dst_ip',
                         'cflow.srcaddr': 'src_ip',
                         'cflow.ip_version': 'ip_version',
                         'cflow.protocol': 'protocol',
                         'cflow.srcaddrv6': 'src_ipv6',
                         'cflow.dstaddrv6': 'dst_ipv6',
                         'ip.src': 'exporter_ip',
                         'cflow.octets64': 'octets',
                         'cflow.length_min': 'min_length',
                         'cflow.length_max': 'max_length',
                         'cflow.flowset_id': 'flowset_id'}
        if stop_capture:
            if not cls.stop_capture(client_object):
                pylogger.error('Failed to stop TShark capture process.')
        if port:
            read_filter = "-d udp.port==%s,cflow %s" % (port, read_filter)
        raw_data = cls.extract_capture_results(
            client_object, file_name=file_name, read_filter=read_filter)
        # Handle missing elements in a table by adding NULL string for parsing.
        while "\t\t" in raw_data:
            raw_data = raw_data.replace("\t\t", "\tNULL\t")
        while "\n\t" in raw_data:
            raw_data = raw_data.replace("\n\t", "\nNULL\t")
        parser = horizontal_table_parser.HorizontalTableParser()
        parsed_data = parser.get_parsed_data(raw_data)
        return utilities.map_attributes(attribute_map, parsed_data)

    @classmethod
    def get_capture_data(cls, client_object, file_name=None,
                         read_filter=None, stop_capture=None,
                         attribute_map=None, **kwargs):
        """
        Returns the data captured by TShark from a file specified in the input
        param file_name based on the filters specified by the user in the
        read_filter input. The attribute_map is a hash that could be optionally
        specified by the user to map the name of an entry in the captured data
        to a user defined name. Currently implementation will allow the
        data to be captured in tabular format only using -T fields option
        provided by TShark.

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host.
        @type file_name: string
        @param file_name: Name/path of the capture file.
        @type read_filter: string
        @param read_filter: Read filter to use while reading the captured file.
            something as '-T fields -E header=y -e ip.src -e ip.dst'
        @type stop_capture: boolean
        @param stop_capture: Flag indicating whether an attempt should be made
            to stop the capture process first.
        @type attribute_map: dict
        @param attribute_map: map captured tshark attributes to user defined
            attributes.
        """
        # XXX(mbindal) Figure out other read filters in tshark packet capture.
        attribute_map = {'ip.dst': 'dst_ip',
                         'ip.src': 'src_ip',
                         'eth.src': 'eth_src_mac',
                         'eth.dst': 'eth_dst_mac',
                         'arp.src.proto_ipv4': 'arp_src_ip',
                         'arp.dst.proto_ipv4': 'arp_dst_ip',
                         'arp.src.hw_mac': 'arp_src_mac',
                         'arp.dst.hw_mac': 'arp_dst_mac',
                         'vlan.id': 'vlan_id',
                         'udp.srcport': 'udp_src_port',
                         'udp.dstport': 'udp_dst_port',
                         'tcp.srcport': 'tcp_srcport',
                         'tcp.dstport': 'tcp_dstport'}
        if stop_capture:
            if not cls.stop_capture(client_object):
                raise AssertionError('Failed to stop TShark capture process.')
        raw_data = cls.extract_capture_results(
            client_object, file_name=file_name, read_filter=read_filter)
        if '-T ' not in read_filter:
            raise AssertionError('Tabular format with -T required in '
                                 'read_filter, got: %r' % read_filter)
        # Handle missing elements in a table by adding NULL string for parsing.
        while "\t\t" in raw_data:
            raw_data = raw_data.replace("\t\t", "\tNULL\t")
        while "\n\t" in raw_data:
            raw_data = raw_data.replace("\n\t", "\nNULL\t")
        parser = horizontal_table_parser.HorizontalTableParser()
        parsed_data = parser.get_parsed_data(raw_data)
        result = utilities.map_attributes(attribute_map, parsed_data)
        if 'table' in result:
            result['table'].append(
                {'pktcount': len(raw_data.strip().splitlines())})
        return result
