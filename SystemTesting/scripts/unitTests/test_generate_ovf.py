import mock
import os
import pytest
import sys
import tempfile
import yaml

from conftest import _funcname_, use_vcr
from scripts import generateServerOVF as dut
import vmware.provision.provision as provision

@use_vcr()
def test_generate_ovf():
    build = 'ob-2069601'
    dut.get_ovf_build(build)
    
