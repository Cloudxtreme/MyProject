#!/usr/bin/env python
########################################################################
# Copyright (C) 2015 VMWare, Inc.
# All Rights Reserved
########################################################################


import vmware.common.global_config as global_config
import vmware.common.reporter as reporter


pylogger = global_config.pylogger


class TaskStepResult:
    """Data definition of allowed Task Step results."""

    PASS = "PASS"
    FAIL = "FAIL"

    def __init__(self, **kwargs):
        raise AssertionError("Data class only, do not instantiate.")


class TaskResult:
    """VDNet Task Result."""

    def __init__(self, **kwargs):
        self.status_code = kwargs.get('status_code', 'EINVALID')
        self.reason = kwargs.get('reason')
        self.error = kwargs.get('error')
        self.response_data = kwargs.get('response_data')

    def to_dict(self):
        return dict(status_code=self.status_code, reason=self.reason,
                    error=self.error, response_data=self.response_data)


class TaskMixin(object):
    """
    Testing task.
    """

    def __init__(self, **kwargs):
        self.result = TaskResult()

    def step_report(self, result, msg, *args, **kwargs):
        """Report the result of a task step.

        @type result: boolean
        @param result: True if the task step is passed, False otherwise
        @type msg: string
        @param msg: A message describing the task step.
        """
        rptr_config = getattr(pylogger, '_reporter_config', None)
        if rptr_config is not None:
            rptr = reporter.ReporterFactory.get_reporter(
                pylogger._reporter_config)
            rptr.step_report(result=result, msg=msg, *args, **kwargs)
        else:
            log_func = pylogger.info if result else pylogger.error
            log_func("%s: Task Step Result: %s" % (result, msg))


if __name__ == "__main__":
    print("=== Task example step reporting ===")
    t = TaskMixin()
    t.step_report(True, 'foo')  # PASS test
    t.step_report(False, 'bar')  # FAIL test
