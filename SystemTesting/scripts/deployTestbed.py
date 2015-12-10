#!/usr/bin/env python
########################################################################
# Copyright (C) 2012 VMware, Inc.
# All Rights Reserved
########################################################################

import eventlet
import json
import logging
import optparse
import os
import pprint
import pwd
import Queue
import re
import subprocess
import sys
import time
import xml
import yaml

import eventlet.debug
import eventlet.green.urllib2 as urllib2

import build_utilities
import nsx_network
import lib.host as host

import vmware.common.connections.ssh_connection as ssh
import vmware.common.connections.expect_connection as expect_connection
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.common.nimbus_utils as nimbus_utils
import vmware.common.regex_utils as regex_utils
import vmware.common.thread_utils as thread_utils
import vmware.common.utilities as utilities
import vmware.common.vsphere_utilities as vsphere_utilities

# provision comes from /build/trees/nsx-provision/avalanche/provision
# you can override that by setting PROVISION and sourcing main/environment
import vmware.provision.provision as provision
import vmware.kvm.kvm_facade as kvm_facade
import vsm
import nsxapi_appliance_management

DEFAULT_ESX_CPUS = 4
DEFAULT_ESX_MEMORY = 16384
DEFAULT_ESX_PASSWORD = 'ca$hc0w'
DEFAULT_ESX_HDSIZE = 32000000
DEFAULT_ESX_SSDSIZE = 10000000
DEFAULT_KVM_CPUS = 8
DEFAULT_KVM_MEMORY = 16384
DEFAULT_VC_CPUS = 2
DEFAULT_VC_MEMORY = 8192
FAILURE = "FAILURE"
RUNNING = "RUNNING"
SLEEP_TIME = 5
SUCCESS = "SUCCESS"
DEFAULT_NIC = 'e1000e'
MAX_RETRIES = 2

# Note: DEFAULT_CPU|MEMORY_RESERVATION are converted to
# cpu|memory_reservation in read_nimbus_config, so using
# cpu|memory_reservation here for configuring the vm reservations
KEY_CPU_RESERVATION = 'cpu_reservation'
KEY_MEMORY_RESERVATION = 'memory_reservation'
KVM_BOOT_TIME = 100
POLL_TIME = 5
BOOT_TIMEOUT_SECS = 2700   # Seconds
VCVA_FIRSTBOOT_TIMEOUT = 'vcvaFirstbootTimeout'
LINUX_OS_TYPE = 'LINUX'
WINDOWS_OS_TYPE = 'WINDOWS'
OPENVSWITCH = {"rhel64": "openvswitch",
               "rhel70": "openvswitch",
               'ubuntu1404': 'openvswitch-switch'}
LIBVIRTD = {"rhel64": "libvirtd",
            "rhel70": "libvirtd",
            'ubuntu1404': 'libvirt-bin'}
PHYSICALHOSTNAME = 'physicalhostname'

# R&D Ops team maintain hardware for Nimbus based
# provisioning service. This is also reffered as
# Nimbus public pod.
# https://wiki.eng.vmware.com/RDOps#Nimbus

rdops_public_pod = False
# Network provisioning is not yet supported
# on Nimbus public pod. Also, some of the clusters
# maintained within NSBU also don't support network
# provisiong. Using a flag to indicate
# that support
network_provision_support = False
KVMAffinity = None

log = logging.getLogger(__name__)

loglevel = os.environ.get('LOGLEVEL', 'DEBUG')
log.setLevel(loglevel)

cmdOpts = None
json_data = None
# passthru_whole_podspec is here and not True because of an oddity seen in
# nimbus logging for --testbed save'
# when we set this True we see behavior described in bugzilla# 1385354
# introduced by change b64d8155cf425f782901560a800a07a8a00f4846
passthru_whole_podspec = False
sem = eventlet.semaphore.Semaphore()
queue = Queue.Queue()

#
# Not all modules on local OS supports greenlets
# applying monkey patch to ensure that these modules
# are greenlet friendly
# Ref: http://eventlet.net/doc/basic_usage.html
#
eventlet.monkey_patch()
eventlet.debug.hub_prevent_multiple_readers(False)

if 'NIMBUS_BASE' in os.environ:
    NIMBUS_BASE = os.environ['NIMBUS_BASE']
else:
    NIMBUS_BASE = "/mts/git"
NSX_PASSWORD = constants.ManagerCredential.PASSWORD
VSM_PASSWORD = constants.VSMCredential.PASSWORD
NSX_EDGE_USERNAME = constants.EdgeCredential.USERNAME
NSX_EDGE_PASSWORD = constants.EdgeCredential.PASSWORD
NSX_CONTROLLER_PASSWORD = constants.ControllerCredential.PASSWORD


def process_args(args):
    usage = "usage: %prog [options]"
    parser = optparse.OptionParser(usage=usage)
    parser.add_option("--config", dest="config", action="store",
                      type="string", help="Testbed JSON config")
    parser.add_option("--logdir", dest="logdir", action="store",
                      type="string", help="log directory", default='/tmp')
    parser.add_option("--no-stdout", dest="stdout", action="store_false",
                      help="Avoid logging output to stdout", default=True)
    parser.add_option("--cleanup", dest="cleanup", action="store_true",
                      help="cleanup existing testbed")
    parser.add_option("--collectlogs", dest="collectlogs", action="store_true",
                      help="Collect the logs")
    parser.add_option("--testrunid", dest="testrunid", action="store",
                      type="string", help="instance id")
    parser.add_option(
        "--podspec", dest="podSpec", action="store",
        type="string", help="POD name or env file for POD configuration")
    parser.add_option(
        "--contexts", dest="contexts", action="store",
        type="string", help="Contexts name that represents group of PODs")

    # onecloud, on implies extra podspec content is required, see onecloud_main
    parser.add_option("--onecloud", action="store_true",
                      help="use onecloud for deployment")

    (options, args) = parser.parse_args(args)
    log.info("Deploy cmdOpts are %s" % options)
    return (options, args)


def setup_logging():
    global log
    logfile = cmdOpts.logdir + os.sep + 'deploy_testbed.log'
    formatter = logging.Formatter('%(asctime)s %(levelname)-8s %(message)s',
                                  datefmt='%Y-%m-%d %H:%M:%S')
    log = logging.getLogger('vdnet')
    if not cmdOpts.stdout:
        log.propagate = False
    logging.basicConfig(level=logging.DEBUG)
    log.setLevel(loglevel)

    fh = logging.FileHandler(logfile)
    fh.setLevel(loglevel)
    fh.setFormatter(formatter)
    log.addHandler(fh)


def automd_prefix(path):
    _automd = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    return os.path.abspath(os.path.join(_automd, path))


def set_env_podspec():
    """Use the nimbus cluster defined under NIMBUS environment variable.
    If not defined, use a default
    this function should guarauntee to provide a podspec and set cmdOpts.podSpec
    """
    global network_provision_support
    global rdops_public_pod

    # Process podspec value in user config yaml.
    # If Nimbus environment variables are set, then give priority
    # to that. Otherwise, set the environment variable based
    # on podspec value. This is to handle case where some users
    # may not be using podspec in user config yaml to point to
    # private pod.
    if cmdOpts.podSpec is not None:
        if 'NIMBUS' not in os.environ:
            os.environ['NIMBUS'] = cmdOpts.podSpec.split("/")[-1]
        if 'NIMBUS_CONFIG_FILE' not in os.environ:
            os.environ['NIMBUS_CONFIG_FILE'] = \
                "/mts/home4/netfvt/master-config.json"

    if (('NIMBUS_CONFIG_FILE' in os.environ.keys()) and \
        ('NIMBUS' in os.environ.keys())):
        log.info("Using NIMBUS_CONFIG_FILE %s" % os.environ['NIMBUS_CONFIG_FILE'])
        log.info("Using NIMBUS context %s" % os.environ['NIMBUS'])
        assert os.path.isfile(os.environ['NIMBUS_CONFIG_FILE'])
        func = nimbus_utils.read_nimbus_config
        config_dict = func(os.environ['NIMBUS_CONFIG_FILE'],
                           os.environ['NIMBUS'])
        if 'nsx' in config_dict:
            log.info("Network provisioning supported on %s" %
                     os.environ['NIMBUS'])
            network_provision_support = True
    else:
        log.info("Using RDOPs public POD")
        rdops_public_pod = True


def RunCommand(command, returnObject=False, maxTimeout=300, shell=False,
               splitCommand=True, strict=None, stdout=subprocess.PIPE,
               stderr=subprocess.STDOUT, env=None):
    if splitCommand:
        cmd = command.split(' ')
    else:
        cmd = command
    log.debug('command : %s' % cmd)
    p = None
    if returnObject:
        p = subprocess.Popen(cmd, shell=shell, stdout=stdout,
                             stderr=stderr, env=env)
    else:
        try:
            (returncode, stdout, stderr) = eventlet.timeout.with_timeout(
                maxTimeout, RunCommandSync, cmd, strict=strict)
            log.debug('returncode: %s' % returncode)
            log.debug('stdout : %s' % stdout)
            log.debug('stderr : %s' % stderr)
            return (returncode, stdout, stderr)
        except eventlet.Timeout:
            log.debug("Hit timeout while running command: %s" % cmd)
            return (-1, None, None)
    return p


def RunCommandSync(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                   shell=False, strict=None):
    """ Routine to run command in sync mode

    @param command: command to run
    @param stdout: file handle for stdout
    @param stderr: file handle for stderr
    @type stict: bool
    @param strict: Raises exception when command returns a failure.
    @return tuple: (returncode, stdout, stderr)
    """
    p = subprocess.Popen(command, shell=shell, stdout=stdout, stderr=stderr)
    stdout, stderr = p.communicate()
    p.wait()
    # XXX(salmanm): Checking stdout is a workaround since the deployment
    # scripts aren't returning the right status code and also not logging
    # the error to the right stream.
    if strict and p.returncode:
        log.error("Command %r failed with returncode: %r,"
                  "\nSTDOUT:\n%r, STDERR:\n%r" % (command, p.returncode,
                                                  stdout, stderr))
        raise RuntimeError('Command %r failed' % command)
    return (p.returncode, stdout, stderr)


def SetRunId(component, options):
    if 'runid' not in options:
        options['runid'] = os.getpid()


def GetCurrentUser():
    user = pwd.getpwuid(os.getuid())[0]
    return user


def DeployESXInVMUsingNimbus(options):
    SetRunId("ESX", options)
    runid = GetRunId(options)

    if 'installtype' not in options:
        options['installtype'] = 'pxeboot'
    installtype = options.get('installtype')

    if 'ip' in options:
        ip = options['ip']
        message = "ESX " + str(options['runid']) + " " + ip + " " + "None"
        update_result(message, json_data)
        log.info('ESX IP %s defined already' % ip)
        return ip

    # constructing nimbus command
    # NUMBUS_BASE's nimbus-esxdeploy does not support stateless esx, if
    # installtype is 'stateless' use /mts/git/bin/nimbus-esxdeploy which
    # does support deploying stateless esx
    if installtype == 'stateless':
        nimbusBin = '/mts/git/bin/nimbus-esxdeploy'
    elif PHYSICALHOSTNAME in options:
        if installtype not in ['pxeboot', 'pxeinstall', 'fullinstall']:
            log.warn("Physical host does not support %s install type,"
                     " will use pxeboot as default" % installtype)
        nimbusBin = NIMBUS_BASE + '/bin/nimbus-physical-esxdeploy'
    else:
        nimbusBin = NIMBUS_BASE + '/bin/nimbus-esxdeploy'

    command = nimbusBin

    # Check if install type is specified, default is pxeboot
    ksScript = None
    if installtype == 'pxeinstall':
        ksScript = 'http://engweb.eng.vmware.com/~netfvt/ks.cfg'
    elif installtype in ('template', 'linkedclone'):
        command = command + ' --usePrepared'
    elif installtype == 'fullinstall':
        command = command + ' --fullInstall'
    if 'disk' not in options and installtype == 'linkedclone':
        command = command + ' --preferLinkedClones'
    if ksScript is not None:
        command = command + ' --pxe-installer ' + ksScript

    instanceName = GetInstanceNameFromSpec("ESX", options)
    esxBuild = GetBuild(options)
    if esxBuild == 'ESX_BUILD':
        esxBuild = os.environ['ESX_BUILD']
        options['build'] = esxBuild

    # Flag to determine the ESX deployed as an VM.
    is_vm = True
    # Deploy ESX on physical host
    if PHYSICALHOSTNAME in options:
        ignore_options_on_physicalhost = ['disk', 'cpu', 'memory']
        if any(item in options for item in ignore_options_on_physicalhost):
            log.warn("The options: %s does not support on the physical host,"
                     " and will be ignored" % str(ignore_options_on_physicalhost).strip('[]'))
        command = command + ' --catMachine ' + options[PHYSICALHOSTNAME]
        command = command + ' ' + str(esxBuild)
        is_vm = False
    else:
        command = command + ' --useVHV'
        if 'disk' in options:
            if installtype == 'linkedclone':
                log.warn("disk option not supported with installtype=linkedclone,"
                         " deploying fullclones instead")
            for num in options['disk']:
                size = options['disk'][num].get('size', DEFAULT_ESX_HDSIZE)
                log.debug("Adding disk.%s with size=%s" % (num, size))
                command = command + ' --disk %s' % size
        else:
            if installtype != 'linkedclone':
                size = DEFAULT_ESX_HDSIZE
                log.debug("Adding disk.1 with size=%s" % size)
                command = command + ' --disk %s' % DEFAULT_ESX_HDSIZE

        if 'ssd' in options:
            # Add Solid State Disks if user requests so
            command = AddSSDToCommand(options, command, DEFAULT_ESX_SSDSIZE)



        if 'vmnic' in options:
            # if vmnic is defined, then get the total number of nics
            # Increment that by one for management network (public)
            command = AddAdaptersToCommand(options, command, 'vmnic', True)
        else:
            command = command + ' --nics 4 --nicType %s' % DEFAULT_NIC

        command = AddCPUsToCommand(options, command, DEFAULT_ESX_CPUS)
        command = AddMemoryToCommand(options, command, DEFAULT_ESX_MEMORY)

        if installtype == 'stateless':
            vcIndex, vcInstanceName = GetAutodeployServer(options)
            result = WaitForInventory("VC", vcIndex, vcInstanceName,  options)
            if result:
                command = command + ' --autodeployServer ' + result + ' -B ' + str(esxBuild) + \
                    ' ' + instanceName + ' ~/pxe/autodeploy'
                log.debug("COMMAND: %s " % command)
            else:
                return None
        else:
            command = command + ' ' + instanceName + ' ' + str(esxBuild)

        # PR1081563
        # removing serial-uri option since passing
        # empty string to it doesn't work with 5.5. based nimbus

        # return if ESX is already deployed
        ip = NimbusVMExists(instanceName)
        runid = GetRunId(options)
        if ip is not False:
            message = "ESX" + " " + str(runid) + " " + ip + " " + instanceName
            update_result(message, json_data)
            return ip

    ip = NimbusDeploy("ESX", instanceName, command, options, is_vm)
    if ip is not None:
        NimbusESXDeploymentPostProcess(options, ip)
    else:
        ip = "None"
    message = "ESX" + " " + str(runid) + " " + ip + " " + instanceName
    update_result(message, json_data)

    return ip


def NimbusESXDeploymentPostProcess(options, ip):
    #
    # post-process for esx deploy especially for installtype: template
    # With 'template' option, the vESX cloned has datastore uuid
    # same as other clones thus causing error when adding these hosts
    # to VC. PR1004507
    #
    if 'installtype' in options:
        if options['installtype'] != 'template' and \
           options['installtype'] != 'linkedclone':
            return None
    #
    # When vESX VM are created using linked clone method,
    # the datastore UUIDs are not changed and hence caused
    # datastore UUID conflict when adding vESX to VC.
    # Since re-signature cannot be forced, using the following
    # scripts vmfs_destroy.py to umount and vmfs_create.py
    # to mount datastore (triggers uuid change)
    #
    sys.path.append('/build/trees/main/toolseng/ra/plugins/product/esx')
    script_dir = os.path.dirname(os.path.realpath(__file__))

    password = DEFAULT_ESX_PASSWORD
    vmfs_destroy_command = 'python %s/vmfs_destroy.py -v standalone --ipaddr %s ' \
        '--username root --password %s' % (script_dir, ip, password)
    try:
        RunCommand(vmfs_destroy_command)
    except Exception, e:
        log.info('Failed to do umount datastore %s' % e)

    free_luns = 0
    if 'free_luns' in options:
        free_luns = options['free_luns']

    vmfs_create_command = 'python %s/vmfs_create.py -v standalone --ipaddr %s '\
                          '--username root --password %s ' \
                          '--free_luns %s --prefix datastore' \
                          % (script_dir, ip, password, free_luns)
    try:
        RunCommand(vmfs_create_command)
    except Exception, e:
        log.info('Failed to do mount datastore %s' % e)


def DeployNimbusVC(options):
    # There's no support for VCVA on CAT from APR 2012,
    # the fallback is to use cloudvm target. nimbus-vcvadeploy
    # cmd handles both vcva and cloudvm builds. Now this is the only
    # way to create VC as the older windows VC is almost deprecated.
    # Keeping the old nimbus-vcdeploy-cat related code if we ever
    # had to use it again. CAT's tester.py passes the cloudvm build
    # as vpxdvmtree and vpxdblddir since cloudvm is part of VPXD
    # builder but we need to pass it as vcvaBuild to nimbus-vcvadeploy
    # cmd to deploy a cloud VM. This is kinda convoluted but this is
    # how it is now.
    VC = "VC"
    SetRunId(VC, options)
    runid = GetRunId(options)
    if 'ip' in options:
        ip = options.get('ip')
        if ip:
            message_list = [VC, str(runid), ip, "None"]
            message = ' '.join(message_list)
            update_result(message, json_data)
            log.info('VC IP %s defined in user spec' % ip)
            return ip

    bootTimeout = options.get(VCVA_FIRSTBOOT_TIMEOUT, BOOT_TIMEOUT_SECS)

    instanceName = GetInstanceNameFromSpec(VC, options)
    vcBuild = GetBuild(options)
    os_type = options.get('ostype', LINUX_OS_TYPE)
    # Prepare args if os type is windows
    if os_type.upper() == WINDOWS_OS_TYPE:
        log.info("Initializing %r VC" % os_type.upper())
        nimbusBin = NIMBUS_BASE + '/bin/nimbus-vcdeploy-cat'
        command_list_1 = [nimbusBin, '--useWinVersion', 'win2008r2',
                          '--vimisoBuild', str(vcBuild)]
    # Prepare args if os type is linux
    elif os_type.upper() == LINUX_OS_TYPE:
        log.info("Initializing %r VC" % os_type.upper())
        nimbusBin = NIMBUS_BASE + '/bin/nimbus-vcvadeploy'
        command_list_1 = [nimbusBin, '--enableTftp',
                          '--vcvaBuild', str(vcBuild)]
    else:
        raise ValueError("VC deploy requires supported os, not %s" % os_type)

    command_list_2 = ['--maxRetries', str(MAX_RETRIES), '--bootTimeout',
                      str(bootTimeout), instanceName]

    # Process and params params to command for linked VCs
    command_list_3 = []
    multi_vc_node = 'multi_vc_node'
    if multi_vc_node in options:
        if options[multi_vc_node] == '1':
            command_list_3 = [' multivc-node-1']
        else:
            linked_vc = 'linked_vc'
            if linked_vc in options:
                options['vc'] = options[linked_vc]
            func = GetAutodeployComponent
            vc_index, vc_instance_name = func(options,
                                              VC.lower())
            vc_ip = WaitForInventory(VC,
                                     vc_index,
                                     vc_instance_name,
                                     options)
            vc_options = get_vc_info()
            func = vsphere_utilities.get_vm_host_name
            vc_host_name = func(vc_options,
                                vc_instance_name)
            multi_vc_node = 'multivc-node-%s' % options[multi_vc_node]
            command_list_3 = [multi_vc_node, '--replicationPartner',
                              vc_host_name, '--linkedVCHost', vc_ip]

    command_list = command_list_1 + command_list_2 + command_list_3
    command = ' '.join(command_list)
    command = AddCPUsToCommand(options, command, DEFAULT_VC_CPUS)
    command = AddMemoryToCommand(options, command, DEFAULT_VC_MEMORY)
    if 'nic' in options:
        command = AddAdaptersToCommand(options, command, 'nic', True)

    ip = NimbusDeploy(VC, instanceName, command, options)
    if ip is None:
        ip = "None"
    message_list = [VC, str(runid), ip, instanceName]
    message = ' '.join(message_list)
    update_result(message, json_data)

    return ip


def DeploySpirentVM(options):
    SetRunId("spirent", options)
    runid = GetRunId(options)
    if 'ip' in options:
        ip = options.get('ip')
        if ip:
            message_list = ["spirent", str(runid), ip, "None"]
            message = ' '.join(message_list)
            queue.put(message)
            log.info('%s IP %s defined in user spec' % ("spirent", ip))
            return ip

    instanceName = GetInstanceNameFromSpec("spirent", options)
    if 'ovfurl' not in options:
        options['ovfurl'] = ('/mts/home1/yuanyouy/'
                             'Spirent_TestCenter_Virtual_ESX_4.51.6246.ova')

    if 'installtype' in options and options['installtype'] == 'nested':
        if 'esx' in options or 'host' in options:
            return DeployStandaloneVM(options, "spirent", instanceName)
    else:
        raise ValueError("Missing/Incorrect installtype param in options: %s" %
                pprint.pformat(options))

def DeployNimbusLogInsightServer(options):
    LogInsightServer="LogInsightServer"
    SetRunId(LogInsightServer, options)
    runid = GetRunId(options)
    if 'ip' in options:
        ip = options.get('ip')
        if ip:
            message_list = [LogInsightServer, str(runid), ip, "None"]
            message = ' '.join(message_list)
            queue.put(message)
            log.info('%s IP %s defined in user spec' % (LogInsightServer, ip))
            return ip

    nimbusBin = NIMBUS_BASE + '/bin/nimbus-loginsightdeploy'
    instanceName = GetInstanceNameFromSpec(LogInsightServer, options)

    command = nimbusBin + ' ' + instanceName
    command = command + ' --logInsightBuild ' + options['build']

    return NimbusDeploy(LogInsightServer, instanceName, command, options)


def DeployNimbusVSM(options):
    SetRunId("VSM", options)
    if 'ip' in options:
        ip = options['ip']
        queue.put("VSM " + str(options['runid']) + " " + ip + " " + "None")
        log.info('VSM IP %s defined already' % ip)
        return ip

    nimbusBin = NIMBUS_BASE + '/bin/nimbus-vsmdeploy'
    instanceName = GetInstanceNameFromSpec("VSM", options)
    password = options.get('password', VSM_PASSWORD)
    root_password = options.get('root_password', VSM_PASSWORD)

    if 'installtype' in options and options['installtype'] == 'nested':
        if 'esx' in options or 'host' in options:
            propertyDict = GetPropertyDictForVSM(
                root_password=root_password, cli_password=password,
                hostname=instanceName)
            return DeployStandaloneVM(options, "VSM", instanceName,
                                      propertyDict)
    else:
        nimbusBin = NIMBUS_BASE + '/bin/nimbus-ovfdeploy'
        propertyXmlPath = create_property_mappings_xml_file(
            options, component='vsm', hostname=instanceName,
            root_password=root_password, cli_password=password)
        command = nimbusBin + ' ' + instanceName
        command = command + ' ' + options['ovfurl']
        # Wait for http port 22 to be up, otherwise ovf deployment will return
        # pre-maturely
        command = command + ' --usespyarp --usePrepared --ports 22 \
        --configurablePropertyFile ' + propertyXmlPath
        ovf_spec = get_ovf_spec(options['ovfurl'])
        command = AddCPUsToCommand(options, command,ovf_spec['default_cpu'])
        command = AddMemoryToCommand(options, command, ovf_spec['default_memory'])
        if 'nic' in options:
            command = AddAdaptersToCommand(options, command, 'nic')
        ip = NimbusDeploy("VSM", instanceName, command, options)
        if ip == None:
           return None
        username = options['username']
        log.info("Checking if service status is RUNNING for VSM ip %s" %ip)
        if CheckVSMServiceStatusAfterDeployment(ip, username,
            password) == FAILURE:
           log.info("Services are not running on the VSM ip %s" %ip)
           return None
        else:
           log.info("Services are running on the VSM ip %s" %ip)
           return ip

def get_ovf_spec(ovf_url):
    """ function to get cpu/memory from the ovf spec

    @param ovf_url: url of the ovf
    @return ovf_spec:  dict containing cpu and memory information
    """

    log.info('getting ovf spec from %s' % str(ovf_url))

    nsx_namespaces = {"ovf": "http://schemas.dmtf.org/ovf/envelope/1",
                      "cim": "http://schemas.dmtf.org/wbem/wscim/1/common",
                      "rasd": "http://schemas.dmtf.org/wbem/wscim/1/"
                      "cim-schema/2/CIM_ResourceAllocationSettingData",
                      "vssd": "http://schemas.dmtf.org/wbem/wscim/1/"
                      "cim-schema/2/CIM_VirtualSystemSettingData",
                      "xsi": "http://www.w3.org/2001/XMLSchema-instance",
                      "vmw": "http://www.vmware.com/schema/ovf"}
    response = urllib2.urlopen(ovf_url).read()
    root = xml.etree.ElementTree.fromstring(response)
    # Find all elements matching the section
    # VirtualSystem/VirtualHardwareSection/Item/ElementName
    items = root.findall("ovf:VirtualSystem/ovf:VirtualHardwareSection/"
                         "ovf:Item/rasd:ElementName",
                         namespaces=nsx_namespaces)
    ovf_spec = {}
    # read cpu and memory information.
    for item in items:
        if re.search('memory', item.text):
            pattern = re.compile('([0-9]+).*')
            default_memory = pattern.findall(item.text)[0]
            ovf_spec['default_memory'] = default_memory
            log.debug("Default memory in ovf=%s is %s" % (ovf_url, default_memory))
        elif re.search('CPU', item.text):
            pattern = re.compile('([0-9]+).*')
            default_cpu = pattern.findall(item.text)[0]
            ovf_spec['default_cpu'] = default_cpu
            log.debug("Default cpu in ovf=%s is %s" % (ovf_url, default_cpu))

    return ovf_spec


def DeployNimbusNSXManager(options):
    SetRunId("NSXManager", options)
    if 'ip' in options:
        ip = options['ip']
        queue.put(
            "NSXManager " + str(options['runid']) + " " + ip + " " + "None")
        log.info('NSXManager IP %s defined already' % ip)
        return ip

    instanceName = GetInstanceNameFromSpec("NSXManager", options)

    password = options.get('password', NSX_PASSWORD)
    root_password = options.get('root_password', NSX_PASSWORD)
    if 'kvm' in options:
        (ip, username, password) = GetComponentIPAndCredentials(options, 'kvm')

        if 'network' in options:
            network = options['network']
        else:
            network = 'br0'
        result = DeployVMOnKVM(kvmIp=ip, kvmUsername=username,
                               kvmPassword=password, component='NSXManager',
                               instanceName=instanceName,
                               qcow2ImageUrl=options['ovfurl'],
                               network=network, runId=options['runid'])
        if result.status_code == 0:
            func = KVMNSXManagerDeploymentPostProcess
            return func(kvmIp=ip, kvmUsername=username, kvmPassword=password,
                        component="NSXManager", instanceName=instanceName,
                        nsxPassword=password, runId=options['runid'])
        else:
            raise RuntimeError("DeployVMOnKVM failed with options: %r" %
                options)
    elif 'installtype' in options and options['installtype'] == 'nested':
        if 'esx' in options:
            propertyDict = GetPropertyDictForNSX(
                root_password=root_password, cli_password=password,
                hostname=instanceName)
            return DeployStandaloneVM(options, "NSXManager", instanceName,
                                      propertyDict)
    else:
        nimbusBin = NIMBUS_BASE + '/bin/nimbus-ovfdeploy'
        propertyXmlPath = create_property_mappings_xml_file(
            options, component='nsxmanager', hostname=instanceName,
            root_password=root_password, cli_password=password)
        command = nimbusBin + ' ' + instanceName
        command = command + ' ' + options['ovfurl']
        # get cpu and memory information from ovf spec(url)
        ovf_spec = get_ovf_spec(options['ovfurl'])
        # if cpu/memory is provided in user yaml then add it to command or
        # add default cpu/memory read from ovf spec to command
        command = AddCPUsToCommand(options, command, ovf_spec['default_cpu'])
        command = AddMemoryToCommand(options, command,
                                     ovf_spec['default_memory'])
        # Wait for http port 22 to be up, otherwise ovf deployment will return
        # pre-maturely
        command = command + ' --usespyarp --usePrepared --ports 22 \
      --configurablePropertyFile ' + propertyXmlPath

    return NimbusDeploy("NSXManager", instanceName, command, options)

def DeployNimbusTORGateway(options):
    SetRunId("TORGateway", options)
    log.info('TORGateway deployment starting')
    if 'ip' in options:
        ip = options['ip']
        queue.put(
            "TORGateway " + str(options['runid']) + " " + ip + " " + "None")
        log.info('TORGateway IP %s defined already' % ip)
        return ip

    # TODO: Need to add this into buildweb
    url = 'http://w2-dbc202.eng.vmware.com/agrawalm/ovfs/torgateway/torgateway.ovf'

    instanceName = GetInstanceNameFromSpec("TORGateway", options)
    log.info(NIMBUS_BASE)
    nimbusBin = NIMBUS_BASE + '/bin/nimbus-ovfdeploy'
    command = nimbusBin
    if 'pif' in options:
        command = AddAdaptersToCommand(options, command, prefix='pif',
                                       addNicType=False)
        command = command + ' --usespyarp --usePrepared --ports 22'
    log.info(command)
    ovf_spec = get_ovf_spec(url)
    log.info(ovf_spec)
    #get cpu and memory information from ovf spec(url)
    command = AddCPUsToCommand(options, command, ovf_spec['default_cpu'])
    log.info(command)
    command = AddMemoryToCommand(options, command,
                                     ovf_spec['default_memory'])
    log.info(command)
    command = command + ' ' + instanceName
    log.info(command)
    command = command + ' ' + url
    log.info(command)

    log.info('TORGateway deployment calling NimbusDeploy')
    return NimbusDeploy("TORGateway", instanceName, command, options)


def DeployNimbusNSXController(options):
    SetRunId("NSXController", options)
    if 'ip' in options:
        ip = options['ip']
        queue.put(
            "NSXController " + str(options['runid']) + " " + ip + " " + "None")
        log.info('NSXController IP %s defined already' % ip)
        return ip

    instanceName = GetInstanceNameFromSpec("NSXController", options)
    password = options.get('password', NSX_CONTROLLER_PASSWORD)
    root_password = options.get('root_password', NSX_CONTROLLER_PASSWORD)

    if 'installtype' in options and options['installtype'] == 'nested':
        propertyDict = GetPropertyDictForNSX(
            root_password=root_password, cli_password=password,
            hostname=instanceName)
        return DeployStandaloneVM(options, "NSXController", instanceName,
                                  propertyDict)
    else:
        nimbusBin = NIMBUS_BASE + '/bin/nimbus-ovfdeploy'
        propertyXmlPath = create_property_mappings_xml_file(
            options, component='nsxcontroller', hostname=instanceName,
            root_password=root_password, cli_password=password)
        command = nimbusBin + ' ' + instanceName
        command = command + ' ' + options['ovfurl']
        # get cpu and memory information from ovf spec(url)
        ovf_spec = get_ovf_spec(options['ovfurl'])
        # if cpu/memory is provided in user yaml then add it to command or
        # add default cpu/memory read from ovf spec to command
        command = AddCPUsToCommand(options, command, ovf_spec['default_cpu'])
        command = AddMemoryToCommand(options, command,
                                     ovf_spec['default_memory'])
        command = command + ' --usespyarp --usePrepared --ports 22 \
           --configurablePropertyFile ' + propertyXmlPath

    return NimbusDeploy("NSXController", instanceName, command, options)


def DeployNimbusNSXEdge(options):
    SetRunId("NSXEdge", options)
    if 'ip' in options:
        ip = options['ip']
        queue.put("NSXEdge " + str(options['runid']) + " " + ip + " " + "None")
        log.info('NSXEdge IP %s defined already' % ip)
        return ip

    instanceName = GetInstanceNameFromSpec("NSXEdge", options)
    # username = options.get('username', NSX_EDGE_USERNAME)
    password = options.get('password', NSX_EDGE_PASSWORD)
    root_password = options.get('root_password', NSX_EDGE_PASSWORD)
    deploymentOption=options.get('deploymentoption', None)

    if options.get('installtype') == 'nested':
        propertyDict = GetPropertyDictForNSX(
            root_password=root_password, cli_password=password,
            hostname=instanceName)
        return DeployStandaloneVM(options, "NSXEdge", instanceName,
                                  propertyDict, deploymentOption=deploymentOption)
    else:
        nimbusBin = NIMBUS_BASE + '/bin/nimbus-ovfdeploy'
        propertyXmlPath = create_property_mappings_xml_file(
            options, component='nsxedge', hostname=instanceName,
            root_password=root_password, cli_password=password)
        command = nimbusBin + ' ' + instanceName
        command = command + ' ' + options['ovfurl']
        # get cpu and memory information from ovf spec(url)
        ovf_spec = get_ovf_spec(options['ovfurl'])
        # if cpu/memory is provided in user yaml then add it to command or
        # add default cpu/memory read from ovf spec to command
        command = AddCPUsToCommand(options, command, ovf_spec['default_cpu'])
        command = AddMemoryToCommand(options, command, ovf_spec['default_memory'])
        command = command + ' --usespyarp --usePrepared \
         --configurablePropertyFile ' + propertyXmlPath

    return NimbusDeploy("NSXEdge", instanceName, command, options)


def GetComponentIPAndCredentials(options, component):
    index, instanceName = GetAutodeployComponent(options, component)
    if 'username' in json_data[component][index]:
        username = json_data[component][index]['username']
    else:
        username = 'root'
    if 'password' in json_data[component][index]:
        password = json_data[component][index]['password']
    else:
        password = DEFAULT_ESX_PASSWORD

    ip = WaitForInventory(component, index, instanceName,  options)

    return (ip, username, password)


def DeployVMOnKVM(kvmIp, kvmUsername, kvmPassword, component, instanceName,
                  qcow2ImageUrl, network, runId):
    if kvmIp == "None":
        log.error("Skipping %s deployment as received ip %s for kvm"
                  % (component, kvmIp))
        queue.put(component + " " + str(runId) + " " + "None" + " "
                  + instanceName)
        return None
    # Download vm build.
    fileName = qcow2ImageUrl.split('/')[-1]
    destinationFilePath = '/vms/images/%s' % fileName

    func = expect_connection.ExpectConnection
    expectConnection = func(ip=kvmIp, username=kvmUsername,
                            password=kvmPassword)
    expectConnection.create_connection('#')
    log.info("Downloading NSX Manager image using URL %s on KVM %s."
             % (qcow2ImageUrl, kvmIp))
    func = expectConnection.read_until_prompt
    result = func(['bytes*', '#'], 'wget %s -O %s'
                  % (qcow2ImageUrl, destinationFilePath), timeout=600)
    if result.status_code != 0:
        log.error("Command to download %s build from URL %s on KVM %s failed \
                  with error: %s" % (component, qcow2ImageUrl, kvmIp,
                                     result.error))
        queue.put(component + " " + str(runId) + " " + "None" + " "
                  + "None")
        return None

    # Start VM install on KVM.
    sshConnection = ssh.SSHConnection(ip=kvmIp, username=kvmUsername,
                                      password=kvmPassword)
    sshConnection.create_connection()
    log.info("Installing NSX Manager image %s on KVM %s."
             % (qcow2ImageUrl, kvmIp))
    func = sshConnection.request
    result = func('virt-install --import --noautoconsole --name %s \
                  --ram 12288 --disk %s,format=qcow2 \
                  --network=bridge:%s,model=e1000'
                  % (instanceName, destinationFilePath, network))
    if result.status_code != 0:
        log.error("Command to deploy %s on KVM %s failed with \
                  error: %s" % (component, kvmIp, result.error))

    return result


def KVMNSXManagerDeploymentPostProcess(kvmIp, kvmUsername, kvmPassword,
                                       component, instanceName, nsxPassword,
                                       runId):
    log.info("Waiting for NSX Manager boot up to complete")
    # Pass NSX Manager password using expect.
    func = expect_connection.ExpectConnection
    expectConnection = func(ip=kvmIp, username=kvmUsername,
                            password=kvmPassword)
    expectConnection.create_connection('#')
    func = expectConnection.read_until_prompt
    result = func(['bytes*', 'password:'], 'virsh console %s'
                  % instanceName, timeout=120)
    if result.status_code != 0:
        log.error("Command to set password on %s failed with error: %s"
                  % (component, result.error))
        queue.put(component + " " + str(runId) + " " + "None" + " "
                  + "None")
        return None

    result = func(['bytes*', 'password:'], nsxPassword)
    if result.status_code != 0:
        log.info("Command to set password on %s failed with error: %s"
                 % (component, result.error))
        queue.put(component + " " + str(runId) + " " + "None" + " "
                  + "None")
        return None

    # Wait for nsxmanager login prompt.
    result = func(['bytes*', 'manager login:'], nsxPassword, timeout=300)
    if result.status_code != 0:
        log.info("Command to wait for %s login prompt failed with error: %s"
                 % (component, result.error))
        queue.put(component + " " + str(runId) + " " + "None" + " "
                  + "None")
        return None

    # Login to NSX Manager.
    expectConnection.default_prompt('admin', 'Password:')
    expectConnection.default_prompt(nsxPassword, 'manager>', timeout=90)

    # Get IP of NSX Manager
    result = expectConnection.default_prompt('show interface mgmt',
                                             'manager>')
    pattern = re.compile('\w.*?([0-9]+.[0-9]+.[0-9]+.[0-9]+)/.*')
    ip = pattern.findall(result)[0]
    if ip is not None:
        queue.put(component + " " + str(runId) + " " + ip + " "
                  + "None")
        return ip
    else:
        queue.put(component + " " + str(runId) + " " + "None" + " "
                  + "None")

    return None


def create_property_mappings_xml_file(options, component=None, hostname=None,
                                      root_password=None, cli_password=None,
                                      api_user=None, api_password=None):
    components = ['nsxmanager', 'nsxedge', 'vsm', 'nsxcontroller']
    property_function_dict = {'nsxmanager': GetPropertyDictForNSX,
                              'nsxedge': GetPropertyDictForNSX,
                              'vsm': GetPropertyDictForVSM,
                              'nsxcontroller': GetPropertyDictForNSX
                              }
    if component.lower() in components:
        root = xml.etree.ElementTree.Element("ProductSection")
        proprty_dict = property_function_dict[component.lower()](
            root_password, cli_password, hostname)

        for key, value in proprty_dict.items():
            doc = xml.etree.ElementTree.SubElement(root, "property")
            xml.etree.ElementTree.SubElement(doc, "key").text = key
            xml.etree.ElementTree.SubElement(doc, "value").text = value

    tree = xml.etree.ElementTree.ElementTree(root)
    log_dir = GetComponentLogDir(component, options)
    xml_file = "%s/%s-property-mappings.xml" % (log_dir, hostname)
    tree.write(xml_file)
    return xml_file


def GetPropertyDictForNSX(root_password=None, cli_password=None,
                                 hostname=None):
    propertyDict = {}
    propertyDict['nsx_passwd_0'] = root_password
    propertyDict['nsx_cli_passwd_0'] = cli_password
    hostname = re.sub(r'[a-z]+-vdnet-', '', hostname)
    propertyDict['nsx_hostname'] = hostname
    propertyDict['nsx_isSSHEnabled'] = 'True'
    return propertyDict


def GetPropertyDictForVSM(root_password=None, cli_password=None,
                          hostname=None):
    propertyDict = {}
    propertyDict['vsm_passwd_0'] = root_password
    propertyDict['vsm_cli_passwd_0'] = cli_password
    propertyDict['vsm_cli_en_passwd_0'] = cli_password
    propertyDict['vsm_hostname'] = hostname
    propertyDict['vsm_isSSHEnabled'] = 'True'
    return propertyDict

@utilities.with_sem(lambda *a, **kw: sem)
def CreateDummyPortGroup(component, options, result, esx_user, esx_password,
                         network_name_dict, network_opt_value_dict):
    # XXX(sqian): Fix for PR: 1478890
    # Create port groups not existing on the host ESX before
    # deploying Edge VM
    if component == 'NSXEdge':
        vmnic_list = None
        if 'dummy_vss_vmnic' in options:
           # Value of dummy_vss_vmnic may be
           #   dummy_vss_vmnic: 'vmnic1'
           # or
           #   dummy_vss_vmnic: 'vmnic1,vmnic2'
           log.info("Found dummy_vss_vmnic, its value is %r" %
                    options['dummy_vss_vmnic'])
           vmnic_list = options['dummy_vss_vmnic'].split(',')

        pg_list = ['%s' % (options[opt_val])
                   for key, opt_val in
                   zip(network_name_dict[component],
                       network_opt_value_dict[component])]
        vsphere_utilities.create_portgroups_if_no_existing( \
                             esx_ip=result,
                             esx_user=esx_user,
                             esx_password=esx_password,
                             pglist=pg_list,
                             vmniclist=vmnic_list)


def DeployStandaloneVM(options, component, instanceName, propertyDict=None, deploymentOption=None):
    NETWORK_NAME_DICT = {'NSXManager': ['Network 1'],
                         'NSXEdge': ['Network 0', 'Network 1', 'Network 2'],
                         'VSM': ['VSMgmt'],
                         'spirent': ['VM Network']
                         }
    NETWORK_OPT_VALUE_DICT = {'NSXManager': ['network'],
                              'NSXEdge': ['management_network',
                                          'uplink_network',
                                          'internal_network'],
                              'VSM': ['network'],
                              'spirent': ['management_network']
                              }
    SPECIAL_COMPONENTS = ['NSXManager', 'NSXEdge', 'VSM', 'spirent']
    datastoreName = None
    if 'datastore' in options:
        datastoreName = options['datastore']
    if 'host' in options:
        options['esx'] = options['host']
    esxIndex, esxInstanceName = GetAutodeployComponent(options, 'esx')
    result = WaitForInventory("ESX", esxIndex, esxInstanceName,  options)
    if 'username' in json_data['esx'][esxIndex]:
        esx_user = json_data['esx'][esxIndex]['username']
    else:
        log.info("Using default username 'root' for esx.%s" % esxIndex)
        esx_user = 'root'
    if 'password' in json_data['esx'][esxIndex]:
        esx_password = json_data['esx'][esxIndex]['password']
    else:
        log.info("Using default password '%s' for esx.%s" %
                (DEFAULT_ESX_PASSWORD, esxIndex))
        esx_password = DEFAULT_ESX_PASSWORD

    if result != "None":
        if component in SPECIAL_COMPONENTS:
            network_list = ['--net:%s=%s' % (key, options[opt_val])
                            for key, opt_val in
                            zip(NETWORK_NAME_DICT[component],
                                NETWORK_OPT_VALUE_DICT[component])]
            CreateDummyPortGroup(
                component, options, result, esx_user, esx_password,
                NETWORK_NAME_DICT, NETWORK_OPT_VALUE_DICT)
        else:
            network_list = ['--network=%s' % options['network']]

        ip = vsphere_utilities.\
            deploy_standalone_vm(instance_name=instanceName,
                                 component=component,
                                 network_param_list=network_list,
                                 datastore_name=datastoreName,
                                 ovf_url=options['ovfurl'],
                                 esx_ip=result,
                                 esx_user=esx_user,
                                 esx_password=esx_password,
                                 property_dict=propertyDict,
                                 deploymentOption=deploymentOption)
        if ip is not None:
            queue.put(component + " " + str(options['runid']) + " " + ip + " "
                      + instanceName)
        else:
            queue.put(component + " " + str(options['runid']) + " " + "None"
                      + " " + instanceName)
        return ip
    else:
        log.error("Skipping %s deployment as received ip %s for esx.%s"
                  % (component, result, esxIndex))
        queue.put(component + " " + str(options['runid']) + " " + "None" + " "
                  + instanceName)
    return None


def GetBuild(options):
    build = options.get('build')
    if build is not None:
        build = str(build)
        if ':' in build:
            build = build_utilities.get_build_from_tuple(build)

    if build is None:
        raise ValueError("Missing/Incorrect build param in options: %s" %
                pprint.pformat(options))
    return build


def DeployNimbusNeutron(options):
    SetRunId("Neutron", options)
    if 'ip' in options:
        ip = options['ip']
        queue.put("Neutron " + str(options['runid']) + " " + ip + " " + "None")
        log.info('Neutron IP %s defined already' % ip)
        return ip

    nimbusBin = NIMBUS_BASE + '/bin/nimbus-vsmdeploy'

    vsmBuild = GetBuild(options)
    instanceName = GetInstanceNameFromSpec("Neutron", options)

    command = nimbusBin + ' --vsmBuild ' + str(vsmBuild) \
        + ' --maxRetries ' + str(MAX_RETRIES) + ' ' + instanceName

    return NimbusDeploy("Neutron", instanceName, command, options)


def DeployNimbusHypervisor(options, type):
    SetRunId(type, options)
    if 'ip' in options:
        ip = options['ip']
        message = type + " " + str(options['runid']) + " " + ip + " " + "None"
        update_result(message, json_data)
        log.info('%s ip %s defined already' % (type, ip))
        return ip
    else:
        log.info('DeployNimbusHypervisor called with options: type=%s, %s' %
                 (type, options))

    hvBuild = GetBuild(options)
    if type == "KVM":
        kvm_builds = {
            'rhel64': ('http://build-squid.eng.vmware.com/build/mts/release/'
                       'bora-2773861/publish/'
                       'rhel64_avalanche_template_v1.ovf'),
            'rhel70':
                ('http://build-squid.eng.vmware.com/build/mts/release/'
                 'bora-2954016/publish/rhel70_BB_template_v8.ovf'),
            'ubuntu1204': 'http://apt.nicira.eng.vmware.com/apt/ovf/kvm.ovf',
            'ubuntu1404':
                ('http://build-squid.eng.vmware.com/build/mts/release/bora-'
                 '2906514/publish/ubuntu1404_kvm_v2.ovf'),
        }
        # Allow deployment description to give build path directly, or use
        # one of the provided nicknames.
        url = kvm_builds.get(hvBuild, str(hvBuild))
        log.debug("Using KVM build at url/path: %r" % url)
    elif type == "XEN":
        url = 'http://pa-dbc1106.eng.vmware.com/gjayavelu/ovf/' \
              'xen62-clearwater-auto/xen62-clearwater-auto.ovf'

    nimbusBin = NIMBUS_BASE + '/bin/nimbus-ovfdeploy'
    instanceName = GetInstanceNameFromSpec(type, options)
    command = ("%s --usespyarp --usePrepared --ports 22 "
               "--useVHV --rebootIfNoIp --ipWaitTimeout 120" % nimbusBin)
    command = AddCPUsToCommand(options, command, DEFAULT_KVM_CPUS)
    command = AddMemoryToCommand(options, command, DEFAULT_KVM_MEMORY)
    command = AddAdaptersToCommand(options, command, 'pif')
    command = command + ' ' + instanceName
    command = command + ' ' + url
    ip = NimbusDeploy(type, instanceName, command, options)
    if ip is None:
        ip = "None"
    runid = GetRunId(options)
    message = type + " " + str(runid) + " " + ip + " " + instanceName
    update_result(message, json_data)
    return ip


def ssh_request(ip, username, password, cmd, strict=True):
    """
    Method to execute a command on the remote host via ssh.

    @param ip: IP of the remote host
    @type ip: str
    @param username: Username to login to the remote host.
    @type username: str
    @param password: Password corresponding to the user name that we want to
        login as.
    @type password: str
    @param cmd: Command that we want to execute on the remote host.
    @type cmd: str
    @param strict: When set, method will raise an exception if the command
        executed on the host hasn't succeeded. The raising of exception is
    """
    host_obj = host.Host(ip, user=username, passwd=password)
    host_keys_file = global_config.get_host_keys_file()
    host_obj.known_hosts_file = host_keys_file
    host_obj.perm_auth_expect(passwd=password)
    msg = "Failed to run command: %r" % cmd
    if strict:
        result = host_obj.req_call(cmd, msg=msg)
    else:
        result = host_obj.call(cmd)
    return result


def DeployNimbusKVM(options):
    ip = DeployNimbusHypervisor(options, "KVM")
    if ip in ('None', None, ''):
        raise RuntimeError("KVM host did not get an IP, deployment opts "
                           "used:\n%s" % pprint.pformat(options))
    if 'username' not in options:
        raise Exception("Username not found for KVM host in: %s" %
                        pprint.pformat(options))
    if 'password' not in options:
        raise Exception("Password not found for KVM host in: %s" %
                        pprint.pformat(options))
    username, password = options['username'], options['password']
    ovs_is_running = False
    libvirt_is_running = False
    hvBuild = GetBuild(options)
    curr_time = time.time()
    kvm = kvm_facade.KVMFacade(ip=ip, username=username, password=password)
    while time.time() - curr_time < KVM_BOOT_TIME:
        log.debug("Checking OVS and libvirt status on KVM %r ..." % ip)
        ovs_is_running = kvm.is_service_running(
            execution_type='cmd', service_name=OPENVSWITCH[hvBuild])
        libvirt_is_running = kvm.is_service_running(
            execution_type='cmd', service_name=LIBVIRTD[hvBuild])
        if ovs_is_running and libvirt_is_running:
            break
        time.sleep(POLL_TIME)
    if not (ovs_is_running and libvirt_is_running):
        raise Exception("OVS and libvirt services didn't come up on KVM host "
                        "%r in %r seconds"  % (ip, KVM_BOOT_TIME))

    cmd = 'cat /proc/cpuinfo | grep flags'
    cmd_out = ssh_request(ip, username, password, cmd)
    if 'vmx' not in cmd_out:
        raise RuntimeError("Nested HV support is not enabled on kvm=%s:\n%s" %
                           (ip, cmd_out))

    log.debug("OVS and libvirt are up on KVM host %r" % ip)
    return ip


def DeployNimbusXEN(options):
    # Currently, Xen VM gets successfully, but finding ip address
    # is not working since tools cannot be installed on Xen VMs
    return DeployNimbusHypervisor(options, "XEN")


def DeployNimbusNVPController(options):
    return DeployNimbusNVPSuite("NVPController", options)


def DeployNimbusServiceNode(options):
    return DeployNimbusNVPSuite("ServiceNode", options)


def DeployNimbusGateway(options):
    return DeployNimbusNVPSuite("Gateway", options)


def DeployNimbusNVPSuite(component, options):
    SetRunId(component, options)
    if 'ip' in options:
        ip = options['ip']
        queue.put(
            component + " " + str(options['runid']) + " " + ip + " " + "None")
        log.info('%s %s defined already' % (component, ip))
        return ip

    componentMap = {'NVPController': 'nsx-controller',
                    'ServiceNode': 'nsx-service-node',
                    'Gateway': 'nsx-gateway'}
    build = GetBuild(options)
    build_url = 'https://devdashboard.nicira.eng.vmware.com/buildinfo/' \
                'all_info/%s' % build
    json_ = urllib2.urlopen(build_url).read()
    try:
        build_info = json.loads(json_)
    except ValueError, e:
        log.error("Wrong NVP build number '%s' may be supplied: %r\n%s\n%s" %
                  (build, e, build_url, json_))
        raise
    project_version = build_info['PROJECT_VERSION']
    url = ("http://apt.nicira.eng.vmware.com/builds/NVP%s/precise_amd64/"
           "ovf/%s-%s-build%s.ovf" % (build, componentMap[component],
                                      project_version, build))

    nimbusBin = NIMBUS_BASE + '/bin/nimbus-ovfdeploy'
    instanceName = GetInstanceNameFromSpec(component, options)
    command = nimbusBin + ' --usespyarp --usePrepared'

    command = AddAdaptersToCommand(options, command)
    command = command + ' ' + instanceName
    command = command + ' ' + url

    return NimbusDeploy(component, instanceName, command, options)


def DeployNimbusAuthServer(options):
    component = "AuthServer"
    SetRunId(component, options)
    if 'ip' in options:
        ip = options['ip']
        queue.put(
            component + " " + str(options['runid']) + " " + ip + " " + "None")
        log.info('%s ip %s defined already' % (component, ip))
        return ip

    url = 'http://blr-dbc202.eng.vmware.com/dgargote/ovf/Tacacs+/Tacacs+.ovf'

    nimbusBin = NIMBUS_BASE + '/bin/nimbus-ovfdeploy'
    instanceName = GetInstanceNameFromSpec(component, options)
    command = nimbusBin + ' --usespyarp --usePrepared'
    command = AddAdaptersToCommand(options, command)
    command = command + ' ' + instanceName
    command = command + ' ' + url

    return NimbusDeploy(component, instanceName, command, options)


def DeployNimbusNSXUIDriver(options):
    component = "nsx_uidriver"
    SetRunId(component, options)
    if 'ip' in options:
        ip = options['ip']
        queue.put(
            component + " " + str(options['runid']) + " " + ip + " " + "None")
        log.info('%s ip %s defined already' % (component, ip))
        return ip

    # Default value of os_type is none
    os_type = 'linux'
    if 'os_type' in options:
        os_type = options['os_type'].lower

    if os_type == 'linux':
        url = 'http://apt.nicira.eng.vmware.com/apt/vmware/UIAutomation_lin_1.0.ovf'
    else:
        raise NotImplementedError('Only linux support available')

    nimbusBin = NIMBUS_BASE + '/bin/nimbus-ovfdeploy'
    instanceName = GetInstanceNameFromSpec(component, options)
    command = nimbusBin + ' --usespyarp --usePrepared'
    command = command + ' ' + instanceName
    command = command + ' ' + url
    return NimbusDeploy(component, instanceName, command, options)


def AddAdaptersToCommand(options, command, prefix='nic', addNicType=False):
    if prefix in options:
        # [] in indexes are already resolved
        if '0' not in options[prefix].keys():
            # if mgmt nic is not defined, then get the total number of nics
            # Increment that by one for management network (public)
            log.info(
                "Adding mgmt interface as index [0] not "
                "specificed for %s", prefix)
            command = command + ' --nics ' + str(len(options[prefix]) + 1)
            command = command + ' --network public'
            if addNicType:
                command = command + ' --nicType %s' % DEFAULT_NIC
        else:
            command = command + ' --nics ' + str(len(options[prefix]))
        # sort the order of nics since some tests depend on the order
        for item in sorted(options[prefix].keys()):
            network = 'public'
            if options[prefix][item] and 'network' in options[prefix][item]:
                network = GetComponent(options[prefix][item]['network'])
            if addNicType:
                if options[prefix][item] and \
                   'driver' in options[prefix][item] and \
                   options[prefix][item]['driver'] != 'any':
                    driver = options[prefix][item]['driver']
                else:
                    # defaulting to e1000e PR1022571
                    driver = DEFAULT_NIC

            log.info("putting %s.%s on network %s " % (prefix, item, network))
            command = command + ' --network ' + network
            if addNicType:
                command = command + ' --nicType ' + driver
    return command


def AddSSDToCommand(options, command, default_ssdsize):
    for num in options['ssd']:
        size = None
        if 'size' in options['ssd'][num]:
            size = options['ssd'][num]['size']
        else:
            size = default_ssdsize
        log.debug("Adding ssd disk.%s with size=%s" % (num, size))
        command = command + ' --ssd %s' % size
    return command


def AddCPUsToCommand(options, command, default_cpus):
    cpus = default_cpus
    if 'cpus' in options:
        if int(options['cpus']['cores']) >= int(default_cpus):
            cpus = options['cpus']['cores']
        else:
            log.info("Invalid number of CPU cores, should be >= %s"
                     % default_cpus)
            return None
    command = command + ' --cpus ' + str(cpus)
    return command


def AddMemoryToCommand(options, command, default_memory):
    memory = default_memory
    if 'memory' in options:
        if int(options['memory']['size']) >= int(default_memory):
            memory = options['memory']['size']
        else:
            log.info("Invalid memory size, should be >= %s" % default_memory)
            return None
    command = command + ' --memory ' + str(memory)
    return command


def deployment_post_process(options, instanceName, is_vm=True):
    if ('NIMBUS_CONFIG_FILE' in os.environ and 'NIMBUS' in os.environ and is_vm):
        func = nimbus_utils.read_nimbus_config
        config_dict = func(os.environ['NIMBUS_CONFIG_FILE'],
                           os.environ['NIMBUS'])

        def to_int(val):
            if val is not None:
                return int(val)
        cpu_reservation = to_int(config_dict.get(KEY_CPU_RESERVATION))
        memory_reservation = to_int(config_dict.get(KEY_MEMORY_RESERVATION))
        mhz_per_core = 1000 # BUG: 1420892
        if cpu_reservation or memory_reservation:
            vc_options = get_vc_info()
            vsphere_utilities.configure_vm_reservation(
                vc_options, instanceName, cpu_reservation=cpu_reservation,
                memory_reservation=memory_reservation,
                mhz_per_core=mhz_per_core)


class AffinityOptions(object):

    def __init__(self):
        super(AffinityOptions, self).__init__()
        self.affinitized_vms = []
        self.affinitized_pod = None
        self.affinitized_pod_updated = False
        self.sem = eventlet.semaphore.Semaphore()

    @utilities.with_sem(lambda s, *a, **kw: s.sem)
    def update_affinitized_vm(self, vm_name):
        self.affinitized_vms.append(vm_name)

    @utilities.with_sem(lambda s, *a, **kw: s.sem)
    def get_affinitized_option(self, vm_name):
        others = [x for x in self.affinitized_vms if x != vm_name]
        if vm_name in self.affinitized_vms and others:
            affinity_opts = (" --affinitizedVM %s " %
                             " --affinitizedVM ".join(others))
        else:
            affinity_opts = " "
        return affinity_opts

    @utilities.with_sem(lambda s, *a, **kw: s.sem)
    def update_nimbus_pod(self, vm_name, pod):
        if self.affinitized_vms and self.affinitized_vms[0] == vm_name:
            self.affinitized_pod = pod
            self.affinitized_pod_updated = True
        log.debug("%s is deployed on nimbus pod %s" % (vm_name, pod))

    @utilities.with_sem(lambda s, *a, **kw: s.sem)
    def _get_nimbus_pod(self, vm_name):
        if ((not self.affinitized_vms or
             vm_name not in self.affinitized_vms or
             vm_name == self.affinitized_vms[0])):
            return
        if not self.affinitized_pod_updated:
            return 'RETRY'
        return self.affinitized_pod

    def get_nimbus_pod(self, vm_name):
        for _ in xrange(60):  # wait for 60mins
            pod = self._get_nimbus_pod(vm_name)
            if pod == 'RETRY':
                log.debug("Waiting on nimbus pod for %s" %
                          self.affinitized_vms[0])
                time.sleep(60)
            else:
                return pod

def NimbusDeploy(component, componentInstanceName, command, options, is_vm=True):
    log.info("Routine to deploy %s using Nimbus" % component)
    runid = GetRunId(options)
    sleepTime = 60
    ip = NimbusVMExists(componentInstanceName)
    if ip:
        queue.put(
            component + " " + str(runid) + " " + ip + " " +
            componentInstanceName)
        return ip

    log_dir = GetComponentLogDir(component, options)
    resultFile = "%s%s%s%s-result.json" % (log_dir, os.sep, component, str(runid))
    command = command + ' --result ' + resultFile

    pod = KVMAffinity.get_nimbus_pod(componentInstanceName)
    if pod is not None:
        env = os.environ
        env['NIMBUS'] = pod
    else:
        env = None
    log.debug("Deploy on Nimbus using command: %s" % command)

    nimbusStatus = None
    bootTimeout = 2700
    timeout = bootTimeout * (int(MAX_RETRIES))
    log_file = "%s/deploy.log" % log_dir
    log.info("nimbus output for %s is in %s" % (component, log_file))
    with open(log_file, "a") as file_handle:
        nimbusOutput = RunCommand(command, returnObject=True, env=env,
                                  stdout=file_handle, stderr=file_handle)
        while ((nimbusStatus is None) and (timeout > 0)):
            nimbusStatus = nimbusOutput.poll()
            time.sleep(sleepTime)
            timeout = (timeout - sleepTime)
            log.info("waiting for nimbus %s deploy to complete, time left:\
                     %s" % (componentInstanceName, timeout))

        if (int(timeout) <= 0):
            nimbusStatus = 1  # mark nimbus status as failure
            nimbusOutput.kill()
            log.warn('TIMEOUT: nimbus OVF deploy failed')

    if nimbusStatus:
        log.info("nimbus %s exitcode %s" % (component, nimbusStatus))
        queue.put(component + " " + str(runid) + " " +
                  "None" + " " + componentInstanceName)
        return None

    result_json = json.loads(open(resultFile).read())
    log.debug("instance: %s ip: %s " %
              (result_json['name'], result_json['ip']))
    ip = result_json['ip']

    pod = result_json.get('pod')
    KVMAffinity.update_nimbus_pod(componentInstanceName, pod)

    #
    # xxx(hchilkot):
    # if component to be deployed is esx
    # don't update the global json_data.
    # This may cause failure while deploying
    # nsxedge, controller etc. on the esx hosts
    # since we delete/create the datastores in esx.
    # the json_data should be updated only after
    # post processing is completed.
    # Ideally all components should update json_data
    # with ip info in their respective methods.
    # See PR 1480672.
    #
    if component != "ESX":
        message = component + " " + str(runid) + " " + ip + " " \
                  + componentInstanceName
        queue.put(message)
        update_result(message, json_data)

    if ip is not None:
        deployment_post_process(options, componentInstanceName,is_vm)
    return ip

def CheckVSMServiceStatusAfterDeployment(ip, username, password):
    vsm_obj = vsm.VSM(ip, username, password, "")
    appliance_mgmt_obj = nsxapi_appliance_management.NSXAPIApplianceManagement(vsm_obj)
    status = appliance_mgmt_obj.get_vsm_service_status()
    max_retry = 120
    while((status != RUNNING) and (max_retry>0)):
      status = appliance_mgmt_obj.get_vsm_service_status()
      time.sleep(SLEEP_TIME)
      max_retry = max_retry-1
    if status != RUNNING:
      return FAILURE
    else:
      return SUCCESS

def WaitForInventory(component, componentIndex, componentInstanceName,
                     options, nested=False):
    sleepTime = 60
    bootTimeout = 2700
    instanceWaitTime = 4200
    data = json.loads(open(cmdOpts.config).read())
    component = component.lower()
    timeout = bootTimeout * (int(MAX_RETRIES))
    for option in data[component][componentIndex].keys():
        # Check if ip is defined in config.json file
        if option == 'ip':
            log.info("Found ip in json.config = %s " %
                     data[component][componentIndex]['ip'])
            return data[component][componentIndex]['ip']
    if nested:
        ip = vsphere_utilities.get_standalone_vm_ip(
            options, componentInstanceName)
    else:
        ip = NimbusVMExists(componentInstanceName)
    if ip:
        log.info("Found ip from componentInstanceName %s ip %s " %
                 (componentInstanceName, ip))
        return ip

    while(int(timeout) > 0):
        time.sleep(sleepTime)
        timeout = (timeout - sleepTime)
        log.info("Waiting for %s %s %s to complete, time left: %s\
           " % (componentInstanceName, component, componentIndex, timeout))
        for temp in json_data[component][componentIndex].keys():
            # Check if ip is defined in global json_data
            if temp == 'ip':
                log.info("Found ip in-memory global variable json_data  = %s "
                         % json_data[component][componentIndex]['ip'])
                return json_data[component][componentIndex]['ip']
        if (component == 'VC') and (int(timeout) > instanceWaitTime):
            continue
        if (int(timeout) < instanceWaitTime):
            if nested:
                ip = vsphere_utilities.get_standalone_vm_ip(
                    options, componentInstanceName)
            else:
                ip = NimbusVMExists(componentInstanceName)
            if ip:
                log.info("Found ip from componentInstanceName %s ip %s " %
                         (componentInstanceName, ip))
                return ip
    if (int(timeout) <= 0):
        log.debug("TIMEOUT:Failed to wait for %s " % componentInstanceName)
        return None


def GetInstanceNameFromSpec(component, options):
    build = GetBuild(options)
    if re.search("/", build):
        temp = re.split(r"/", build)
        for item in temp:
            if re.match("^[0-9]*$", item):
                build = "pxe-%s" % item
    return GetInstanceName(component, build, options['runid'],
                           cmdOpts.testrunid)


def GetInstanceName(component=None, build=None, index=None, testrunId=None):
    instanceName = 'vdnet-' + component.lower() + '-' + str(build) + '-' + \
                   str(index)
    if testrunId:
        instanceName = instanceName + '-' + testrunId
    user = GetCurrentUser()
    instanceName = user + '-' + instanceName
    envUser = None
    if 'USER' in os.environ.keys():
        envUser = os.environ['USER']
    if ((envUser is not None) and (envUser not in instanceName)):
        instanceName = envUser + '-' + instanceName
    return instanceName


def GetAutodeployServer(options):

    if ('installtype' in options) and (options['installtype'] == 'stateless') and \
       ('autodeployserver' in options):
        temp = re.split(r"\.", options['autodeployserver'])
        # component = temp[0]
        index = temp[1]
        # remove [] in index
        index = re.sub(r'\[|\]', '', index)
    instanceName = GetInstanceName(
        "VC", json_data['vc'][index]['build'], index, cmdOpts.testrunid)
    return (index, instanceName)


def GetAutodeployComponent(options, component):
    if (component in options):
        temp = re.split(r"\.", options[component])
        index = temp[1]
        # remove [] in index
        index = re.sub(r'\[|\]', '', index)
    instanceName = GetInstanceName(component.upper(),
                                   json_data[component][index]['build'], index,
                                   cmdOpts.testrunid)
    return (index, instanceName)


def KillInstance(options, component=None):
    log.info("Routine to kill instance using Nimbus")
    user = GetCurrentUser()
    envUser = None
    if 'USER' in os.environ.keys():
        envUser = os.environ['USER']
        log.info("Env user is %s and current user is %s" % (envUser, user))
    else:
        log.info("No USER entry in env and current user is %s" % (user))

    if 'instance' in options:
        instanceName = options['instance']
    elif component is not None:
        instanceName = GetInstanceNameFromSpec(component, options)
    else:
        log.info("Instance name is not passed")
        return 0
    nimbusBin = NIMBUS_BASE + '/bin/nimbus-ctl'

    # First, power off the VM
    command = nimbusBin + ' off ' + instanceName
    log.debug("command %s" % command)
    nimbusOutput = RunCommand(command, returnObject=False)
    log.debug("Powering off VM result: %r" % repr(nimbusOutput))

    # Now, destroy the VM
    command = nimbusBin + ' destroy ' + instanceName
    log.debug("command %s" % command)
    nimbusOutput = RunCommand(command, returnObject=False)
    log.debug("Destroying VM result: %r" % repr(nimbusOutput))


def NimbusVMExists(instanceName):
    options = get_vc_info()
    ip = None
    if (not rdops_public_pod):
        ip = nsx_network.get_vm_ip(options, instanceName)
    else:
        nimbus_bin = NIMBUS_BASE + '/bin/nimbus-ctl'
        command = nimbus_bin + ' ip ' + instanceName
        log.info("command %s" % command)
        nimbus_output = RunCommand(command, returnObject=False)
        pattern = "%s: %s" % (instanceName, regex_utils.ip)
        data = re.findall(pattern, str(nimbus_output))
        if data:
            ip = data[0]

    if not ip:
        log.debug("%s ip returned by get_vm_ip" % (ip))
        log.debug("Nimbus VM %s does not exist" % (instanceName))
        return False
    else:
        log.info("Found instance %s with IP=%s" % (instanceName, ip))
        return ip


# This method collects the screenshot of the deployed
# VM in case of failures. This will be helpful for
# debugging and to know what might have gone wrong.


def CollectScreenshot(component, options, password):
    if 'instance' in options:
        instanceName = options['instance']
    else:
        log.info("Instance name is missing")
        return None

    nimbusBin = NIMBUS_BASE + '/bin/nimbus-ctl'
    if 'username' in options:
        username = options['username']
    else:
        username = 'root'

    logDir = GetComponentLogDir(component, options)
    # compose the command to collect the screenshot
    command = nimbusBin + ' --username ' + username \
        + ' --password ' + password + ' --outputPath ' \
        + logDir + ' screenshot ' + instanceName
    log.debug("command %s" % command)

    (rc, stdout, stderr) = RunCommand(command)
    WriteDeployOutput(component, options, stdout)


def CollectBundle(component, options, supportBundle, password):
    if options.get('instance') in ('None', '', None):
        log.info("No instance name in %s" % options)
        return

    instanceName = options['instance']
    nimbusBin = NIMBUS_BASE + '/bin/nimbus-ctl'
    if 'username' in options:
        username = options['username']
    else:
        username = 'root'

    logDir = GetComponentLogDir(component, options)

    # compose the command to collect the bundle
    command = nimbusBin + ' --username ' + username \
        + ' --password ' + password + ' --outputPath ' \
        + logDir + supportBundle + instanceName
    log.debug("command %s" % command)

    (rc, stdout, stderr) = RunCommand(
        command, returnObject=False, maxTimeout=600)
    WriteDeployOutput(component, options, stdout)


def CollectVCBundle(options):
    SetRunId("VC", options)
    log.info("Routine to collect VC bundle")
    if options.get('instance') in ('None', '', None):
        log.info("No instance name for VC in %s" % options)
        return
    supportBundle = ' vc-supportbundle '
    if 'password' in options:
        password = options['password']
    else:
        password = 'vmware'
    CollectScreenshot("VC", options, password)
    CollectBundle("VC", options, supportBundle, password)


def CollectESXBundle(options):
    SetRunId("ESX", options)
    log.info("Routine to collect ESX bundle")
    if options.get('instance') in ('None', '', None):
        # Collect bundle is not supported for physical ESXs
        log.info("No instance name for ESX in %s" % options)
        return
    supportBundle = ' esx-supportbundle '
    if 'password' in options:
        password = options['password']
    else:
        password = DEFAULT_ESX_PASSWORD
    CollectScreenshot("ESX", options, password)
    CollectBundle("ESX", options, supportBundle, password)


def CollectVSMBundle(options):
    SetRunId("VSM", options)
    log.info("Routine to collect VSM bundle")
    if options.get('ip') in ('None', '', None):
        log.info("No instance ip in %s" % options)
        return
    ip = options['ip']
    nimbusBin = NIMBUS_BASE + '/bin/nimbus-vsm-supportbundle'
    # Since nimbus-vsm-supportbundle uses appliance-management endpoint
    # to get the support bundle, use admin/default as userid/passwd
    username = 'admin'
    password = 'default'

    logDir = GetComponentLogDir("VSM", options)

    # compose the command to collect ESX bundle
    command = nimbusBin + ' --username ' + username \
        + ' --password ' + password + ' --outputPath ' \
        + logDir + ' ' + ip
    log.debug("command %s" % command)

    (rc, stdout, stderr) = RunCommand(command)
    WriteDeployOutput("VSM", options, stdout)

# Parse the JSON testbed spec and spawn as many threads as
# necessary for respective product deployments


def DeployTestbed(data, cleanUp=None, collectLogs=None, logdir=None):
    deployKeyMap = dict(
        esx=DeployESXInVMUsingNimbus,
        vc=DeployNimbusVC,
        vsm=DeployNimbusVSM,
        nvpcontroller=DeployNimbusNVPController,
        neutron=DeployNimbusNeutron,
        xen=DeployNimbusXEN,
        kvm=DeployNimbusKVM,
        servicenode=DeployNimbusServiceNode,
        gateway=DeployNimbusGateway,
        authserver=DeployNimbusAuthServer,
        nsxmanager=DeployNimbusNSXManager,
        torgateway=DeployNimbusTORGateway,
        nsxcontroller=DeployNimbusNSXController,
        nsxedge=DeployNimbusNSXEdge,
        loginsightserver=DeployNimbusLogInsightServer,
        spirent=DeploySpirentVM,
        nsx_uidriver=DeployNimbusNSXUIDriver)
    supportBundleKeyMap = dict(
        esx=CollectESXBundle,
        vc=CollectVCBundle,
        vsm=CollectVSMBundle)
    pool = thread_utils.EventletGreenPool(30)
    for x, y in data.get('kvm',{}).iteritems():
        y.update({'runid': x})
        KVMAffinity.update_affinitized_vm(GetInstanceNameFromSpec("KVM", y))
    for key in data:
        key = key.lower()
        if key not in deployKeyMap:
            log.info("given %s component is not supported" % key)
            continue
        if collectLogs is not None and key not in supportBundleKeyMap:
            log.info("SupportBundle is not supported for component %s"
                     % key)
            continue
        for instance in data[key]:
            options = data[key][instance]
            options['runid'] = instance
            if collectLogs is not None:
                if logdir is not None:
                    options['logdir'] = logdir
                pool.spawn(supportBundleKeyMap[key], options)
            elif cleanUp is not None:
                pool.spawn(KillInstance, options, component=key)
            else:
                log.info("Spawning thread %s for deploying %s.%s" %
                         (deployKeyMap[key], key, instance))
                pool.spawn(deployKeyMap[key], options)

    if pool.running():
        pool.waitall()


def UpdateJSON(item, _json_data):
    temp = item.split(' ')
    product = str(temp[0])
    index = str(temp[1])
    ip = str(temp[2])
    instance = str(temp[3])
    product = product.lower()
    prd = {}
    temp = {'ip': ip, 'instance': instance}
    prd[index] = temp

    _json_data[product][index]['ip'] = ip
    _json_data[product][index]['instance'] = instance

    return


@utilities.with_sem(lambda *a, **kw: sem)
def update_result(message, _json_data):
    log.info("updating json_data with %s" % message)
    UpdateJSON(message, _json_data)


def GetRunId(options):
    runid = None
    if 'runid' in options:
        runid = options['runid']
    else:
        runid = os.getpid()
        options['runid'] = runid
    return runid


def GetLogDir(options):
    logDir = None
    if 'logdir' in options:
        logDir = options['logdir']
    else:
        logDir = cmdOpts.logdir
    return "%s/testbed" % logDir


def GetComponentLogDir(component, options):
    logDir = GetLogDir(options)
    logDir = "%s/%s-%s" % (logDir, component.lower(), str(options['runid']))
    if not os.path.exists(logDir):
        os.mkdir(logDir)

    return logDir


def WriteDeployOutput(component, options, output):
    if output is None:
        log.debug("No output found for deployment of: %r" % component)
        return
    logDir = GetComponentLogDir(component, options)
    logFile = "%s/deploy.log" % logDir
    log.info("nimbus output for %s is in %s" % (component, logFile))
    fileHandle = open(logFile, "a")
    with open(logFile, 'a') as fileHandle:
        fileHandle.write(output)


def CreateServerOVF(build):
    """function to check for availability of
       servervmovf build for the given build
       and create ovf build if it doesn't exists.
    @params build : esx build number
    @return None
    """

    options = dict()
    options['runid'] = build
    script_dir = os.path.dirname(os.path.realpath(__file__))
    ovf_create_command = '%s/generate-ovf --build %s ' \
        % (script_dir, build)
    (rc, stdout, stderr) = RunCommand(ovf_create_command, False, 2500)
    WriteDeployOutput("build", options, stdout)
    log.info("Collect server ovf stdout %s" % stdout)
    log.info("Collect server ovf  stderr %s" % stderr)


def PreProcessESX(data, component):
    """function to do pre processing required for
       deploying esx. When user has specified template
       or linked clone mode then in this case
       servervmovf build is required. This function
       calls the script which handles the creation
       of servervmovf.

    @param options : spec containing esx information
    @return None (json_data will be updated)
    """
    # TODO (gjayavelu/hchilkot): Nimbus ToT takes care of generating ovf now
    # This block to generate ovf for ESX can be removed after proper evalaution
    # There is dependency on NIMBUS_CONFIG_FILE for generateOVF.py, but that is
    # not set in case of nimbus public pod
    if rdops_public_pod:
        return
    pool = thread_utils.EventletGreenPool(30)
    builds = list()
    for instance in data.keys():
        if 'ip' not in data[instance].keys():
            for key in data[instance].keys():
                key.lower()
                if ((key == 'installtype') and
                    (data[instance][key] == 'template' or
                     data[instance][key] == 'linkedclone')):
                    builds.append(str(data[instance]['build']))
                else:
                    continue
    if builds:
        builds = list(set(builds))
        for build in builds:
            pool.spawn(CreateServerOVF, build)
        if pool.running():
            pool.waitall()


def ProvisionNetwork(options, component):
    """function to provision network (NSX)

    @param options spec containing network information
    @return None (json_data will be updated)
    """
    SetRunId(component, options)
    name = GetNetworkName(options)
    if not network_provision_support:
        regexp = re.compile(r'isolated')
        if regexp.search(name) is None:
            raise ValueError("Network provisioning not supported on this POD. "
                             "Use VLAN backed network by passing name as isolated-xx, "
                             "where xx is 01 to 08")
    else:
        name = "%s-%s" % (name, str(options['runid']))
        if not IsNetworkExist(name):
            log.info("Provisioning network %s" % name)
            script_dir = os.path.dirname(os.path.realpath(__file__))
            # constructing command to create network
            network_create_command = '%s/nimbus-nsxnetwork --action create ' \
                '--name %s ' % (script_dir, name)
            (_, stdout, stderr) = RunCommand(
                network_create_command, returnObject=False, maxTimeout=1800,
                strict=True)
            WriteDeployOutput("Network", options, stdout)
        # nimbus scripts always prefix vms and networks name with userid
        user = GetCurrentUser()
        name = "%s-%s" % (user, name)
    json_data['network'][str(options['runid'])]['instance'] = name


def GetComponent(value):
    """ function to resolve component index

    @param value in <component>.[<index>] format
    @return instance name of the given component
    """
    if not re.search("\.", value):
        return value

    # TODO: move/re-write resolving index in Perl to Python
    # and re-use same code
    temp = re.split(r"\.", value)
    component = temp[0]
    index = temp[1]
    # remove [] in index
    index = re.sub(r'\[|\]', '', index)

    return json_data[component][index]['instance']


def GetNetworkName(options):
    """ function get full network name based on runid and
    user defined name

    @params options dictionary with name and runid keys
    @return network name
    """
    if 'name' in options:
        name = options['name']
    else:
        name = 'nsx-network'
    return name


def PreProcessNetwork(data, component):
    """ function to pre-process Network before
    actual network provision.

    @params data dictionary containing network spec
    @returns None
    """
    for instance in data.keys():
        options = data[instance]
        options['runid'] = instance
        ProvisionNetwork(options, component)


def PreProcessNSX(data, component):
    components = ['nsxmanager',
                  'nsxedge',
                  'nsxcontroller',
                  'vsm',
                  'loginsightserver']
    ovf_search_pattern_dict = {'nsxmanager': 'NSX-Manager-.*.ovf',
                              'nsxedge': 'nsx-edge-.*.ovf',
                              'nsxcontroller': 'nsx-controller-.*.ovf',
                              'vsm': 'VMware-NSX-Manager.*.ovf',
                              'loginsightserver': 'VMware-vRealize-Log-Insight.*.ova'
                              }
    if component.lower() in components:
        for instance in data.keys():
            if 'ip' not in data[instance]:
                build = GetBuild(data[instance])
                url = build_utilities.get_build_deliverable_url(
                    build, ovf_search_pattern_dict[component])
                json_data[component][instance]['build'] = build
                json_data[component][instance]['ovfurl'] = url


def PreprocessDeployTestbed(data):
    """ function to pre-process or run any steps before
    actual appliances deployment. Example, network provisioning

    @params data dictionary containing deployment spec
    @returns None (TODO: revisit this)
    """
    preprocessKeyMap = dict(
        network=PreProcessNetwork,
        esx=PreProcessESX,
        nsxmanager=PreProcessNSX,
        nsxcontroller=PreProcessNSX,
        nsxedge=PreProcessNSX,
        loginsightserver=PreProcessNSX,
        vsm=PreProcessNSX)
    pool = thread_utils.EventletGreenPool(30)
    for key in data.keys():
        key = key.lower()
        if key not in preprocessKeyMap.keys():
            log.debug("No pre-process for %s component" % key)
            continue

        pool.spawn(preprocessKeyMap[key], data[key], key)

    if pool.running():
        pool.waitall()


def source(script, update=True):
    cmd = ". %s; env" % script
    rc, data, _ = RunCommandSync(cmd, shell=True)

    if rc:
        log.warn("Failed to read config values from %s" % script)
        return {}
    else:
        env = dict((line.split("=", 1) for line in data.splitlines()
                    if '=' in line))
        if update:
            os.environ.update(env)
        return env


def IsNetworkExist(networkName):
    options = get_vc_info()
    options.name = networkName

    network = nsx_network.get_network_on_vc(options)
    if not network:
        log.info("Network %s does not exist" % (networkName))
        return False
    else:
        return True


def get_vc_info():
    options = nsx_network.Options()
    if ('NIMBUS_CONFIG_FILE' in os.environ.keys()) and \
       ('NIMBUS' in os.environ.keys()):
        func = nimbus_utils.read_nimbus_config
        config_dict = func(os.environ['NIMBUS_CONFIG_FILE'],
                           os.environ['NIMBUS'])
        options.vc = config_dict['vc']
        options.vc_user = config_dict['vc_user']
        options.vc_password = config_dict['vc_password']
        options.datacenter = config_dict['datacenter']

    return options


def nimbus_main():
    global cmdOpts

    # Set Pxe base directory to be netfvt's DBC to avoid issues
    # due to lack of disk space in user's home directory.
    # This directory is used by nimbus-esxdeploy to copy
    # pxe images. Changed /dbc/pa-dbc1113/netfvt/nimbus dir
    # permissions so that any directory or file that you create
    # will have write permissions for all users using umask by
    # running 'umask 0022' on /dbc/pa-dbc1113/netfvt/nimbus.
    # Any files that gets created will have ~022 permissons
    # which is 755. If all users use the same PXE location,
    # it will reduce the deploy  time too since we reuse the pxe files.
    #
    if ('PXE_BASE_DIR' not in os.environ.keys()):
        os.environ['PXE_BASE_DIR'] = '/dbc/pa-dbc1113/netfvt/nimbus'

    # Read the JSON testbed spec
    global json_data
    with open(cmdOpts.config, 'r') as fo:
        json_data = json.loads(fo.read())
    if cmdOpts.cleanup:
        DeployTestbed(json_data, cmdOpts.cleanup)
    elif cmdOpts.collectlogs:
        DeployTestbed(json_data, None, cmdOpts.collectlogs, cmdOpts.logdir)
    else:
        # Pre-process before deploying testbed
        if not cmdOpts.onecloud:
            PreprocessDeployTestbed(json_data)

        DeployTestbed(json_data)

    # Now read from the queue and update the local json variable
    while (queue.qsize() > 0):
        item = queue.get()
        UpdateJSON(item, json_data)
        queue.task_done()

    if queue.qsize() > 0:
        queue.join()

    # Write the local data to the JSON file
    testbed_path = os.path.join(cmdOpts.logdir, "testbed.json")
    with open(testbed_path, 'w') as outfile:
        json.dump(json_data, outfile, sort_keys=True, indent=4)
        outfile.flush()


def onecloud_main(options):
    """
    Called with spec to pre-deploy testbed nsx-provisioning will rewrite topo
    with IPs so that nimbus can complete the deployment, many settings that
    nsx-provisioning has as defaults in a file called vcloudsettings are
    gathered from the env which has been set by a podspec which contains
    ONECLOUD_*, namely ONECLOUD=1, ...
    ONECLOUD_USERNAME/_PASSWORD/_SERVER/_TENANT/_NETWORKS

    optional env settings from session.pm is ONECLOUD_REUSE, this is consumed
    here.
    A setting of some use for diagnosis is VAPP_SAVE, which tells
    provisioning to not destroy the vapp when deployment fails.
    That is not processed here, but  internally in the library.
    """
    # deprecated: vcloudsettings import settings
    # now, caller should have sourced onecloud podspec
    log.info('using ONECLOUD')
    env = source(options.podSpec, passthru_whole_podspec)
    assert 'ONECLOUD_SERVER' in env, \
        "ONECLOUD provisioning now requires onecloud settings in podspec"\
        " for example yaml/onecloud/podspec.sh"
    _username = env.get('ONECLOUD_USERNAME')
    if not _username:
        _username = GetCurrentUser()
    _password = env.get('ONECLOUD_PASSWORD')
    assert _password, "password required for onecloud operation is not present"
    _server = env['ONECLOUD_SERVER']
    _tenant = env['ONECLOUD_TENANT']
    _networks = env.get('ONECLOUD_NETWORKS')
    _catalog = env.get('ONECLOUD_CATALOG')
    _reuse = env.get('ONECLOUD_REUSE')
    _power = env.get('ONECLOUD_POWER')
    _loglevel = env.get('ONECLOUD_LOGLEVEL')
    if not _loglevel:
        _loglevel = loglevel

    vdnet_json = options.config
    log.info("converting %s to onecloud" % vdnet_json)
    onecloud_json = os.path.join(options.logdir, 'onecloud.json')
    onecloud_out = os.path.join(options.logdir, 'onecloud_out.yaml')
    kwargs = {'vdnet': 'True',
              'onecloud': 'True',
              'deploy': onecloud_json,
              'username': _username,
              'password': _password,
              'auth_url': _server,
              'tenant': _tenant,
              'outfile': onecloud_out,
              'log_level': _loglevel,
              'verbose': 'True'}

    if _networks:
        # e.g. yaml/vcloud/networks.yaml
        # onecloud requires the network mask/cidr and mgmt=y|n be set
        # this is not the same as legacy nimbus networks which to start
        # are simply named port-groups. Having this flag allows legacy
        # tests to be run on onecloud with little modification
        if _networks[0] != '/':
            # prefix with automation
            _networks = automd_prefix(_networks)
        kwargs['networks'] = _networks

    if _catalog:
        kwargs['catalog'] = _catalog

    lab_name = 'testbed'
    if _reuse:
        # process reuse =~ 0|1|name, if its 0 we dont pass --reuse
        if str(_reuse).lower() not in ('false', '0', 'no'):
            kwargs['reuse'] = 1
        # 1 means implicitly use latest previously deployed vapp
        #   starting with USER id e.g. jdoe_10_21
        # explicit vapp name requires we set reuse and
        # pass in --lab_name vapp-name
        # for doc see nsx-provision/vmware/provision/provision.py
        if _reuse.startswith(GetCurrentUser()):
            # specified lab must exist, otherwise provision will fail
            lab_name = _reuse

        if _power:
            # process power =~ 0|1
            # a vapp-reuse optimization where-in if networks are changed then
            # pass in vm
            # 0 is default which means no power-cycle, meaning vcloud-networks
            # are not editable, this cuts down reuse-time from 10m ->2m
            # for doc see nsx-provision/vmware/provision/provision.py
            #
            options.power = str(_power).lower()
            kwargs['power'] = options.power not in ('false', '0', 'no')

    with open(vdnet_json, 'r') as fo:
        _json = json.loads(fo.read())
    with open(onecloud_json, 'w') as fo:
        _json = {lab_name: _json}
        json.dump(_json, fo)
    log.info("calling nsx-provision for onecloud deployment: %s"
             % kwargs)
    cloud = provision.run(**kwargs)

    with open(onecloud_out, 'r') as fo:
        _dict = yaml.load(fo)

    with open(vdnet_json, 'w') as fo:
        # Drop the testbed!
        _dict = _dict.values()[0]
        json.dump(_dict, fo)

    log.info("completed onecloud provision of vapp %s, new config in %s" %
             (cloud._vapp_name, options.config))
    return _dict


def main(args):
    global cmdOpts
    global KVMAffinity
    KVMAffinity = AffinityOptions()
    try:
        cmdOpts, _ = process_args(args)
        # Set the logging
        logDir = "%s/testbed" % cmdOpts.logdir
        if not os.path.exists(logDir):
            os.mkdir(logDir)

        setup_logging()
        set_env_podspec()
        env = source(cmdOpts.podSpec, passthru_whole_podspec)
        if not cmdOpts.onecloud:
            cmdOpts.onecloud = env.get('ONECLOUD') or os.environ.get('ONECLOUD')
        if cmdOpts.onecloud:
            testbed = onecloud_main(cmdOpts)

            # post-process new-testbed esx will skip if deploy is not
            # linkedclone nor template
            _reuse = env.get('ONECLOUD_REUSE')
            if _reuse is not None:
                _reuse = str(_reuse).lower() not in ('false', '0', 'no')
            if 'esx' in testbed and not _reuse:
                _all = len(testbed['esx'])
                pool = thread_utils.EventletGreenPool(_all)
                for index, config in testbed['esx'].iteritems():
                    ip = config['ip']
                    args = [config, ip]
                    pool.spawn(NimbusESXDeploymentPostProcess, *args)
                pool.waitall()

        nimbus_main()
    except Exception:
        log.exception("Deploy Testbed Failed with exception !")
        raise
    log.info("Exiting Main Thread")

if __name__ == "__main__":
    main(sys.argv[1:])
