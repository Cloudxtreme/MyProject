#!/usr/bin/env python
import optparse
import pprint

import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.interfaces.labels as labels
import vmware.kvm.kvm as kvm
import vmware.kvm.api.kvm_api_client as kvm_api_client
import vmware.kvm.cli.kvm_cli_client as kvm_cli_client
import vmware.kvm.cmd.kvm_cmd_client as kvm_cmd_client

pylogger = global_config.pylogger
auto_resolve = base_facade.auto_resolve


class KVMFacade(kvm.KVM, base_facade.BaseFacade):
    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API

    def __init__(self, ip=None, username=None, password=None, version=None):
        super(KVMFacade, self).__init__(ip=ip, username=username,
                                        password=password, version=version)
        # instantiate client objects
        api_client = kvm_api_client.KVMAPIClient(
            ip=self.ip, username=self.username, password=self.password)
        cli_client = kvm_cli_client.KVMCLIClient(
            ip=self.ip, username=self.username, password=self.password)
        cmd_client = kvm_cmd_client.KVMCMDClient(
            ip=self.ip, username=self.username, password=self.password)
        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client,
                         constants.ExecutionType.CMD: cmd_client}

    @auto_resolve(labels.POWER, execution_type=constants.ExecutionType.CMD)
    def wait_for_reboot(self, execution_type=None, timeout=None, **kwargs):
        """
        Waits for reboot on the hypervisor.

        @type execution_type: str
        @param execution_type: Determines which client will be used to execute
            the method.
        @type timeout: int
        @param timeout: Value in seconds after the wait for reboot times out.
        """
        pass

    def req_call(self, cmd, **kwargs):
        raise NotImplementedError("Implementation required in client class")


if __name__ == "__main__":
    opt_parser = optparse.OptionParser()
    opt_parser.add_option('--kvm-ip', action='store', default='10.145.161.225',
                          help='IP of KVM hypervisor [%default*]')
    opt_parser.add_option('--kvm-user', action='store', default='root',
                          help='Username for logging into KVM [%default*]')
    opt_parser.add_option('--kvm-pass', action='store', default='default',
                          help='Password for logging into KVM [%default*]')
    options, args = opt_parser.parse_args()
    if None in (options.kvm_ip, options.kvm_user, options.kvm_pass):
        opt_parser.error('Missing KVM IP or user or pass')
    import vmware.kvm.kvm_facade as kvm_facade
    import vmware.kvm.ovs.bridge.bridge_facade as bridge_facade
    import vmware.kvm.ovs.port.port_facade as port_facade
    hc = kvm_facade.KVMFacade(ip=options.kvm_ip, username=options.kvm_user,
                              password=options.kvm_pass)
    hc.initialize()
    print hc.is_service_running(execution_type=constants.ExecutionType.CMD,
                                service_name=hc.get_nsx_switch_service_name())
    ubuntu_install_resources = [
        "http://apt.nicira.eng.vmware.com/builds/openvswitch32944/"
        "precise_amd64/nicira-ovs-hypervisor-node_2.0.1.32944_all.deb",
        "http://apt.nicira.eng.vmware.com/builds/openvswitch32944/"
        "precise_amd64/openvswitch-common_2.0.1.32944_amd64.deb",
        "http://apt.nicira.eng.vmware.com/builds/openvswitch32944/"
        "precise_amd64/openvswitch-datapath-dkms_2.0.1.32944_all.deb",
        "http://apt.nicira.eng.vmware.com/builds/openvswitch32944/"
        "precise_amd64/openvswitch-switch_2.0.1.32944_amd64.deb",
        "http://apt.nicira.eng.vmware.com/builds/openvswitch32944/"
        "precise_amd64/tcpdump-ovs_4.1.1.ovs2.0.1.32944_amd64.deb"]
    rhel_install_resources = [
        "http://apt.nicira.eng.vmware.com/builds/openvswitch32944/"
        "rhel64_x86_64/kmod-openvswitch-2.0.1.32944-1.el6.x86_64.rpm",
        "http://apt.nicira.eng.vmware.com/builds/openvswitch32944/"
        "rhel64_x86_64/nicira-ovs-hypervisor-node-2.0.1.32944-1.x86_64.rpm",
        "http://apt.nicira.eng.vmware.com/builds/openvswitch32944/"
        "rhel64_x86_64/nicira-ovs-hypervisor-node-debuginfo-2.0.1.32944-1"
        ".x86_64.rpm",
        "http://apt.nicira.eng.vmware.com/builds/openvswitch32944/"
        "rhel64_x86_64/openvswitch-2.0.1.32944-1.x86_64.rpm",
        "http://apt.nicira.eng.vmware.com/builds/openvswitch32944/"
        "rhel64_x86_64/openvswitch-debuginfo-2.0.1.32944-1.x86_64.rpm",
        "http://apt.nicira.eng.vmware.com/builds/openvswitch32944/"
        "rhel64_x86_64/tcpdump-ovs-4.1.1.ovs2.0.1.32944-1.x86_64.rpm"]
    ubuntu_packages = ["openvswitch-common", "openvswitch-dkms",
                       "openvswitch-switch", "nicira-ovs-hypervisor-node"]
    rhel_packages = ["openvswitch"]
    pylogger.debug("Hypervisor OS Version: %r" % hc.os_version)
    if hc.os_version == 'RHEL64':
        install_resources = rhel_install_resources
        packages = rhel_packages
    else:
        install_resources = ubuntu_install_resources
        packages = ubuntu_packages
    clear_firewall_rule = False
    try:
        hc.install(resource=install_resources)
        pylogger.info(
            "Open* packages installed: %s" %
            pprint.pformat(hc.are_installed(packages=packages)))
        ovs = bridge_facade.BridgeFacade(hc)
        name = ovs.create(schema={'name': 'test_br'})['name']
        ovs = bridge_facade.BridgeFacade(hc, name=name)
        port1 = port_facade.PortFacade(ovs)
        ovs.initialize()
        name = port1.create(schema={'name': 'eth1'})['name']
        port1 = port_facade.PortFacade(ovs, name=name)
        pylogger.info('eth1 port uuid: %r' % port1.get_uuid())
        pylogger.info('eth1 port number: %r' % port1.get_number())
        pylogger.info('eth1 port status: %r' % port1.get_status())
        pylogger.info('Attachments on port eth1: %r' % port1.get_attachment())
        pylogger.info(
            'Ports info on test_br:\n%s' %
            pprint.pformat(ovs.get_ports()))
        # Firewall Interface Tests
        pylogger.info('Firewall Rules List: %s' %
                      pprint.pformat(hc.list_firewall_rules()))
        pylogger.info('Adding Firewall Rule Result: %r' %
                      hc.add_firewall_rule(
                          chain='INPUT', protocol='udp',
                          protocol_options={'dport': 1111},
                          match_extensions={'comment_match_ext':
                                            {'comment': 'Doctest rule'}},
                          rule_num=1, action='ACCEPT'))
        clear_firewall_rule = True
        other = 'udp dpt:1111 /* Doctest rule */'
        pylogger.info('Firewall Rule Found: %s' %
                      pprint.pformat(hc.list_firewall_rules(
                          target='ACCEPT', other=other)))
        pylogger.info('Deleting Firewall Rule Result: %s' %
                      hc.delete_firewall_rule(
                          chain='INPUT', protocol='udp',
                          protocol_options={'dport': 1111},
                          match_extensions={'comment_match_ext':
                                            {'comment': 'Doctest rule'}},
                          action='ACCEPT'))
        clear_firewall_rule = False
    finally:
        pylogger.info("Cleaning up after the self test")
        port1.delete(name='eth1')
        ovs.delete(name='test_br')
        hc.uninstall(resource=packages)
        if clear_firewall_rule:
            pylogger.info('Deleting Firewall Rule Result: %s' %
                          hc.delete_firewall_rule(
                              chain='INPUT', protocol='udp',
                              protocol_options={'dport': 1111},
                              match_extensions={'comment_match_ext':
                                                {'comment': 'Doctest rule'}},
                              action='ACCEPT'))
    hc.reboot()
