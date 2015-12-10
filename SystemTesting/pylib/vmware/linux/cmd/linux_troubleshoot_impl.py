import os
import re
import traceback

import vmware.common as common
import vmware.common.global_config as global_config
import vmware.common.utilities as utilities
import vmware.interfaces.troubleshoot_interface as troubleshoot_interface
import vmware.linux.cmd.linux_fileops_impl as linux_fileops_impl
import vmware.linux.linux_helper as linux_helper

# Helper classes.
Linux = linux_helper.Linux
LinuxFileOpsImpl = linux_fileops_impl.LinuxFileOpsImpl

# Logger handle.
pylogger = global_config.pylogger

# Defaults for getting data from top.
DEFAULT_TOP_ITERATIONS = 3
DEFAULT_TOP_REFRESH_DELAY = 3
TOP_OUTPUT_FILE_PREFIX = "top_output"
# In addition for the time to refresh top screen, we use this grace time to let
# the top command finish.
TOP_COMMAND_COMPLETION_MARGIN = 5

# Log directories on hosts.
VAR_LOG = "/var/log"
OVS_BUGTOOL_DIR = "%s/ovs-bugtool" % VAR_LOG


class LinuxTroubleshootImpl(troubleshoot_interface.TroubleshootInterface):
    TECH_BUNDLE_SCRIPT = "/opt/vmware/nsx-agent/bin/support_save.py"
    TECH_SUPPORT_TIMEOUT = 600

    @classmethod
    def collect_logs(cls, client_object, logdir=None):
        """
        Method to collect host logs into a .tar.gz file.

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host
        @type logdir: string
        @param logdir: The directory where the logs will be stored.
        @rtype: status_code
        @return: SUCCESS or FAILURE
        """
        log_methods = {VAR_LOG: cls._collect_var_log,
                       "top_output": cls._collect_top_output,
                       "ovsbugtool": cls._collect_ovsbugtool_output,
                       "tech_support": cls._collect_nsxsupport_bundle}
        exceptions = {}
        for log_name, method in log_methods.iteritems():
            try:
                method(client_object, logdir=logdir)
            except Exception:
                exceptions[log_name] = traceback.format_exc()
        if exceptions:
            for log_name, exception in exceptions.iteritems():
                pylogger.error("Exceptions raised during log collection of "
                               "%r:\n%r" % (log_name, exception))
            raise Exception("Exceptions caught in collecting logs on %r" %
                            client_object.ip)
        return common.status_codes.SUCCESS

    @classmethod
    def _collect_nsxsupport_bundle(cls, client_object, logdir=None,
                                   timeout=None):
        """
        Method to collect tech support bundle from host.

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host
        @type logdir: str
        @param logdir: The directory where the logs will be stored.
        @type timeout: int
        @param timeout: Time after which the log collection command will
            quit even if logs were not collected within that time frame.
        """
        pylogger.debug("Generating nsx tech support bundle on %r ..." %
                       client_object.ip)
        if timeout is None:
            timeout = cls.TECH_SUPPORT_TIMEOUT
        cmd = "python %s" % cls.TECH_BUNDLE_SCRIPT
        ret = client_object.connection.request(
            cmd, timeout=timeout).response_data
        regex = "([\S]+.gz.tar)"
        match = re.search(regex, ret)
        if not match:
            raise RuntimeError("Unable to find the tech support output "
                               "file name using regex: %r in output:\n%r" %
                               (regex, ret))
        remote_path = match.group()
        local_path = os.path.join(logdir, os.path.basename(remote_path))
        Linux.get_file(client_object, remote_path, local_path)

    @classmethod
    def _collect_var_log(cls, client_object, logdir=None,
                         output_tar_file=None):
        """
        Method to collect /var/log into a .tar.gz file.

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host
        @type logdir: string
        @param logdir: The directory where the logs will be stored.
        @rtype: status_code
        @return: SUCCESS or FAILURE
        """
        if output_tar_file is None:
            prefix = ("%s-var_log" %
                      "_".join(client_object.ip.split(".")))
            output_tar_file = utilities.get_random_name(prefix=prefix)
            output_tar_file = "%s.tar.gz" % output_tar_file
        remote_path = os.path.join(client_object.TMP_DIR, output_tar_file)
        local_path = os.path.join(logdir, os.path.join(output_tar_file))
        # Tar command fails if files being compressed are modified during
        # compression.
        backup_dir = os.path.join(
            client_object.TMP_DIR,
            utilities.get_random_name(prefix="var_log"))
        try:
            Linux.copy_dir(client_object, src_dir=VAR_LOG, dst_dir=backup_dir)
            Linux.tar(
                client_object, create=True, tar_file=remote_path,
                directory=backup_dir)
        finally:
            LinuxFileOpsImpl.remove_file(client_object, file_name=backup_dir,
                                         options="-rf")
        Linux.get_file(client_object, remote_path, local_path)
        Linux.delete_file(client_object, remote_path)

    @classmethod
    def _collect_top_output(cls, client_object, iterations=None, batch=None,
                            delay=None, out_file=None, logdir=None):
        """
        Method to dump the top output to a file.

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host
        @type logdir: str
        @param logdir: The directory on the launcher where the log needs to be
            copied to.
        @type out_file: str
        @param out_file: File name to which the output will be dumped.
        @type iterations: int
        @param iterations: Number of times the top output should be polled.
        @type delay: int
        @param delay: Delay between top screen refreshes.
        @type batch: bool
        @param batch: Runs the top in batch mode which is helpful for sending
            output from top to the other programs. It is set to true by default
            since without this flag the dumped top output contains special
            characters.
        """
        pylogger.debug("Collecting the top output from %r ..." %
                       client_object.ip)
        if out_file is None:
            ip = "_".join(client_object.ip.split("."))
            prefix = (
                "%s-%s" % (os.path.join(client_object.TMP_DIR,
                           TOP_OUTPUT_FILE_PREFIX), ip))
            out_file = utilities.get_random_name(prefix=prefix)
        cmd = ["top"]
        if iterations is None:
            iterations = DEFAULT_TOP_ITERATIONS
        elif type(iterations) != int:
            raise TypeError("Argument 'iteration' should be of int type, "
                            "got %s: %r" % (type(iterations), iterations))
        cmd.append("-n %s" % iterations)
        if delay is None:
            delay = DEFAULT_TOP_REFRESH_DELAY
        elif type(delay) != int:
            raise TypeError("Argument 'delay' should be of int type, "
                            "got %s: %r" % (type(delay), delay))
        cmd.append("-d %s" % delay)
        if batch is None:
            batch = True
        if batch:
            cmd.append("-b")
        redirect_cmd = "%s > %s" % (" ".join(cmd), out_file)
        cmd_timeout = delay * iterations + TOP_COMMAND_COMPLETION_MARGIN
        client_object.connection.request(
            redirect_cmd, timeout=cmd_timeout)
        local_path = os.path.join(logdir, os.path.basename(out_file))
        Linux.get_file(client_object, out_file, local_path)
        Linux.delete_file(client_object, out_file)

    @classmethod
    def _collect_ovsbugtool_output(cls, client_object, logdir=None):
        """
        Method to generate the tar file created by ovs-bugtool.

        The tar file generated by ovs-bugtool resides under
        /var/log/ovsbug-tool.

        @type logdir: str
        @param logdir: Directory on launcher to receive copy of the log.
        """
        pylogger.debug("Generating ovs-bugtool output on %r ..." %
                       client_object.ip)
        cmd = "yes | ovs-bugtool"
        ret = client_object.connection.request(cmd).response_data
        regex = "([\S]+.tar.gz)"
        match = re.search(regex, ret)
        if not match:
            raise RuntimeError("Unable to find the ovs-bugtool's output  "
                               "file name using regex: %r in output:\n%r" %
                               (regex, ret))
        remote_path = match.group()
        ip = "_".join(client_object.ip.split("."))
        local_path = os.path.join(logdir, "ovs-bugtool-%s.tar.gz" % ip)
        Linux.get_file(client_object, remote_path, local_path)
        Linux.delete_file(client_object, remote_path)
