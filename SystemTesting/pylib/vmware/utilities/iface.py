import ipaddr


def one(iterable):
    found_one = False
    for x in iterable:
        if x:
            if found_one:
                # found another
                return False
            else:
                found_one = True
    return found_one


class Iface(object):
    """
    Iface object to store all interface related params like ips, ips_v6,
    mtu and device names
    """
    LINK_STATE_DOWN = 'DOWN'
    LINK_STATE_UP = 'UP'
    LABEL_IFACE_FLAGS = 'flags'
    LABEL_IFACE_STATUS = 'status'
    LABEL_MAC = 'mac'
    DEFAULT_MTU = 1500
    # Stats related key labels.
    RX_BYTES = 'rx_bytes'
    RX_PACKETS = 'rx_packets'
    RX_ERRORS = 'rx_errors'
    RX_DROPPED = 'rx_dropped'
    TX_BYTES = 'tx_bytes'
    TX_PACKETS = 'tx_packets'
    TX_ERRORS = 'tx_errors'
    TX_DROPPED = 'tx_dropped'

    @classmethod
    def from_ip_addr(cls, info, all_=None):
        """
        >>> a = '''
        ... 1: lo: <LOOPBACK,UP,LOWER_UP> mtu 16436 qdisc noqueue state UNKNOWN
        ...     link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
        ...     inet 127.0.0.1/8 scope host lo
        ...     inet6 ::1/128 scope host
        ...        valid_lft forever preferred_lft forever
        ... 2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP  # noqa
        ... qlen 1000
        ...     link/ether 00:50:56:ad:43:d7 brd ff:ff:ff:ff:ff:ff
        ...     inet6 fe80::250:56ff:fead:43d7/64 scope link
        ...        valid_lft forever preferred_lft forever
        ... 3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP  # noqa
        ... qlen 1000
        ...     link/ether 00:50:56:ad:43:d8 brd ff:ff:ff:ff:ff:ff
        ...     inet6 fe80::250:56ff:fead:43d8/64 scope link
        ...        valid_lft forever preferred_lft forever
        ... 4: eth2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP  # noqa
        ... qlen 1000
        ...     link/ether 00:50:56:ad:43:d9 brd ff:ff:ff:ff:ff:ff
        ...     inet6 fe80::250:56ff:fead:43d9/64 scope link
        ...        valid_lft forever preferred_lft forever
        ... 125: ovs-system: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN
        ...     link/ether ea:3e:3a:8f:3f:b2 brd ff:ff:ff:ff:ff:ff
        ... 126: breth2: <BROADCAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN  # noqa
        ...     link/ether 00:50:56:ad:43:d9 brd ff:ff:ff:ff:ff:ff
        ...     inet6 fe80::4c51:29ff:fe5d:ecf7/64 scope link
        ...        valid_lft forever preferred_lft forever
        ... 127: breth1: <BROADCAST,PROMISC,UP,LOWER_UP> mtu 1500 qdisc noqueue state  # noqa
        ... UNKNOWN
        ...     link/ether 00:50:56:ad:43:d8 brd ff:ff:ff:ff:ff:ff
        ...     inet6 fe80::c47:cff:fe9d:8d9/64 scope link
        ...        valid_lft forever preferred_lft forever
        ... 128: breth0: <BROADCAST,PROMISC,UP,LOWER_UP> mtu 1500 qdisc noqueue state  # noqa
        ... UNKNOWN
        ...     link/ether 00:50:56:ad:43:d7 brd ff:ff:ff:ff:ff:ff
        ...     inet 10.34.20.214/24 brd 10.34.20.255 scope global breth0
        ...     inet6 fdc8:90cd:639:8a:903f:1e19:386b:3c19/64 scope global temporary dynamic  # noqa
        ...        valid_lft 599710sec preferred_lft 80710sec
        ...     inet6 fdc8:90cd:639:8a:250:56ff:fead:43d7/64 scope global dynamic
        ...        valid_lft 2591977sec preferred_lft 604777sec
        ...     inet6 fe80::d457:5dff:fe7f:f91b/64 scope link
        ...        valid_lft forever preferred_lft forever
        ... 130: breth1.400@breth1: <BROADCAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP  # noqa
        ...     link/ether 00:50:56:ad:43:d8 brd ff:ff:ff:ff:ff:ff
        ...     inet 101.0.0.5/24 brd 101.0.0.255 scope global breth1.400
        ...     inet6 fe80::250:56ff:fead:43d8/64 scope link
        ...        valid_lft forever preferred_lft forever
        ... '''
        >>> intfs = Iface.from_ip_addr(a)
        >>> print repr(intfs)
        [<Iface...
        >>> one(x.is_ip_configured('10.34.20.214') for x in intfs)
        True
        """
        _ = cls  # Silence pychecker
        if all_ is None:
            all_ = False
        lines = [ln.split() for ln in info.splitlines()]
        macs, ips, ips_v6 = [], [], []
        dev = mtu = None
        intfs = []
        for ln in lines:
            if not ln:
                continue
            if ":" in ln[0]:
                if macs:
                    # if dev != 'lo':  # Ignore loopback interface
                    intfs.append(Iface(dev, mtu, macs[0], ips, ips_v6))
                    macs, ips, ips_v6 = [], [], []
                # remove @breth1 from breth1.100@breth1
                dev = ln[1][:-1].split('@')[0]
                mtu = int(ln[4])
                # unused_qdisc = ln[6]
                # unused_state = ln[8]
            elif 'link' in ln[0]:
                macs.append((ln[1]))
            elif 'inet' == ln[0]:
                ips.append(ln[1])
            elif 'inet6' == ln[0]:
                ips_v6.append(ln[1])
            else:
                continue
        if macs:
            intfs.append(Iface(dev, mtu, macs[0], ips, ips_v6))
        if all_:
            return intfs
        return [iface for iface in intfs if iface.ips]

    def __init__(self, dev, mtu, mac, ips, ips_v6):
        self.dev = dev
        self.mtu = mtu
        self.mac = mac
        self.ips = ips
        self.ips_v6 = ips_v6

    def __repr__(self):
        cls_name = self.__class__.__name__
        return ("<%s(dev=%r, mac=%r, ips=%r, ips_v6=%r, mtu=%r)>" %
                (cls_name, self.dev, self.mac, self.ips, self.ips_v6,
                 self.mtu))

    def is_ip_configured(self, ip):
        netmask = None
        if "/" in ip:
            ip, netmask = ip.split("/")
        ip_addr = ipaddr.IPAddress(ip)
        for x in self.ips + self.ips_v6:
            x_ip, x_netmask = x.split("/")
            if ((ip_addr == ipaddr.IPAddress(x_ip) and
                 (netmask is None or netmask == x_netmask))):
                return True
        return False


if __name__ == "__main__":
    import doctest_helper
    doctest_helper.run_testmod()
