import inspect
import mock
import os
import pytest
import vcr as _vcr

def _funcname_(depth=1):
    stack = inspect.stack()
    frame = stack[depth][0]
    code = frame.f_code
    return code.co_name

# VCR settings
# parameters for vcrpy - a mechanism for canned comms with urllib2
# record once or never, and run tests against canned data or real-product
# https://github.com/kevin1024/vcrpy
fixtures_path = os.path.join(os.path.dirname(__file__),'fixtures')
fixtures_path = os.path.abspath(fixtures_path)

# to reset vcr, remove all content of test/fixtures, then
# export RECORD=once and run tests,
record_mode=os.getenv('RECORD','never')
vcr = _vcr.VCR( cassette_library_dir=fixtures_path, record_mode=record_mode)

def cassette_exists(vcr_file):
    vcr_path = os.path.join(fixtures_path,vcr_file)
    return os.path.exists(vcr_path)

def pred_cassette_exists_caller(name):
    def inner():
        return cassette_exists(name)
    return inner

class use_vcr(object):
    """name is used if provided, else use the wrapped function name
    this is a hack because of https://github.com/kevin1024/vcrpy/issues/98
    """
    def __init__(self,name=None, enabled=record_mode != 'zero'):
        self._name = name
        self.enabled = enabled

    def __call__(self, wrappee):
        _name = wrappee.func_name
        if self._name and isinstance(self._name,str):
            _name = self._name
        vcr_file = _name+'.yaml'
        def inner(*args, **kwargs):
            if self.enabled:
                with vcr.use_cassette(vcr_file):
                    return wrappee(*args, **kwargs)
            else:
                return wrappee(*args,**kwargs)
        return inner
