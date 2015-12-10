# Version strings and identifiers.
#


class Version(object):
    """Base class for versions.

    Block object instantiation. Force consumers to reference class values.
    """
    # TODO(jschmidt): Implement rich comparison. Consider that instantiation
    # is needed in order to have objects that can be compared.
    # http://legacy.python.org/dev/peps/pep-0207/
    # object.__lt__(self, other)
    # object.__le__(self, other)
    # object.__eq__(self, other)
    # object.__ne__(self, other)
    # object.__gt__(self, other)
    # object.__ge__(self, other)

    def __init__(self, *args, **kwargs):
        raise AssertionError("Version object can not be instantiated: %s" %
                             type(self))


class NSXTransformers(Version):
    """NSX Transformers versions"""
    # TODO(jschmidt): When implementing comparison, consider if this needs to
    # be product/major/minor instead of a static string.
    AVALANCHE = "NSX70"
    BUMBLEBEE = "NSX70"
