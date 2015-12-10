import os

import vmware.linux.cmd.linux_adapter_impl as linux_adapter_impl
import vmware.linux.linux_helper as linux_helper

Linux = linux_helper.Linux


class RHEL64AdapterImpl(linux_adapter_impl.LinuxAdapterImpl):
    NETWORK_SCRIPTS_PATH = '/etc/sysconfig/network-scripts'
    ACCEPTABLE_OPTS = ('ONBOOT', 'BOOTPROTO', 'DEVICE')

    @classmethod
    def persist_iface_config(cls, client_object, iface_opts=None):
        if 'DEVICE' not in iface_opts:
            raise ValueError("Device name for which the config is being "
                             "persisted is not provided")
        opt_list = []
        for opt, val in iface_opts.iteritems():
            if opt.upper() not in cls.ACCEPTABLE_OPTS:
                raise ValueError("Unsupported opt %r provided, only %r are "
                                 "supported" % (cls.ACCEPTABLE_OPTS))
            opt_list.append('%s=%s' % (opt.upper(), val.lower()))
        file_path = os.path.join(cls.NETWORK_SCRIPTS_PATH,
                                 "ifcfg-%s" % iface_opts['DEVICE'])
        Linux.create_file(
            client_object, file_path, content="\n".join(opt_list),
            overwrite=True)
