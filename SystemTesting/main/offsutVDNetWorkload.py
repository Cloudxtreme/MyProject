#!/build/toolchain/lin32/python-2.7.9-openssl1.0.1k/bin/python

#
# We register this script as offsut workload for VDNet in CAT.
# It will be executed from CAT launcher (example: cat-pa-launcher-1.eng.vmware.com)
# on one of vdnet master controller
# (need an extra step i.e configure vmktestdevnanny to login with no password).
# CAT launches this script with a bunch of command line parameters in addition
# to the custom parameters that we configured in CAT.
# For example, it will look like this:
#
#/vmsrc/vdnet/esx5x-stable/automation/main/offsutVDNetWorkload.py
# --framework=vdnet --testrunid 1890813 --location PA --machineip 10.115.172.176
# --resultsdir /PA/results/esx/0/1/8/9/0/8/1/3/USE924N1VD
# --resultsurl http://cat.eng.vmware.com/PA/results/esx/0/1/8/9/0/8/1/3/USE924N1VD/
# --macaddrs 00:1b:21:11:71:1a,00:1b:21:11:71:1b,78:e71:8f:54:ba,
# 78:e71:8f:54:bc,78:e71:8f:54:be,78:e71:8f:54:c0
# --psodurl http://cat.eng.vmware.com/tester/testruns/1890813/field/result/
# --product visor --esx_vmtree cat-pa-builder-1.eng.vmware.com:/snapshots/
# vmkernel-main/obj/clean/1415885/bora --esx_blddir
# cat-pa-builder-1.eng.vmware.com:/snapshots/vmkernel-main/obj/clean/1415885/
# bora/build --esx_pxedir /mts/builder-pxe/vmkernel-main/obj/clean/1415885/visor
#
# Here, only --framework=vdnet is the option I defined, rest comes from CAT.
# Using these information, this script:
# - if --machineip is 0.0.0.0 i.e no machine is given,
#   then using the given pxedir, this script deploys ESX using NIMBUS
# - configures the host: staf installation, disabling firewall
# - then the given vdnet script will be run, default is a shell script
#   to virtual devices BAT tests.
# - the script will monitor the test status and report fail, pass, psod, or
#   timeout back to CAT.
#


from subprocess import Popen, PIPE
from optparse import OptionParser
import csv
import os
import pwd
import sys
import time
import json
import ssl
import httplib
import urllib
import urllib2
import re
import logging
import traceback
import pprint
import paramiko
import yaml
import signal
import tempfile

global logger
global vcInstanceName
global esxInstanceNames
global sslUnverifiedContext
logger = logging.getLogger('vdnet.cat.launcher')

NICIRA_BUILD_API = 'https://devdashboard.nicira.eng.vmware.com'
NICIRA_BUILD_URL = 'http://apt.nicira.eng.vmware.com/builds'
PASS = 'PASS'
FAIL = 'FAIL'
INVALID_INFRASTRUCTURE = 'INVALID-I'
OFFSUT_YAML = 'offsutconfig.yaml'

scriptDir = os.path.dirname(os.path.abspath(__file__))


def load_yaml(yaml_file, dst_dir):
    """
    Routine to resolve all aliases and merges in the given yaml file by loading
    the required files included by using the tag "!include".

    Arguments:
        yaml_file: absolute path to TDS yaml file
        dst_dir: destination dir to create merged file
    Returns:
        dict: python dictionary which contains resolved aliases
              and merges
    """
    dir_name = os.path.dirname(os.path.abspath(yaml_file))
    yaml_file_name = os.path.basename(yaml_file)
    dst_file_path = os.path.join(dst_dir, yaml_file_name)
    yaml_data = open(yaml_file, 'r').read()

    file_start = True
    with open(dst_file_path, 'w+') as dst_file_handle:
        for line in yaml_data.splitlines():
            if file_start and line.startswith('!include'):
                include_files = line.split()[1:]
                for include_file in include_files:
                    include_file_path = os.path.join(dir_name, include_file)
                    if not os.path.exists(include_file_path):
                        raise RuntimeError("%s doesn't exist in directory %s" %
                                           (include_file, dir_name))
                    with open(include_file_path, 'r') as include_file_handle:
                        dst_file_handle.write(include_file_handle.read())
            else:
                dst_file_handle.write(line)
                dst_file_handle.write('\n')
                file_start = False
    logger.info('Merged file can be found at: %r' % dst_file_path)
    with open(dst_file_path, 'r') as dst_file_handle:
        yaml_dict = yaml.load(dst_file_handle)
        os.remove(dst_file_path)
    return yaml_dict


def handler(*args):
    logger.debug('Signal handler called with options %s' % options)
    Cleanup(options, 2)
    sys.exit(1)


def KillChildProcesses(parentPID, sig=signal.SIGINT, timeout=3600):
    command = "ps -o pid --ppid %d --noheaders" % parentPID
    cmd = command.split(' ')
    ps_command = Popen(cmd, stdout=PIPE, stderr=PIPE)
    stdout, stderr = ps_command.communicate()
    if (ps_command.returncode != 0):
        logger.debug('returncode: %s with error %s' %
                     (ps_command.returncode, stderr))
        return False

    logger.debug("Kill child processes of process %d" % parentPID)
    for pid in stdout.split("\n")[:-1]:
        logger.debug("Child process %s will be killed" % pid)
        os.kill(int(pid), sig)
        killtime = timeout
        while (killtime > 0):
            try:
                os.kill(int(pid), 0)
                time.sleep(30)
                killtime -= 30
            except:
                break
        if (killtime <= 0):
            logger.debug(
                "Child process %s not killed after %d seconds" % (pid, timeout))
            return False
    return True


def Daemonize(stdin='/dev/null', stdout=None, stderr=None):
    try:
        if os.fork() > 0:
            sys.exit(0)
    except OSError, e:
        raise Exception, "%s [%d]" % (e.strerror, e.errno)
    os.setsid()
    os.chdir('/')
    os.umask(000)
    import signal
    signal.signal(signal.SIGHUP, signal.SIG_IGN)
    try:
        if os.fork() > 0:
            sys.exit(0)
    except OSError, e:
        raise Exception, "%s [%d]" % (e.strerror, e.errno)

    si = file(stdin, 'r')
    so = file(stdout, 'a+')
    se = file(stderr, 'a+', 0)
    os.dup2(si.fileno(), sys.stdin.fileno())
    os.dup2(so.fileno(), sys.stdout.fileno())
    os.dup2(se.fileno(), sys.stderr.fileno())


# Abstraction of command execution in the shell
# Also does extra logging so that this we can babysit this part of the code.
def RunCommand(command, returnObject=False):
    cmd = command.split(' ')
    logger.debug('%s' % cmd)
    p = None
    logger.debug('command : %s' % command)
    if returnObject:
        p = Popen(cmd, stdout=None, stderr=None)
    else:
        p = Popen(cmd, stdout=None, stderr=None)
        p.communicate()
        logger.debug('returncode: %s' % p.returncode)
        return p.returncode
    return p


# Abstract out the post results module. Takes returncode as a parameter and
# posts the results accordingly
def PostResultToCAT(options, returncode):
    testrunid = options.testrunid
    logger.debug("Process has returned. rc=%s" % returncode)
    # Post result if process completed.
    url = ['cat.eng.vmware.com:80',
           '/tester/testruns/%s/daemonupdate/' % testrunid]
    result = FAIL
    test_count = get_test_count(options)
    if returncode == 0:
        result = PASS
    elif test_count == 0:
        # if no test is run, treat it as infrastructure issue
        result = INVALID_INFRASTRUCTURE
    else:
        result = FAIL

    ret = False
    for i in range(60):
        if ret or not testrunid:
            break
        try:
            logger.debug("Trying to post result %s. Attempt %s ..." % (
                result, i))
            params = urllib.urlencode(
                {'testrunid': testrunid, 'result': result})
            headers = {"Content-type": "application/x-www-form-urlencoded",
                       "Accept": "text/plain"}
            conn = httplib.HTTPConnection(url[0])
            conn.request("POST", url[1], params, headers)
            response = conn.getresponse()
            if response.status == 200:
                ret = True
                logger.debug("Posted result: %s, return code: %s" %
                             (result, returncode))
                logger.debug("Post response: %s %s" %
                             (response.status, response.reason))
                response.read()
                conn.close()
        except Exception, e:
            logger.debug("Posting Result Exception: %s" % e)
    return


def GetLogDir(options):
    if options.resultsdir:
        logdir = options.resultsdir[0]
    else:
        return tempfile.gettempdir()
    logdir = logdir.rsplit('/', 1)[0]
    return logdir


def Run(options):
    # Default values.
    bin = '/build/toolchain/lin32/python-2.7.9-openssl1.0.1k/bin/python'
    program = '/tmp/depot/testsuite/testsuite.py'

    p4 = [
        '/build/toolchain/lin32/perforce-r09.1/p4',
        '-p perforce-qa:1666',
        '-u qa',
        '-P b1gd3m0',
        '-c rmqa-perforce',
        'print %s' % options.file,
        'grep -v "%s"' % options.file,
    ]

    # Set global values accordinly from command line arguments.
    hosts = ','.join(options.machineip)
    logDir = GetLogDir(options)
    testrunid = options.testrunid
    logfile = "%s/launcher.log" % logDir

    LOG_FORMAT = '%(asctime)s %(levelname)-8s %(message)s'

    logging.basicConfig(filename=logfile,
                        level=logging.DEBUG,
                        format=LOG_FORMAT,
                        datefmt='%a, %d %b %Y %H:%M:%S')
    logger.debug("Received the following args ... \n %s" % ' '.join(sys.argv))
    logger.debug("Starting CAT Tests ...")
    logger.debug("Options: ---\n%s" % pprint.pformat(options.__dict__))

    # If we have //depot preceding config file name, read file directly from
    # perforce
    # keep this for backward compatibility
    vdnetFramework = 1
    if vdnetFramework:
        # CAT environment will pass command line parameters to this script. The
        # parameters include the ip address of the machines (ESX hosts) that are
        # registered as part of the tester. If tester is configured to use no
        # machine registered on CAT (Using Nimbus is one such case), then 0.0.0.0
        # will be passed as ip address. So, when ip address is 0.0.0.0, assume
        # ESX should be deployed using Nimbus.
        #
        # Also, --vpxd_vmtree and --vpxd_blddir will be passed as parameters
        # if vpxd is selected as one of the builders in a workload unit of CAT.
        # In that case, deploy VC using Nimbus
        #
        VC = ""
        vcvaBuild = None
        if options.vpxdvmtree:
            temp = re.split(r"/", options.vpxdvmtree)
            vcvaBuild = temp[-1]
            vcvaBuild = re.sub("bora-", "", vcvaBuild)

        vsmBuild = None
        if options.nsxvmtree:
            temp = re.split(r"/", options.nsxvmtree)
            vsmBuild = temp[-1]
            vsmBuild = re.sub("bora-", "", vsmBuild)

        esxBuild = GetESXBuild(options)

        if options.vdnetOptions != None:
            vdnetOptions = options.vdnetOptions
            #
            # Remove single quote in the beginning and end of the vdnet options
            #
            config = load_yaml(options.userconfig, logDir)

            if not 'options' in config:
                config['options'] = {}

            keyMap = {'host': esxBuild, 'vc': vcvaBuild,
                      'vsm': vsmBuild, 'neutron': vsmBuild, 'powerclivm': esxBuild}
            components = ['host', 'vc', 'vsm', 'neutron', 'powerclivm']
            if options.testrunid != None:
                config['options']['testrunid'] = options.testrunid

            #
            # BEGIN SETTING DEFAULT OPTIONS FOR CAT
            #
            if not 'options' in config:
                config['options'] = {}

            config['options']['testrunid'] = options.testrunid

            # update defaults specific to CAT
            config['options']['keeptestbed'] = 0

            #
            # Set the POD environment variables
            #
            if 'podspec' in config['options']:
                if 'NIMBUS_CONFIG_FILE' not in os.environ.keys():
                    os.environ['NIMBUS_CONFIG_FILE'] = \
                        '/mts/home4/netfvt/master-config.json'
                    podSpec = config['options']['podspec']
                    os.environ['NIMBUS'] = podSpec.split("/")[-1]

            # Set default for dontupgstafsdk to 1
            if not 'dontupgstafsdk' in config['options']:
                config['options']['dontupgstafsdk'] = 1

            # Set default for collectlogs to 1
            if not 'collectlogs' in config['options']:
                config['options']['collectlogs'] = 1

            # MUST FIX: change to notools=0
            if not 'notools' in config['options']:
                config['options']['notools'] = 1

            #
            # Set VDNET_MC_SETUP=0 since it is assumed that the
            # user ran vdnet at least once on the launcher host
            # to verify if the configuration is right
            #
            os.environ['VDNET_MC_SETUP'] = "0"

            # END OF DEFAULT OPTIONS FOR CAT YAML

            #
            # Initiate CAT POD cleanup in the background
            #
            #
            # Run cleanup command in the background
            # Note: this is best effort cleanup. The output
            # of this script not going to decide test output
            #
            scriptDir = os.path.dirname(os.path.realpath(__file__))
            try:
                if 'NIMBUS_CONFIG_FILE' in os.environ.keys():
                    command = "%s" % scriptDir + '/catPODCleanup'
                    RunCommand(command, returnObject=True)
                else:
                    logger.debug(
                        "Skip catPODCleanup as NIMBUS_CONFIG_FILE is not set")
            except Exception, error:
                logger.debug(
                    "Error running CAT POD cleanup script: %s" % error)
            # if options.ship_builds equal "0", will not ship builds to vdnet.
            if options.ship_builds == None or options.ship_builds == "1":
               for item in components:
                   if (item in config['testbed']) and (keyMap[item] != None):
                       for key in config['testbed'][item].keys():
                           config['testbed'][item][key]['build'] = keyMap[item]

            # if valid ip address is given, update it
            hosts = options.machineip
            if hosts and hosts[0] != '0.0.0.0':
                for index in range(len(config['testbed']['host'])):
                    componentIndex = index + 1
                    componentIndex = '[%s]' % componentIndex
                    config['testbed']['host'][
                        componentIndex]['ip'] = hosts[index]
                    endpoints = ['host', 'vm', 'setup']
                    for item in endpoints:
                        disconnectCmd = 'STAF local ' + item + \
                            ' disconnect anchor ' + hosts[index] + ':root'
                        logger.debug("Disconnecting anchor %s " %
                                     disconnectCmd)
                        RunCommand(disconnectCmd)

            configFile = logDir + os.sep + OFFSUT_YAML
            logger.debug("writing updated yaml file %s" % configFile)
            with open(configFile, 'w') as outfile:
                yaml.dump(config, outfile)
                outfile.flush()
                outfile.close()

            #
            # Remove single quote in the beginning and end of the vdnet options
            #
            vdnetOptions = vdnetOptions.strip('\'')
            cmd = "%s" % scriptDir + '/vdnet'
            opt = ["--config %s --logs %s" % (configFile, logDir)]
            opt = opt + [" %s" % vdnetOptions]
            cmd = '%s %s' % (cmd, ' '.join(opt))

        else:
            logger.debug('Neither vdnetOptions nor vdNetScript passed')
            return 1
        # Naming as vdnet-stderr since we don't print vdnet output to STDOUT
        # when using this script
        cmd = '%s 2>&1 | /usr/bin/tee %s/vdnet-stderr.log' % (cmd, logDir)

        logger.debug('VDNet command %s' % cmd)
    try:
        logger.debug("Command %s" % cmd)
        # Spaw subprocess for main script.
        logger.debug("user: %s" % (pwd.getpwuid(os.getuid())[0]))
        p = RunCommand(cmd, returnObject=True)
        logger.debug("Process ID: %s" % p.pid)

        # Poll for process completion.
        #  Check for PSOD or TIMEOUT and exit on occurrence.
        #  if testrunid is defined, then get the workload timeout by
        #  reading the CAT UI using the rest api
        #
        retries = 600
        wait = 60.0
        if not testrunid:
            wait = 1.0
        else:
            try:
                url = GetWorkloadURL(options)
                context = None
                if GetURLSchema(url) == 'https':
                    context = sslUnverifiedContext
                json_ = urllib.urlopen(url, context=context).read()
                workload = json.loads(json_)
                logger.debug("workload details %s" % workload)
                timeout = workload['timeout']
                # keep the offsut timeout less than
                # workload timeout in tester
                timeout = timeout - 120
                retries = timeout / 60
                logger.debug("Poll timeout updated to %s secs" % timeout)
            except Exception, e:
                logger.debug('Failed to get workload timeout, using default ' +
                             '36000 seconds: %s' % e)

        psodTimeout = False
        for i in range(retries):
            if p.poll() is None:
                logger.debug("sleeping %s secs" % retries)
                time.sleep(wait)
            else:
                break
            if options.psodurl:
                f = None
                status = ''
                try:
                    f = urllib2.urlopen(options.psodurl)
                    status = f.read()
                except Exception, e:
                    logger.debug("PSOD url Exception: %s" % e)
                if re.search('PSOD|TIMEOUT|INVALID', status, re.I):
                    logger.debug("Received status: %s" % status)
                    psodTimeout = True
                    break

        if p.poll() is None:
            # Handle case for PSOD and Timeout
            if psodTimeout:
                logger.debug("Looks like one of the hosts hit PSOD")
            else:
                logger.debug("Command: %s \nhas not returned after %s sec or PSOD." %
                             (cmd, wait * i))
            try:
                pgid = os.getpgid(p.pid)
                if (KillChildProcesses(p.pid) == True):
                    logger.debug(
                        "All the child processes of %s have been killed ..." % p.pid)
                # send SIGINT to the process group
                os.kill(p.pid, 2)
                logger.debug("Killing process group %s Done..." % pgid)
            except OSError, e:
                logger.debug("Failed to kill process %s: %s" % (pgid, e))

            return 1
        else:
            logger.debug("Return code from vdnet process %s" % p.returncode)
            return p.returncode
    except Exception:
        logger.debug("Test Run Process Exception:\n%s" %
                     traceback.format_exc())
        return 1


def SetupHost(hostname):
    """Setup the ESX CAT host"""
    username = 'root'
    password = None
    result = ''

    logger.debug("Setting up host %s" % hostname)
    password = GetHostPassword(hostname, username)
    if None == password:
        logger.debug("Unable to find host %s password" % hostname)
        return 1

    # Disable esx firewall
    result = DisableEsxiFirewall(hostname, username, password)
    logger.debug("Disable firewall rc %s" % result)
    if result != 0:
        return result

    return result


def GetHostPassword(hostname, username):
    """ Routine to get Host Password """
    pwdList = ['', 'ca$hc0w', 'vmw@re']

    password = None
    for pwd in pwdList:
        transport = paramiko.Transport((hostname, 22))
        logger.debug('Trying password %s' % pwd)
        try:
            transport.connect(username=username, password=pwd)
        except Exception, e:
            logger.debug('Transport connect failed %s' % e)
        else:
            password = pwd
            break
        finally:
            transport.close()

    return password


def DisableEsxiFirewall(hostname, username, password):
    """Disable ESXi firewall"""
    cmd = '/sbin/esxcli network firewall set --enabled=false'
    (rc, stdout, stderr) = RunSshCommand(hostname,
                                         username,
                                         password,
                                         cmd)
    return CheckExitStatus(cmd, rc, stdout, stderr)


def InstallEsxiStaf(hostname, username, password):
    """Install staf on ESXi"""
    stafCmds = [
        '/bin/mkdir /pa-group',
        '/sbin/esxcfg-nas -a -o pa-group -s cbs pa-group',
        '/bin/ln -s /vmfs/volumes/pa-group /pa-group/cbs',
        'source /.profile; /pa-group/cbs/non-framework/cbs/common/visor/setupVisorStaf.sh',
        "echo 'ca$hc0w' | passwd --stdin",
    ]
    for cmd in stafCmds:
        (rc, stdout, stderr) = RunSshCommand(hostname,
                                             username,
                                             password,
                                             cmd)
        CheckExitStatus(cmd, rc, stdout, stderr)

    # Verify staf is functioning
    return CheckStaf(hostname)


def CheckStaf(hostname):
    """Check staf is ping-able on the specified host"""
    for tries in range(4):
        cmd = '/usr/local/staf/bin/staf ' + hostname + ' ping ping'
        (rc, stdout, stderr) = RunCommand(cmd)
        if 'PONG' in stdout:
            return 0
        time.sleep(1)
    logger.debug('Staf check failed for host %s' % hostname)
    return 1


def RunSshCommand(hostname, username, password, command):
    """Run a ssh command, uses paramiko transport object"""
    logger.debug('RunSshCommand: ' + command)

    (rc, stdout, stderr) = [1, '', '']
    transport = paramiko.Transport((hostname, 22))

    try:
        transport.connect(username=username, password=password)
    except Exception, e:
        logger.debug('Transport connect failed %s' % e)
        stderr = e
        return (rc, stdout, stderr)

    session = transport.open_channel("session")
    session.exec_command(command)

    rc = session.recv_exit_status()
    stdout = []
    stderr = []

    while session.recv_ready():
        stdout.append(session.recv(100))
    stdout = "".join(stdout)

    while session.recv_stderr_ready():
        stderr.append(session.recv_stderr(100))
    stderr = "".join(stderr)

    transport.close()
    return (rc, stdout, stderr)


def CheckExitStatus(cmd, rc, stdout, stderr):
    """Check the exit status and log a warning if its not 0"""
    if rc != 0:
        logger.debug('Command %s returned exit status: %d, ' % (cmd, rc) +
                     'stdout: %s, stderr: %s' % (stdout, stderr))
    else:
        logger.debug('Command %s returned exit status: %d, ' % (cmd, rc) +
                     'stdout: %s, stderr: %s' % (stdout, stderr))
    return rc


def TestbedCollectLogs(options):
    results = GetLogDir(options)
    if results is None:
        logger.debug("Log directory is not given")
        return None

    configFile = results + os.sep + OFFSUT_YAML
    stream = open(configFile, 'r')
    config = yaml.load(stream)
    if 'collectlogs' in config['options']:
        if config['options']['collectlogs'] == 1:
            scriptDir = os.path.dirname(os.path.realpath(__file__))
            cmd = "%s" % scriptDir + '/../scripts/deployTestbed.py'
            testbedJSON = results + os.sep + "testbed.json"

            opt = ["--collectlogs --config %s --logdir %s" %
                   (testbedJSON, results)]
            if 'podspec' in config['options']:
                opt = opt + [" --podspec %s" % config['options']['podspec']]

            cmd = '%s %s' % (cmd, ' '.join(opt))
            logger.debug('Testbed collectlogs command %s' % cmd)
            return RunCommand(cmd)


def TestbedCleanup(options):
    results = GetLogDir(options)
    configFile = results + os.sep + OFFSUT_YAML
    stream = open(configFile, 'r')
    config = yaml.load(stream)
    if 'keeptestbed' in config['options']:
        if config['options']['keeptestbed'] == 0:
            scriptDir = os.path.dirname(os.path.realpath(__file__))
            cmd = "%s" % scriptDir + '/../scripts/deployTestbed.py'
            testbedJSON = results + os.sep + "testbed.json"

            opt = ["--cleanup --config %s --logdir %s" %
                   (testbedJSON, results)]
            if 'podspec' in config['options']:
                opt = opt + [" --podspec %s" % config['options']['podspec']]

            cmd = '%s %s' % (cmd, ' '.join(opt))
            logger.debug('Testbed cleanup command %s' % cmd)
            return RunCommand(cmd)


def GetESXBuild(options):
    #
    # options.esxpxedir sometimes contain pxe image location
    # which is not accessible everywhere for deployment.
    # For example,
    # /mts/builder-pxe/sb/vmkernel-main/release/clean/2494614/esxall-visor,
    # So, vmtree is better option to get build number that works for
    # both nimbus deployment and ESX upgrade using esxcli
    #
    esxBuild = None
    if options.vmtree:
        temp = re.split(r"/", options.vmtree)
        if re.search("bora-", temp[-2]):
            esxBuild = temp[-2]
            esxBuild = re.sub("bora-", "", esxBuild)
        elif re.search("sb-", temp[-2]):
            esxBuild = temp[-2]
    return esxBuild


def Cleanup(options, result):
    ssl._create_default_https_context = ssl._create_unverified_context
    PostResultToCAT(options, result)
    # Do a second round of cleanup, just in case vdnet missed any
    # deployed VMs and collect the logs before that.
    if result == 2:
        try:
            TestbedCollectLogs(options)
        except Exception, e:
            logger.debug('Failed to collect testbed logs %s' % e)

    try:
        TestbedCleanup(options)
    except Exception, e:
        logger.debug('Failed to do testbed cleanup %s' % e)

    owner = None
    if options.autotriage == "1":
        if options.owner == None or options.owner.strip() == "":
            owner = GetOwner(options)
        else:
            owner = options.owner.strip()


    if owner and result:
        # Run the Auto Triage script
        logger.debug("Running auto triage script")
        count = 0

        testrun_url = "https://%s/testrun/%s" % (GetCATServer(options),
                                                 options.testrunid)

        for (path, dirs, files) in os.walk(logdir):
            test_case = path.split('/')[-1]
            if re.match("\d+_", test_case):
                autoTriageCmd = '%s/../pylib/common/auto_triage_main.py -b -d %s ' \
                    '-a %s --file_product_bug %s -t %s --testrunurl %s' \
                    % (scriptDir, path, owner, options.file_product_bug,
                       test_case, testrun_url)

                RunCommand(autoTriageCmd)
                count += 1
        # If there were no tests run, check for errors in vdnet main session
        # which includes testbed deployment
        if count == 0:
            autoTriageCmd = '%s/../pylib/common/auto_triage_main.py -b -d %s ' \
                '-a %s -t %s --testrunurl %s' \
                % (scriptDir, logdir, owner, "VDNet Session", testrun_url)
            RunCommand(autoTriageCmd)


def GetOwner(options):
    ''' Routine to get testrun owner from testrunid '''
    tester = None
    try:
        url = GetTesterURL(options)
        logger.debug("tester api url: %s" % url)
        context = None
        if GetURLSchema(url) == 'https':
            context = sslUnverifiedContext
        json_data = urllib.urlopen(url, context=context).read()
        tester = json.loads(json_data)
        owner = tester['owner']
        logger.debug("Found tester owner: %s" % owner)
        return owner
    except Exception, error:
        logger.debug('Failed to get owner for tester: %s' % error)
        if tester != None:
            logger.debug('Tester queried: %s' % tester)


def GetCATServer(options):
    ''' Routine to get CAT server name from testrunid '''
    resultsurl = options.resultsurl
    temp = re.split(r"/", resultsurl)
    # cat-wdc-services.eng.vmware.com have API calls disabled, so using
    # nsx-cat.eng.vmware.com. Workaround for PR 1384769
    if temp[2] == "cat-wdc-services.eng.vmware.com":
        cat_server = "nsx-cat.eng.vmware.com"
    else:
        cat_server = temp[2]

    logger.debug("tester api url: %s" % cat_server)
    return cat_server


def GetTesterURL(options):
    ''' Routine to get tester URL from testrunid '''
    cat_server = GetCATServer(options)
    url = 'https://%s/api/v1.0/testrun/%s' % (cat_server, options.testrunid)
    context = None
    if GetURLSchema(url) == 'https':
        context = sslUnverifiedContext
    json_data = urllib.urlopen(url, context=context).read()
    testrun = json.loads(json_data)

    url = 'https://%s%s' % (cat_server, testrun['tester']['resource_uri'])
    logger.debug("tester api url: %s" % url)
    return url


def GetWorkloadURL(options):
    ''' Routine to get workload URL from testrunid '''
    cat_server = GetCATServer(options)
    url = 'https://%s/api/v1.0/testrun/%s' % (cat_server, options.testrunid)
    context = None
    if GetURLSchema(url) == 'https':
        context = sslUnverifiedContext
    json_data = urllib.urlopen(url, context=context).read()
    testrun = json.loads(json_data)

    url = 'https://%s%s' % (cat_server, testrun['workload']['resource_uri'])
    logger.debug("workload api url: %s" % url)
    return url

def GetURLSchema(url):
    if url.lstrip().startswith('https'):
        return 'https'
    else:
        return 'http'

def get_test_count(options):
    logdir = GetLogDir(options)
    count = 0
    with open('%s/testinfo.csv' % logdir) as csvfile:
        reader = csv.reader(csvfile, delimiter=',', quotechar='|')
        for row in reader:
            count = count + 1
    return count

if __name__ == "__main__":
    # Program settings.
    usage = "usage: %prog [options]"
    version = "%prog 0.1"
    vcInstanceName = None
    global esxInstanceNames
    esxInstanceNames = []

    # Parse commandline arguments.
    parser = OptionParser(usage=usage, version=version)
    parser.add_option("--testrunid", dest="testrunid", action="store",
                      type="string", help="Test run UID")
    parser.add_option("--machineip", dest="machineip", action="append", default=[],
                      help="host name(s) / IP addresses")
    parser.add_option("--resultsdir", dest="resultsdir", action="append",
                      help="Results directory")
    parser.add_option("--location", dest="location", action="append",
                      help="Location")
    parser.add_option("--esx_pxedir ", dest="esxpxedir", action="append",
                      help="PXE directory")
    parser.add_option("--psodurl", dest="psodurl", action="store",
                      type="string", help="PSOD URL")
    parser.add_option("--resultsurl", dest="resultsurl", action="store",
                      type="string", help="Results URL")
    parser.add_option("--macaddrs", dest="macaddrs", action="append",
                      help="MAC Address list")
    parser.add_option("--esx_blddir", dest="builddir", action="store",
                      type="string", help="Build Directory")
    parser.add_option("--esx_vmtree", dest="vmtree", action="store",
                      type="string", help="VMTREE Directory")
    parser.add_option("--vpxd_vmtree", dest="vpxdvmtree", action="store",
                      type="string", help="VPXD VMTREE")
    parser.add_option("--vpxd_blddir", dest="vpxdblddir", action="store",
                      type="string", help="VPXD Build Dir")
    parser.add_option("--nsx_vmtree", dest="nsxvmtree", action="store",
                      type="string", help="NSX VMTREE")
    parser.add_option("--nsx_blddir", dest="nsxblddir", action="store",
                      type="string", help="NSX Build Dir")
    parser.add_option("--product", dest="product", action="store",
                      type="string", help="Product Type")
    parser.add_option("-c", "--config", dest="file", action="store", default='',
                      type="string", help="filename")
    parser.add_option("-b", "--bootoptions", dest="bootOptions", action="store", default='',
                      type="string", help="Boot Options")
    parser.add_option("--framework", dest="framework", action="store",
                      type="string", help="Framework name")
    parser.add_option("--numOfESXVMs", dest="numOfESXVMs", action="store",
                      type="int", help=" Number of ESX Host from Nimbus needed")
    parser.add_option("--vdnetScript", dest="vdnetScript", action="store",
                      type="string", help="VDNet script to run")
    parser.add_option("--vdnetOptions", dest="vdnetOptions", action="store",
                      type="string", help="VDNet command line parameters to use")
    parser.add_option("--vcvaFirstbootTimeout", dest="vcvaFirstbootTimeout",
                      action="store", type="int", help="VCVA/couldVM firstboot timeout")
    parser.add_option("--userconfig", dest="userconfig",
                      action="store", type="string", help="config file")
    parser.add_option("--autotriage", dest="autotriage", default="0",
                      action="store", type="string",
                      help="enable/disable auto triage")
    parser.add_option("--file_product_bug", dest="file_product_bug",
                      default="no", action="store", type="string",
                      help="enable/disable filing PR against product")
    parser.add_option("--owner", dest="owner", action="store", type="string",
                      help="assignee username for auto triage")
    parser.add_option("--ship_builds", dest="ship_builds", default="1",
                       action="store", type="string",
                      help="option of disable/enable to ship builds from CAT to vdnet")
    (options, args) = parser.parse_args()

    if not options.file and len(args):
        options.file = args[0]

    # Initiate sig handler PR1158988
    signal.signal(signal.SIGINT, handler)
    # Create SSL context
    sslUnverifiedContext = ssl._create_unverified_context()
    # Allow disabling of daemonzing when editing.
    if not options.testrunid and os.access(__file__, os.W_OK):
        sys.exit(Run(options))
    logdir = GetLogDir(options)
    if logdir is None:
        print "log directory not given"
        sys.exit(Run(options))

    logfile = "%s/launcher.log" % logdir

    Daemonize(stdout=logfile, stderr=logfile)
    result = Run(options)
    logger.debug("Final result %s" % result)

    Cleanup(options, result)
    logger.debug("exiting now %s" % result)
    sys.exit(result)
