import subprocess
import time

import vmware.common.constants as constants
import vmware.common.global_config as global_config

pylogger = global_config.pylogger


def run_command_sync(command):
    """
    Routine to run command in sync mode
    @type  command: str
    @param command: command to run
    @rtype: tuple
    @return: Returns returncode, stdout and stderr
    """
    pylogger.debug('Executing command %r' % command)
    p = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE,
                         stderr=subprocess.PIPE)
    stdout, stderr = p.communicate()
    if stdout:
        for line in stdout.splitlines():
            pylogger.debug("STDOUT: %r" % line)
    if stderr:
        logger = pylogger.error if p.returncode else pylogger.debug
        for line in stderr.splitlines():
            logger("STDERR: %r" % line)
    return (p.returncode, stdout, stderr)


def ping(host, count=1):
    cmd = "ping -c %s %s" % (count, host)
    return_code, _, _ = run_command_sync(cmd)
    return not return_code


def wait_for_ip_reachable(ip, timeout=None, post_reboot_sleep=None):
    if timeout is None:
        timeout = constants.Timeout.HOST_REBOOT_MAX
    if post_reboot_sleep is None:
        post_reboot_sleep = constants.Timeout.POST_REBOOT_SLEEP
    reboot_started = False
    reboot_completed = False
    # XXX(James, Mayank, Prabuddh, Mihir): Use wait_until style instead of
    # tight loop. For example:
    # wait_until() reboot started timeout 30 seconds, but with faster interval
    # 0.5s.
    # wait_until() reboot completed longer timeout 120 seconds (maybe more),
    # and a slower interval 5 to 10 seconds.
    for _ in xrange(timeout):
        if not ping(ip):
            if not reboot_started:
                reboot_started = True
                pylogger.debug("%r's reboot started" % ip)
        elif reboot_started:
            reboot_completed = True
            pylogger.debug("%r's reboot completed" % ip)
            break
        time.sleep(1)
    if post_reboot_sleep is not None:
        time.sleep(post_reboot_sleep)
    if not reboot_completed:
        pylogger.debug("%r failed to come up after reboot in %r seconds" %
                       (ip, timeout))
    return reboot_completed
