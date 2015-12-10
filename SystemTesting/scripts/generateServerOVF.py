#!/build/toolchain/lin32/python-2.7.9-openssl1.0.1k/bin/python

#
# This script is used to generate the servervmovf build
# for the given esx build. Before creating the ovf build
# it checks if servervmovf already exists for given esx
# build, if it exists it won't generate new build otherwise
# it would create the new one.
#
#

import json
from optparse import OptionParser
import os
import ssl
import re
from subprocess import Popen, PIPE
import sys
import urllib2
from urllib2 import URLError

from bs4 import BeautifulSoup
import P4 as P4
from pyVmomi import Vim, SoapStubAdapter

import vmware.common.nimbus_utils as nimbus_utils
from build_utilities import get_resource

NIMBUS_TEMPLATE_URL = "http://rdinfra3-nimbus-templates.eng.vmware.com/nimbus-templates/ESXVM"

def RunCommand(command):
   """ function to run command

   @params cmd : command to be run

   @return rc return code of the command
   @return stdout output of the command
   @return stderr stderror of the command
   """

   result = None
   stdout = None
   stderr = None

   result = Popen(command, shell=True, stdout=PIPE, stderr=PIPE)
   stdout, stderr = result.communicate()
   return (result.returncode, stdout, stderr)

def get_perforce_change(perforce_server, user, password):
   """ function to login to perforce and get the TOT
   change.

   @params perforce_server : perforce server to login to
   @params user : perforce user
   @params password password to login to perforce.

   @returns change TOT change
   """

   p4 = P4.P4()
   p4.user = user
   p4.password = password
   p4.port = perforce_server
   try:
      p4.connect()
      p4.run_login("-a")
      changes = p4.run("changes", "-s", "submitted", "-m",  "1")
   except P4.P4Exception:
      for e in p4.errors:
         print "error =%s while getting TOT change" % e
   change = changes[0]['change']
   if not change:
      print "Failed to get TOT change"
      return False
   else:
      return change

def generate_servervmovf(change, build, user):
   """ This function starts the command to
   generate the servervmovf tartget using gobuild

   @params change : change list
   @params build : esx build for which servervmovf has to created
   @params user : user name for generating ovf build
   """
   command = '/build/apps/bin/gobuild-sandbox-queue -v servervmovf \
             --branch=main --buildtype=beta --changeset=False \
             --syncto %s --component-builds server=%s --output json \
             --accept-defaults' % (change, build)
   if user:
      command = command + ' --user ' + user
   (rc, stdout, stderr) = RunCommand(command)

   if stdout:
      build_info = json.loads(stdout)
      ovf_build = build_info['builds'][0]['build_id']
      print "server vm ovf build is %s" % (ovf_build)
      return ovf_build
   else:
      print "generate_servervmovf stderror = %s" % (stderr)
      return None


def is_known_build(build):
   """ check if the given build is known
   @params build: esx build
   @return True if it is known build
   """

   build_id = build.split('-')[-1]
   template = list()
   vm = "ESX-VM-%s/" % (build_id)
   try:
      html = urllib2.urlopen(NIMBUS_TEMPLATE_URL)
   except URLError, e:
     print "error %s while accessing %s" \
            % (e.code, NIMBUS_TEMPLATE_URL)
     return None

   soup = BeautifulSoup(html)
   html.close()
   for link in soup.find_all('a'):
      item = link.get('href')
      template.append(item)

   if vm in template:
      print "build %s is a well known build" % (build)
      return True

   return None

def get_template(build):
   """ check if a tempalate already exists

   @params build: esx server build

   @ return True if a template exists
   """
   func = nimbus_utils.read_nimbus_config
   config_dict = func(os.environ['NIMBUS_CONFIG_FILE'],
                      os.environ['NIMBUS'])
   server = config_dict['vc']
   user = config_dict['vc_user']
   password = config_dict['vc_password']
   datacenter = config_dict['datacenter']
   cluster = config_dict['computer']

   # template name is of the format esx-template-<build>
   template = "esx-template-%s" %build
   result = check_for_template(server, user, password,\
                               datacenter, template)
   if result:
      print "template %s exist" % (template)
      return True
   else:
      print "template %s doesn't exist" % (template)
      return False

def check_for_template(server, user, password, name, \
                       template):
   """ check if given template exists
   @params server: vc server
   @params user: username of the vc
   @params password: password to login to vc
   @params name: Name of the datacenter
   @params template: name of the template

   @return True if template exists
   """

   stub = SoapStubAdapter(host=server, port=443, path="/sdk", \
                          version="vim.version.version7")
   serviceInstance = Vim.ServiceInstance("ServiceInstance", stub)
   content = serviceInstance.RetrieveContent()
   content.sessionManager.Login(user, password)
   datacenters = content.rootFolder.childEntity
   for datacenter in datacenters:
      if datacenter.name == name:
         vmFolder = datacenter.vmFolder.childEntity
         for folder in vmFolder:
            if folder.name == "nimbus":
               templates = folder.childEntity
               for vm in templates:
                  if vm.name == template:
                     return True
   return None

def get_ovf_build(build):
   """ Function to check if the server ovf
   build already exists for the given
   esx build.

   @params build : esx server build
   """

   exists = False
   if build.find('sb-') == 0:
      build_id = build.split('-')[-1]
      url = "/sb/build/%s" % (build_id)
   else:
      build_id = build.split('-')[-1]
      url = "/ob/build/%s" % (build_id)

   data = get_resource(url)
   consumers = get_resource(data['_sb_parent_builds_url'])
   _list = consumers['_list']
   for item in _list:
     data = get_resource(item['_build_url'])
     if data['product'] == "servervmovf" and \
        data['ondisk'] == True:
        deliverables = get_resource( data['_deliverables_url'])
        download = []
        # we have answer, build exists. now document which ovf
        for res in deliverables['_list']:
           _uri = res['_download_url']
           if _uri.endswith('.ovf'):
              download.append(_uri)
        if len(download) == 1:
           download = download.pop()
        print "servervmovf build %s exists for %s at %s" \
              % ( data['id'], build, download)
        exists = True
        break
     else:
        continue

   if not exists:
      print "ovf build for ESX build %s doesn't exist" \
             % (build)
   return exists

def wait_for_build(build):
   """ Function to check the status of the ovf
       build and wait for it to get completed.
       The timeout is 1800 sec(30 mins).Typically
       it gets over in 20-25 mins.

   @params build : ovf build
   @return None
   """

   timeout = 2100
   command = "/build/apps/bin/waitforbuild --time %s --job --output json --build-kind=sb %s" \
              % (timeout, build)
   (rc, stdout, stderr) = RunCommand(command)
   if rc == 0:
      print "build %s succeeded" %( build)
      return True
   elif rc == 1:
      print "build %s Failed " %(build)
   elif rc == 2:
     print "exception while running the waitforbuild"
   elif rc == 3:
     print "Time out while waiting for build %s" %(build)
   elif rc == 4:
     print "Build %s not needed " %(build)
   else:
     print "unknown error while waiting for build %s" %(build)

   return False

def main(args):
   usage = "usage: %prog [options]"
   parser = OptionParser(usage=usage)
   parser.add_option("--p4user", dest="p4user", action="store",
                     default=os.getenv('P4USER'), type="string",
                     help="user name to connect to perforce")
   parser.add_option("--p4password", dest="p4password", action = "store",
                     default=os.getenv('P4PASSWORD'), type="string",
                     help="password to connect to perforce")
   parser.add_option("--build", dest="build", action="store", type="string",
                      help="server build number")
   parser.add_option("--build_user", dest="build_user", action="store", type ="string",
                     help="username to be used to generate the ovf build")
   parser.add_option("--force", action="store_true", default=False,
                     help="force image upload")

   global options
   (options, args) = parser.parse_args(args)
   perforce="perforce-qa.eng.vmware.com:1666"

   ssl._create_default_https_context = ssl._create_unverified_context
   #
   # before going ahead with creation of serverovf check if it
   # already exists
   #
   if (re.match("sb", options.build)):
      type="sb"
   elif(re.match("ob", options.build)):
      type="ob"
   else:
      type="ob"
      options.build = "ob-%s" %(options.build)

   # check if given build is known build

   if is_known_build(options.build):
      sys.exit(0)
   else:
      print "build %s is not a well known build" % (options.build)

   #
   # check if template exists on nimbus cluster
   # this means someone has deployed the esx ovf
   #

   if not options.force:
      if get_template(options.build):
         print "template exists for %s" %(options.build)
         sys.exit(0)
      else:
         print "template doesn't exist for %s" % (options.build)
   else:
      print "forced upload requested"

   ovf_build = get_ovf_build(options.build)
   if ovf_build:
      print "ovf build already exists for build %s" \
             % (options.build)
      sys.exit(0)
   change = get_perforce_change(perforce, options.p4user, \
            options.p4password)
   if not change:
      print "failed to get the TOT change"
      sys.exit(1)

   # generate ovf build for the esx build
   ovf_build = generate_servervmovf(change, options.build, options.build_user)
   if ovf_build is not None:
      status = wait_for_build(ovf_build)
      if status:
         print "generated ovf build %s for server build %s" \
                % (ovf_build, options.build)
         sys.exit(0)
      else:
         print "generating ovf build %s failed for server  \
                build %s" % (ovf_build, options.build)
         sys.exit(1)
   else:
      print "creating ovf build failed for server build %s" \
             % (options.build)
      sys.exit(1)

if __name__ == "__main__":
   main(sys.argv[1:])
