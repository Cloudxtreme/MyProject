import os
from os.path import dirname
import pytest
import sys
import yaml
from scripts import local_stage as dut

_tag = 'rtqa9-candidate2'
automation = dirname(dirname(dirname(__file__)))
rtqa_builds = os.path.join(automation, 'yaml/nsxtransformers/rtqa_builds.yaml')

class TestLocalStaging(object):
    def test_get_vibs_from_yaml(self):
        exists = os.path.exists(rtqa_builds)
        assert exists, "failed to find yaml file for rtqa_builds %s" % rtqa_builds
        with open(rtqa_builds,'r') as fo:
            builds = yaml.load(fo)
        assert builds
        dict_ = builds.values()[0]
        assert 'rtqa' in dict_.keys()[0]

    def test_flatten(self, tag=_tag):
        expected = ['1','2','3']
        _build = {
            'BUILD': {
                tag: {
                    'nsxmanager': {
                        'resource': expected
                    }
                }
            }
        }
        bla = dut.flatten_resources(_build)
        assert bla == expected

        news = ['4','5','6']
        _build['BUILD'][tag]['flart'] = {'resource':news}
        expected2 = news+expected   # order by dict
        bla = dut.flatten_resources(_build)
        assert bla == expected2

    def test_get_real_vibs(self):
        with open(rtqa_builds,'r') as fo:
            builds = yaml.load(fo)
        assert builds
        resources = dut.flatten_resources(builds)
        counter = 0
        for res in resources:
            if res.endswith('.vib'):
                counter+=1
        assert counter > 1
