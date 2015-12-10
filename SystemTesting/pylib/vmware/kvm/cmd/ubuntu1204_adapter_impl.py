import vmware.linux.cmd.linux_adapter_impl as linux_adapter_impl
import vmware.linux.cmd.linux_os_impl as linux_os_impl

Linux = linux_os_impl.LinuxOSImpl


class Ubuntu1204AdapterImpl(linux_adapter_impl.LinuxAdapterImpl):
    NETWORK_SCRIPTS_PATH = '/etc/network/interfaces'
    ACCEPTABLE_OPTS = ('ONBOOT', 'BOOTPROTO', 'DEVICE')

    @classmethod
    def persist_iface_config(cls, client_object, iface_opts=None,
                             static_config=None):
        if 'DEVICE' not in iface_opts:
            raise ValueError("Device name for which the config is being "
                             "persisted is not provided")
        if static_config and type(static_config) is not dict:
            raise ValueError("Static configuration should be passed in as  "
                             "a dictionary to the method")
        opt_list = []
        onboot_up = False
        bootproto = None
        for opt, val in iface_opts.iteritems():
            if opt.upper() not in cls.ACCEPTABLE_OPTS:
                raise ValueError("Unsupported opt %r provided, only %r are "
                                 "supported" % (cls.ACCEPTABLE_OPTS))
            if opt.upper() == 'ONBOOT' and val.lower() == 'yes':
                onboot_up = True
            elif opt.upper() == 'BOOTPROTO':
                # In Debian systems the bootproto could be either one of dhcp,
                # static or manual.
                bootproto = val.lower() if val.lower() != 'none' else 'manual'
                if bootproto == 'dhcp' and static_config:
                    raise ValueError("Cannot use boot protocol as dhcp "
                                     "when static configuration is specified. "
                                     "Got dhcp: %r and static_config: %r" % (
                                         bootproto, static_config))
        if onboot_up:
            opt_list.append('auto %s' % iface_opts['DEVICE'])
            if bootproto:
                opt_list.append('iface %s inet %s' % (iface_opts['DEVICE'],
                                                      bootproto))
                if bootproto == 'manual':
                    opt_list.append('\tup ifconfig %s up' %
                                    iface_opts['DEVICE'])
            if static_config:
                for key, val in static_config.iteritems():
                    opt_list.append('\t%s %s' % (key, val))
            Linux.append_file(
                client_object, path=cls.NETWORK_SCRIPTS_PATH,
                content="\n%s" % "\n".join(opt_list))
