import json
import mock
import os
import sys
import tempfile
import yaml

from conftest import _funcname_
from scripts import deployTestbed as dut
import vmware.provision.provision as provision

config = {"esx":{"1":{"profile":"update","installtype":"linkedclone","vmnic":{"1":{"network":"isolated-01"}},
                      "build":"ESX_1964156"},
                 "2":{"profile":"update","installtype":"linkedclone","vmnic":{"1":{"network":"isolated-01"}},
                      "build":"ESX_1964156"}}}

class TestDeployTestbed(object):
    def setup_class(cls):
        pass

    def setup_method(self,method):
        pass


    @mock.patch.object(dut, 'onecloud_main')
    @mock.patch.object(dut, 'nimbus_main')
    def test_main(self, nimbus_main, onecloud_main):
        args = ['--config', 'foo']
        dut.main(args)
        assert nimbus_main.call_count == 1
        assert nimbus_main.called
        assert onecloud_main.call_count == 0
        assert not onecloud_main.called

        args.extend(['--onecloud', '--podspec', 'yaml/onecloud/podspec.sh'])
        dut.main(args)
        assert nimbus_main.call_count == 2
        assert onecloud_main.called
        assert onecloud_main.call_count == 1

    @mock.patch.object(dut, 'onecloud_main')
    @mock.patch.object(dut, 'nimbus_main')
    def test_onecloud_no_podspec(self, nimbus_main, onecloud_main):
        # onecloud needs some settings, from a podspec, but 
        # we should still be able to not assert for lack of podspec
        os.environ['ONECLOUD'] = '1'
        args = ['--config', 'foo']
        dut.main(args)
        assert nimbus_main.call_count == 1
        assert nimbus_main.called
        assert onecloud_main.call_count == 1
        assert onecloud_main.called

    def test_source(self):
        assert {} == dut.source('no/such/file', True)
        podspec = dut.automd_prefix('yaml/onecloud/podspec.sh')
        if 'ONECLOUD' in os.environ:
            del os.environ['ONECLOUD']
        env = dut.source( podspec, False)
        assert env
        assert env['ONECLOUD']
        assert 'ONECLOUD' not in os.environ
        env = dut.source(podspec, True)
        assert 'ONECLOUD' in os.environ

    @mock.patch.object(provision, 'run')
    def test_onecloud_podspec(self, _run):
        os.environ['ONECLOUD'] = 'True'
        fd, name = tempfile.mkstemp(_funcname_())
        os.close(fd)
        with open(name, 'w') as fo:
            json.dump(config, fo)
        onecloud_out = os.path.join(os.path.dirname(name),
                                    'onecloud_out.yaml')
        with open(onecloud_out, 'w') as fo:
            yaml.dump(config, fo)
        args = ['--config', name,
                '--podspec', 'yaml/onecloud/podspec.sh']
        (dut.cmdOpts, args) = dut.process_args(args)
        dut.set_env_podspec()
        dut.onecloud_main(dut.cmdOpts)
        assert _run.called

    @mock.patch.object(provision, 'run')
    def test_onecloud_deploy(self, _run):
        os.environ['ONECLOUD'] = 'True'
        fd, name = tempfile.mkstemp(_funcname_())
        os.close(fd)
        with open(name, 'w') as fo:
            json.dump(config, fo)
        onecloud_out = os.path.join(os.path.dirname(name), 'onecloud_out.yaml')
        with open(onecloud_out, 'w') as fo:
            yaml.dump(config, fo)
        args = ['--config', name,
                '--podspec', 'yaml/onecloud/podspec.sh']
        (dut.cmdOpts, args) = dut.process_args(args)
        dut.set_env_podspec()
        dut.onecloud_main(dut.cmdOpts)
        assert _run.called
        onecloud_out = os.path.join(os.path.dirname(name), 'onecloud_out.yaml')
        assert os.path.exists(onecloud_out)
