#!/usr/bin/env python
import collections
import commands
import os
from os.path import dirname
from pprint import pprint
import sys
import yaml
import logging

log_level = os.getenv("LOGLEVEL","INFO")
logging.basicConfig(level=log_level)
log =logging.getLogger(__name__)


_html = os.getenv('WWW','/var/www/html')
_tag = 'rtqa{0}-candidate{1}'

def download(url, path):
    basename = url.split('/')[-1]
    exists = os.path.exists(os.path.join(path,basename))
    if basename:
        if exists:
            log.debug('nothing to download for %s/%s' % (path, basename))
        else:
            cmd = 'cd {0}; wget {1}'.format(path,url)
            log.info('running cmd: %s' % cmd)
            status, out = commands.getstatusoutput(cmd)
            assert status == 0

def download_all(resources, path):
    for resource in resources:
        resource = resource.strip()
        if resource:
            download(resource, path)

def flatten_resources(dense, key=None, sep='_'):
    """search for and return resources as a list
    """
    RESOURCE='resource'
    resources = []
    assert type(dense) == dict
    log.debug('flatten_resources %s' % dense)
    for k,v in dense.items():
        if RESOURCE in v:
            resources.extend(v[RESOURCE])
        else:
            for k,second in v.iteritems():
                if isinstance(second, collections.MutableMapping):
                    resources.extend(flatten_resources(second, k, sep*2))
    return resources

def load_yaml(path):
    assert os.path.exists(os.path.abspath(path))
    with open(path,'r') as fo:
        _builds = yaml.load(fo)
    return _builds

def main(builds, major, minor):
    _builds = load_yaml(builds)
    log.info( 'loaded build')
    log.debug('build', _builds)
    tag = _tag.format(major,minor)
    resources = flatten_resources(_builds.values()[0][tag])
    log.info('resources to be downloaded:%s' % resources)
    if resources:
        path = 'rtqa{0}c{1}'.format(major,minor)
        path = os.path.join(_html,path)
        if not os.path.exists(path):
            cmd = 'mkdir -p '+ path
            status,output = commands.getstatusoutput(cmd)
            assert status == 0, "cmd:%s failed" % cmd
            log.info( 'status %s output %s' % (status,output))
        download_all(resources, path)

if __name__ == '__main__':
    major = 8
    minor = 5
    if len(sys.argv) > 2:
        major = sys.argv[2]
        if len(sys.argv) > 3:
            minor = sys.argv[3]
    main(sys.argv[1], major, minor)
