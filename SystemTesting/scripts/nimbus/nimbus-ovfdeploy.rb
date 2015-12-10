#!/usr/bin/env ruby
require 'json'
require 'yaml'
require 'rbvmomi-utils/ssh'
require 'trollop'
require 'rbvmomi'
require 'rbvmomi-utils/esxvm'
require 'rbvmomi-utils/flag'
require 'rbvmomi-utils/pxeconfig'
require 'nimbus'
require 'nimbusUtils'
require 'rbvmomi-utils/profile'
require 'nimbus/phonehome'
require 'eventmachine'
require 'rbvmomi-utils/eventmachine'
require 'mq'
require 'rbvmomi-utils/amqp'
require 'rbvmomi-utils/fileuri'
require 'VMwareBuildWeb.rb'

include RbVmomi
include Trollop

require 'nimbusRbvmomi'

opts = Trollop.options do
  banner <<-EOS
Deploy an OVF to the Nimbus cloud.

Usage:
    nimbus-ovfdeploy [options] name ovfDescriptorPath

Other options:
  EOS

  D = RbVmomiUtils::ESXVM::DEFAULT_CFG
  opt :debug, "Log SOAP messages", short: 'd'
  opt :"create-only", "Don't boot the VM", short: :none
  opt :lease, "Lease in days", type: :int, default: 3
  opt :configurablePropertyFile, "xml file that has user configurable property mappings", type: :string
  opt :result, "Write VM info to this file", type: :string
  opt :prop, "property in the form key=value", multi: true, short: 'p', type: :string
  opt :ports, "Services port number to check after boot, example: --ports 22 --ports 80", short: :none, type: :int , multi: true
  opt :usespyarp, "Use spyarp to get IP address of VM"
  opt :useLinkedClone, "Use linked to clone to deploy from OVF"
  opt :network, "Network", :default => ['public'], :multi => true
  opt :memory, "Memory", :default => "4096", :multi => false
  opt :nics, "Number of NICs", :default => D[:nics]
  opt :destroyVmOnFailure , "Cleanup VMs in case of any error", type: :boolean, :default => false
end

Trollop.die "don't run this script as root" if ['root', 'mts'].member? ENV['USER']

vm_name = ARGV[0] or fail "must give vm name"
ovfDescPath = ARGV[1] or fail "must give ovf descriptor path"
vm_name = "#{ENV['USER']}-#{vm_name}" unless vm_name =~ /^#{ENV['USER']}/

phonehome 'ovfdeploy.start', vm_name: vm_name, ovfDescPath: ovfDescPath, opts: opts

EM.spawn_reactor

vim = nil
exit_code = 0
begin
  deployer = NimbusDeployer.new opts
  vim = deployer.vim
  amqp = NimbusUtils.connect_amqp

  computer = deployer.computer
  datastore = deployer.datastore

  # if uri is a existing file, create a file uri
  if File.exists?(ovfDescPath)
    # use absolute expanded path for file uri
    ovfDescPath = 'file://'+File.expand_path(ovfDescPath)
  end

  ovfURI = URI.parse ovfDescPath
  puts "#{Time.now}: Using OVF: #{ovfURI}"
  ovfStr = open(ovfURI).read
  ovfXml = Nokogiri::XML(ovfStr).remove_namespaces!
  networks = Hash[ovfXml.xpath('//NetworkSection/Network').map{|x| desc = x.xpath('Description').first; [x['name'], desc ? desc : '']}]

  networkMappings = Hash[networks.keys.map{|x| [x, Nimbus.network]}]
  puts "#{Time.now}: networks: #{networkMappings.map{|k, v| "#{k} = #{v}"}.join(', ')}"

  pc = vim.serviceContent.propertyCollector
  hosts = computer.host
  hosts_props = pc.collectMultiple(hosts, 'datastore', 'runtime.connectionState', 'runtime.inMaintenanceMode', 'name')
  host = hosts.shuffle.find do |x|
    host_props = hosts_props[x]
    is_connected = host_props['runtime.connectionState'] == 'connected'
    is_ds_accessible = host_props['datastore'].member?(datastore)
    is_connected && is_ds_accessible && !host_props['runtime.inMaintenanceMode']
  end
  if !host
    fail "Couldn't find a capable host"
  end
  puts "#{Time.now}: host: #{host.name}"

  if opts[:configurablePropertyFile]
    # read the property mapping from the xml file
    propertyMappings = Nimbus.getPropertyMappings opts[:configurablePropertyFile]
  else
    # if the user configurable properties were not passed as key/value pairs, set the defaults
    propertyMappings = Nimbus.getPropertyMappingsFromKeyValue opts[:prop]
  end
  config = {}
  if opts[:useLinkedClone]
    templateName = ovfDescPath.split('/').last
    puts "#{Time.now}: Template name: #{templateName}"
    template = deployer.lookupLinkedCloneTemplate templateName
    # if the template is not found, the template will be created.
    if !template
      phonehome 'ovfdeploy.templateStart', ovf_url: ovfURI, template_name: templateName, vm_name: vm_name, opts: opts
      if propertyMappings
        puts "Setting property mappings: #{propertyMappings}"
        template = deployer.uploadOvfToLinkedCloneTemplate ovfURI, templateName, nil, {}, propertyMappings
      else
        template = deployer.uploadOvfToLinkedCloneTemplate ovfURI, templateName
      end
      phonehome 'ovfdeploy.templateFinish', ovf_url: ovfURI, template_name: templateName, vm_name: vm_name, opts: opts
    end
    vm = deployer.linkedClone template, vm_name, config
  else
    vm = vim.serviceContent.ovfManager.deployOVF(
      uri: ovfURI,
      vmName: vm_name,
      vmFolder: deployer.vmFolder,
      host: host,
      resourcePool: deployer.rp,
      datastore: datastore,
      networkMappings: networkMappings,
      propertyMappings: propertyMappings)
  end

  note = YAML.load vm.config.annotation
  if !note.is_a?(Hash)
    note = {}
  end
  if opts[:lease] && opts[:lease] != 0
    note['lease'] = Time.now + 3600*24*opts[:lease]
  end
  if opts[:usespyarp]
    # This option is needed in case the OVF does not support guest tools.
    # we don't change config with networkBackings and arpspy stuff unless needed
    # because due to which ovfs like /win2k8v16.ovf are not getting ip see PR 1071368
    puts "#{Time.now}: Assigning lease and configuring VM for arpspy ..."
    networkBackings = Nimbus.getNetworkBackings(opts[:network])
    cpus = vm.summary.config.numCpu
    config = NimbusUtils.getvmcfg(vim, vm_name,
                             opts.merge(pxe: false,
                                        datastore: datastore.name,
                                        memory: opts[:memory],
                                        cpus: cpus,
                                        networkBackings: networkBackings),
                             vm, false)
     config.annotation = YAML.dump(note)
   else
    puts "#{Time.now}: Assigning lease ..."
    config = { :annotation => YAML.dump(note) }
  end
  # Add more network interfaces if specified in the command-line
  if opts[:nicType] || !opts[:nics].nil? || opts[:network] != ['public']
    reconfigOps = Nimbus.generateNicConfigOps vm, opts[:nicType], opts[:nics], opts[:network]
    config.deviceChange = reconfigOps
  end

  vm.ReconfigVM_Task(:spec => config).wait_for_completion

  # The below call is added to keep automation running w.r.t the change
  # introduced in cloudvm for security purpose
  # The following are the changes:
  # 1. doesn't provide a default password
  # 2. uses funky root shell
  # 3. disables ssh
  # Pl. note that this is just a workaround and automation
  # at some point need to address this issue in their scripts itself.
  puts "Setting root shell to bin/bash..."
  vm.setVAppProperty_Task('', 'guestinfo.cis.appliance.root.shell2', '/bin/bash', true)

  puts "#{Time.now}: powering on VM ..."
  vm.PowerOnVM_Task!.wait_for_completion

  spinner = Spinner.new
  spinner.begin "Waiting for VM to boot ..."
  ip = nil

  unless opts[:ports].empty?
    puts "#{Time.now}: Service ports to check #{opts[:ports]} ..."
  end
  ip, type = NimbusUtils.wait_for_ip amqp, vm, nil, nil, opts[:ports]

  fail "failed to determine IP address" unless ip
  spinner.done
  NimbusUtils.annotate_vm_with_ip vm, ip
  puts "#{Time.now}: Determined IP address: #{ip}"
  puts "#{Time.now}: done"

  if opts[:result]
    open(opts[:result], 'w') { |file|
      result_obj = {"name" => vm_name, "ip" => ip, 'pod' => ENV['NIMBUS']}
      file.puts "#{result_obj.to_json}"
    }
  end
rescue RbVmomi::Fault => ex
  phonehome 'ovfdeploy.exception', klass: $!.class, message: $!.message, backtrace: $!.backtrace
  puts "#{Time.now}: Exception: #{ex.message}"
  puts ex.backtrace.join("\n")
  pp ex.fault
  exit_code = 1
rescue Exception => ex
  phonehome 'ovfdeploy.exception', klass: $!.class, message: $!.message, backtrace: $!.backtrace
  puts "#{Time.now}: Exception: #{ex.message}"
  puts ex.backtrace.join("\n")
  exit_code = 1
ensure
  # cleanup vm if there were any exceptions
  if exit_code == 1 && opts[:destroyVmOnFailure]
    if vm.runtime.powerState != "poweredOff"
      vm.PowerOffVM_Task.wait_for_completion
    end
    vm.destroyFixPR778803
  end
  if vim
    vim.close
  end
  EM.kill_reactor
end

phonehome 'ovfdeploy.finish'
exit exit_code

