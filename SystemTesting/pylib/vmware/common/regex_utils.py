#!/usr/bin/env python

# TODO(Amey/Reid):  Look into precompiling all of these

ONLY = lambda x: "^(%s)$" % x if "|" in x and "\1" not in x else "^%s$" % x

octet = (
    "(?:(?:25[0-5])|"   # 250-255
    "(?:2[0-4][0-9])|"  # 200-249
    "(?:1[0-9][0-9])|"  # 100-199
    "(?:[1-9][0-9])|"   # 10-99
    "(?:[0-9]))"        # 0-9
)
ip = "((?:%(octet)s)(?:\.(?:%(octet)s)){3})" % ({'octet': octet})
ip_only = ONLY(ip)

hostname = ("(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)"
            "*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])")  # RFC 1123
hostname_only = ONLY(hostname)

ipv6_map = {'word': "[A-Fa-f0-9]{1,4}",
            'sep': ":",
            "zeros": "::",
            "ipv4": "(%s)" % ip}

ipv6 = (
    "((%(word)s%(sep)s){7}%(word)s)"  # full length with 8 words
    "|((%(word)s%(sep)s){1}(%(sep)s%(word)s){1,5})"  # A::...
    "|((%(word)s%(sep)s){2}(%(sep)s%(word)s){1,4})"  # A:B::...
    "|((%(word)s%(sep)s){3}(%(sep)s%(word)s){1,3})"  # A:B:C::...
    "|((%(word)s%(sep)s){4}(%(sep)s%(word)s){1,2})"  # A:B:C:D::...
    "|((%(word)s%(sep)s){5}(%(sep)s%(word)s){1})"  # A:B:C:D:E::...
    "|((%(word)s%(sep)s){6}%(ipv4)s)"
    "|((%(word)s%(sep)s){0,4}%(word)s%(zeros)s%(ipv4)s)"
    "|(%(zeros)s(%(word)s%(sep)s){0,4}%(word)s%(ipv4)s)"
    "|((%(word)s%(sep)s){0,5}%(word)s%(zeros)s)"  # ending in ::
    "|(%(zeros)s(%(word)s%(sep)s){0,5}%(word)s)"  # starting with ::
) % ipv6_map
ipv6_only = ONLY(ipv6)
ipv4_or_v6 = "((%s)|(%s))" % (ip, ipv6)

__octet = '[A-Fa-f0-9]{1,2}'
__mac_map = {'octet': __octet, 'sep': "[:-]"}
__colon_mac_map = {'octet': __octet, 'sep': ":"}
__mac_format = '%(octet)s(%(sep)s%(octet)s){5}'
mac = __mac_format % __mac_map
colon_mac = __mac_format % __colon_mac_map
mac_only = ONLY(mac)
colon_mac_only = ONLY(colon_mac)


def uuid_regex_doctests():
    """
    Regexes for UUIDs
    >>> import re
    >>> import uuid as uuid_module
    >>> u4 = uuid_module.uuid4
    >>> and_stuff = lambda s: 'bar%sfoo' % s
    >>> assert re.search(uuid, and_stuff(u4()))
    >>> assert re.search(uuid_only, str(u4()))
    >>> assert not re.search(uuid_only, and_stuff(u4()))
    >>> assert re.search(uuid_or_wildcard, and_stuff(u4()))
    >>> assert re.search(uuid_or_wildcard, and_stuff('*'))
    >>> assert not re.search(uuid_or_wildcard, and_stuff(''))
    """
    pass


uuid = '[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}'
uuid_only = ONLY(uuid)
uuid_or_wildcard = "(\*|%s)" % uuid  # Matches UUID or '*'


def vlan_iface_regex_doctests():
    """
    Regexes for VLAN interfaces
    >>> import re
    >>> assert re.match(vlan, 'breth4.5')
    >>> assert re.match(vlan, 'eth100.0')
    >>> assert re.match(vlan, 'xenbr1.1')
    >>> assert re.match(vlan, 'br1.100')
    >>> assert not re.match(vlan, 'peth55.0')
    >>> assert not re.match(vlan, 'breth0.')
    >>> assert not re.match(vlan, 'eth.1')
    """
    pass

vlan = "((br)?eth|xenbr|br-vmnic|br-bond|br)\d+\.(\d+)"
vlan_only = ONLY(vlan)


if __name__ == '__main__':
    import doctest
    doctest.testmod()
