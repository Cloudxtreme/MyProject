########################################################################
# Copyright (C) 2014 VMware, Inc.
# # All Rights Reserved
########################################################################

""" This is a standalone script for the different vsphere utilities."""

import logging
import re
import scripts.nsx_network as nsx_network
import ssl
import time
from pyVmomi import Vim, SoapStubAdapter
import eventlet
from eventlet.green import subprocess
from subprocess import PIPE, STDOUT

eventlet.monkey_patch()


def run_command(command, returnObject=False, maxTimeout=300, shell=False,
                splitCommand=True):
    log = logging.getLogger('vdnet')
    if splitCommand:
        cmd = command.split(' ')
    else:
        cmd = command
    log.debug('command : %s' % cmd)
    p = None
    if returnObject:
        p = subprocess.Popen(cmd, shell=shell, stdout=PIPE, stderr=STDOUT)
    else:
        try:
            (returncode, stdout, stderr) = eventlet.timeout.with_timeout(
                maxTimeout, run_command_sync, cmd)
            log.debug('returncode: %s' % returncode)
            log.debug('stdout : %s' % stdout)
            log.debug('stderr : %s' % stderr)
            return (returncode, stdout, stderr)
        except eventlet.Timeout:
            log.debug("Hit timeout while running command: %s" % cmd)
            return (-1, None, None)
    return p


def run_command_sync(command, stdout=PIPE, stderr=STDOUT, shell=False):
    """ Routine to run command in sync mode

    @param command: command to run
    @param stdout: file handle for stdout
    @param stderr: file handle for stderr
    @return tuple: (returncode, stdout, stderr)
    """
    p = subprocess.Popen(command, shell=shell, stdout=stdout, stderr=stderr)
    stdout, stderr = p.communicate()
    return (p.returncode, stdout, stderr)


def get_standalone_vm_ip(esx_ip, esx_user, esx_password, vm_name):
    """ function to get ip address of standalone vm which is accessible

    @param esx_ip: IP of esx on which vm is running
    @param esx_user: User of esx on which vm is running
    @param esx_password: Password of esx on which vm is running
    @param vm_name: name of the vm
    @return ip address of the vm
    """
    log = logging.getLogger('vdnet')

    if esx_user is None:
        log.info("Using default username 'root' for esx")
        esx_user = 'root'
    if esx_password is None:
        log.info("Using default password 'ca$hc0w' for esx")
        esx_password = 'ca$hc0w'

    vm = get_standalone_vm_by_name(esx_ip, esx_user, esx_password, vm_name)
    if not vm or vm is None:
        log.info("Not able to find vm %s, probably never deployed" % vm_name)
        return None
    summary = vm.summary
    # check if the vm is powered on
    if summary.runtime.powerState != 'poweredOn':
        log.info("VM %s not in powerdOn state: %s. Powering on the VM" %
                 (vm_name, vm.runtime.powerState))
        vm.PowerOnVM_Task()
    timeout = 1200
    sleepTime = 10
    while timeout > 0:
        log.info("Getting vmware tools status for vm %s\n" % vm_name)
        if vm.guest.toolsRunningStatus == 'guestToolsRunning':
            break
        time.sleep(sleepTime)
        timeout = (timeout - sleepTime)

    # look for all ip addresses exposed by the guest
    # and select the one that is reachable
    timeout = 240
    sleepTime = 10
    while timeout > 0:
        for net_info in vm.guest.net:
            if net_info is None or net_info.ipConfig is None:
                log.info("net_info not defined, probably tools not running \
                         for vm %s" % vm_name)
                break
            for entry in net_info.ipConfig.ipAddress:
                match = re.match("\d+.\d+.\d+.\d+", entry.ipAddress)
                if match:
                    cmd = "ping -c 1 -t 60 %s 2>&1 > /dev/null" \
                        % entry.ipAddress
                    (result, stdout, stderr) = run_command_sync(cmd,
                                                                shell=True)
                    if result == 0:
                        return entry.ipAddress

        # check if summary has ip address information
        if vm.summary.guest.ipAddress \
           and vm.summary.guest.ipAddress != '127.0.0.1' and \
           not re.match("169.254.[0-9]*.[0-9]*", vm.summary.guest.ipAddress):
            return vm.summary.guest.ipAddress
        time.sleep(sleepTime)
        timeout = (timeout - sleepTime)

    log.info("No ip address found for vm %s\n" % vm_name)
    return None


def get_standalone_vm_by_name(esx_ip, esx_user, esx_password, vm_name):
    """ function to get vm mor object

    @param esx_ip: IP of esx on which vm is running
    @param esx_user: User of esx on which vm is running
    @param esx_password: Password of esx on which vm is running
    @param vm_name: Name of the VM
    @return MOR for the given vm option
    """
    log = logging.getLogger('vdnet')

    if esx_user is None:
        log.info("Using default username 'root' for esx")
        esx_user = 'root'
    if esx_password is None:
        log.info("Using default password 'ca$hc0w' for esx")
        esx_password = 'ca$hc0w'

    hosts = get_esx_host(esx_ip, esx_user, esx_password)
    if hosts is None:
        return None
    for host in hosts:
        for vm in host.vm:
            if vm.name == vm_name:
                return vm
    return None


def get_esx_host_content(esx_ip, esx_user, esx_password):
    """ function to get content object of given esx host

    @param esx_ip: IP of esx on which vm is running
    @param esx_user: User of esx on which vm is running
    @param esx_password: Password of esx on which vm is running
    @return esx host content object
    """
    log = logging.getLogger('vdnet')

    if esx_user is None:
        log.info("Using default username 'root' for esx")
        esx_user = 'root'
    if esx_password is None:
        log.info("Using default password 'ca$hc0w' for esx")
        esx_password = 'ca$hc0w'

    stub = SoapStubAdapter(host=esx_ip, port=443, path="/sdk",
                           version="vim.version.version7")
    service_instance = Vim.ServiceInstance("ServiceInstance", stub)
    if not service_instance:
        log.info("serviceInstance not defined for esx %s" % esx_ip)
    content = service_instance.RetrieveContent()
    if not content:
        log.info("content not defined for esx %s" % esx_ip)
    content.sessionManager.Login(esx_user, esx_password)
    return content


def get_esx_host(esx_ip, esx_user, esx_password):
    """ function to get esx managed object reference

    @param esx_ip: IP of esx on which vm is running
    @param esx_user: User of esx on which vm is running
    @param esx_password: Password of esx on which vm is running
    @return MOR for the given esx option
    """
    log = logging.getLogger('vdnet')

    if esx_user is None:
        log.info("Using default username 'root' for esx")
        esx_user = 'root'
    if esx_password is None:
        log.info("Using default password 'ca$hc0w' for esx")
        esx_password = 'ca$hc0w'

    content = get_esx_host_content(esx_ip, esx_user, esx_password)
    rootFolder = content.rootFolder
    for haDatacenter in rootFolder.childEntity:
        for haComputeResource in haDatacenter.hostFolder.childEntity:
            return haComputeResource.host
    return None


def get_datastore_for_vm_deploy(esx_ip, esx_user, esx_password):
    """ function to get datastore for standalone vm deploy

    @param esx_ip: IP of esx
    @param esx_user: User of esx
    @param esx_password: Password of esx
    @return datastore mor_object
    """
    hosts = get_esx_host(esx_ip, esx_user, esx_password)
    if hosts is None:
        return None
    for item in hosts:
        for datastore in item.datastoreBrowser.datastore:
            return datastore
    return None


def get_deploy_command(instance_name=None, network_param_list=[],
                       datastore_name=None, ovf_url=None, esx_user=None,
                       esx_password=None, esx_ip=None, property_dict=None,
                       memory=None, cpus=None):
    """ function to get deploy command for given component

    @instance_name name of the instance
    @network_param_list list of network param for ovftool command
    @datastore_name name of datastore
    @ovf_url component ovf url
    @esx_user username of esx
    @esx_password password of esx
    @esx_ip IP of esx on which component is to be installed
    @memory memory size to be assigned to component to be deployed
    @cpus number cpus to be assigned to component to be deployed
    @return command to deploy the component
    """
    command = ['ovftool', '--powerOn', '--X:injectOvfEnv', '--name=%s'
               % instance_name, '-ds=%s' % datastore_name]
    if memory is not None:
        command.append('--memorySize:%s' % memory)
    if cpus is not None:
        command.append("--numberOfCpus:%s" % cpus)

    for network_param in network_param_list:
        command.append(network_param)

    if property_dict is not None:
        for (k, v) in property_dict.items():
            command.append('--prop:%s=%s' % (k, v))
        command.extend(['--X:logToConsole', '--acceptAllEulas',
                        '--allowExtraConfig', '--skipManifestCheck',
                        '--noSSLVerify', '-dm=thin', '--quiet',
                        '--hideEula', '--X:logLevel=error', ovf_url,
                        'vi://%s:%s@%s' % (esx_user, esx_password, esx_ip)])
    else:
        command.extend(['--X:logToConsole', '--acceptAllEulas',
                        '--allowExtraConfig', '--skipManifestCheck',
                        '--noSSLVerify', '-dm=thin', '--quiet',
                        '--hideEula', '--X:logLevel=error', ovf_url,
                        'vi://%s:%s@%s' % (esx_user, esx_password, esx_ip)])

    return command


def deploy_standalone_vm(instance_name=None, component=None,
                         network_param_list=[], datastore_name=None,
                         ovf_url=None, esx_ip=None, esx_user=None,
                         esx_password=None, property_dict=None, memory=None,
                         cpus=None):
    """ function to deploy VM for given component

    @param instance_name name of the component to be deployed
    @param component name of component to be deployed
    @network_param_list list of network param for ovftool command
    @param  datastore_name datastore name for vm deploy
    @param ovf_url vm ovf url
    @json_data hash containing deployment configuration
    @esx_ip = ip of esx on which component vm is to be deployed
    @esx_index = index of esx
    @memory memory size to be assigned to component to be deployed
    @cpus number cpus to be assigned to component to be deployed
    @return datastore mor_object
    """
    log = logging.getLogger('vdnet')
    ssl._create_default_https_context = ssl._create_unverified_context

    if esx_ip is None:
        log.error("Received %r ip of standalone ESX to deploy %s."
                  % (esx_ip, component))
        return None
    if esx_user is None:
        log.info("Using default username 'root' for esx")
        esx_user = 'root'
    if esx_password is None:
        log.info("Using default password 'ca$hc0w' for esx")
        esx_password = 'ca$hc0w'

    ip = get_standalone_vm_ip(esx_ip, esx_user, esx_password, instance_name)
    if ip:
        log.warn("%s vm already present" % component)
        return ip

    if datastore_name is None:
        datastore = get_datastore_for_vm_deploy(esx_ip, esx_user, esx_password)
        if datastore is None:
            raise Exception("Failed to find datastore on esx %s to deploy %s" %
                            (esx_ip, component))
        datastore_name = datastore.name
    command = get_deploy_command(instance_name=instance_name,
                                 network_param_list=network_param_list,
                                 datastore_name=datastore_name,
                                 ovf_url=ovf_url, esx_user=esx_user,
                                 esx_password=esx_password, esx_ip=esx_ip,
                                 property_dict=property_dict, memory=memory,
                                 cpus=cpus)
    if command is None:
        raise Exception("Failed to get command to deploy %s on esx %s" %
                        (component, esx_ip))

    log.info("Deploying %s on esx %s using command: %s" %
             (component, esx_ip, command))
    retries = '2'
    bootTimeout = 2700
    timeout = bootTimeout * (int(retries))
    (returncode, stdout, stderr) = run_command(command, returnObject=False,
                                               maxTimeout=timeout,
                                               splitCommand=False)
    if returncode != 0:
        raise Exception("Failed to deploy %s on esx %s using command: %s" %
                        (component, esx_ip, command))
    else:
        ip = get_standalone_vm_ip(esx_ip, esx_user, esx_password,
                                  instance_name)
        if ip:
            log.debug("instance: %s ip: %s " % (instance_name, ip))
            return ip
        else:
            log.warn("instance: %s, failed to get vm ip" % instance_name)


def configure_vm_reservation(
        options, vm_name, cpu_reservation=None, memory_reservation=None,
        mhz_per_core=None):
    """
    Routine to run configure VMs reservations for cpu and memory when given
    in percents of total allocated
    @type vm_name: string
    @param vm_name: name of the VM
    @type cpu_reservation: int
    @param cpu_reservation: percent of the CPU to be reserved per allocated
    @type memory_reservation: int
    @param memory_reservation: percent of the memory to be reserved per
                               allocated
    @type mhz_per_core: int
    @param mhz_per_core: MHz per core as exposed to VM
    @raise ValueError: if vm is not found
    @raise Exception: if updating of cpu/memory reservation errors
    """
    log = logging.getLogger('vdnet')
    vm = nsx_network.get_vm_by_name(options, vm_name)
    if vm is not None:
        resource_spec = Vim.ResourceConfigSpec()
        resource_spec.entity = vm

        if cpu_reservation is not None:
            if mhz_per_core is None:
                mhz_per_core = 1000   # BUG: 1420892 Assuming each core is 1GHz
            cpu_reservation = int((vm.config.hardware.numCPU * mhz_per_core *
                                   int(cpu_reservation)) / 100)
            resource_spec.cpuAllocation = Vim.ResourceAllocationInfo()
            resource_spec.cpuAllocation.reservation = cpu_reservation
        if memory_reservation is not None:
            memory_reservation = int((vm.config.hardware.memoryMB *
                                      int(memory_reservation)) / 100)
            resource_spec.memoryAllocation = Vim.ResourceAllocationInfo()
            resource_spec.memoryAllocation.reservation = memory_reservation

        if ((cpu_reservation is not None or
             memory_reservation is not None)):
            vc_vm_pool = vm.resourcePool
            try:
                vc_vm_pool.UpdateChildResourceConfiguration(
                    [resource_spec])
            except Exception:
                log.exception("Failed to update cpu/memory resources for vm %r"
                              % vm_name)
                raise
            new_cpu_res = vm.resourceConfig.cpuAllocation.reservation
            new_memory_res = vm.resourceConfig.memoryAllocation.reservation
            log.info("Updated %r with reservations: cpu=%sMHz, memory=%sMB" %
                     (vm_name, new_cpu_res, new_memory_res))
    else:
        raise ValueError("Failed to find vm %r for resources allocation" %
                         vm_name)


def get_vm_host_name(options, vm_name):
    """ function to get vm host name

    @type options: dict
    @param options: cli options to this script
    @type vm_name: string
    @param vm_name: name of the vm
    @return host name vm that matches given name
    @raise ValueError: if vm is not found
    """
    vm = nsx_network.get_vm_by_name(options, vm_name)
    if vm is not None:
        return vm.GetSummary().GetGuest().GetHostName()
    else:
        raise ValueError("Failed to find vm %r using options %r for getting \
                         host name" % (vm_name, options))
