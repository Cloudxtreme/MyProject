import vmware.parsers.application_process_parser\
    as application_process_parser
import vmware.parsers.application_version_parser\
    as application_version_parser
import vmware.parsers.cluster_node_parser as cluster_node_parser
import vmware.parsers.edge_cli_json_parser\
    as edge_cli_json_parser
import vmware.parsers.edge_cluster_status_parser\
    as edge_cluster_status_parser
import vmware.parsers.show_cert_thumbprint_parser\
    as show_cert_thumbprint_parser
import vmware.parsers.flat_vertical_table_parser\
    as flat_vertical_parser
import vmware.parsers.horizontal_table_parser\
    as horizontal_table_parser
import vmware.parsers.list_interfaces_parser\
    as list_interfaces_parser
import vmware.parsers.list_users_parser\
    as list_users_parser
import vmware.parsers.list_vhosts_parser\
    as list_vhosts_parser
import vmware.parsers.list_exchanges_parser\
    as list_exchanges_parser
import vmware.parsers.list_permissions_parser\
    as list_permissions_parser
import vmware.parsers.list_processes_parser\
    as list_processes_parser
import vmware.parsers.list_user_permissions_parser\
    as list_user_permissions_parser
import vmware.parsers.list_bindings_parser\
    as list_bindings_parser
import vmware.parsers.list_channels_parser\
    as list_channels_parser
import vmware.parsers.list_commands_parser\
    as list_commands_parser
import vmware.parsers.list_connections_parser\
    as list_connections_parser
import vmware.parsers.list_consumers_parser\
    as list_consumers_parser
import vmware.parsers.list_logfiles_parser\
    as list_logfiles_parser
import vmware.parsers.list_queues_parser\
    as list_queues_parser
import vmware.parsers.list_services_parser\
    as list_services_parser
import vmware.parsers.netvdl2_logicalswitch_parser\
    as netvdl2_logicalswitch_parser
import vmware.parsers.nsx_controller_parser\
    as nsx_controller_parser
import vmware.parsers.netvdl2_table_parser\
    as netvdl2_table_parser
import vmware.parsers.ping_host_parser\
    as ping_host_parser
import vmware.parsers.show_auth_parser\
    as show_auth_parser
import vmware.parsers.show_clock_parser\
    as show_clock_parser
import vmware.parsers.show_cluster_status_parser\
    as show_cluster_status_parser
import vmware.parsers.show_file_presence_parser\
    as show_file_presence_parser
import vmware.parsers.show_file_systems_parser\
    as show_file_systems_parser
import vmware.parsers.show_hostname_parser\
    as show_hostname_parser
import vmware.parsers.show_ip_route_parser\
    as show_ip_route_parser
import vmware.parsers.show_nsx_configuration_parser\
    as show_nsx_configuration_parser
import vmware.parsers.show_password_parser\
    as show_password_parser
import vmware.parsers.show_version_parser\
    as show_version_parser
import vmware.parsers.show_interface_nsx_parser\
    as show_interface_nsx_parser
import vmware.parsers.show_interfaces_nsx_parser\
    as show_interfaces_nsx_parser
import vmware.parsers.show_traceroute_parser\
    as show_traceroute_parser
import vmware.parsers.system_date_parser\
    as system_date_parser
import vmware.parsers.vertical_table_parser\
    as vertical_table_parser
import vmware.parsers.netdvs_port_parser\
    as netdvs_port_parser
import vmware.parsers.show_interface_parser\
    as show_interface_parser
import vmware.parsers.show_system_config_parser\
    as show_system_config_parser
import vmware.parsers.show_edge_version_parser\
    as show_edge_version_parser
import vmware.parsers.show_process_monitor_parser\
    as show_process_monitor_parser
import vmware.parsers.system_meminfo_parser\
    as system_meminfo_parser
import vmware.parsers.netdvs_teaming_parser\
    as netdvs_teaming_parser
import vmware.parsers.get_bpg_neighbors_parser as get_bpg_neighbors_parser


def get_data_parser(parser_key):

    # Hashmap of data-parsers
    data_parsers = {'raw/applicationProcess': application_process_parser.ApplicationProcessParser,  # noqa
                    'raw/applicationVersion': application_version_parser.ApplicationVersionParser,  # noqa
                    'raw/horizontalTable': horizontal_table_parser.HorizontalTableParser,  # noqa
                    'raw/verticalTable': vertical_table_parser.VerticalTableParser,  # noqa
                    'raw/jsonCli': edge_cli_json_parser.EdgeCliJsonParser,  # noqa
                    'raw/netvdl2LogicalSwitch': netvdl2_logicalswitch_parser.Vdl2LogicalSwitchParser,  # noqa
                    'raw/nsxController': nsx_controller_parser.NsxControllerParser,  # noqa
                    'raw/listUsers': list_users_parser.ListUsersParser,  # noqa
                    'raw/listUserPermissions': list_user_permissions_parser.ListUserPermissionsParser,  # noqa
                    'raw/listPermissions': list_permissions_parser.ListPermissionsParser,  # noqa
                    'raw/listProcesses': list_processes_parser.ListProcessesParser,  # noqa
                    'raw/listQueues': list_queues_parser.ListQueuesParser,  # noqa
                    'raw/listExchanges': list_exchanges_parser.ListExchangesParser,  # noqa
                    'raw/listBindings': list_bindings_parser.ListBindingsParser,  # noqa
                    'raw/listChannels': list_channels_parser.ListChannelsParser,  # noqa
                    'raw/listCommands': list_commands_parser.ListCommandsParser,  # noqa
                    'raw/listConnections': list_connections_parser.ListConnectionsParser,  # noqa
                    'raw/listConsumers': list_consumers_parser.ListConsumersParser,  # noqa
                    'raw/listHosts': list_vhosts_parser.ListvHostsParser,  # noqa
                    'raw/listInterfaces': list_interfaces_parser.ListInterfacesParser,  # noqa
                    'raw/listLogFiles': list_logfiles_parser.ListLogFilesParser,  # noqa
                    'raw/flatverticalTable': flat_vertical_parser.FlatVerticalTableParser,  # noqa
                    'raw/pingHost': ping_host_parser.PingHostParser,  # noqa
                    'raw/showTacacsServerAuth': show_auth_parser.ShowAuthParser,  # noqa
                    'raw/showClusterParser': show_cluster_status_parser.ShowClusterParser,  # noqa
                    'raw/ShowFilePresenceParser': show_file_presence_parser.ShowFilePresenceParser,  # noqa
                    'raw/showFileSystemsParser': show_file_systems_parser.ShowFileSystemsParser,  # noqa
                    'raw/showHostname': show_hostname_parser.ShowHostnameParser,  # noqa
                    'raw/showinterface': show_interface_parser.ShowInterfaceParser,  # noqa
                    'raw/showIpRoute': show_ip_route_parser.ShowIpRouteParser,  # noqa
                    'raw/showNSXConfiguration': show_nsx_configuration_parser.ShowNSXConfigurationParser,  # noqa
                    'raw/showVersion': show_version_parser.ShowVersionParser,  # noqa
                    'raw/showEdgeVersion': show_edge_version_parser.ShowEdgeVersionParser,  # noqa
                    'raw/showInterfaceNSX': show_interface_nsx_parser.ShowInterfaceNSXParser,  # noqa
                    'raw/showInterfacesNSX': show_interfaces_nsx_parser.ShowInterfacesNSXParser,  # noqa
                    'raw/showApiCertificate': show_cert_thumbprint_parser.ShowCertThumbprintParser,  # noqa
                    'raw/ShowPasswordParser': show_password_parser.ShowPasswordParser,  # noqa
                    'raw/showSystemConfig': show_system_config_parser.ShowSystemConfig,  # noqa
                    'raw/showTraceRoute': show_traceroute_parser.ShowTraceRouteParser,  # noqa
                    'raw/vnistatsverticalTable': flat_vertical_parser.VniStatsVerticalTableParser,  # noqa
                    'raw/vdl2ArpTable': netvdl2_table_parser.Vdl2ArpTableParser,  # noqa
                    'raw/vdl2MacTable': netvdl2_table_parser.Vdl2MacTableParser,  # noqa
                    'raw/vdl2VtepTable': netvdl2_table_parser.Vdl2VtepTableParser,  # noqa
                    'raw/listServices': list_services_parser.ListServicesParser,  # noqa
                    'raw/clusternodes': cluster_node_parser.ClusterNodeParser,  # noqa
                    'raw/netdvsPort': netdvs_port_parser.DvsPortParser,         # noqa
                    'raw/showClock': show_clock_parser.ShowClockParser,  # noqa
                    'raw/showedgeclusterstatus': edge_cluster_status_parser.EdgeClusterStatusParser,  # noqa
                    'raw/sysDate': system_date_parser.SystemDateParser,  # noqa
                    'raw/showBgpNeighbors': get_bpg_neighbors_parser.GetBGPNeighbors,  # noqa
                    'raw/showProcessMonitor': show_process_monitor_parser.ShowProcessMonitorParser,  # noqa
                    'raw/netdvsTeaming':  netdvs_teaming_parser.TeamingParser,  # noqa
                    'raw/systemMeminfo': system_meminfo_parser.SystemMeminfoParser}  # noqa
    return data_parsers[parser_key]()
