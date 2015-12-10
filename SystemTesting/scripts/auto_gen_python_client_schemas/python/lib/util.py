# Copyright (C) 2011 Nicira, Inc.
#
# This is an unpublished work, is confidential and proprietary to
# Nicira, Inc. as a trade secret and is not to be used or
# disclosed without Nicira's consent.

from __future__ import print_function

from collections import defaultdict
import time

def singleton(cls):
    """Class decorator for defining singleton classes.

    From pep-0318
    """
    _instances = {}
    def get_instance():
        if cls not in _instances:
            _instances[cls] = cls()
        return _instances[cls]
    return get_instance


class TimerGroup(object):
    """
    Utility class for timing code blocks. Usage pattern:

    g = TimerGroup()
    with g.timer("name1"):
       some_stmts

    with g.timer("name2"):
       some_stmts
    g.print_report()
    """

    def __init__(self):
        self.timers = []

    class _Timer(object):
        def __init__(self, group, name):
            self.name = name
            group.timers.append(self)

        def __enter__(self):
            self.start = time.time()
            return self

        def __exit__(self, *args):
            self.end = time.time()
            self.duration = self.end - self.start


    def timer(self, name):
        """ Builder function. Using the returned context manager in a
        with statement will time with statement block """
        return self._Timer(self, name)


    def print_report(self, printer=print):
        """
        Print a report using self.timers
        """

        printer("===> Timer report <===")
        for timer in self.timers:
            printer("%25s: %3.5f" % (timer.name, timer.duration))


class Counter(object):  # pylint: disable=R0903
    """
    Inspired by Python 2.7's collections.Counter
    """
    def __init__(self, input_keys):
        self._data = defaultdict(int)
        for i in input_keys:
            self._data[i] += 1

    def items(self):
        """ Return (key,value) sequence """
        return self._data.items()

    def __iter__(self):
        return self._data.__iter__()

    def __getitem__(self, key):
        return self._data.__getitem__(key)

    def __repr__(self):
        return "{%s}" % (", ".join("'%s': %d" % (k, v)
                                   for (k, v) in self._data.iteritems()))
