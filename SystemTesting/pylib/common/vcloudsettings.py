"""provision.py needs these settings

usage: from vcloudsettings import settings

export SETTINGS=devops|systest|???

devops and systest and ? (default ~ devops)
======     -------
these are fixed defaults that are all overridable in invocation of provision.py

fixed parameters defined in vcloud, made shorthand, so I only have to remember
which cloud I use, rather than the long name for something in vcloud,

dictate what cloud to run in by setting
export SETTINGS=devops|systest|???
new orgs should be added here as they see fit to edit the code and add tests

This may become moot or redundant if we have searchable public catalogs
"""
import os
import vmware.provision.common.constants as constants
from vmware.provision.common.settings import Settings
import logging
logging.basicConfig()
log = logging.getLogger(__name__)

username = "automate"
password = "password"
auth_url = "vcore6-us01.oc.vmware.com"  # part of uri to cloud
server = "vcore6-us01.oc.vmware.com"
log_level = os.getenv('LOGLEVEL', default='WARN')
dirname = os.path.dirname


def named_parent_folder(name):
    """look for named folder in path above __file__
    """
    path = os.path.abspath(__file__)
    while os.path.basename(path) != name:
        path = dirname(path)
        if path == '/':
            raise Exception('unable to find parent folder %s' % name)
    return path

ONECLOUD_NETWORKS = os.path.join(named_parent_folder('automation'),
                                 'yaml', 'onecloud', 'networks.yaml')

# a selection of cloud settings 
# the one to use is dictated by env SETTINGS
legal_settings = {
    'devops': Settings(tenant="us01-c6-nsbu-tools-tr",
                       auth_url=auth_url,
                       catalog='automate',
                       server=server,
                       log_level=log_level,
                       username=username,
                       password=password,
                       networks=ONECLOUD_NETWORKS,
                       template='testesx'),

    'systest': Settings(tenant='us01-c6-nsbu-nsxqe-tr',
                        auth_url=auth_url,
                        catalog='System-Test',
                        server=server,
                        log_level=log_level,
                        username=username,
                        password=password,
                        template='vApp_Avalanche_Template',
                        networks=ONECLOUD_NETWORKS,
                        pool=True),

    'energon': Settings(tenant="us01-c2-nsbu-energon-infra-tr",
                        auth_url="vcore2-us01.oc.vmware.com",
                        catalog='automate',
                        server="vcore2-us01.oc.vmware.com",
                        log_level=log_level,
                        username=username,
                        password=password,
                        networks=ONECLOUD_NETWORKS,
                        template='detect_dhcp'),
}

settings_key = os.getenv('SETTINGS', default='systest')
settings = legal_settings[settings_key]

if settings_key in legal_settings:
    log.info('Using nsx-provisioning settings %s' % settings_key)
    settings = legal_settings[settings_key]
else:
    raise Exception('env $SETTINGS="%s" not a legal value in: %s'
                    % (settings_key, legal_settings.keys()))
