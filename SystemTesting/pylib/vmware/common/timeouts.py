#!/usr/bin/env python

import collections
import time

import mh.lib.displayutils as displayutils
import mh.lib.inspectutils as inspectutils
import mh.lib.timeutils as timeutils

# Master switch to disallow timeouts.
MAX_TIMEOUT = 24 * 60 * 60  # 1 day
MIN_TIMEOUT = 0


class Timeout(object):
    ZERO_WAIT_MARGIN = 0.01
    trackers = []  # Deliberately class-wide
    debug = False
    code_coverage_multiplier = 1

    def __init__(self, timeout, name, desc, display=True):
        self.name = name
        self.desc = desc
        self.timeout = timeout * self.code_coverage_multiplier
        self.display = display

        self.wait_times = collections.defaultdict(int)
        self.min_val = None
        self.max_val = None
        Timeout.trackers.append(self)

    @property
    def total(self):
        return sum(k * v for k, v in self.wait_times.iteritems())

    def sleep(self, msg='', multiplier=1, adder=0, logger=None):
        # Using a local here, since timeout is a property
        dur = self.timeout * multiplier + adder
        if msg:
            msg = "%s - " % msg
        if self.display and dur > 1:
            if logger:
                logger.info("%sSleeping for %s ..." % (msg, dur))
            else:
                print "%sSleeping for %s ...\r" % (msg, dur),
        time.sleep(dur)
        self.update(dur)

    def track_runtime(self, func, args=[], kwargs={}):
        (waited, data) = timeutils.func_runtime(func, args, kwargs)
        self.update(waited)
        return data

    def format_timeout_data(self, waited, timeout, func, args, kwargs,
                            back=1):
        """
        This function gathers all the data it can about the wait_until call
        that is executed. It examines the stack to see what called it, and it
        formats the data in a useful way to output where necessary.
        """
        # Go <back> frames back.  The usual frames are as follows:
        #   0: inspectutils.get_frame_info
        #   1: self.format_timeout_data
        #   2: self.update
        #   3: self.wait_until
        #   4: The method that called self.wait_until.
        fi = inspectutils.get_frame_info(back=back + 1)
        if fi:
            caller = "%s:%s - %s(...)" % (fi.filename, fi.lineno, fi.function)
        else:
            caller = "Unknown"
        if func:
            fn = func.__name__
            if hasattr(func, "im_class"):
                fn = "%s.%s" % (func.im_class.__name__, fn)
            fn = "%s(args=%s, kwargs=%s)" % (fn, str(args), str(kwargs))
        else:
            fn = "Unknown"
        limit = float(timeout)
        percent = limit and min(waited / limit, 1.0) or 1.0
        pct_line = displayutils.pct_line(percent, 80)
        return {
            "limit": limit, "func": fn, "caller": caller, "name": self.name,
            "desc": self.desc, "waited": waited, "percent": percent,
            "percent_line": pct_line}

    def wait_until(self, func, args=None, kwargs=None,
                   timeout=None, multiplier=None, interval=None,
                   checker=None, invert=False, raise_exc=None,
                   exc_handler=False, logger=None):
        if args is None:
            args = []
        if kwargs is None:
            kwargs = {}
        if timeout is None:
            timeout = self.timeout
        if multiplier is None:
            multiplier = 1
        # Default interval is timeout/5, capped below at 1 and above at 15
        if interval is None:
            interval = min(max(1, int(int(timeout) / 5)), 15)
        exc = None
        (timeout, interval, multiplier) = (int(timeout), int(interval),
                                           int(multiplier))
        try:
            (waited, ret_data) = timeutils.wait_until(
                func, args, kwargs, checker=checker, interval=interval,
                timeout=timeout, minimum=0, hard=timeout, invert=invert,
                multiplier=multiplier, return_data=True, log_msg=True,
                logger=logger, exc_handler=exc_handler)
        except (timeutils.SoftTimeout, timeutils.HardTimeout), e:
            (exc, waited, ret_data) = (e, e.waited, e.result)
            if raise_exc and logger:
                logger.exception(e)
        self.update(waited)
        if exc is not None and raise_exc:
            # TODO:  Ensure this is thread safe without 'exc'
            # We want to preserve the full stack trace in our exception
            raise
        return ret_data

    @staticmethod
    def _update_val(current, update, func):
        """ func is expected to be min/max """
        if current is None:
            return update
        else:
            return func(current, update)

    def update(self, value):
        value = int(value)
        self.min_val = self._update_val(self.min_val, value, min)
        self.max_val = self._update_val(self.max_val, value, max)
        self.wait_times[value] += 1
        # Prevent spamming in rapid 0-second timeouts case, even
        # with debug enabled
        if self.debug and value and self.display:
            self.PrintTrackers(only=self)

    def __str__(self):
        return ("<Timeout %s for %ss>" % (self.name, self.timeout))

    def updated(self):
        return bool(self.wait_times)

    @classmethod
    def TotalTime(cls, trackers=None):
        if trackers is None:
            trackers = cls.trackers
        return sum(t.total for t in trackers)

    @classmethod
    def get_timeout_summary(cls, condition=None, only=None):
        if condition is None:
            condition = lambda t: True
        if only is None:
            trackers = cls.trackers
        elif hasattr(only, '__iter__'):
            trackers = only
        else:
            trackers = [only]
        trackers = [t for t in trackers if condition(t)]
        C = displayutils.TextTableCol
        cols = ((C("Timeout"), lambda t: t.name),
                (C("Description"), lambda t: t.desc),
                (C("Soft"), lambda t: t.timeout),
                (C("Hard"), lambda t: t.timeout * t.multiplier),
                (C("Min"), lambda t: t.min_val),
                (C("Max"), lambda t: t.max_val),
                (C("Total"), lambda t: t.total))
        for i, tr in enumerate(sorted(trackers, key=lambda t: -t.total)):
            for col, func in cols:
                col.set(i, func(tr))
        total_time = timeutils.nametime(cls.TotalTime(trackers=trackers))
        title = "Timeout Summary [%s]" % total_time
        table = displayutils.TextTable(title, [c for c, f in cols])
        return table.text_rows(xrange(len(trackers)))

    @classmethod
    def PrintTimeouts(cls, logger=None, **kwargs):
        summary = cls.get_timeout_summary(**kwargs)
        if logger:
            logger.info(summary)
        else:
            print summary

    @classmethod
    def PrintTrackers(cls, only=None, detail=False, logger=None):
        condition = lambda t:  t.updated()
        cls.PrintTimeouts(condition=condition, only=only)
        if detail and logger:
            logger.info(cls.get_detailed_timeouts())
        else:
            print cls.get_detailed_timeouts()

cluster_stability_check = Timeout(
    60*5, "Cluster Stability Check",
    "Delay for cluster to stabilize on bootup")
nsx_mpa_start_delay = Timeout(
    30, "NSX-MPA Startup Delay",
    "Delay for nsx-mpa process to start running")
nsxa_start_delay = Timeout(
    30, "NSXA Startup Delay",
    "Delay for nsxa process to start running")
logical_component_realization_timeout = Timeout(
    300, "Wait for logical component to be realized",
    "Delay for logical component to be realized on hosts")
kvm_vm_power_on_retry_timeout = Timeout(
    60, "KVM VM Power on retry Timeout",
    "Timeout for retries when KVM VM power on fails with known busy errors")
file_creation_timeout = Timeout(
    60, "Wait for file to be created",
    "Delay for creating a file")
