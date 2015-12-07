/*************************************************************************
 * Copyright 2009 VMware, Inc. All rights reserved. -- VMware Confidential
 * ************************************************************************
 */
package com.vmware.vcqa.vim.dvs;

import static com.vmware.vcqa.TestConstants.VM_DEFAULT_GUEST_WINDOWS;
import static com.vmware.vcqa.TestConstants.VM_VIRTUALDEVICE_ETHERNET_PCNET32;
import static com.vmware.vcqa.TestConstants.VM_VIRTUALDEVICE_SCSI_BUSL_CONTROLLER;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.MessageConstants.VM_CREATE_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.VM_CREATE_PASS;
import static com.vmware.vcqa.vim.MessageConstants.VM_POWEROFF_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.VM_POWEROFF_PASS;
import static com.vmware.vcqa.vim.MessageConstants.VM_POWERON_PASS;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.BLOCKED_KEY;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.INSHAPING_POLICY_KEY;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.OUT_SHAPING_POLICY_KEY;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.QOS_TAG_KEY;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.SECURITY_POLICY_KEY;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.TX_UPLINK_KEY;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.UPLINK_TEAMING_POLICY_KEY;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.VENDOR_SPECIFIC_CONFIG_KEY;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.VLAN_KEY;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.io.Writer;
import java.lang.reflect.Method;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.ByteBuffer;
import java.nio.CharBuffer;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.Vector;

import javax.security.auth.DestroyFailedException;

import org.json.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import ch.ethz.ssh2.Connection;

import com.vmware.vc.*;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.LogUtil;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.execution.TestDataHandler;
import com.vmware.vcqa.internal.vim.InternalServiceInstance;
import com.vmware.vcqa.internal.vim.dvs.InternalDVSHelper;
import com.vmware.vcqa.internal.vim.dvs.InternalHostDistributedVirtualSwitchManager;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.NetworkUtil;
import com.vmware.vcqa.util.SSHUtil;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.util.VmHelper;
import com.vmware.vcqa.vim.AuthorizationManager;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.MORConstants;
import com.vmware.vcqa.vim.SessionManager;
import com.vmware.vcqa.vim.VMSpecManager;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.event.EventManager;
import com.vmware.vcqa.vim.host.DatastoreSystem;
import com.vmware.vcqa.vim.host.NetworkResourcePoolHelper;
import com.vmware.vcqa.vim.host.NetworkSystem;
import com.vmware.vcqa.vim.host.VmotionSystem;

/**
 * This class comprises of useful utility methods for performing operations
 * related to distributed virtual switches
 */
public class DVSUtil
{
   private static final Logger log = LoggerFactory.getLogger(DVSUtil.class);
   public static final String[] allEthernetCardTypes = {
            VirtualPCNet32.class.getName(), VirtualE1000.class.getName(),
            VirtualVmxnet.class.getName(), VirtualVmxnet2.class.getName(),
            VirtualVmxnet3.class.getName(), VirtualE1000E.class.getName() };

   private static final String DOWNLOAD_NSXA2_SCRIPT = "wget -P /tmp http://vmweb.vmware.com/~ksu/nsxa2/nsxa2 ";
   private static final String DOWNLOAD_NSXA_VIM_PYTHON_SCRIPT = "wget -P /tmp http://vmweb.vmware.com/~ksu/nsxa2/nsxaVim2.py";
   private static final String CHANGE_PERMISSION_NSXA2_EXECUTABLE = "chmod +x /tmp/nsxa2";
   private static final String START_NSXA2_SIMULATOR = "sh -c 'cd /tmp; nohup /tmp/nsxa2";
   private static final String REDIRECT_OUTPUT = " > /dev/null 2>&1 &'";
   private static final String GET_NSXA2_PROCESS = "ps | grep nsxa2";
   private static final String KILL_PROCESS = "kill ";
   private static final String CLEAR_NSXA2 = "cd /tmp && ./nsxa2 clear";
   private static int nsxaFailCount = 0;

   /**
    * This method returns a delta VirtualMachineConfigSpec array object for
    * changing all the virtual ethernet card devices on the VM to have
    * DVPort(standalone/portgroup) backings.
    *
    * @param vmMor ManagedObjectReference of the virtual machine
    * @param connectAnchor object that contains the connection information
    * @param portConnection[] array object that contains the Distributed Virtual
    *           Port and/or portgroup details
    * @return VirtualMachineConfigSpec[] delta config spec
    *         VirtualMachineConfigSpec[0] contains the updated delta config spec
    *         and VirtualMachineConfigSpec[1] contains the delta config spec to
    *         restore the original config spec of the VM to be used in test
    *         cleanup
    * @throws MethodFault,Exception
    */
   public static VirtualMachineConfigSpec[] getVMConfigSpecForDVSPort(final ManagedObjectReference vmMor,
                                                                      final ConnectAnchor connectAnchor,
                                                                      final DistributedVirtualSwitchPortConnection[] portConnection)
      throws Exception
   {
      return getVMConfigSpecForDVSPortForVNic(vmMor, connectAnchor,
               portConnection, null, null);
   }

   /**
    * This method returns all the pnic keys that are connecting the host proxy
    * switch to the vds
    *
    * @param connectAnchor
    * @param hostMor
    * @param vdsMor
    * @return List<String> The list of pnic keys connecting the host proxy switch
    *         to the vds
    * @throws MethodFault,Exception
    */
   public static List<String> getPnicListOnProxySwitch(final ConnectAnchor connectAnchor,
                                                       final ManagedObjectReference hostMor,
                                                       final ManagedObjectReference vdsMor)
      throws Exception
   {
      assertNotNull(connectAnchor, "The connect Anchor is null");
      assertNotNull(hostMor, "The host Mor is null");
      assertNotNull(vdsMor, "The vds Mor is null");
      final List<String> pnicList = new ArrayList<String>();
      final DistributedVirtualSwitch vds = new DistributedVirtualSwitch(
               connectAnchor);
      final NetworkSystem nwSystem = new NetworkSystem(connectAnchor);
      final String vdsUuid = vds.getConfig(vdsMor).getUuid();
      final ManagedObjectReference nsMor = nwSystem.getNetworkSystem(hostMor);
      final HostProxySwitch[] hostProxySwitch = com.vmware.vcqa.util.TestUtil.vectorToArray(
               nwSystem.getNetworkInfo(nsMor).getProxySwitch(),
               com.vmware.vc.HostProxySwitch.class);
      if (hostProxySwitch != null && hostProxySwitch.length >= 1) {
         for (final HostProxySwitch proxySwitch : hostProxySwitch) {
            if (proxySwitch.getDvsUuid().equals(vdsUuid)
                     && com.vmware.vcqa.util.TestUtil.vectorToArray(
                              proxySwitch.getPnic(), java.lang.String.class) != null) {
               pnicList.addAll(Arrays.asList(com.vmware.vcqa.util.TestUtil.vectorToArray(
                        proxySwitch.getPnic(), java.lang.String.class)));
               break;
            }
         }
      } else {
         log.info("There are no proxy switches on the host");
      }
      return pnicList;
   }

   /**
    * The method gets the host dvs manager mor
    *
    * @param connectAnchor
    * @param hostMor
    * @return ManagedObjectReference
    * @throws Exception
    */
   public static ManagedObjectReference getHostDVSMgrMor(ConnectAnchor connectAnchor,
                                                         ManagedObjectReference hostMor)
      throws Exception
   {
      assertNotNull(connectAnchor, "The connect anchor is valid", "The "
               + "connect anchor is null");
      assertNotNull(hostMor, "The host mor is valid", "The host mor is null");
      ConnectAnchor hostConnectAnchor = DVSUtil.getHostConnectAnchor(
               connectAnchor, hostMor);
      assertNotNull(hostConnectAnchor, "Obtained the connect anchor to hostd",
               "Failed to obtain a connect anchor to hostd");
      InternalServiceInstance msi = new InternalServiceInstance(
               hostConnectAnchor);
      return msi.getInternalServiceInstanceContent().getHostDistributedVirtualSwitchManager();
   }

   /**
    * Create a default VMConfigSpec.
    *
    * @param connectAnchor ConnectAnchor
    * @param hostMor The MOR of the resource pool where the defaultVMSpec has to
    *           be created.
    * @param deviceType type of the device.
    * @param vmName String
    * @return vmConfigSpec VirtualMachineConfigSpec.
    * @throws MethodFault, Exception
    */
   public static VirtualMachineConfigSpec buildDefaultSpec(final ConnectAnchor connectAnchor,
                                                           final ManagedObjectReference poolMor,
                                                           final String deviceType,
                                                           final String vmName,
                                                           final int noOfCards)
      throws Exception
   {
      VirtualMachineConfigSpec vmConfigSpec = null;
      final HostSystem ihs = new HostSystem(connectAnchor);
      final VirtualMachine ivm = new VirtualMachine(connectAnchor);
      final Vector<String> deviceTypesVector = new Vector<String>();
      if (poolMor != null) {
         deviceTypesVector.add(TestConstants.VM_VIRTUALDEVICE_DISK);
         deviceTypesVector.add(VM_VIRTUALDEVICE_SCSI_BUSL_CONTROLLER);
         for (int i = 0; i < noOfCards; i++) {
            deviceTypesVector.add(TestConstants.VM_VIRTUALDEVICE_ETHERNET_PCNET32);
         }
         deviceTypesVector.add(deviceType);
         // create the VMCfg with the default devices.
         vmConfigSpec = ivm.createVMConfigSpec(poolMor, vmName,
                  VM_DEFAULT_GUEST_WINDOWS, deviceTypesVector, null);
      } else {
         log.error("Unable to get the resource pool from the " + "host.");
      }
      return vmConfigSpec;
   }

   /**
    * This method returns a VirtualMachineConfigSpec for changing a VM's VNIC to
    * have a DVPort Backing
    *
    * @param vmMor ManagedObjectReference for the VM
    * @param anchor ConnectAnchor object
    * @param pcn array object that contains the Distributed Virtual Port and/or
    *           portgroup details
    * @param nicName VNIC whose backing is to be changed
    * @param macAddress (optional) new macAddress of the VNIC
    * @return VirtualMachineConfigSpec[] deltaConfigSpec
    *         VirtualMachineConfigSpec[0] contains the updated delta config spec
    *         and VirtualMachineConfigSpec[1] contains the delta config spec to
    *         restore the original conifg spec of the VM to be updated in the
    *         test cleanup
    * @throws MethodFault
    * @throws Exception
    */
   public static VirtualMachineConfigSpec[] getVMConfigSpecForDVSPortForVNic(final ManagedObjectReference vmMor,
                                                                             final ConnectAnchor connectAnchor,
                                                                             final DistributedVirtualSwitchPortConnection[] pcn,
                                                                             final String nicName,
                                                                             final String macAddress)
      throws Exception
   {
      VirtualMachineConfigSpec[] deltaConfigSpec = null;
      VirtualMachineConfigSpec updatedDeltaConfigSpec = null;
      VirtualMachineConfigSpec originalDeltaConfigSpec = null;
      VirtualMachine ivm = null;
      VirtualMachineConfigInfo vmConfigInfo = null;
      VirtualDevice[] vds = null;
      VirtualDeviceConfigSpec updatedDeviceConfigSpec = null;
      VirtualDeviceConfigSpec originalDeviceConfigSpec = null;
      VirtualEthernetCardDistributedVirtualPortBackingInfo dvPortBacking = null;
      final List<VirtualDeviceConfigSpec> updatedDeviceChange = new ArrayList<VirtualDeviceConfigSpec>();
      final List<VirtualDeviceConfigSpec> originalDeviceChange = new ArrayList<VirtualDeviceConfigSpec>();
      VirtualDeviceConnectInfo vdConnectInfo = null;
      int j = 0;
      if (connectAnchor != null) {
         ivm = new VirtualMachine(connectAnchor);
         if (vmMor != null && pcn != null) {
            vmConfigInfo = ivm.getVMConfigInfo(vmMor);
            updatedDeltaConfigSpec = new VirtualMachineConfigSpec();
            originalDeltaConfigSpec = new VirtualMachineConfigSpec();
            if (vmConfigInfo != null
                     && vmConfigInfo.getHardware() != null
                     && com.vmware.vcqa.util.TestUtil.vectorToArray(
                              vmConfigInfo.getHardware().getDevice(),
                              com.vmware.vc.VirtualDevice.class) != null) {
               vds = com.vmware.vcqa.util.TestUtil.vectorToArray(
                        vmConfigInfo.getHardware().getDevice(),
                        com.vmware.vc.VirtualDevice.class);
               for (final VirtualDevice vd : vds) {
                  if (vd != null && vd instanceof VirtualEthernetCard) {
                     final VirtualEthernetCard vcCard = (VirtualEthernetCard) vd;
                     if (nicName != null) {
                        if (updatedDeviceConfigSpec != null) {
                           break;
                        }
                        if (!nicName.equals(vd.getDeviceInfo().getLabel())) {
                           continue;
                        }
                     } else {
                        if (j >= pcn.length) {
                           break;
                        }
                     }
                     updatedDeviceConfigSpec = new VirtualDeviceConfigSpec();
                     originalDeviceConfigSpec = new VirtualDeviceConfigSpec();
                     originalDeviceConfigSpec.setOperation(VirtualDeviceConfigSpecOperation.EDIT);
                     originalDeviceConfigSpec.setDevice((VirtualDevice) TestUtil.deepCopyObject(vd));
                     originalDeviceChange.add(originalDeviceConfigSpec);
                     dvPortBacking = new VirtualEthernetCardDistributedVirtualPortBackingInfo();
                     dvPortBacking.setPort(pcn[j++]);
                     vcCard.setBacking(dvPortBacking);
                     vdConnectInfo = new VirtualDeviceConnectInfo();
                     vdConnectInfo.setStartConnected(true);
                     vdConnectInfo.setConnected(true);
                     vdConnectInfo.setAllowGuestControl(true);
                     vcCard.setConnectable(vdConnectInfo);
                     if (macAddress != null) {
                        vcCard.setAddressType(TestConstants.MAC_ADDRESSTYPE_MANUAL);
                        vcCard.setMacAddress(macAddress);
                     }
                     updatedDeviceConfigSpec.setOperation(VirtualDeviceConfigSpecOperation.EDIT);
                     updatedDeviceConfigSpec.setDevice(vcCard);
                     updatedDeviceChange.add(updatedDeviceConfigSpec);
                  }
               }
               if (updatedDeviceConfigSpec != null) {
                  updatedDeltaConfigSpec = new VirtualMachineConfigSpec();
                  updatedDeltaConfigSpec.getDeviceChange().clear();
                  updatedDeltaConfigSpec.getDeviceChange().addAll(
                           com.vmware.vcqa.util.TestUtil.arrayToVector(updatedDeviceChange.toArray(new VirtualDeviceConfigSpec[updatedDeviceChange.size()])));
                  originalDeltaConfigSpec = new VirtualMachineConfigSpec();
                  originalDeltaConfigSpec.getDeviceChange().clear();
                  originalDeltaConfigSpec.getDeviceChange().addAll(
                           com.vmware.vcqa.util.TestUtil.arrayToVector(originalDeviceChange.toArray(new VirtualDeviceConfigSpec[originalDeviceChange.size()])));
                  deltaConfigSpec = new VirtualMachineConfigSpec[2];
                  deltaConfigSpec[0] = updatedDeltaConfigSpec;
                  deltaConfigSpec[1] = originalDeltaConfigSpec;
               } else {
                  log.warn("No matching VNIC found");
                  return null;
               }
            }
         } else {
            log.warn("The Virtual Machine MOR and the"
                     + "DistributedVirtualSwitchPortConnection cannot be null");
         }
      } else {
         log.warn("The connectAnchor object cannot be null");
      }
      return deltaConfigSpec;
   }

   /**
    * This method reconfigures all the virtual machine vnics to the respective
    * portgroups passed in the map
    *
    * @param vmMor ManagedObjectReference of the virtual machine
    * @param connectAnchor Connection
    * @param ethernetCardNetworkMap map of the connection between the ethernet
    *           card and the portgroup
    * @return VirtualMachineConfigSpec, the original config spec of the virtual
    *         machine to restore the original settings
    * @throws MethodFault, Exception
    */
   public static VirtualMachineConfigSpec reconfigureVMConnectToVdsPort(ManagedObjectReference vmMor,
                                                                        ConnectAnchor connectAnchor,
                                                                        Map<String, Map<String, Boolean>> ethernetCardNetworkMap,
                                                                        String vdsUuid)
      throws Exception
   {
      VirtualMachineConfigSpec updatedDeltaConfigSpec = null;
      VirtualMachineConfigSpec originalDeltaConfigSpec = null;
      VirtualMachine ivm = null;
      VirtualMachineConfigInfo vmConfigInfo = null;
      VirtualDevice[] vds = null;
      VirtualEthernetCardDistributedVirtualPortBackingInfo backingInfo = null;
      VirtualDeviceConfigSpec updatedDeviceConfigSpec = null;
      VirtualDeviceConfigSpec originalDeviceConfigSpec = null;
      List<VirtualDeviceConfigSpec> updatedDeviceChange = new ArrayList<VirtualDeviceConfigSpec>();
      List<VirtualDeviceConfigSpec> originalDeviceChange = new ArrayList<VirtualDeviceConfigSpec>();
      assertNotNull(connectAnchor, "The connect anchor is null");
      ivm = new VirtualMachine(connectAnchor);
      assertNotNull(vmMor, "The virtual machine mor is null");
      assertNotNull(ethernetCardNetworkMap, "The ethernet card network map "
               + "is null");
      vmConfigInfo = ivm.getVMConfigInfo(vmMor);
      updatedDeltaConfigSpec = new VirtualMachineConfigSpec();
      originalDeltaConfigSpec = new VirtualMachineConfigSpec();
      if (vmConfigInfo != null
               && vmConfigInfo.getHardware() != null
               && com.vmware.vcqa.util.TestUtil.vectorToArray(
                        vmConfigInfo.getHardware().getDevice(),
                        com.vmware.vc.VirtualDevice.class) != null) {
         vds = com.vmware.vcqa.util.TestUtil.vectorToArray(
                  vmConfigInfo.getHardware().getDevice(),
                  com.vmware.vc.VirtualDevice.class);
         for (VirtualDevice vd : vds) {
            if (vd != null && vd instanceof VirtualEthernetCard) {
               updatedDeviceConfigSpec = new VirtualDeviceConfigSpec();
               originalDeviceConfigSpec = new VirtualDeviceConfigSpec();
               originalDeviceConfigSpec.setOperation(VirtualDeviceConfigSpecOperation.EDIT);
               originalDeviceConfigSpec.setDevice((VirtualDevice) TestUtil.deepCopyObject(vd));
               originalDeviceChange.add(originalDeviceConfigSpec);
               backingInfo = new VirtualEthernetCardDistributedVirtualPortBackingInfo();
               DistributedVirtualSwitchPortConnection portConn = new DistributedVirtualSwitchPortConnection();
               portConn.setSwitchUuid(vdsUuid);
               Map<String, Boolean> portBoolMap = ethernetCardNetworkMap.get(vd.getDeviceInfo().getLabel());
               if (portBoolMap == null || portBoolMap.keySet() == null
                        || portBoolMap.keySet().isEmpty()) {
                  continue;
               }
               String key = portBoolMap.keySet().iterator().next();
               /*
                * portBoolMap contains a boolean value for a key which
                * is true if the key represents a dvportgroup and false
                * if it represents a dvport
                */
               if (!portBoolMap.get(key)) {
                  portConn.setPortKey(key);
               } else {
                  portConn.setPortgroupKey(key);
               }
               backingInfo.setPort(portConn);
               vd.setBacking(backingInfo);
               if (vd.getConnectable() != null) {
                  vd.getConnectable().setStartConnected(true);
               }
               updatedDeviceConfigSpec.setOperation(VirtualDeviceConfigSpecOperation.EDIT);
               updatedDeviceConfigSpec.setDevice(vd);
               updatedDeviceChange.add(updatedDeviceConfigSpec);
            }
         }
         updatedDeltaConfigSpec.getDeviceChange().clear();
         updatedDeltaConfigSpec.getDeviceChange().addAll(
                  com.vmware.vcqa.util.TestUtil.arrayToVector(updatedDeviceChange.toArray(new VirtualDeviceConfigSpec[updatedDeviceChange.size()])));
         originalDeltaConfigSpec.getDeviceChange().clear();
         originalDeltaConfigSpec.getDeviceChange().addAll(
                  com.vmware.vcqa.util.TestUtil.arrayToVector(originalDeviceChange.toArray(new VirtualDeviceConfigSpec[originalDeviceChange.size()])));
      }
      /*
       * Reconfigure the virtual machine with the new settings
       */
      assertTrue(ivm.reconfigVM(vmMor, updatedDeltaConfigSpec),
               "Reconfigured the virtual machine to connect to the new "
                        + "dvport/dvportgroup(s)",
               "Failed to reconfigure the virtual machine to "
                        + "connect to the dvport/dvportgroup(s)");
      return originalDeltaConfigSpec;
   }

   /**
    * Method to check the network connectivity. If destIp is null, the network
    * connectivity of the source is checked. If both values are set, the network
    * connectivity between the source and destination is checked. The second
    * scenario is applicable for testing network connectivity for 2 VMs in the
    * same PVLAN etc...
    *
    * @param srcIp IP address of the source
    * @param destIp IP address of the destination. A null value indicates that
    *           only the network connectivity of the source is to be checked
    * @param params optional boolean[] parameter, the first parameter to
    *           indicate whether the source OS is linux or not and the second
    *           parameter indicates whether the address is an ipv6 address or
    *           not
    * @return boolean, true if network connectivity is available, false
    *         otherwise
    */
   public static boolean checkNetworkConnectivity(final String srcIp,
                                                  final String destIp,
                                                  final boolean... params)
      throws Exception
   {
      log.info("Checking network connectivity...");
      boolean isConnected = false;
      String command = null;
      boolean isSrcLinux = true;
      boolean isIpv6Address = false;
      Set<String> keySet = null;
      Iterator<String> itr = null;
      String val = null;
      String key = null;
      Map<String, String> dataMap = null;
      String userName = null;
      String password = null;
      Connection sshConn = null;
      if (params != null) {
         if (params.length >= 1) {
            isSrcLinux = params[0];
            if (params.length > 1) {
               isIpv6Address = params[1];
            }
         }
      }
      if (isSrcLinux) {
         userName = TestConstants.ESX_USERNAME;
         password = TestConstants.ESX_PASSWORD;
      } else {
         userName = TestConstants.SERVER_WIN_USERNAME;
         password = TestConstants.ESX_PASSWORD;
      }
      //sshConn = SSHUtil.getSSHConnection(srcIp, userName, password);
      try{
    	  sshConn = SSHUtil.getSSHConnection(srcIp, "root", "vmware");
      }catch(Exception e){
    	  sshConn = SSHUtil.getSSHConnection(srcIp, "root", "ca$hc0w");
      }
      DVSUtil.WaitForIpaddress();
      if (destIp == null) {
         if (sshConn != null) {
            log.info("Successfully established the SSH connection to " + srcIp);
            isConnected = true;
         } else {
            log.warn("Could not establish the SSH connection with " + srcIp);
         }
      } else {
         if (isSrcLinux) {
            if (isIpv6Address) {
               command = TestConstants.PING_IPV6_COUNT_THREE_LINUX + destIp;
            } else {
               command = TestConstants.PING_IPV4_COUNT_THREE_LINUX + destIp;
            }
         } else {
            if (isIpv6Address) {
               command = TestConstants.PING_IPV6_COUNT_THREE_WINDOWS + destIp;
            } else {
               command = TestConstants.PING_IPV4_COUNT_THREE_WINDOWS + destIp;
            }
         }
         dataMap = SSHUtil.getRemoteSSHCmdOutput(sshConn, command);
         isConnected = true;
         if (dataMap != null) {
            keySet = dataMap.keySet();
            itr = keySet.iterator();
            while (itr.hasNext()) {
               key = itr.next();
               if (key.equals(TestConstants.SSH_OUTPUT_STREAM)) {
                  val = dataMap.get(key);
                  log.info("SSH OUTPUT: " + val);
                  if (val != null) {
                     /*
                      * Sample SSH output : 3 packets transmitted, 0 received,
                      * 100% packet loss, time 2002ms
                      */
                     final String[] parts = val.split(",");
                     for (final String s : parts) {
                        if (s.indexOf("received") != -1
                                 || s.indexOf("Received") != -1) {
                           if (s.indexOf("0") != -1) {
                              isConnected = false;
                              break;
                           }
                        }
                     }
                  }
               }
            }
         }
      }
      if (SSHUtil.closeSSHConnection(sshConn)) {
         log.info("Successfully closed the SSH connection.");
      } else {
         log.warn("Unable to close the SSH connection.");
      }
      return isConnected;
   }

   /**
    * Create HostVirtualNicSpec Object and set the values.
    *
    * @param portConnection DistributedVirtualSwitchPortConnection
    * @param ipAddress IPAddress
    * @param subnetMask subnetMask
    * @param dhcp boolean
    * @return HostVirtualNicSpec
    * @throws MethodFault, Exception
    */
   public static HostVirtualNicSpec buildVnicSpec(final DistributedVirtualSwitchPortConnection portConnection,
                                                  final String ipAddress,
                                                  final String subnetMask,
                                                  final boolean dhcp)
      throws Exception
   {
      final HostVirtualNicSpec spec = new HostVirtualNicSpec();
      spec.setDistributedVirtualPort(portConnection);
      final HostIpConfig ip = new HostIpConfig();
      ip.setDhcp(dhcp);
      ip.setIpAddress(ipAddress);
      ip.setSubnetMask(subnetMask);
      spec.setIp(ip);
      return spec;
   }

   /**
    * This method returns the virtual ethernet card resource allocation object
    * out of the primitive parameters
    *
    * @param reservation
    * @param sharesInfo
    * @param limit
    * @return VirtualEthernetCardResourceAllocation
    */
   public static VirtualEthernetCardResourceAllocation getVirtualEthernetCardResourceAllocation(long reservation,
                                                                                                SharesInfo sharesInfo,
                                                                                                long limit)
   {
      VirtualEthernetCardResourceAllocation vEthernetCardResAlloc = new VirtualEthernetCardResourceAllocation();
      vEthernetCardResAlloc.setReservation(reservation);
      vEthernetCardResAlloc.setShare(sharesInfo);
      vEthernetCardResAlloc.setLimit(limit);
      return vEthernetCardResAlloc;
   }

   /**
    * This method returns the SharesInfo object when the SharesLevel and shares
    * are provided.
    *
    * @param shares
    * @param SharesLevel
    * @return SharesInfo
    */
   public static SharesInfo getShares(Integer shares,
                                      SharesLevel sharesLevel)
   {
      SharesInfo sharesInfo = new SharesInfo();
      sharesInfo.setLevel(sharesLevel);
      sharesInfo.setShares(shares);
      return sharesInfo;
   }

   /**
    * Method to connect to the hostd of the connect anchor passed and power on
    * the VM by the name passed.
    *
    * @param connectAnchor ConnectAnchor Object.
    * @param vmName String name of the VM.
    * @return boolean true if successful, false otherwise.
    * @throws Exception, MethodFault
    */
   public static boolean connectToHostdPowerOnVM(final ConnectAnchor connectAnchor,
                                                 final String vmName)
      throws Exception
   {
      boolean rval = false;
      final AuthorizationManager iAuthentication = null;
      ManagedObjectReference sessionMgrMor = null;
      ManagedObjectReference vmMor = null;
      VirtualMachine ivm = null;
      UserSession loginSession = null;
      final boolean checkGuest = DVSTestConstants.CHECK_GUEST;
      final SessionManager sessionManager = new SessionManager(connectAnchor);
      sessionMgrMor = sessionManager.getSessionManager();
      loginSession = sessionManager.login(sessionMgrMor,
               TestConstants.ESX_USERNAME, TestConstants.ESX_PASSWORD, null);
      if (loginSession != null) {
         try {
            ivm = new VirtualMachine(connectAnchor);
            vmMor = ivm.getVMByName(vmName, null);
            if (vmMor != null) {
               rval = ivm.setVMState(vmMor,
                        VirtualMachinePowerState.POWERED_ON, checkGuest);
               if (rval) {
                  log.info("Successfully able to power on the VM " + vmName);
                  if (checkGuest) {
                     ivm.getIPAddress(vmMor);
                  }
               } else {
                  log.warn("Can not power on the VM from hostd " + vmName);
               }
            } else {
               log.warn("Can not find the VM on the host");
            }
         } finally {
            if (new SessionManager(connectAnchor).logout(sessionMgrMor)) {
               log.info("Hostd Logout Succeded");
               rval &= true;
            } else {
               log.warn("Logout failed");
               rval &= false;
            }
         }
      } else {
         log.warn("Can not login into hostd");
      }
      return rval;
   }

   /**
    * Utility method to retrieve all the virtual ethernet cards on the VM.
    *
    * @param vmMor ManagedObjectReference
    * @param connectAnchor ConnectAnchor
    * @return List<VirtualDeviceConfigSpec> of all the ethernet cards on the
    * @throws MethodFault, Exception
    */
   public static List<VirtualDeviceConfigSpec> getAllVirtualEthernetCardDevices(final ManagedObjectReference vmMor,
                                                                                final ConnectAnchor connectAnchor)
      throws Exception
   {
      final VirtualMachine ivm = new VirtualMachine(connectAnchor);
      final List<VirtualDeviceConfigSpec> vdConfigSpec = new ArrayList<VirtualDeviceConfigSpec>();
      List<VirtualDeviceConfigSpec> deviceSpecs = null;
      List<VirtualDeviceConfigSpec> deviceSpec = null;
      if (vmMor != null && ivm.getVMConfigSpec(vmMor) != null) {
         deviceSpecs = TestUtil.arrayToVector(com.vmware.vcqa.util.TestUtil.vectorToArray(
                  ivm.getVMConfigSpec(vmMor).getDeviceChange(),
                  com.vmware.vc.VirtualDeviceConfigSpec.class));
      }
      for (final String deviceType : allEthernetCardTypes) {
         deviceSpec = VMSpecManager.findDevices(deviceSpecs, deviceType);
         if (deviceSpec != null) {
            vdConfigSpec.addAll(deviceSpec);
         }
      }
      return vdConfigSpec;
   }

   /**
    * Create a VM config spec for adding a new VM.
    *
    * @param connectAnchor ConnectAnchor
    * @param connection DistributedVirtualSwitchPortConnection
    * @param deviceType type of the VirtualEthernetCard to use.
    * @param vmName String
    * @param hostMor The MOR of the host where the VM has to be created.
    * @return VirtualMachineConfigSpec.
    * @throws MethodFault, Exception
    */
   public static VirtualMachineConfigSpec buildCreateVMCfg(final ConnectAnchor connectAnchor,
                                                           final DistributedVirtualSwitchPortConnection connection,
                                                           final String deviceType,
                                                           final String vmName,
                                                           final ManagedObjectReference hostMor)
      throws Exception
   {
      log.info("Given device type: " + deviceType);
      VirtualDeviceConnectInfo connectInfo = null;
      VirtualMachineConfigSpec vmConfigSpec = null;
      HashMap deviceSpecMap = null;
      Iterator deviceSpecItr = null;
      VirtualDeviceConfigSpec deviceSpec = null;
      VirtualEthernetCard ethernetCard = null;
      final VirtualMachine ivm = new VirtualMachine(connectAnchor);
      VirtualEthernetCardDistributedVirtualPortBackingInfo dvPortBacking;
      // create the VMCfg with the default devices.
      vmConfigSpec = buildDefaultSpec(connectAnchor, hostMor, deviceType,
               vmName);
      // now change the backing for the ethernet card.
      deviceSpecMap = ivm.getVirtualDeviceSpec(vmConfigSpec, deviceType);
      deviceSpecItr = deviceSpecMap.values().iterator();
      if (deviceSpecItr.hasNext()) {
         deviceSpec = (VirtualDeviceConfigSpec) deviceSpecItr.next();
         if (deviceSpec != null && deviceSpec.getDevice() != null
                  && deviceSpec.getDevice() instanceof VirtualEthernetCard) {
            ethernetCard = VirtualEthernetCard.class.cast(deviceSpec.getDevice());
            log.info("Got the ethernet card: " + ethernetCard);
            // create a DVS backing to set the backing for given device.
            dvPortBacking = new VirtualEthernetCardDistributedVirtualPortBackingInfo();
            dvPortBacking.setPort(connection);
            ethernetCard.setBacking(dvPortBacking);
            connectInfo = new VirtualDeviceConnectInfo();
            connectInfo.setAllowGuestControl(false);
            connectInfo.setConnected(true);
            connectInfo.setStartConnected(true);
            ethernetCard.setConnectable(connectInfo);
         }
      } else {
         log.error("Unable to find the given device type:" + deviceType);
      }
      return vmConfigSpec;
   }

   /**
    * Create a default VMConfigSpec.
    *
    * @param connectAnchor ConnectAnchor
    * @param hostMor The MOR of the host where the defaultVMSpec has to be
    *           created.
    * @param deviceType type of the device.
    * @param vmName String
    * @return vmConfigSpec VirtualMachineConfigSpec.
    * @throws MethodFault, Exception
    */
   public static VirtualMachineConfigSpec buildDefaultSpec(final ConnectAnchor connectAnchor,
                                                           final ManagedObjectReference hostMor,
                                                           final String deviceType,
                                                           final String vmName)
      throws Exception
   {
      ManagedObjectReference poolMor = null;
      VirtualMachineConfigSpec vmConfigSpec = null;
      final HostSystem ihs = new HostSystem(connectAnchor);
      final VirtualMachine ivm = new VirtualMachine(connectAnchor);
      final Vector<String> deviceTypesVector = new Vector<String>();
      poolMor = ihs.getPoolMor(hostMor);
      if (poolMor != null) {
         deviceTypesVector.add(TestConstants.VM_VIRTUALDEVICE_DISK);
         deviceTypesVector.add(VM_VIRTUALDEVICE_SCSI_BUSL_CONTROLLER);
         deviceTypesVector.add(deviceType);
         // create the VMCfg with the default devices.
         vmConfigSpec = ivm.createVMConfigSpec(poolMor, vmName,
                  VM_DEFAULT_GUEST_WINDOWS, deviceTypesVector, null);
      } else {
         log.error("Unable to get the resource pool from the host.");
      }
      return vmConfigSpec;
   }

   /**
    * Returns the Map with the DVS port key and the DVS port object
    *
    * @param connectAnchor ConnectAnchor
    * @param dvsMor ManagedObjectReference
    * @param portKeys String[] of the DVS portkeys.
    * @return Map<String, DistributedVirtualPort> object.
    * @throws MethodFault, Exception
    */
   public static Map<String, DistributedVirtualPort> getPortMap(final ConnectAnchor connectAnchor,
                                                                final ManagedObjectReference dvsMor,
                                                                final String[] portKeys)
      throws Exception
   {
      Map<String, DistributedVirtualPort> portMap = null;
      DistributedVirtualSwitchPortCriteria portCriteria = null;
      List<DistributedVirtualPort> ports = null;
      final DistributedVirtualSwitch iDVS = new DistributedVirtualSwitch(
               connectAnchor);
      /*
       * Adding sleep as per PR#616149
       */
      DVSUtil.WaitForIpaddress();
      if (iDVS.refreshPortState(dvsMor, portKeys)) {
         log.info("Successfully refreshed the port state");
         portCriteria = iDVS.getPortCriteria(null, null, null, null, portKeys,
                  null);
         ports = iDVS.fetchPorts(dvsMor, portCriteria);
         if (ports != null && ports.size() > 0) {
            for (final DistributedVirtualPort port : ports) {
               if (port != null) {
                  if (portMap == null) {
                     portMap = new HashMap<String, DistributedVirtualPort>();
                  }
                  portMap.put(port.getKey(), port);
               }
            }
         }
      } else {
         log.error("Can not refresh the port state");
      }
      return portMap;
   }

   /**
    * Configures the VM with two ethernet adapters if the VM does not have two
    * of them and then configures the VM's first ethernet adapter to connect to
    * the port connection object passed.
    *
    * @param connectAnchor ConnectAnchor
    * @param vmMor ManagedObjectReference
    * @param hostMor ManagedObjectReference
    * @param portConnection DistributedVirtualSwitchPortConnection
    * @return VirtualMachineConfigSpec the config spec to restore the original
    *         config spec of the VM.
    * @throws MethodFault, Exception
    */
   public static VirtualMachineConfigSpec configureVM(final ConnectAnchor connectAnchor,
                                                      final ManagedObjectReference vmMor,
                                                      final ManagedObjectReference hostMor,
                                                      final DistributedVirtualSwitchPortConnection portConnection)
      throws Exception
   {
      int ethCardsNeeded = 0;
      VirtualEthernetCard ethernetCard = null;
      VirtualEthernetCard ethernetCard2 = null;
      List<VirtualDeviceConfigSpec> originalVDConfigSpec = null;
      List<VirtualDeviceConfigSpec> updatedVDConfigSpec = null;
      List<VirtualDeviceConfigSpec> vdConfigSpec = null;
      final VirtualMachine ivm = new VirtualMachine(connectAnchor);
      final HostSystem ihs = new HostSystem(connectAnchor);
      final VMSpecManager vmSpecManager = ivm.getVMSpecManager(
               ihs.getResourcePool(hostMor).get(0), hostMor);
      VirtualMachineConfigSpec vmConfigSpec = null;
      VirtualDeviceConfigSpec ethernetCardSpec = null;
      List<VirtualDeviceConfigSpec> newVDConfigSpec = null;
      VirtualMachineConfigSpec[] updatedVMConfigSpec = null;
      originalVDConfigSpec = DVSUtil.getAllVirtualEthernetCardDevices(vmMor,
               connectAnchor);
      if (originalVDConfigSpec == null || originalVDConfigSpec.size() == 0) {
         ethCardsNeeded = 2;
      } else if (originalVDConfigSpec.size() < 2) {
         ethCardsNeeded = 2 - originalVDConfigSpec.size();
      }
      if (ethCardsNeeded > 0) {
         vmConfigSpec = new VirtualMachineConfigSpec();
         vdConfigSpec = new ArrayList<VirtualDeviceConfigSpec>(2);
         for (int i = 0; i < ethCardsNeeded; i++) {
            ethernetCardSpec = vmSpecManager.createEthCardSpec(vdConfigSpec,
                     VirtualPCNet32.class, null, null);
            vdConfigSpec.add(ethernetCardSpec);
         }
         vmConfigSpec.getDeviceChange().clear();
         vmConfigSpec.getDeviceChange().addAll(
                  com.vmware.vcqa.util.TestUtil.arrayToVector(vdConfigSpec.toArray(new VirtualDeviceConfigSpec[vdConfigSpec.size()])));
      }
      if (vmConfigSpec != null) {
         if (ivm.reconfigVM(vmMor, vmConfigSpec)) {
            log.info("Successfully reconfigured the VM to have "
                     + "the required number of ethernet adapters");
            updatedVDConfigSpec = DVSUtil.getAllVirtualEthernetCardDevices(
                     vmMor, connectAnchor);
            if (originalVDConfigSpec != null && originalVDConfigSpec.size() > 0) {
               final Iterator<VirtualDeviceConfigSpec> it = updatedVDConfigSpec.iterator();
               final Iterator<VirtualDeviceConfigSpec> it1 = originalVDConfigSpec.iterator();
               while (it.hasNext()) {
                  final VirtualDeviceConfigSpec configSpec1 = it.next();
                  if (configSpec1.getDevice() != null
                           && configSpec1.getDevice() instanceof VirtualEthernetCard) {
                     ethernetCard = (VirtualEthernetCard) configSpec1.getDevice();
                     while (it1.hasNext()) {
                        final VirtualDeviceConfigSpec configSpec2 = it1.next();
                        if (configSpec2.getDevice() != null
                                 && configSpec2.getDevice() instanceof VirtualEthernetCard) {
                           ethernetCard2 = (VirtualEthernetCard) configSpec2.getDevice();
                           if (ethernetCard.getMacAddress().equals(
                                    ethernetCard2.getMacAddress())) {
                              it.remove();
                              break;
                           }
                        }
                     }
                  }
               }
            }
         } else {
            log.error("Can not reconfigure the VM to have the "
                     + "required number of ethernet adapters");
         }
      }
      updatedVMConfigSpec = DVSUtil.getVMConfigSpecForDVSPort(vmMor,
               connectAnchor,
               new DistributedVirtualSwitchPortConnection[] { portConnection });
      if (updatedVMConfigSpec != null && updatedVMConfigSpec.length == 2
               && updatedVMConfigSpec[0] != null
               && updatedVMConfigSpec[1] != null) {
         log.info("Successfully obtained the original and the updated"
                  + " VM config spec");
         if (ivm.reconfigVM(vmMor, updatedVMConfigSpec[0])) {
            log.info("Successfully reconfigured the VM to connect to "
                     + "the DVS");
            if (updatedVDConfigSpec != null
                     && updatedVDConfigSpec.size() > 0
                     && com.vmware.vcqa.util.TestUtil.vectorToArray(
                              updatedVMConfigSpec[1].getDeviceChange(),
                              com.vmware.vc.VirtualDeviceConfigSpec.class) != null
                     && com.vmware.vcqa.util.TestUtil.vectorToArray(
                              updatedVMConfigSpec[1].getDeviceChange(),
                              com.vmware.vc.VirtualDeviceConfigSpec.class).length > 0) {
               final Iterator<VirtualDeviceConfigSpec> it = updatedVDConfigSpec.iterator();
               while (it.hasNext()) {
                  VirtualDeviceConfigSpec configSpec1 = null;
                  configSpec1 = it.next();
                  if (configSpec1 != null
                           && configSpec1.getDevice() != null
                           && configSpec1.getDevice() instanceof VirtualEthernetCard) {
                     ethernetCard = (VirtualEthernetCard) configSpec1.getDevice();
                     boolean matchFound = false;
                     for (final VirtualDeviceConfigSpec ethCardSpec : com.vmware.vcqa.util.TestUtil.vectorToArray(
                              updatedVMConfigSpec[1].getDeviceChange(),
                              com.vmware.vc.VirtualDeviceConfigSpec.class)) {
                        if (ethCardSpec != null
                                 && ethCardSpec.getDevice() != null
                                 && ethCardSpec.getDevice() instanceof VirtualEthernetCard) {
                           ethernetCard2 = (VirtualEthernetCard) ethCardSpec.getDevice();
                           if (ethernetCard2.getMacAddress().equals(
                                    ethernetCard.getMacAddress())) {
                              matchFound = true;
                              ethCardSpec.setOperation(VirtualDeviceConfigSpecOperation.REMOVE);
                              break;
                           }
                        }
                     }
                     if (!matchFound) {
                        if (newVDConfigSpec == null) {
                           newVDConfigSpec = new ArrayList<VirtualDeviceConfigSpec>();
                        }
                        configSpec1.setOperation(VirtualDeviceConfigSpecOperation.REMOVE);
                        newVDConfigSpec.add(configSpec1);
                     }
                  }
               }
               if (newVDConfigSpec != null && newVDConfigSpec.size() > 0) {
                  newVDConfigSpec.addAll(TestUtil.arrayToVector(com.vmware.vcqa.util.TestUtil.vectorToArray(
                           updatedVMConfigSpec[1].getDeviceChange(),
                           com.vmware.vc.VirtualDeviceConfigSpec.class)));
                  updatedVMConfigSpec[1].getDeviceChange().clear();
                  updatedVMConfigSpec[1].getDeviceChange().addAll(
                           com.vmware.vcqa.util.TestUtil.arrayToVector(newVDConfigSpec.toArray(new VirtualDeviceConfigSpec[newVDConfigSpec.size()])));
               }
            }
         } else {
            log.error("Can not reconfigure the VM to connect to " + "the DVS");
         }
      }
      if (updatedVMConfigSpec != null && updatedVMConfigSpec.length == 2) {
         return updatedVMConfigSpec[1];
      } else {
         return null;
      }
   }

   /**
    * This method extracts the maximum number of ports on the host via a
    * "net-dvs -l" call
    *
    * @param hostMor
    * @param connectAnchor
    * @return int Number of default max ports on the dvs -1, if the data is not
    *         available via net-dvs -l
    * @throws Exception
    */
   public static int getMaxProxyPortsFromHost(ManagedObjectReference hostMor,
                                              ConnectAnchor connectAnchor)
      throws Exception
   {
      boolean result = false;
      int count = 0;
      int j = -1;
      assertNotNull(connectAnchor, "The connect anchor was null");
      assertNotNull(hostMor, "The host mor was null");
      HostSystem ihs = new HostSystem(connectAnchor);
      DistributedVirtualSwitch idvs = new DistributedVirtualSwitch(
               connectAnchor);
      DistributedVirtualPortgroup idpg = new DistributedVirtualPortgroup(
               connectAnchor);
      Connection conn = SSHUtil.getSSHConnection(ihs.getHostName(hostMor),
               TestConstants.ESX_USERNAME, TestConstants.ESX_PASSWORD);
      assertNotNull(
               conn,
               "Could not obtain a ssh connection to host : "
                        + ihs.getHostName(hostMor));
      assertNotNull(connectAnchor, "The connect anchor was null");
      Map<String, String> map = SSHUtil.getRemoteSSHCmdOutput(conn,
               DVSTestConstants.NET_DVS_LIST_COMMAND);
      String output = map.get(TestConstants.SSH_OUTPUT_STREAM);
      // check if netiorm is enabled on the dvs
      List<String> outputList = TestUtil.tokenizeString(output, "\n");

      for (int i = 0; i < outputList.size(); i++) {
         String line = outputList.get(i);
         // log.info("The line content : " + line );
         if (line.contains("max ports:")) {
            String[] str = line.split(":");
            String num = str[1].trim();
            j = Integer.valueOf(num);
            break;
         }
      }
      return j;
   }

   /**
    * Returns the MAC address of the first ethernet adapter passed.
    *
    * @param configSpec VirtualMachineConfigSpec object.
    * @return String, the mac address of the first VM ethernet adapter.
    */
   public static String getMac(final VirtualMachineConfigSpec configSpec)
   {
      String macAddress = null;
      final VirtualDeviceConfigSpec[] devChanges = com.vmware.vcqa.util.TestUtil.vectorToArray(
               configSpec.getDeviceChange(),
               com.vmware.vc.VirtualDeviceConfigSpec.class);
      if (devChanges != null && devChanges.length >= 1) {
         final VirtualDeviceConfigSpec devChange = devChanges[0];
         final VirtualDevice vd = devChange.getDevice();
         if (VirtualEthernetCard.class.isInstance(vd)) {
            final VirtualEthernetCard vEthCard = VirtualEthernetCard.class.cast(vd);
            vEthCard.getBacking();
            macAddress = vEthCard.getMacAddress();
         } else {
            log.error("the VirtualDevice is not a ethernet card.");
         }
      } else {
         log.error("Device change is null or of invalid length");
      }
      return macAddress;
   }

   /**
    * Returns the BoolPolicy Object.
    *
    * @param inherited, true if the value is inherited, false otherwise
    * @param value Boolean value
    * @return BoolPolicy
    */
   public static BoolPolicy getBoolPolicy(final boolean inherited,
                                          final Boolean value)
   {
      final BoolPolicy boolPolicy = new BoolPolicy();
      boolPolicy.setInherited(inherited);
      boolPolicy.setValue(value);
      return boolPolicy;
   }

   /**
    * Returns the LongPolicy Object.
    *
    * @param inherited, true if the value is inherited, false otherwise
    * @param value Long value
    * @return LongPolicy
    */
   public static LongPolicy getLongPolicy(final boolean inherited,
                                          final Long value)
   {
      final LongPolicy longPolicy = new LongPolicy();
      longPolicy.setInherited(inherited);
      longPolicy.setValue(value);
      return longPolicy;
   }

   /**
    * Returns the StringPolicy Object.
    *
    * @param inherited, true if the value is inherited, false otherwise
    * @param value String value
    * @return StringPolicy
    */
   public static StringPolicy getStringPolicy(final boolean inherited,
                                              final String value)
   {
      final StringPolicy stringPolicy = new StringPolicy();
      stringPolicy.setInherited(inherited);
      stringPolicy.setValue(value);
      return stringPolicy;
   }

   /**
    * Returns the IntPolicy Object.
    *
    * @param inherited, true if the value is inherited, false otherwise
    * @param value Int value
    * @return IntPolicy
    */
   public static IntPolicy getIntPolicy(final boolean inherited,
                                        final Integer value)
   {
      final IntPolicy intPolicy = new IntPolicy();
      intPolicy.setInherited(inherited);
      intPolicy.setValue(value);
      return intPolicy;
   }

   /**
    * Returns the DVSTrafficShapingPolicy Object.
    *
    * @param inherited true if the value is inherited, false otherwise.
    * @param enabled boolean
    * @param averageBandwidth Long
    * @param peakBandwidth Long
    * @param burstSize Long
    * @return DVSTrafficShapingPolicy Object
    */
   public static DVSTrafficShapingPolicy getTrafficShapingPolicy(final boolean inherited,
                                                                 final Boolean enabled,
                                                                 final Long averageBandwidth,
                                                                 final Long peakBandwidth,
                                                                 final Long burstSize)
   {
      final DVSTrafficShapingPolicy trafficShapingPolicy = new DVSTrafficShapingPolicy();
      trafficShapingPolicy.setInherited(inherited);
      trafficShapingPolicy.setEnabled(getBoolPolicy(enabled == null ? true
               : false, enabled));
      trafficShapingPolicy.setAverageBandwidth(getLongPolicy(
               (averageBandwidth == null) ? true : false, averageBandwidth));
      trafficShapingPolicy.setPeakBandwidth(getLongPolicy(
               peakBandwidth == null ? true : false, peakBandwidth));
      trafficShapingPolicy.setBurstSize(getLongPolicy(burstSize == null ? true
               : false, burstSize));
      return trafficShapingPolicy;
   }

   /**
    * Returns the failure criteria based on the values passed.
    *
    * @param inherited true if the value is inherited, false otherwise.
    * @param checkSpeed String object.
    * @param speed Integer object.
    * @param checkDuplex Boolean object.
    * @param fullDuplex Boolean object.
    * @param checkErrorPercent Boolean object.
    * @param percentage Integer object.
    * @param checkBeacon Boolean object.
    * @return DVSFailureCriteria object
    */
   public static DVSFailureCriteria getFailureCriteria(final boolean inherited,
                                                       final String checkSpeed,
                                                       final Integer speed,
                                                       final Boolean checkDuplex,
                                                       final Boolean fullDuplex,
                                                       final Boolean checkErrorPercent,
                                                       final Integer percentage,
                                                       final Boolean checkBeacon)
   {
      final DVSFailureCriteria failureCriteria = new DVSFailureCriteria();
      failureCriteria.setInherited(inherited);
      failureCriteria.setCheckBeacon(getBoolPolicy(checkBeacon == null ? true
               : false, checkBeacon));
      failureCriteria.setCheckDuplex(getBoolPolicy(checkDuplex == null ? true
               : false, checkDuplex));
      failureCriteria.setCheckErrorPercent(getBoolPolicy(
               checkErrorPercent == null ? true : false, checkErrorPercent));
      failureCriteria.setCheckSpeed(getStringPolicy(checkSpeed == null ? true
               : false, checkSpeed));
      failureCriteria.setFullDuplex(getBoolPolicy(fullDuplex == null ? true
               : false, fullDuplex));
      failureCriteria.setPercentage(getIntPolicy(percentage == null ? true
               : false, percentage));
      failureCriteria.setSpeed(getIntPolicy(speed == null ? true : false, speed));
      return failureCriteria;
   }

   /**
    * This method returns a list of free port keys on the vds whose size depends
    * upon the numKeys parameter passed
    *
    * @param vdsMor
    * @param numKeys
    * @return List<String>
    * @throws Exception
    */
   public static List<String> getFreePortKeys(ManagedObjectReference vdsMor,
                                              int numKeys,
                                              ConnectAnchor connectAnchor)
      throws Exception
   {
      DistributedVirtualSwitch vds = new DistributedVirtualSwitch(connectAnchor);
      ArrayList<String> ports = new ArrayList<String>();
      HashMap<String, List<String>> excludedPorts = new HashMap<String, List<String>>();
      ArrayList<String> listExcludedPorts = new ArrayList<String>();
      for (int i = 0; i < numKeys; i++) {
         String portKey = vds.getFreeStandaloneDVPortKey(vdsMor, excludedPorts);
         if (portKey != null) {
            ports.add(portKey);
            listExcludedPorts.add(portKey);
            excludedPorts.put(null, listExcludedPorts);
         }
      }
      return ports;
   }

   /**
    * Returns the DVSSecurityPolicy Object.
    *
    * @param inherited boolean true if inherited, false otherwise.
    * @param allowPromiscuous Boolean object.
    * @param macChanges Boolean object.
    * @param forgedTransmits Boolean object.
    * @return DVSSecurityPolicy object.
    */
   public static DVSSecurityPolicy getDVSSecurityPolicy(final boolean inherited,
                                                        final Boolean allowPromiscuous,
                                                        final Boolean macChanges,
                                                        final Boolean forgedTransmits)
   {
      final DVSSecurityPolicy securityPolicy = new DVSSecurityPolicy();
      securityPolicy.setAllowPromiscuous(getBoolPolicy(
               allowPromiscuous == null ? true : false, allowPromiscuous));
      securityPolicy.setForgedTransmits(getBoolPolicy(
               forgedTransmits == null ? true : false, forgedTransmits));
      securityPolicy.setMacChanges(getBoolPolicy(macChanges == null ? true
               : false, macChanges));
      securityPolicy.setInherited(inherited);
      return securityPolicy;
   }

   /**
    * Returns the VMwareUplinkPortOrderPolicy object.
    *
    * @param inherited boolean true if the value is inherited, false otherwise.
    * @param activeUplinkPort String[] object.
    * @param standbyUplinkPort String[] object.
    * @return VMwareUplinkPortOrderPolicy object.
    */
   public static VMwareUplinkPortOrderPolicy getPortOrderPolicy(final boolean inherited,
                                                                final String[] activeUplinkPort,
                                                                final String[] standbyUplinkPort)
   {
      final VMwareUplinkPortOrderPolicy portOrderPolicy = new VMwareUplinkPortOrderPolicy();
      portOrderPolicy.setInherited(inherited);
      portOrderPolicy.getActiveUplinkPort().clear();
      portOrderPolicy.getActiveUplinkPort().addAll(
               com.vmware.vcqa.util.TestUtil.arrayToVector(activeUplinkPort));
      portOrderPolicy.getStandbyUplinkPort().clear();
      portOrderPolicy.getStandbyUplinkPort().addAll(
               com.vmware.vcqa.util.TestUtil.arrayToVector(standbyUplinkPort));
      return portOrderPolicy;
   }

   /**
    * Returns the VmwareUplinkPortTeamingPolicy object.
    *
    * @param inherited boolean true if the value is inherited, false otherwise.
    * @param policy
    * @param reversePolicy Boolean object.
    * @param notifySwitches Boolean object.
    * @param rollingOrder Boolean object.
    * @param failureCriteria DVSFailureCriteria object.
    * @param uplinkPortOrder VMwareUplinkPortOrderPolicy object.
    * @return VmwareUplinkPortTeamingPolicy object.
    */
   public static VmwareUplinkPortTeamingPolicy getUplinkPortTeamingPolicy(final boolean inherited,
                                                                          final String policy,
                                                                          final Boolean reversePolicy,
                                                                          final Boolean notifySwitches,
                                                                          final Boolean rollingOrder,
                                                                          final DVSFailureCriteria failureCriteria,
                                                                          final VMwareUplinkPortOrderPolicy uplinkPortOrder)
   {
      final VmwareUplinkPortTeamingPolicy portTeamingPolicy = new VmwareUplinkPortTeamingPolicy();
      portTeamingPolicy.setFailureCriteria(failureCriteria == null ? getFailureCriteria(
               true, null, null, null, null, null, null, null)
               : failureCriteria);
      portTeamingPolicy.setInherited(inherited);
      portTeamingPolicy.setNotifySwitches(getBoolPolicy(
               notifySwitches == null ? true : false, notifySwitches));
      portTeamingPolicy.setPolicy(getStringPolicy(
               policy == null ? true : false, policy));
      portTeamingPolicy.setReversePolicy(getBoolPolicy(
               reversePolicy == null ? true : false, reversePolicy));
      portTeamingPolicy.setRollingOrder(getBoolPolicy(
               rollingOrder == null ? true : false, rollingOrder));
      portTeamingPolicy.setUplinkPortOrder(uplinkPortOrder == null ? getPortOrderPolicy(
               true, null, null) : uplinkPortOrder);
      return portTeamingPolicy;
   }

   /**
    * Method that sets the inherited property to true if the value passed is
    * null, false otherwise.
    *
    * @param vendorSpecificConfig DVSVendorSpecificConfig object.
    * @return DVSVendorSpecificConfig object.
    */
   public static DVSVendorSpecificConfig getVendorSpecificConfig(DVSVendorSpecificConfig vendorSpecificConfig)
   {
      if (vendorSpecificConfig == null) {
         vendorSpecificConfig = new DVSVendorSpecificConfig();
         vendorSpecificConfig.setInherited(true);
      } else {
         vendorSpecificConfig.setInherited(false);
      }
      return vendorSpecificConfig;
   }

   /**
    * Returns the vlan spec object setting the inherited value to true if the
    * value passed is null, false otherwise.
    *
    * @param vlanSpec VmwareDistributedVirtualSwitchVlanSpec object.
    * @return VmwareDistributedVirtualSwitchVlanSpec
    */
   public static VmwareDistributedVirtualSwitchVlanSpec getVmwareDistributedVirtualSwitchVlanSpec(VmwareDistributedVirtualSwitchVlanSpec vlanSpec)
   {
      if (vlanSpec == null) {
         vlanSpec = new VmwareDistributedVirtualSwitchVlanSpec();
         vlanSpec.setInherited(true);
      } else {
         vlanSpec.setInherited(false);
      }
      return vlanSpec;
   }

   /**
    * Returns DVPortSetting Object.
    *
    * @param settingsMap Map<String, Object>
    * @param portSetting DVPortSetting object.
    * @return DVPortSetting object.
    */
   public static DVPortSetting getDefaultPortSetting(Map<String, Object> settingsMap,
                                                     DVPortSetting portSetting)
   {
      if (portSetting == null) {
         portSetting = new DVPortSetting();
      }
      if (settingsMap == null) {
         settingsMap = new HashMap<String, Object>();
      }
      portSetting.setBlocked(getBoolPolicy(
               settingsMap.get(BLOCKED_KEY) == null ? true : false,
               (Boolean) settingsMap.get(BLOCKED_KEY)));
      portSetting.setInShapingPolicy(settingsMap.get(INSHAPING_POLICY_KEY) == null ? getTrafficShapingPolicy(
               true, null, null, null, null)
               : (DVSTrafficShapingPolicy) settingsMap.get(INSHAPING_POLICY_KEY));
      portSetting.setOutShapingPolicy(settingsMap.get(OUT_SHAPING_POLICY_KEY) == null ? getTrafficShapingPolicy(
               true, null, null, null, null)
               : (DVSTrafficShapingPolicy) settingsMap.get(OUT_SHAPING_POLICY_KEY));
      portSetting.setVendorSpecificConfig(settingsMap.get(VENDOR_SPECIFIC_CONFIG_KEY) == null ? getVendorSpecificConfig(null)
               : (DVSVendorSpecificConfig) settingsMap.get(VENDOR_SPECIFIC_CONFIG_KEY));
      return portSetting;
   }

   /**
    * Returns the VMwareDVSPortSetting object.
    *
    * @param settingsMap Map<String, Object> object.
    * @return
    */
   public static VMwareDVSPortSetting getDefaultVMwareDVSPortSetting(Map<String, Object> settingsMap)
   {
      VMwareDVSPortSetting portSetting = null;
      portSetting = new VMwareDVSPortSetting();
      if (settingsMap == null) {
         settingsMap = new HashMap<String, Object>();
      }
      portSetting = (VMwareDVSPortSetting) getDefaultPortSetting(settingsMap,
               portSetting);
      portSetting.setQosTag(getIntPolicy(
               settingsMap.get(QOS_TAG_KEY) == null ? true : false,
               (Integer) settingsMap.get(QOS_TAG_KEY)));
      portSetting.setSecurityPolicy(settingsMap.get(SECURITY_POLICY_KEY) == null ? getDVSSecurityPolicy(
               true, null, null, null)
               : (DVSSecurityPolicy) settingsMap.get(SECURITY_POLICY_KEY));
      portSetting.setTxUplink(getBoolPolicy(
               settingsMap.get(TX_UPLINK_KEY) == null ? true : false,
               (Boolean) settingsMap.get(TX_UPLINK_KEY)));
      portSetting.setVlan(getVmwareDistributedVirtualSwitchVlanSpec((VmwareDistributedVirtualSwitchVlanSpec) settingsMap.get(VLAN_KEY)));
      portSetting.setUplinkTeamingPolicy(settingsMap.get(UPLINK_TEAMING_POLICY_KEY) == null ? getUplinkPortTeamingPolicy(
               true, null, null, null, null, null, null)
               : (VmwareUplinkPortTeamingPolicy) settingsMap.get(UPLINK_TEAMING_POLICY_KEY));
      if (settingsMap.containsKey(DVSTestConstants.IP_FIX_ENABLED_KEY)) {
         portSetting.setIpfixEnabled((BoolPolicy) settingsMap.get(DVSTestConstants.IP_FIX_ENABLED_KEY));
      }
      return portSetting;
   }

   /**
    * Returns the effective port setting computed. This method takes the port
    * setting in the heirarchial order as in the DVS, i.e., the dv port setting,
    * the dv port group setting if applicable and the dvs port setting.
    *
    * @param portSettingArray
    * @return
    * @throws MethodFault, Exception
    */
   public static DVPortSetting computeEffectivePortSetting(final DVPortSetting[] portSettingArray)
      throws Exception
   {
      DVPortSetting effectivePortSetting = null;
      DVPortSetting portSetting = null;
      if (portSettingArray == null || portSettingArray.length == 0) {
         log.warn("Can not compute the port setting array is " + "null");
      } else if (portSettingArray.length == 1) {
         portSetting = portSettingArray[0];
      } else if (portSettingArray.length == 2) {
         effectivePortSetting = portSettingArray[0];
         portSetting = portSettingArray[1];
         if (effectivePortSetting == null && portSetting != null) {
            setInheritableFalse(portSetting);
            effectivePortSetting = portSetting;
         } else if (effectivePortSetting != null && portSetting == null) {
            setInheritableFalse(effectivePortSetting);
         } else {
            setInheritableFalse(portSetting);
            setInheritableFalse(effectivePortSetting);
            deepMergeSetting(portSetting, effectivePortSetting);
            effectivePortSetting = portSetting;
         }
      } else {
         computeEffectivePortSetting(TestUtil.arrayToVector(portSettingArray).subList(
                  1, portSettingArray.length).toArray(
                  new DVPortSetting[portSettingArray.length - 1]));
      }
      return effectivePortSetting;
   }

   /**
    * private method to set the inheritable value to false in the .
    *
    * @param object
    * @throws Exception, MethodFault
    */
   private static void setInheritableFalse(final Object object)
      throws Exception
   {
      HashMap<String, Method> methodsMap = null;
      Set<String> methodNames = null;
      InheritablePolicy policy = null;
      Object childObject = null;
      methodsMap = TestUtil.findMethods(object, true, false, false);
      if (methodsMap != null && methodsMap.keySet() != null) {
         methodNames = methodsMap.keySet();
         for (final String methodName : methodNames) {
            childObject = methodsMap.get(methodName).invoke(object,
                     new Object[] {});
            if (childObject != null && childObject instanceof InheritablePolicy) {
               policy = (InheritablePolicy) childObject;
               policy.setInherited(false);
               setInheritableFalse(childObject);
            }
         }
      } else {
         log.warn("There are no methods in the object");
      }
   }

   /**
    * This method returns the DistributedVirtualSwitchProductSpec object
    *
    * @param connectAnchor Reference to the ConnectAnchor object.
    * @param vDsVserion Dot-separated version string
    * @return DistributedVirtualSwitchProductSpec object
    * @throws MethodFault, Exception
    */
   public static DistributedVirtualSwitchProductSpec getProductSpec(final ConnectAnchor connectAnchor,
                                                                    final String vDsVersion)
      throws Exception
   {
      DistributedVirtualSwitchProductSpec productSpec = null;
      DistributedVirtualSwitchManager iDVSManager = null;
      ManagedObjectReference dvsManagerMOR = null;
      if (vDsVersion != null) {
         /*
          * Get the DVS Manager MOR
          */
         iDVSManager = new DistributedVirtualSwitchManager(connectAnchor);
         dvsManagerMOR = iDVSManager.getDvSwitchManager();
         /*
          * Get the list of switch product specifications that are supported by
          * the Virtual Center Server
          */
         final DistributedVirtualSwitchProductSpec[] productSpecList = iDVSManager.queryAvailableSwitchSpec(dvsManagerMOR);
         /*
          * Check for vDs version
          */
         if (productSpecList != null && productSpecList.length > 0) {
            for (final DistributedVirtualSwitchProductSpec spec : productSpecList) {
               if (vDsVersion.equalsIgnoreCase(spec.getVersion())) {
                  productSpec = spec;
                  break;
               }
            }
         }
      }
      return productSpec;
   }

   /**
    * This method creates the productSpec of a DistributedVirtualSwitch
    *
    * @param name Short form of the product name
    * @param vendor Name of the vendor of this product
    * @param version Dot-separated version string
    * @param build Build string for the server .
    * @param forwardingClass Forwarding class of the distributed virtual switch
    * @param bundleId The ID of the bundle if a host component bundle
    * @param bundleUrl The URL of the bundle
    * @return DistributedVirtualSwitchProductSpec object
    * @throws MethodFault, Exception
    */
   public static DistributedVirtualSwitchProductSpec createProductSpec(final String name,
                                                                       final String vendor,
                                                                       final String version,
                                                                       final String build,
                                                                       final String forwardingClass,
                                                                       final String bundleId,
                                                                       final String bundleUrl)
      throws Exception
   {
      final DistributedVirtualSwitchProductSpec productSpec = new DistributedVirtualSwitchProductSpec();
      productSpec.setName(name);
      productSpec.setVendor(vendor);
      productSpec.setVersion(version);
      productSpec.setBuild(build);
      productSpec.setForwardingClass(forwardingClass);
      productSpec.setBundleId(bundleId);
      productSpec.setBundleUrl(bundleUrl);
      return productSpec;
   }

   /**
    * Reconfigure the given VirtualMachine to use the given DVPort key or
    * DVportgroup key of the DVS. If reconfiguration is successful this method
    * will return the originalDeltaCfgSpec which can be use to restore the VM to
    * original configuration.
    *
    * @param vmMor MOR of VM to be reconfigured.
    * @param dvsMor DVS MOR.
    * @param connectAnchor ConnectAnchor
    * @param portKey port key.
    * @param portgroupKey DVPortgroup key.
    * @return VirtualMachineConfigSpec delta VM configSpec.
    */
   public static VirtualMachineConfigSpec reconfigVM(final ManagedObjectReference vmMor,
                                                     final ManagedObjectReference dvsMor,
                                                     final ConnectAnchor connectAnchor,
                                                     final String portKey,
                                                     final String portgroupKey)
      throws Exception
   {
      DVSConfigInfo dvsInfo = null;
      VirtualMachineConfigSpec originalDeltaCfgSpec = null;
      VirtualMachineConfigSpec[] deltaVmConfigSpecs = null;
      DistributedVirtualSwitchPortConnection dvsConn = null;
      final VirtualMachine ivm = new VirtualMachine(connectAnchor);
      final DistributedVirtualSwitch iDVSwitch = new DistributedVirtualSwitch(
               connectAnchor);
      dvsInfo = iDVSwitch.getConfig(dvsMor);
      dvsConn = new DistributedVirtualSwitchPortConnection();
      dvsConn.setPortKey(portKey);
      dvsConn.setPortgroupKey(portgroupKey);
      dvsConn.setSwitchUuid(dvsInfo.getUuid());
      deltaVmConfigSpecs = getVMConfigSpecForDVSPort(vmMor, connectAnchor,
               new DistributedVirtualSwitchPortConnection[] { dvsConn });
      if (deltaVmConfigSpecs != null) {
         log.info("Got the VM config spec");
         if (ivm.reconfigVM(vmMor, deltaVmConfigSpecs[0])) {
            log.info("Successfully reconfigured the VM");
            originalDeltaCfgSpec = deltaVmConfigSpecs[1];
         } else {
            log.error("Failed to reconfigure the VM.");
         }
      }
      return originalDeltaCfgSpec;
   }

   /**
    * This method returns the getUpgradedEvent on DVS
    *
    * @param dvsMOR Reference to the DistributedVirtualSwitch MOR.
    * @param connectAnchor Reference to the ConnectAnchor object
    * @return boolean
    * @throws MethodFault, Exception
    */
   public static boolean getUpgradedEvent(final ManagedObjectReference dvsMOR,
                                          final ConnectAnchor connectAnchor)
      throws Exception
   {
      boolean result = false;
      EventManager iEvent = null;
      ManagedObjectReference eventManagerMor = null;
      EventFilterSpec eventFilterSpec = null;
      ManagedObjectReference historyCollectorMor = null;
      EventFilterSpecByTime filterSpecTime = null;
      EventFilterSpecByEntity eventFilterSpecByEntity = null;
      Vector<Event> events = null;
      if (dvsMOR != null) {
         Thread.sleep(5000);
         iEvent = new EventManager(connectAnchor);
         eventManagerMor = iEvent.getEventManager();
         eventFilterSpec = new EventFilterSpec();
         eventFilterSpecByEntity = new EventFilterSpecByEntity();
         eventFilterSpecByEntity.setEntity(dvsMOR);
         eventFilterSpecByEntity.setRecursion(EventFilterSpecRecursionOption.SELF);
         eventFilterSpec.setEntity(eventFilterSpecByEntity);
         filterSpecTime = new EventFilterSpecByTime();
         filterSpecTime.setBeginTime(TestConstants.DEFAULT_CALENDAR_VALUE);
         eventFilterSpec.setTime(filterSpecTime);
         historyCollectorMor = iEvent.createCollectorForEvents(eventManagerMor,
                  eventFilterSpec);
         events = iEvent.getEvents(historyCollectorMor);
         if (historyCollectorMor != null) {
            if (events != null && events.size() > 0) {
               for (final Event event : events) {
                  if (Class.forName("com.vmware.vc.DvsUpgradedEvent").isInstance(
                           event)) {
                     result = true;
                     log.info("Successfully found DvsUpgradedEvent");
                     break;
                  }
               }
            }
         }
      }
      return result;
   }

   /**
    * This method verifies the vDs version of DVS with given input
    *
    * @param dvsMOR Reference to the DistributedVirtualSwitch MOR.
    * @param connectAnchor Reference to the ConnectAnchor object
    * @param vDsVersion Reference to the vDs version
    * @return true if successful, false otherwise
    * @throws MethodFault, Exception
    */
   public static boolean verifyDVSProductSpec(final ConnectAnchor connectAnchor,
                                              final ManagedObjectReference dvsMOR,
                                              final String vDsVersion)
      throws Exception
   {
      DistributedVirtualSwitchProductSpec productSpec = null;
      String actualvDsVersion = null;
      boolean versionMatched = false;
      if (dvsMOR != null) {
         productSpec = DVSUtil.getProductSpec(dvsMOR, connectAnchor);
         if (productSpec != null && vDsVersion != null) {
            actualvDsVersion = productSpec.getVersion();
            /*
             * Check for vDsVersion
             */
            versionMatched = (vDsVersion.equalsIgnoreCase(actualvDsVersion)) ? true
                     : false;
            if (versionMatched) {
               log.info("DVS's vDs version matches with " + vDsVersion
                        + " version");
            } else {
               log.error("DVS's vDs version does not matches with "
                        + vDsVersion + " version");
            }
         }
      }
      return versionMatched;
   }

   /**
    * This method returns the ProductSpec of an existing DVS MOR Object.
    *
    * @param dvsMOR ManagedObjectReference of the DV Switch.
    * @param connectAnchor Reference to the ConnectAnchor object
    * @return productSpec of the DV Switch MOR passed.
    * @throws MethodFault, Exception
    */
   public static DistributedVirtualSwitchProductSpec getProductSpec(final ManagedObjectReference dvsMOR,
                                                                    final ConnectAnchor connectAnchor)
      throws Exception
   {
      final DistributedVirtualSwitch iDVS = new DistributedVirtualSwitch(
               connectAnchor);
      assertNotNull(dvsMOR, "dvsMOR is not null", "dvsMOR is null");
      final DVSConfigInfo configInfo = iDVS.getConfig(dvsMOR);
      final DistributedVirtualSwitchProductSpec productSpec = (configInfo != null) ? (configInfo.getProductInfo())
               : null;
      return productSpec;
   }

   /**
    * This method returns the Specification of a DistributedVirtualSwitch
    *
    * @param name of DistributedVirtualSwitch
    * @return Specification of a DistributedVirtualSwitch
    * @throws MethodFault, Exception
    */
   public static DVSConfigSpec createDefaultDVSConfigSpec(String name)
      throws Exception
   {
      DVSConfigSpec configSpec = null;
      name = (name != null) ? name
               : TestUtil.getRandomizedTestId(TestUtil.getShortTime());
      configSpec = new DVSConfigSpec();
      configSpec.setConfigVersion("");
      configSpec.setName(name);
      return configSpec;
   }

   /**
    * This method returns the Specification of a DistributedVirtualSwitch
    *
    * @param name of DistributedVirtualSwitch
    * @param hostMors list of hosts to be added to DVS
    * @return Specification of a DistributedVirtualSwitch
    * @throws MethodFault, Exception
    */
   public static DVSConfigSpec createDefaultDVSConfigSpec(String name,
                                                          final List<ManagedObjectReference> hostMors)
      throws Exception
   {
      DVSConfigSpec configSpec = null;
      name = (name != null) ? name : TestUtil.getShortTime();
      configSpec = new DVSConfigSpec();
      configSpec.setConfigVersion("");
      configSpec.setName(name);
      configSpec = addHostsToDVSConfigSpec(configSpec, hostMors);
      return configSpec;
   }

   /**
    * This method returns the Specification of a DistributedVirtualSwitch
    *
    * @param configSpec Specification of a DistributedVirtualSwitch
    * @param hostMors list of hosts to be added to DVS
    * @return Specification of a DistributedVirtualSwitch
    * @throws MethodFault, Exception
    */
   public static DVSConfigSpec addHostsToDVSConfigSpec(final DVSConfigSpec configSpec,
                                                       final List<ManagedObjectReference> hostMors)
      throws Exception
   {
      if (configSpec != null && hostMors != null && hostMors.size() > 0) {
         DistributedVirtualSwitchHostMemberConfigSpec[] hostMemberCfgs = null;
         DistributedVirtualSwitchHostMemberConfigSpec hostMemberCfg = null;
         DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
         hostMemberCfgs = new DistributedVirtualSwitchHostMemberConfigSpec[hostMors.size()];
         for (int i = 0; i < hostMors.size(); i++) {
            pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
            pnicBacking.getPnicSpec().clear();
            pnicBacking.getPnicSpec().addAll(
                     com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] {}));
            hostMemberCfg = new DistributedVirtualSwitchHostMemberConfigSpec();
            hostMemberCfg.setOperation(TestConstants.CONFIG_SPEC_ADD);
            hostMemberCfg.setHost(hostMors.get(i));
            hostMemberCfg.setBacking(pnicBacking);
            hostMemberCfgs[i] = hostMemberCfg;
         }
         configSpec.getHost().clear();
         configSpec.getHost().addAll(
                  com.vmware.vcqa.util.TestUtil.arrayToVector(hostMemberCfgs));
      }
      return configSpec;
   }

   /**
    * This method returns the Specification of a DistributedVirtualSwitch
    *
    * @param configSpec Specification of a DistributedVirtualSwitch
    * @param pNicMap Map of host mors and pnic devices
    * @param dvsName name of the dvs
    * @return Specification of a DistributedVirtualSwitch
    * @throws MethodFault, Exception
    */
   public static DVSConfigSpec addHostsToDVSConfigSpecWithPnic(DVSConfigSpec configSpec,
                                                               final Map<ManagedObjectReference, String> pNicMap,
                                                               String dvsName)
      throws Exception
   {
      if (pNicMap != null && pNicMap.size() > 0) {
         final Vector<DistributedVirtualSwitchHostMemberConfigSpec> backingList = new Vector<DistributedVirtualSwitchHostMemberConfigSpec>();
         if (configSpec == null) {
            configSpec = new DVSConfigSpec();
            configSpec.setConfigVersion("");
            configSpec.setName(dvsName = (dvsName != null) ? dvsName
                     : TestUtil.getShortTime());
            configSpec.setNumStandalonePorts(1);
         }
         final Set hostSet = pNicMap.keySet();
         final Iterator hostItr = hostSet.iterator();
         while (hostItr.hasNext()) {
            final ManagedObjectReference mor = (ManagedObjectReference) hostItr.next();
            final String pnic = pNicMap.get(mor);
            final DistributedVirtualSwitchHostMemberConfigSpec hostMember = new DistributedVirtualSwitchHostMemberConfigSpec();
            hostMember.setOperation(TestConstants.CONFIG_SPEC_ADD);
            hostMember.setHost(mor);
            final DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
            final DistributedVirtualSwitchHostMemberPnicSpec pnicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();
            pnicSpec.setPnicDevice(pnic);
            pnicBacking.getPnicSpec().clear();
            pnicBacking.getPnicSpec().addAll(
                     com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] { pnicSpec }));
            hostMember.setBacking(pnicBacking);
            backingList.add(hostMember);
         }
         configSpec.getHost().clear();
         configSpec.getHost().addAll(
                  com.vmware.vcqa.util.TestUtil.arrayToVector(TestUtil.vectorToArray(backingList)));
      }
      return configSpec;
   }

   /**
    * This method returns the Specification of a DistributedVirtualSwitch
    *
    * @param configSpec Specification of a DistributedVirtualSwitch
    * @param pNicMap Map of host mors and pnic devices
    * @param dvsName name of the dvs
    * @return Specification of a DistributedVirtualSwitch
    * @throws MethodFault, Exception
    */
   public static DVSConfigSpec addHostsToDVSConfigSpecWithMultiplePnic(DVSConfigSpec configSpec,
                                                                       final Map<ManagedObjectReference, List<String>> pNicMap,
                                                                       String dvsName)
      throws Exception
   {
      if (pNicMap != null && pNicMap.size() > 0) {
         final Vector<DistributedVirtualSwitchHostMemberConfigSpec> backingList = new Vector<DistributedVirtualSwitchHostMemberConfigSpec>();
         if (configSpec == null) {
            configSpec = new DVSConfigSpec();
            configSpec.setConfigVersion("");
            configSpec.setName(dvsName = (dvsName != null) ? dvsName
                     : TestUtil.getShortTime());
            configSpec.setNumStandalonePorts(1);
         }
         final Set hostSet = pNicMap.keySet();
         final Iterator hostItr = hostSet.iterator();
         while (hostItr.hasNext()) {
            final ManagedObjectReference mor = (ManagedObjectReference) hostItr.next();
            ArrayList<String> pnicList = (ArrayList<String>) pNicMap.get(mor);
            final DistributedVirtualSwitchHostMemberConfigSpec hostMember = new DistributedVirtualSwitchHostMemberConfigSpec();
            hostMember.setOperation(TestConstants.CONFIG_SPEC_ADD);
            hostMember.setHost(mor);
            final DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
            ArrayList<DistributedVirtualSwitchHostMemberPnicSpec> pnicSpecList = new ArrayList<DistributedVirtualSwitchHostMemberPnicSpec>();
            for (int i = 0; i < pnicList.size(); i++) {
               DistributedVirtualSwitchHostMemberPnicSpec pnicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();
               pnicSpec.setPnicDevice(pnicList.get(i));
               pnicSpecList.add(pnicSpec);
            }
            pnicBacking.getPnicSpec().clear();
            pnicBacking.getPnicSpec().addAll(pnicSpecList);
            hostMember.setBacking(pnicBacking);
            backingList.add(hostMember);
         }
         configSpec.getHost().clear();
         configSpec.getHost().addAll(
                  com.vmware.vcqa.util.TestUtil.arrayToVector(TestUtil.vectorToArray(backingList)));
      }
      return configSpec;
   }

   /**
    * This method returns the Specification of a DistributedVirtualSwitch
    *
    * @param configSpec Specification of a DistributedVirtualSwitch
    * @param hostMors list of hosts to be added to DVS
    * @param connectAnchor Reference to the ConnectAnchor object
    * @return true if successful, false otherwise
    * @throws MethodFault, Exception
    */
   public static boolean addHostsUsingReconfigureDVS(final ManagedObjectReference dvsMOR,
                                                     final List<ManagedObjectReference> hostMors,
                                                     final ConnectAnchor connectAnchor)
      throws Exception
   {
      boolean reconfigured = false;
      if (dvsMOR != null) {
         DVSConfigInfo configInfo = null;
         DVSConfigSpec deltaConfigSpec = null;
         String validConfigVersion = null;
         DistributedVirtualSwitch iDistributedVirtualSwitch = null;
         assertNotNull(connectAnchor,
                  "Reference to the ConnectAnchor object is not null",
                  "Reference to the ConnectAnchor object is null");
         iDistributedVirtualSwitch = new DistributedVirtualSwitch(connectAnchor);
         configInfo = iDistributedVirtualSwitch.getConfig(dvsMOR);
         deltaConfigSpec = addHostsToDVSConfigSpec(new DVSConfigSpec(),
                  hostMors);
         validConfigVersion = configInfo.getConfigVersion();
         deltaConfigSpec.setConfigVersion(validConfigVersion);
         reconfigured = iDistributedVirtualSwitch.reconfigure(dvsMOR,
                  deltaConfigSpec);
         if (reconfigured) {
            log.info("Successfully reconfigured DVS");
         } else {
            log.error("Failed to reconfigure dvs");
         }
      }
      return reconfigured;
   }

   /**
    * This method returns the Specification of a DistributedVirtualSwitch
    *
    * @return Specification to create the Distributed Virtual Switch
    * @throws MethodFault, Exception
    */
   public static DVSCreateSpec createDVSCreateSpec(final DVSConfigSpec configSpec,
                                                   final DistributedVirtualSwitchProductSpec productSpec,
                                                   final DVSCapability capability)
      throws Exception
   {
      final DVSCreateSpec createSpec = new DVSCreateSpec();
      createSpec.setCapability(capability);
      createSpec.setProductInfo(productSpec);
      createSpec.setConfigSpec(configSpec);
      return createSpec;
   }

   /**
    * This method verifies that the port setting of the port set on the vds is
    * propagated to the host and returns true, if propagated, false otherwise
    *
    * @param connectAnchor
    * @param dvsMor
    * @param hostMor
    * @param dvPortSetting
    * @param portKey
    * @return boolean
    * @throws MethodFault,Exception
    */
   public static boolean verifyPortSettingOnHost(final ConnectAnchor connectAnchor,
                                                 final ManagedObjectReference dvsMor,
                                                 ManagedObjectReference hostMor,
                                                 final DVPortSetting dvPortSetting,
                                                 final String portKey)
      throws Exception
   {
      boolean verified = false;
      final DistributedVirtualSwitch iDistributedVirtualSwitch = new DistributedVirtualSwitch(
               connectAnchor);
      final NetworkSystem ins = new NetworkSystem(connectAnchor);
      final HostSystem ihs = new HostSystem(connectAnchor);
      final VirtualMachine ivm = new VirtualMachine(connectAnchor);
      DVSConfigSpec dvsConfigSpec = null;
      DVSConfigInfo dvsConfigInfo = null;
      DistributedVirtualSwitchHostMemberConfigSpec hostMemberConfigSpec = null;
      DistributedVirtualSwitchHostMemberPnicBacking backing = null;
      HostNetworkConfig[] hostNetworkConfig = null;
      VirtualMachineConfigSpec[] vmConfigSpecs = null;
      ManagedObjectReference vmMor = null;
      Vector<ManagedObjectReference> hostVMs = null;
      DistributedVirtualSwitchPortConnection portConnection = null;
      final ConnectAnchor hostConnectAnchor = null;
      final AuthorizationManager iAuthentication = null;
      ManagedObjectReference sessionMgrMor = null;
      UserSession hostLoginSession = null;
      InternalServiceInstance msi = null;
      ManagedObjectReference hostDVSManager = null;
      InternalHostDistributedVirtualSwitchManager iHostDVSManager = null;
      HostDVSPortData[] portData = null;
      final Vector<ManagedObjectReference> allHosts = null;
      VirtualMachineConfigSpec tempVmConfigSpec = null;
      boolean isVMCreated = false;
      try {
         Assert.assertNotNull(dvPortSetting, "The port setting passed is null");
         Assert.assertNotNull(dvsMor, "The DVS mor is null");
         dvsConfigInfo = iDistributedVirtualSwitch.getConfig(dvsMor);
         dvsConfigSpec = new DVSConfigSpec();
         hostMor = allHosts.get(0);
         Assert.assertNotNull(hostMor, "The host mor is null");
         dvsConfigSpec = new DVSConfigSpec();
         dvsConfigSpec.setConfigVersion(dvsConfigInfo.getConfigVersion());
         dvsConfigSpec.setNumStandalonePorts(1);
         hostMemberConfigSpec = new DistributedVirtualSwitchHostMemberConfigSpec();
         backing = new DistributedVirtualSwitchHostMemberPnicBacking();
         backing.getPnicSpec().clear();
         backing.getPnicSpec().addAll(
                  com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] {}));
         hostMemberConfigSpec.setHost(hostMor);
         hostMemberConfigSpec.setOperation(TestConstants.CONFIG_SPEC_ADD);
         hostMemberConfigSpec.setBacking(backing);
         dvsConfigSpec.getHost().clear();
         dvsConfigSpec.getHost().addAll(
                  com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostMemberConfigSpec }));
         Assert.assertTrue(
                  iDistributedVirtualSwitch.reconfigure(dvsMor, dvsConfigSpec),
                  "Successfully added the host to connect to the DVS",
                  "Cannot add the host to the DVS");
         hostNetworkConfig = iDistributedVirtualSwitch.getHostNetworkConfigMigrateToDVS(
                  dvsMor, hostMor);
         if (hostNetworkConfig != null && hostNetworkConfig.length >= 2
                  && hostNetworkConfig[0] != null
                  && hostNetworkConfig[1] != null) {
            log.info("Successfully obtained the network "
                     + "configuration of the host to update to");
            Assert.assertTrue(ins.updateNetworkConfig(
                     ins.getNetworkSystem(hostMor), hostNetworkConfig[0],
                     TestConstants.CHANGEMODE_MODIFY),
                     "Successfully updated the network configuration of "
                              + "the host", "Can not update the network "
                              + "configuration of the host");
            portConnection = iDistributedVirtualSwitch.getPortConnection(
                     dvsMor, null, false, null);
            Assert.assertNotNull(portConnection, "Can not obtain a free "
                     + "port connection object");
            hostVMs = ihs.getVMs(hostMor, null);
            if (hostVMs == null || hostVMs.size() <= 0) {
               tempVmConfigSpec = DVSUtil.buildDefaultSpec(connectAnchor,
                        hostMor,
                        TestConstants.VM_VIRTUALDEVICE_ETHERNET_PCNET32,
                        "TestPortSetting-VM");
               if (tempVmConfigSpec != null) {
                  vmMor = new Folder(connectAnchor).createVM(ivm.getVMFolder(),
                           tempVmConfigSpec,
                           ihs.getResourcePool(hostMor).get(0), hostMor);
                  if (vmMor != null) {
                     isVMCreated = true;
                  }
               }
            } else {
               vmMor = hostVMs.get(0);
            }
            Assert.assertNotNull(vmMor, "The vm mor is null");
            vmConfigSpecs = DVSUtil.getVMConfigSpecForDVSPort(
                     vmMor,
                     connectAnchor,
                     new DistributedVirtualSwitchPortConnection[] { portConnection });
            if (vmConfigSpecs != null && vmConfigSpecs.length >= 2
                     && vmConfigSpecs[0] != null && vmConfigSpecs[1] != null) {
               Assert.assertTrue(ivm.reconfigVM(vmMor, vmConfigSpecs[0]),
                        "Successfully reconfigured the VM to connect to the "
                                 + "standalone dv port",
                        "Can not reconfigure the VM "
                                 + "to connect to the standalone dv port");
               Assert.assertNotNull(hostConnectAnchor,
                        "The host connect anchor is null");
               final SessionManager sessionManager = new SessionManager(
                        hostConnectAnchor);
               sessionMgrMor = sessionManager.getSessionManager();
               hostLoginSession = sessionManager.login(sessionMgrMor,
                        TestConstants.ESX_USERNAME, TestConstants.ESX_PASSWORD,
                        null);
               Assert.assertNotNull(hostLoginSession,
                        "Can not login into the host");
               msi = new InternalServiceInstance(hostConnectAnchor);
               Assert.assertNotNull(msi, "The service instance is null");
               hostDVSManager = msi.getInternalServiceInstanceContent().getHostDistributedVirtualSwitchManager();
               Assert.assertNotNull(hostDVSManager,
                        "The host DVS manager mor is null");
               iHostDVSManager = new InternalHostDistributedVirtualSwitchManager(
                        hostConnectAnchor);
               portData = iHostDVSManager.fetchPortState(hostDVSManager,
                        dvsConfigInfo.getUuid(),
                        new String[] { portConnection.getPortKey() }, null);
               Assert.assertNotNull(portData, "The port data is null");
               Assert.assertTrue((portData.length == 1),
                        "The size of the array is incorrect");
               Assert.assertNotNull(portData[0], "The port data is null");
               Assert.assertNotNull(portData[0].getSetting(),
                        "The port setting is null");
               verified = TestUtil.compareObject(portData[0].getSetting(),
                        dvPortSetting,
                        TestUtil.getIgnorePropertyList(dvPortSetting, false));
               if (verified) {
                  log.info("Verified that the port setting is "
                           + "correctly set on the host");
                  /*
                   * Power-On the vm
                   */
               } else {
                  log.error("The port setting on the host diverges from"
                           + " the port setting on the VC");
               }
            } else {
               log.error("Can not obtain the vm config spec");
            }
         } else {
            log.error("Can not obtain the network configuration");
         }
      } finally {
         if (vmMor != null) {
            if (isVMCreated
                     && ivm.setVMState(vmMor,
                              VirtualMachinePowerState.POWERED_OFF, false)) {
               // destroy the VM
               verified &= ivm.destroy(vmMor);
            } else {
               if (vmConfigSpecs != null && vmConfigSpecs.length >= 2
                        && vmConfigSpecs[1] != null) {
                  verified &= ivm.reconfigVM(vmMor, vmConfigSpecs[1]);
               }
            }
         }
         if (hostMor != null && hostNetworkConfig != null
                  && hostNetworkConfig[1] != null) {
            verified &= ins.updateNetworkConfig(ins.getNetworkSystem(hostMor),
                     hostNetworkConfig[1], TestConstants.CHANGEMODE_MODIFY);
         }
         if (hostLoginSession != null) {
            verified &= new SessionManager(connectAnchor).logout(sessionMgrMor);
         }
      }
      return verified;
   }

   /**
    * Utility method to migrate the vmotion nic on a host to the vds
    *
    * @param connectAnchor
    * @param host
    * @param vdsMor
    * @param portConnection
    * @throws MethodFault,Exception
    */
   public static void migrateVmotionNicsToVds(final ConnectAnchor connectAnchor,
                                              final ManagedObjectReference host,
                                              final ManagedObjectReference vdsMor,
                                              final DistributedVirtualSwitchPortConnection portConnection)
      throws Exception
   {
      final HostSystem ihs = new HostSystem(connectAnchor);
      final NetworkSystem ins = new NetworkSystem(connectAnchor);
      final VmotionSystem iVMotionSystem = new VmotionSystem(connectAnchor);
      final DistributedVirtualSwitch ivds = new DistributedVirtualSwitch(
               connectAnchor);
      final String switchUuid = ivds.getConfig(vdsMor).getUuid();
      final String hostName = ihs.getHostName(host);
      final HostVirtualNic vnic = iVMotionSystem.getVmotionVirtualNic(
               iVMotionSystem.getVMotionSystem(host), host);
      assertNotNull(vnic, "There is no vmotion nic set up on host " + hostName);
      final HostVirtualNicSpec updatedVnicSpec = vnic.getSpec();
      updatedVnicSpec.setDistributedVirtualPort(portConnection);
      updatedVnicSpec.setPortgroup(null);
      assertTrue(
               ins.updateVirtualNic(ins.getNetworkSystem(host),
                        vnic.getDevice(), updatedVnicSpec),
               "Successfully moved the " + "vmotion nic on host " + hostName
                        + " to the vds", "Failed to "
                        + "move the the vmotion nic on host " + hostName
                        + " to the " + "vds");
   }

   /**
    * This method returns the Distributed Virtual Switch MOR
    *
    * @param connectAnchor Reference to the ConnectAnchor object
    * @param Specification to create the Distributed Virtual Switch
    * @param dcMor Reference to the DataCenter
    * @return Distributed Virtual Switch MOR
    * @throws MethodFault, Exception
    */
   public static ManagedObjectReference createDVSFromCreateSpec(final ConnectAnchor connectAnchor,
                                                                final DVSCreateSpec createSpec,
                                                                ManagedObjectReference dcMor)
      throws Exception
   {
      ManagedObjectReference networkFolderMor = null;
      ManagedObjectReference dvsMOR = null;
      Folder iFolder = null;
      DistributedVirtualSwitch iDistributedVirtualSwitch = null;
      assertNotNull(connectAnchor,
               "Reference to the ConnectAnchor object is not null",
               "Reference to the ConnectAnchor object is null");
      assertNotNull(createSpec, "DVSCreateSpec is not null",
               "DVSCreateSpec is null");
      iFolder = new Folder(connectAnchor);
      iDistributedVirtualSwitch = new DistributedVirtualSwitch(connectAnchor);

      if (dcMor == null) {
         dcMor = iFolder.getDataCenter();
      }
      assertNotNull(dcMor, "Got the DataCenter object", "DataCenter is null");
      networkFolderMor = iFolder.getNetworkFolder(dcMor);
      assertNotNull(networkFolderMor, "Got the network folder",
               "Failed to get the network folder");
      dvsMOR = iFolder.createDistributedVirtualSwitch(networkFolderMor,
               createSpec);
      if (dvsMOR != null) {
         assertTrue((iDistributedVirtualSwitch.validateDVSConfigSpec(dvsMOR,
                  createSpec.getConfigSpec(), null)),
                  "The config spec of the Distributed Virtual Switch"
                           + "is not created as per specifications");
      }
      return dvsMOR;
   }

   /**
    * This method returns the Distributed Virtual Switch MOR
    *
    * @param connectAnchor Reference to the ConnectAnchor object
    * @param Specification to create the Distributed Virtual Switch
    * @return Distributed Virtual Switch MOR
    * @throws MethodFault, Exception
    */
   public static ManagedObjectReference createDVSFromCreateSpec(final ConnectAnchor connectAnchor,
                                                                final DVSCreateSpec createSpec)
      throws Exception
   {
      return createDVSFromCreateSpec(connectAnchor, createSpec, null);

   }

   /**
    * This method verifies the CompatibilityResults
    *
    * @param expected Reference to the expected compatibility results
    * @param actual Reference to the actual compatibility results
    * @return boolean true if successful, false otherwise.
    * @throws MethodFault, Exception
    */
   public static boolean verifyCompatibilityResults(final DistributedVirtualSwitchManagerCompatibilityResult[] expected,
                                                    final DistributedVirtualSwitchManagerCompatibilityResult[] actual)
      throws Exception
   {
      boolean isEqual = true;
      final Map<ManagedObjectReference, List<LocalizedMethodFault>> expectedMap = createHashMap(expected);
      final Map<ManagedObjectReference, List<LocalizedMethodFault>> actualMap = createHashMap(actual);
      boolean isFound = false;
      if (expectedMap != null && actualMap != null) {
         for (final ManagedObjectReference expectedMor : expectedMap.keySet()) {
            if (actualMap.containsKey(expectedMor)) {
               // Found the host mor in the actual Map
               final List<LocalizedMethodFault> expectedMethodFault = expectedMap.get(expectedMor);
               final List<LocalizedMethodFault> actualMethodFault = actualMap.get(expectedMor);
               if (expectedMethodFault == null) {
                  if (actualMethodFault != null) {
                     isEqual = false;
                  }
               } else {
                  if (actualMethodFault == null) {
                     isEqual = false;
                  } else {
                     for (final LocalizedMethodFault fault : expectedMethodFault) {
                        final String faultClassName = fault.getFault().getClass().getName();
                        for (final LocalizedMethodFault actualFault : actualMethodFault) {
                           isFound = false;
                           if (actualFault.getFault().getClass().getName().equals(
                                    faultClassName)) {
                              isFound = true;
                              actualMethodFault.remove(actualFault);
                              break;
                           }
                        }
                        isEqual &= isFound;
                     }
                  }
               }
            } else {
               isEqual = false;
            }
         }
         if (isEqual) {
            log.info("Successfully verified CompatibilityResults");
         } else {
            log.error("Unable verify CompatibilityResults");
         }
      }
      return isEqual;
   }

   /**
    * This method creates HashMap
    *
    * @param result Reference to the expected compatibility result
    * @return Map containing hostmor as key and error list as values
    * @throws MethodFault, Exception
    */
   public static Map<ManagedObjectReference, List<LocalizedMethodFault>> createHashMap(final DistributedVirtualSwitchManagerCompatibilityResult[] result)
      throws Exception
   {
      final Map<ManagedObjectReference, List<LocalizedMethodFault>> compatibilityMap = new HashMap<ManagedObjectReference, List<LocalizedMethodFault>>();
      ManagedObjectReference hostMor = null;
      List<LocalizedMethodFault> listError = null;
      LocalizedMethodFault[] error = null;
      if (result != null && result.length > 0) {
         for (final DistributedVirtualSwitchManagerCompatibilityResult res : result) {
            hostMor = res.getHost();
            if (hostMor != null) {
               error = com.vmware.vcqa.util.TestUtil.vectorToArray(
                        res.getError(),
                        com.vmware.vc.LocalizedMethodFault.class);
               if (error != null && error.length >= 1) {
                  listError = new ArrayList<LocalizedMethodFault>();
                  for (final LocalizedMethodFault err : error) {
                     listError.add(err);
                  }
                  compatibilityMap.put(hostMor, listError);
               } else {
                  compatibilityMap.put(hostMor, null);
               }

            } else {
               log.error("The host mor was null");
            }
         }
      }
      return compatibilityMap;
   }

   /**
    * This method verifies the query feature capability for a given version
    *
    * @param featureCapability Reference to the DVSFeatureCapability object
    * @param version vDs version
    * @return boolean true if successful, false otherwise.
    * @throws MethodFault, Exception
    */
   public static boolean verifyQueryFeatureCapability(final DVSFeatureCapability featureCapability,
                                                      final String version)
      throws Exception
   {
      boolean result = false;
      if (featureCapability != null && version != null) {
         log.info("version  :" + version);
         LogUtil.printDetailedObject(featureCapability, "~");
         VMwareDVSFeatureCapability vmwareDVSCapability = (VMwareDVSFeatureCapability) featureCapability;
         VMwareDVSHealthCheckCapability vmwareDVSHealthCheckCapability = (VMwareDVSHealthCheckCapability) featureCapability.getHealthCheckCapability();
         DVSNetworkResourceManagementCapability networkResourceMgmtCapability = vmwareDVSCapability.getNetworkResourceManagementCapability();
         VMwareDvsLacpCapability lacpCapbility = vmwareDVSCapability.getLacpCapability();
         boolean version60 = DVSTestConstants.VDS_VERSION_60.equalsIgnoreCase(version)
                  && networkResourceMgmtCapability.isNetworkResourceControlVersion3Supported()
                  && lacpCapbility.isMultiLacpGroupSupported()
                  && featureCapability.isNetworkFilterSupported()
                  && vmwareDVSHealthCheckCapability.isVlanMtuSupported()
                  && vmwareDVSHealthCheckCapability.isTeamingSupported()
                  && vmwareDVSCapability.isLldpSupported()
                  && networkResourceMgmtCapability.isNetworkResourceManagementSupported()
                  && vmwareDVSCapability.isVspanSupported();
         boolean version55 = DVSTestConstants.VDS_VERSION_55.equalsIgnoreCase(version)
                  && lacpCapbility.isMultiLacpGroupSupported()
                  && featureCapability.isNetworkFilterSupported()
                  && vmwareDVSHealthCheckCapability.isVlanMtuSupported()
                  && vmwareDVSHealthCheckCapability.isTeamingSupported()
                  && vmwareDVSCapability.isIpfixSupported()
                  && vmwareDVSCapability.isLldpSupported()
                  && networkResourceMgmtCapability.isNetworkResourceManagementSupported()
                  && vmwareDVSCapability.isVspanSupported();
         boolean version51 = DVSTestConstants.VDS_VERSION_51.equalsIgnoreCase(version)
                  && vmwareDVSHealthCheckCapability.isVlanMtuSupported()
                  && vmwareDVSHealthCheckCapability.isTeamingSupported()
                  && vmwareDVSCapability.isIpfixSupported()
                  && vmwareDVSCapability.isLldpSupported()
                  && networkResourceMgmtCapability.isNetworkResourceManagementSupported()
                  && vmwareDVSCapability.isVspanSupported();
         boolean version50 = DVSTestConstants.VDS_VERSION_50.equalsIgnoreCase(version)
                  && networkResourceMgmtCapability.isUserDefinedNetworkResourcePoolsSupported()
                  && vmwareDVSCapability.isIpfixSupported()
                  && vmwareDVSCapability.isLldpSupported()
                  && vmwareDVSCapability.isVspanSupported()
                  && !(vmwareDVSHealthCheckCapability.isVlanMtuSupported())
                  && !(vmwareDVSHealthCheckCapability.isTeamingSupported());
         boolean version41 = DVSTestConstants.VDS_VERSION_41.equalsIgnoreCase(version)
                  && networkResourceMgmtCapability.isNetworkResourceManagementSupported()
                  && vmwareDVSCapability.isVmDirectPathGen2Supported()
                  && !networkResourceMgmtCapability.isUserDefinedNetworkResourcePoolsSupported()
                  && !vmwareDVSCapability.isIpfixSupported()
                  && !vmwareDVSCapability.isLldpSupported()
                  && !vmwareDVSCapability.isVspanSupported()
                  && !vmwareDVSHealthCheckCapability.isVlanMtuSupported();
         boolean version40 = DVSTestConstants.VDS_VERSION_40.equalsIgnoreCase(version)
                  && !networkResourceMgmtCapability.isNetworkResourceManagementSupported()
                  && !vmwareDVSCapability.isVmDirectPathGen2Supported()
                  && !networkResourceMgmtCapability.isUserDefinedNetworkResourcePoolsSupported()
                  && !vmwareDVSCapability.isIpfixSupported()
                  && !vmwareDVSCapability.isLldpSupported()
                  && !vmwareDVSCapability.isVspanSupported();
         if (version60 || version55 || version51 || version50 || version41
                  || version40) {
            log.info("Successfully verified query feature "
                     + "capability for version : " + version);
            result = true;
         } else {
            log.error("Unable to verify the query feature "
                     + "capability for version : " + version);
         }
      }
      log.warn("DVSFeatureCapability and/or version is null");
      return result;
   }

   /**
    * This method creates the container of hosts to check the compatibility
    *
    * @param container Check hosts in this container. The supported container
    *           types are Datacenter, Folder and ComputeResource
    * @param recursive If true, check hosts of all levels in the hierarchy with
    *           container as root of the tree
    * @return DistributedVirtualSwitchManagerHostContainer container of hosts
    * @throws MethodFault, Exception
    */
   public static DistributedVirtualSwitchManagerHostContainer createHostContainer(final ManagedObjectReference container,
                                                                                  final boolean recursive)
      throws Exception
   {
      final DistributedVirtualSwitchManagerHostContainer hostContainer = new DistributedVirtualSwitchManagerHostContainer();
      hostContainer.setContainer(container);
      hostContainer.setRecursive(recursive);
      LogUtil.printDetailedObject(hostContainer, ":");
      return hostContainer;
   }

   /**
    * This method creates ContainerFilter by checking hosts in this container
    *
    * @param container Check hosts in this container. The supported container
    *           types are Datacenter, Folder and ComputeResource
    * @param inclusive If this flag is true, then the filter returns the hosts
    *           in the container that meet the criteria, otherwise, it returns
    *           hosts that don't meet the criteria
    * @return DistributedVirtualSwitchManagerHostDvsFilterSpec The hosts against
    *         which to check compatibility.
    * @throws MethodFault, Exception
    */
   public static DistributedVirtualSwitchManagerHostDvsFilterSpec createHostContainerFilter(final DistributedVirtualSwitchManagerHostContainer container,
                                                                                            final boolean inclusive)
      throws Exception
   {
      final DistributedVirtualSwitchManagerHostContainerFilter hostContainerFilter = new DistributedVirtualSwitchManagerHostContainerFilter();
      hostContainerFilter.setHostContainer(container);
      hostContainerFilter.setInclusive(inclusive);
      LogUtil.printDetailedObject(hostContainerFilter, ":");
      return hostContainerFilter;
   }

   /**
    * This method compares the vds version strings passed
    *
    * @param version1
    * @param version2
    * @return int 0, if equal 1, if greater -1, if lesser
    * @throws Exception
    */
   public static int compareVdsVersion(String version1,
                                       String version2)
      throws Exception
   {
      float versionOne = Float.valueOf(version1);
      float versionTwo = Float.valueOf(version2);
      int returnVal = versionOne > versionTwo ? 1
               : (versionOne == versionTwo ? 0 : -1);
      return returnVal;
   }

   /**
    * This method creates HostDvsMembershipFilter by checking host compatibility
    * against all hosts in the DVS (or not in the DVS if inclusive flag in base
    * class is false)
    *
    * @param container Check hosts in this container. The supported container
    *           types are Datacenter, Folder and ComputeResource
    * @param recursive If true, check hosts of all levels in the hierarchy with
    *           container as root of the tree
    * @param inclusive If this flag is true, then the filter returns the hosts
    *           in the container that meet the criteria, otherwise, it returns
    *           hosts that don't meet the criteria
    * @return DistributedVirtualSwitchManagerHostDvsFilterSpec The hosts against
    *         which to check compatibility.
    * @throws MethodFault, Exception
    */
   public static DistributedVirtualSwitchManagerHostDvsFilterSpec createHostDvsMembershipFilter(final ManagedObjectReference distributedVirtualSwitch,
                                                                                                final boolean inclusive)
      throws Exception
   {
      final DistributedVirtualSwitchManagerHostDvsMembershipFilter membershipFilter = new DistributedVirtualSwitchManagerHostDvsMembershipFilter();
      membershipFilter.setDistributedVirtualSwitch(distributedVirtualSwitch);
      membershipFilter.setInclusive(inclusive);
      LogUtil.printDetailedObject(membershipFilter, ":");
      return membershipFilter;
   }

   /**
    * This method creates ostArrayFilter by considering all hosts in this array
    *
    * @param hosts List of hosts to consider.
    * @param inclusive If this flag is true, then the filter returns the hosts
    *           in the container that meet the criteria, otherwise, it returns
    *           hosts that don't meet the criteria
    * @return DistributedVirtualSwitchManagerHostDvsFilterSpec The hosts against
    *         which to check compatibility.
    * @throws MethodFault, Exception
    */
   public static DistributedVirtualSwitchManagerHostDvsFilterSpec createHostArrayFilter(final Vector<ManagedObjectReference> hosts,
                                                                                        final boolean inclusive)
      throws Exception
   {
      DistributedVirtualSwitchManagerHostArrayFilter hostArrayFilter = null;
      if (hosts != null && hosts.size() > 0) {
         hostArrayFilter = new DistributedVirtualSwitchManagerHostArrayFilter();
         hostArrayFilter.getHost().clear();
         hostArrayFilter.getHost().addAll(
                  com.vmware.vcqa.util.TestUtil.arrayToVector(TestUtil.vectorToArray(hosts)));
         hostArrayFilter.setInclusive(inclusive);
         LogUtil.printDetailedObject(hostArrayFilter, ":");
      } else {
         log.warn("List of hosts is zero or null");
      }
      return hostArrayFilter;
   }

   /**
    * This method returns the LocalizedMethodFault array
    *
    * @param methodFaults List of the faults that makes the host not compatible
    *           with a given DvsProductSpec
    * @return faults LocalizedMethodFault array
    * @throws MethodFault, Exception
    */
   public static LocalizedMethodFault[] createLocalizedMethodFault(final Vector<MethodFault> methodFaults)
      throws Exception
   {
      LocalizedMethodFault[] faults = null;
      if (methodFaults != null && methodFaults.size() > 0) {
         faults = new LocalizedMethodFault[methodFaults.size()];
         for (int i = 0; i < methodFaults.size(); i++) {
            faults[i] = new LocalizedMethodFault();
            faults[i].setFault(methodFaults.get(i));
         }
      }
      return faults;
   }

   /**
    * Returns the source setting merged with the destination setting passed.
    *
    * @param destination
    * @param source
    * @throws Exception
    */
   public static void deepMergeSetting(Object destination,
                                       final Object source)
      throws Exception
   {
      Map<String, Method> methodsMap = null;
      Method method = null;
      Object srcObject = null;
      Object destObject = null;
      BoolPolicy srcBoolPolicy = null;
      BoolPolicy destBoolPolicy = null;
      StringPolicy srcStringPolicy = null;
      StringPolicy destStringPolicy = null;
      LongPolicy srcLongPolicy = null;
      LongPolicy destLongPolicy = null;
      IntPolicy srcIntPolicy = null;
      IntPolicy destIntPolicy = null;
      VMwareUplinkPortOrderPolicy srcPortOrderPolicy = null;
      VMwareUplinkPortOrderPolicy destPortOrderPolicy = null;
      if (source == null) {
         return;
      } else if (destination == null) {
         destination = source;
      } else {
         if (destination.getClass().equals(source.getClass())) {
            if (destination instanceof BoolPolicy) {
               srcBoolPolicy = (BoolPolicy) source;
               if (srcBoolPolicy.isValue() != null && srcBoolPolicy.isValue()) {
                  destBoolPolicy = (BoolPolicy) destination;
                  destBoolPolicy.setValue(srcBoolPolicy.isValue());
                  destBoolPolicy.setInherited(false);
               }
            } else if (destination instanceof IntPolicy) {
               srcIntPolicy = (IntPolicy) source;
               if (srcIntPolicy.getValue() != null) {
                  destIntPolicy = (IntPolicy) destination;
                  destIntPolicy.setValue(srcIntPolicy.getValue());
                  destIntPolicy.setInherited(false);
               }
            } else if (destination instanceof StringPolicy) {
               srcStringPolicy = (StringPolicy) source;
               if (srcStringPolicy.getValue() != null) {
                  destStringPolicy = (StringPolicy) destination;
                  destStringPolicy.setValue(srcStringPolicy.getValue());
                  destStringPolicy.setInherited(false);
               }
            } else if (destination instanceof LongPolicy) {
               srcLongPolicy = (LongPolicy) source;
               if (srcLongPolicy.getValue() != null) {
                  destLongPolicy = (LongPolicy) destination;
                  destLongPolicy.setValue(srcLongPolicy.getValue());
                  destLongPolicy.setInherited(false);
               }
            } else if (destination instanceof VMwareUplinkPortOrderPolicy) {
               srcPortOrderPolicy = (VMwareUplinkPortOrderPolicy) source;
               if (com.vmware.vcqa.util.TestUtil.vectorToArray(
                        srcPortOrderPolicy.getActiveUplinkPort(),
                        java.lang.String.class) != null) {
                  destPortOrderPolicy = (VMwareUplinkPortOrderPolicy) destination;
                  destPortOrderPolicy.getActiveUplinkPort().clear();
                  destPortOrderPolicy.getActiveUplinkPort().addAll(
                           srcPortOrderPolicy.getActiveUplinkPort());
                  destPortOrderPolicy.setInherited(false);
               }
               if (com.vmware.vcqa.util.TestUtil.vectorToArray(
                        srcPortOrderPolicy.getStandbyUplinkPort(),
                        java.lang.String.class) != null) {
                  destPortOrderPolicy = (VMwareUplinkPortOrderPolicy) destination;
                  destPortOrderPolicy.getStandbyUplinkPort().clear();
                  destPortOrderPolicy.getStandbyUplinkPort().addAll(
                           srcPortOrderPolicy.getStandbyUplinkPort());
                  destPortOrderPolicy.setInherited(false);
               }
            } else {
               methodsMap = TestUtil.findMethods(destination, true, false,
                        false);
               if (methodsMap != null && methodsMap.keySet() != null) {
                  for (final String methodName : methodsMap.keySet()) {
                     method = methodsMap.get(methodName);
                     srcObject = method.invoke(source, new Object[] {});
                     destObject = method.invoke(destination, new Object[] {});
                     if (srcObject != null
                              && srcObject instanceof InheritablePolicy) {
                        deepMergeSetting(destObject, srcObject);
                     }
                  }
               }
            }
         } else {
            log.warn("The object classes are not equal");
         }
      }
   }

   /**
    * This method waits for time mentioned in DVS.properties file. This delay is
    * required to get the IP address of VM
    *
    * @throws Exception
    */
   public static void WaitForIpaddress()
      throws Exception
   {
      final String delay = TestUtil.getPropertyValue("GET_IP_WAIT_TIME",
               DVSTestConstants.DVS_PROP_FILE);
      int delayInMins = -1;
      if (delay != null && !delay.equals("-1")) {
         try {
            delayInMins = Integer.parseInt(delay);
         } catch (final NumberFormatException nf) {
            log.warn("");
            delayInMins = -1;
         }
         if (delayInMins > 0) {
            log.info("Sleeping for " + delayInMins
                     + " mins, to populate valid IP of VM");
            Thread.sleep(1000 * 60 * delayInMins);
         }
      }
   }

   /**
    * Method to build DistributedVirtualSwitchPortConnection object.
    *
    * @param switchUuid DVS switch uuid.
    * @param portKey Key of the given port.
    * @param portgroupKey Key of the portgroup.
    * @return connection DistributedVirtualSwitchPortConnection.
    */
   public static DistributedVirtualSwitchPortConnection buildDistributedVirtualSwitchPortConnection(final String switchUuid,
                                                                                                    final String portKey,
                                                                                                    final String portgroupKey)
   {
      final DistributedVirtualSwitchPortConnection connection = new DistributedVirtualSwitchPortConnection();
      connection.setSwitchUuid(switchUuid);
      connection.setPortKey(portKey);
      connection.setPortgroupKey(portgroupKey);
      return connection;
   }

   /**
    * This method adds host(without pnics) to the DistributedVirtualSwitch
    *
    * @param connectAnchor Reference to the ConnectAnchor object
    * @param dvsMOR ManagedObjectReference of the DV Switch
    * @param hostMors ManagedObjectReference of the host
    * @return true if successful, false otherwise
    * @throws MethodFault, Exception
    */
   public static boolean addHostsToDVS(final ConnectAnchor connectAnchor,
                                       final ManagedObjectReference dvsMOR,
                                       final ManagedObjectReference hostMOR)
      throws Exception
   {
      boolean reconfigured = false;
      if (dvsMOR != null) {
         assertNotNull(connectAnchor,
                  "Reference to the ConnectAnchor object is not null",
                  "Reference to the ConnectAnchor object is null");
         DistributedVirtualSwitch iDistributedVirtualSwitch = new DistributedVirtualSwitch(
                  connectAnchor);
         DVSConfigInfo configInfo = iDistributedVirtualSwitch.getConfig(dvsMOR);
         List<ManagedObjectReference> hostMorList = new ArrayList<ManagedObjectReference>();
         hostMorList.add(hostMOR);
         DVSConfigSpec deltaConfigSpec = addHostsToDVSConfigSpec(
                  new DVSConfigSpec(), hostMorList);
         String validConfigVersion = configInfo.getConfigVersion();
         deltaConfigSpec.setConfigVersion(validConfigVersion);
         reconfigured = iDistributedVirtualSwitch.reconfigure(dvsMOR,
                  deltaConfigSpec);
         if (reconfigured) {
            log.info("Successfully reconfigured DVS");
         } else {
            log.error("Failed to reconfigure dvs");
         }
      }
      return reconfigured;
   }

   /**
    * This method adds host and pnic to the DistributedVirtualSwitch
    *
    * @param connectAnchor Reference to the ConnectAnchor object
    * @param dvsMOR ManagedObjectReference of the DV Switch
    * @param hostMors ManagedObjectReference of the host
    * @param pNicMap Map of host mors and pnic devices
    * @return true if successful, false otherwise
    * @throws MethodFault, Exception
    */
   public static boolean addHostsWithPnicsToDVS(final ConnectAnchor connectAnchor,
                                                final ManagedObjectReference dvsMOR,
                                                final Map<ManagedObjectReference, String> pNicMap)
      throws Exception
   {
      boolean reconfigured = false;
      if (dvsMOR != null) {
         DVSConfigInfo configInfo = null;
         DVSConfigSpec deltaConfigSpec = null;
         String validConfigVersion = null;
         DistributedVirtualSwitch iDistributedVirtualSwitch = null;
         assertNotNull(connectAnchor,
                  "Reference to the ConnectAnchor object is not null",
                  "Reference to the ConnectAnchor object is null");
         iDistributedVirtualSwitch = new DistributedVirtualSwitch(connectAnchor);
         configInfo = iDistributedVirtualSwitch.getConfig(dvsMOR);
         deltaConfigSpec = addHostsToDVSConfigSpecWithPnic(new DVSConfigSpec(),
                  pNicMap, null);
         validConfigVersion = configInfo.getConfigVersion();
         deltaConfigSpec.setConfigVersion(validConfigVersion);
         reconfigured = iDistributedVirtualSwitch.reconfigure(dvsMOR,
                  deltaConfigSpec);
         if (reconfigured) {
            log.info("Successfully reconfigured DVS");
         } else {
            log.error("Failed to reconfigure dvs");
         }
      }
      return reconfigured;
   }

   /**
    * This method adds host and multiple pnics to the DistributedVirtualSwitch
    *
    * @param connectAnchor Reference to the ConnectAnchor object
    * @param dvsMOR ManagedObjectReference of the DV Switch
    * @param pNicMap Map of host mors and pnic devices
    * @return true if successful, false otherwise
    * @throws MethodFault, Exception
    */
   public static boolean addHostsWithMultiplePnicsToDVS(final ConnectAnchor connectAnchor,
                                                        final ManagedObjectReference dvsMOR,
                                                        final Map<ManagedObjectReference, List<String>> pNicMap)
      throws Exception
   {
      boolean reconfigured = false;
      if (dvsMOR != null) {
         assertNotNull(connectAnchor,
                  "Reference to the ConnectAnchor object is not null",
                  "Reference to the ConnectAnchor object is null");
         DistributedVirtualSwitch iDistributedVirtualSwitch = new DistributedVirtualSwitch(
                  connectAnchor);
         DVSConfigInfo configInfo = iDistributedVirtualSwitch.getConfig(dvsMOR);
         DVSConfigSpec deltaConfigSpec = addHostsToDVSConfigSpecWithMultiplePnic(
                  new DVSConfigSpec(), pNicMap, null);
         String validConfigVersion = configInfo.getConfigVersion();
         deltaConfigSpec.setConfigVersion(validConfigVersion);
         reconfigured = iDistributedVirtualSwitch.reconfigure(dvsMOR,
                  deltaConfigSpec);
         if (reconfigured) {
            log.info("Successfully reconfigured DVS");
         } else {
            log.error("Failed to reconfigure dvs");
         }
      }
      return reconfigured;
   }

   /**
    * This method is used for spanning a host with pnic across multiple DVS.
    *
    * @param connectAnchor Reference to the ConnectAnchor object
    * @param hostMor ManagedObjectReference of the host to be added.
    * @param dvsMorList List of ManagedObjectReference of the DV Switch.
    * @return true if successful, false otherwise
    * @throws MethodFault, Exception
    */
   public static boolean addFreePnicAndHostToDVS(final ConnectAnchor connectAnchor,
                                                 final ManagedObjectReference hostMor,
                                                 final List<ManagedObjectReference> dvsMorList)
      throws Exception
   {
      boolean result = false;
      int noOfDvs = 0;
      if (connectAnchor != null && hostMor != null && dvsMorList != null) {
         NetworkSystem ins = null;
         ManagedObjectReference dvsMor = null;
         String[] pnicDevices = null;
         ins = new NetworkSystem(connectAnchor);
         noOfDvs = dvsMorList.size();
         /*
          * Check free pnics on the host
          */
         pnicDevices = ins.getPNicIds(hostMor, false);
         if (pnicDevices != null && pnicDevices.length >= noOfDvs) {
            result = true;
            log.info("Found free pnics :" + noOfDvs);
            for (int i = 0; i < noOfDvs; i++) {
               final Map<ManagedObjectReference, String> pNicMap = new HashMap<ManagedObjectReference, String>();
               dvsMor = dvsMorList.get(i);
               pNicMap.put(hostMor, pnicDevices[i]);
               if (!addHostsWithPnicsToDVS(connectAnchor, dvsMor, pNicMap)) {
                  result &= false;
                  break;
               } else {
                  result &= true;
               }
            }
         } else {
            log.warn("Number of free pnics should match"
                     + " with number of DVS");
            result = false;
         }
      } else {
         log.warn("Host Mor and/or DVS list is null");
      }
      return result;
   }

   /**
    * This method is used for spanning a host with pnic across multiple DVS.
    *
    * @param connectAnchor Reference to the ConnectAnchor object
    * @param hostMor ManagedObjectReference of the host to be added.
    * @param dvsMorList List of ManagedObjectReference of the DV Switch.
    * @param nicsNumberOfEachDvs Number of the nics to be added for each DVS.
    * @return true if successful, false otherwise
    * @throws MethodFault, Exception
    */
   public static boolean addPnicsAndHostToDVS(final ConnectAnchor connectAnchor,
                                              final ManagedObjectReference hostMor,
                                              final List<ManagedObjectReference> dvsMorList,
                                              final Integer nicsNumberOfEachDvs)
      throws Exception
   {
      boolean result = true;
      int noOfDvs = 0;
      if (connectAnchor != null && hostMor != null && dvsMorList != null) {
         NetworkSystem ins = null;
         ManagedObjectReference dvsMor = null;
         String[] pnicDevices = null;
         ins = new NetworkSystem(connectAnchor);
         noOfDvs = dvsMorList.size();
         if (nicsNumberOfEachDvs == 0) {
            // Add host to DVS without pnics.
            for (int i = 0; i < noOfDvs; i++) {
               dvsMor = dvsMorList.get(i);
               if (!addHostsToDVS(connectAnchor, dvsMor, hostMor)) {
                  result &= false;
                  break;
               } else {
                  result &= true;
               }
            }
         } else {
            /*
             * Check free pnics on the host
             */
            pnicDevices = ins.getPNicIds(hostMor, false);
            if (pnicDevices != null && pnicDevices.length >= noOfDvs) {
               result = true;
               log.info("Found free pnics :" + noOfDvs);
               // handle each DVS one by one
               for (int i = 0; i < noOfDvs * nicsNumberOfEachDvs.intValue(); i = i
                        + nicsNumberOfEachDvs.intValue()) {
                  Map<ManagedObjectReference, List<String>> pNicMap = new HashMap<ManagedObjectReference, List<String>>();
                  dvsMor = dvsMorList.get(i);
                  ArrayList<String> pNicList = new ArrayList<String>();
                  for (int j = 0; j < nicsNumberOfEachDvs.intValue(); j++) {
                     /* pNicList contains the pNic keys that will be added to current dvs.
                      * The size of pNicList is nicsNumberOfEachDvs.intValue().
                      */
                     pNicList.add(pnicDevices[i + j]);
                  }
                  pNicMap.put(hostMor, pNicList);
                  if (!addHostsWithMultiplePnicsToDVS(connectAnchor, dvsMor,
                           pNicMap)) {
                     result &= false;
                     break;
                  } else {
                     result &= true;
                  }
               }
            } else {
               log.warn("Number of free pnics should match"
                        + " with number of DVS");
               result = false;
            }
         }
      } else {
         log.warn("Host Mor and/or DVS list is null");
      }
      return result;
   }

   /**
    * This method gets the vDs version from DVS.properties file or from argument
    * If the value is set from argument then argument value is set. Ex:
    * -DVDS_VERSION=6.0.0
    *
    * @return String, the vDs version specified in DVS.properties file or from
    *         argument
    */
   public static String getvDsVersion()
   {
      /*
       * Get the version value from /dvs/DVS.properties file
       */
      String vDsVersion = TestUtil.getPropertyValue(
               DVSTestConstants.VDS_VERSION, DVSTestConstants.DVS_PROP_FILE);
      TestDataHandler.getSingleton();
      /*
       * Get the version value from test args. Ex: -DVDS_VERSION=6.0.0
       */
      String vDsVersionArgs = TestDataHandler.getValue(
               DVSTestConstants.VDS_VERSION, null);
      if (vDsVersionArgs != null) {
         /*
          * Override the version if set from args
          */
         log.info("Setting vDS version from arguments.");
         vDsVersion = vDsVersionArgs;
      } else if (vDsVersion == null) {
         log.info("Setting vDS version to default");
         vDsVersion = DVSTestConstants.VDS_VERSION_DEFAULT;
      }
      log.info(vDsVersion);
      return vDsVersion;
   }

   /**
    * Get the port keys based on the port criteria passed.
    *
    * @connectAnchor Reference to the ConnectAnchor object
    * @param dvsMor DVS Mor.
    * @param portgroupKey Given portgroup key.
    * @return List<String> List containing portkeys of the DVSwitch.
    * @throws MethodFault, Exception
    */
   public static List<String> fetchPortKeys(final ConnectAnchor connectAnchor,
                                            final ManagedObjectReference dvsMor,
                                            final String portgroupKey)
      throws Exception
   {
      assertNotNull(connectAnchor,
               "Reference to the ConnectAnchor object is not null",
               "Reference to the ConnectAnchor object is null");
      final DistributedVirtualSwitch iDVSwitch = new DistributedVirtualSwitch(
               connectAnchor);
      final DistributedVirtualSwitchPortCriteria portCriteria = iDVSwitch.getPortCriteria(
               null, null, null, new String[] { portgroupKey }, null, true);
      return iDVSwitch.fetchPortKeys(dvsMor, portCriteria);
   }

   /**
    * Method that returns the vnic spec based on if the host in question is a
    * ESX host or a visor host. If the host is Visor it will set the ip address
    * to take the dhcp value, otherwise it will retrieve the ip address from the
    * list of alternate ip's of the vmkernel nic or the service console nic.
    *
    * @connectAnchor Reference to the ConnectAnchor object
    * @param portConnection DistributedVirtualSwitchPortConnection object
    * @param hostMor ManagedObjectReference object.
    * @return HostVirtualNicSpec
    * @throws MethodFault, Exception
    */
   public static HostVirtualNicSpec buildVnicSpec(final ConnectAnchor connectAnchor,
                                                  final DistributedVirtualSwitchPortConnection portConnection,
                                                  final ManagedObjectReference hostMor)
      throws Exception
   {
      assertNotNull(connectAnchor,
               "Reference to the ConnectAnchor object is not null",
               "Reference to the ConnectAnchor object is null");
      HostVirtualNicSpec hostVNicSpec = null;
      HostVirtualNicSpec vnicSpec = null;
      HostNetworkInfo hostNetworkInfo = null;
      final HostSystem ihs = new HostSystem(connectAnchor);
      final NetworkSystem ins = new NetworkSystem(connectAnchor);
      if (ihs.isEesxHost(hostMor)) {
         hostVNicSpec = buildVnicSpec(portConnection, null, null, true);
      } else {
         hostNetworkInfo = ins.getNetworkInfo(ins.getNetworkSystem(hostMor));
         assertNotNull(hostNetworkInfo,
                  "Can not retrieve the host network info");
         if (com.vmware.vcqa.util.TestUtil.vectorToArray(
                  hostNetworkInfo.getConsoleVnic(),
                  com.vmware.vc.HostVirtualNic.class) != null
                  && com.vmware.vcqa.util.TestUtil.vectorToArray(
                           hostNetworkInfo.getConsoleVnic(),
                           com.vmware.vc.HostVirtualNic.class).length > 0
                  && com.vmware.vcqa.util.TestUtil.vectorToArray(
                           hostNetworkInfo.getConsoleVnic(),
                           com.vmware.vc.HostVirtualNic.class)[0] != null
                  && com.vmware.vcqa.util.TestUtil.vectorToArray(
                           hostNetworkInfo.getConsoleVnic(),
                           com.vmware.vc.HostVirtualNic.class)[0].getSpec() != null) {
            vnicSpec = com.vmware.vcqa.util.TestUtil.vectorToArray(
                     hostNetworkInfo.getConsoleVnic(),
                     com.vmware.vc.HostVirtualNic.class)[0].getSpec();
         } else if (com.vmware.vcqa.util.TestUtil.vectorToArray(
                  hostNetworkInfo.getVnic(), com.vmware.vc.HostVirtualNic.class) != null
                  && com.vmware.vcqa.util.TestUtil.vectorToArray(
                           hostNetworkInfo.getVnic(),
                           com.vmware.vc.HostVirtualNic.class).length > 0
                  && com.vmware.vcqa.util.TestUtil.vectorToArray(
                           hostNetworkInfo.getVnic(),
                           com.vmware.vc.HostVirtualNic.class)[0] != null
                  && com.vmware.vcqa.util.TestUtil.vectorToArray(
                           hostNetworkInfo.getVnic(),
                           com.vmware.vc.HostVirtualNic.class)[0].getSpec() != null) {
            vnicSpec = com.vmware.vcqa.util.TestUtil.vectorToArray(
                     hostNetworkInfo.getVnic(),
                     com.vmware.vc.HostVirtualNic.class)[0].getSpec();
         } else {
            log.error("There are no vnic or service console "
                     + "vnics on the host");
         }
         assertNotNull(vnicSpec, "The vnic spec is null");
         String ipAddress = TestUtil.getAlternateServiceConsoleIP(vnicSpec.getIp().getIpAddress());
         if (ipAddress != null) {
            hostVNicSpec = buildVnicSpec(portConnection, ipAddress,
                     vnicSpec.getIp().getSubnetMask(), false);
         } else {
            hostVNicSpec = buildVnicSpec(portConnection, null, null, true);
         }
      }
      return hostVNicSpec;
   }

   /**
    * This method get the subnetMask.
    *
    * @connectAnchor Reference to the ConnectAnchor object
    * @param hostMor Given hostMor.
    * @return String subnetMask.
    * @throws MethodFault, Exception
    */
   public static String getSubnetMask(final ConnectAnchor connectAnchor,
                                      final ManagedObjectReference hostMor)
      throws Exception
   {
      HostNetworkInfo networkInfo = null;
      String subnetMask = null;
      ManagedObjectReference nwSystemMor = null;
      HostVirtualNic hostVirtualNic = null;
      assertNotNull(connectAnchor,
               "Reference to the ConnectAnchor object is not null",
               "Reference to the ConnectAnchor object is null");
      final NetworkSystem ins = new NetworkSystem(connectAnchor);
      final HostSystem ihs = new HostSystem(connectAnchor);
      nwSystemMor = ins.getNetworkSystem(hostMor);
      networkInfo = ins.getNetworkInfo(nwSystemMor);
      if (ihs.isEesxHost(hostMor)) {
         hostVirtualNic = com.vmware.vcqa.util.TestUtil.vectorToArray(
                  networkInfo.getVnic(), com.vmware.vc.HostVirtualNic.class)[0];
      } else {
         hostVirtualNic = com.vmware.vcqa.util.TestUtil.vectorToArray(
                  networkInfo.getConsoleVnic(),
                  com.vmware.vc.HostVirtualNic.class)[0];
      }
      assertNotNull(hostVirtualNic, "Successfully get the hostvirtualNic.",
               "Failed to get the hostVirtualNic");
      final HostVirtualNicSpec hostVNicSpec = hostVirtualNic.getSpec();
      assertNotNull(hostVNicSpec, "Successfully get the hostVirtualNicSpec.",
               "Failed to get the hostVirtualNicSpec.");
      final HostIpConfig hostIpConfig = hostVNicSpec.getIp();
      assertNotNull(hostIpConfig, "Successfully get the hostIPconfig.",
               "Failed to get the hostIPConfig.");
      subnetMask = hostIpConfig.getSubnetMask();
      return subnetMask;
   }

   /**
    * This method returns a hostd connection to the caller after login.
    *
    * @param connectAnchor
    * @param hostMor
    * @return ManagedObjectReference
    * @throws Exception
    */
   public static ConnectAnchor getHostConnectAnchor(ConnectAnchor connectAnchor,
                                                    ManagedObjectReference hostMor)
      throws Exception
   {
      assertNotNull(connectAnchor, "The connect anchor is null");
      assertNotNull(hostMor, "The host Mor is null");
      HostSystem hostSystem = new HostSystem(connectAnchor);
      UserSession hostLoginSession = null;
      ConnectAnchor hostConnectAnchor = new ConnectAnchor(
               hostSystem.getHostName(hostMor), connectAnchor.getPort());
      SessionManager sessionManager = new SessionManager(hostConnectAnchor);
      ManagedObjectReference sessionMgrMor = sessionManager.getSessionManager();
      hostLoginSession = new SessionManager(hostConnectAnchor).login(
               sessionMgrMor, TestConstants.ESX_USERNAME,
               TestConstants.ESX_PASSWORD, null);
      Assert.assertNotNull(hostLoginSession, "Cannot login into the host");
      return hostConnectAnchor;
   }

   /**
    * This method create the HostvirtualNic and add virtualNic.
    *
    * @connectAnchor Reference to the ConnectAnchor object
    * @param aHostMor Given source/destination hostMor.
    * @param portConnection Given DVPortconnection.
    * @return String HostVirtualNic Device.
    */
   public static String addVnic(final ConnectAnchor connectAnchor,
                                final ManagedObjectReference aHostMor,
                                final DistributedVirtualSwitchPortConnection portConnection)
      throws Exception
   {
      String device = null;
      HostVirtualNicSpec hostVnicSpec = null; // use to create VNIC.
      String vnicId = null;
      ManagedObjectReference nsMor = null;// Network System of give host.
      HostNetworkInfo networkInfo = null;
      DistributedVirtualSwitchPortConnection newConn = null;
      assertNotNull(connectAnchor,
               "Reference to the ConnectAnchor object is not null",
               "Reference to the ConnectAnchor object is null");
      final NetworkSystem ins = new NetworkSystem(connectAnchor);
      hostVnicSpec = DVSUtil.buildVnicSpec(connectAnchor, portConnection,
               aHostMor);
      nsMor = ins.getNetworkSystem(aHostMor);
      vnicId = ins.addVirtualNic(nsMor, "", hostVnicSpec);
      assertNotNull(vnicId, "Successfully added the virtual Nic",
               "Failed to add the virtual Nic.");
      networkInfo = ins.getNetworkInfo(nsMor);
      final HostVirtualNic[] vNics = com.vmware.vcqa.util.TestUtil.vectorToArray(
               networkInfo.getVnic(), com.vmware.vc.HostVirtualNic.class);
      assertNotNull(vNics, "Failed to get vNics.");
      for (final HostVirtualNic vnic : vNics) {
         log.info("Vnic Key: " + vnic.getKey());
         log.info("Vnic Device: " + vnic.getDevice());
         assertNotNull(vNics, "Failed to get vNics.");
         assertNotNull(vnic.getSpec(), "Failed to get HostVirtualNicSpec.");
         newConn = vnic.getSpec().getDistributedVirtualPort();
         if (newConn != null
                  && TestUtil.compareObject(
                           portConnection,
                           newConn,
                           TestUtil.getIgnorePropertyList(portConnection, false))) {
            device = vnic.getDevice();
         } else {
            log.error("Failed to match the PortConnections");
         }
      }
      return device;
   }

   /**
    * This method verifies the CompatibilityResults
    *
    * @connectAnchor Reference to the ConnectAnchor object
    * @param expected Reference to the expected compatibility results
    * @param actual Reference to the actual compatibility results
    * @param allHosts List of Compatible hosts
    * @return boolean true if successful, false otherwise.
    * @throws MethodFault, Exception
    */
   public static boolean verifyHostsInCompatibilityResults(final ConnectAnchor connectAnchor,
                                                           final DistributedVirtualSwitchManagerCompatibilityResult[] actualCompatibilityResult,
                                                           final DistributedVirtualSwitchManagerCompatibilityResult[] expectedCompatibilityResult,
                                                           final List<ManagedObjectReference> allHosts,
                                                           final String vDsVersion)
      throws Exception
   {
      boolean isEqual = false;
      if (actualCompatibilityResult != null
               && expectedCompatibilityResult != null
               && actualCompatibilityResult.length > 0
               && expectedCompatibilityResult.length <= actualCompatibilityResult.length) {
         assertNotNull(connectAnchor,
                  "Reference to the ConnectAnchor object is not null",
                  "Reference to the ConnectAnchor object is null");
         final HostSystem ihs = new HostSystem(connectAnchor);
         for (final DistributedVirtualSwitchManagerCompatibilityResult result : actualCompatibilityResult) {
            final ManagedObjectReference actualHostmor = result.getHost();
            final String actualHostName = ihs.getHostName(actualHostmor);
            final LocalizedMethodFault[] actualFault = com.vmware.vcqa.util.TestUtil.vectorToArray(
                     result.getError(),
                     com.vmware.vc.LocalizedMethodFault.class);
            if (allHosts.contains(actualHostmor)) {
               Assert.assertNull(actualFault,
                        "Error is not returned for compatible host "
                                 + actualHostName,
                        "Got   error for compatible host" + actualHostName);
               isEqual = true;
            } else {
               if (vDsVersion != null
                        && !vDsVersion.equalsIgnoreCase(DVSTestConstants.VDS_VERSION_40)) {
                  assertTrue((actualFault != null && actualFault.length > 0),
                           "Error is returned for incompatible host "
                                    + actualHostName,
                           "Failed to return  Error for incompatible host"
                                    + actualHostName);
               }
               isEqual = true;
            }
         }
         isEqual = true;
      }
      if (isEqual) {
         log.info("Successfully verifies  the CompatibilityResults");
      } else {
         log.error("Unable to  verify the CompatibilityResults");
      }
      return isEqual;
   }

   /**
    * Create a DVPortgroupConfigSpec object using the given values.
    *
    * @connectAnchor Reference to the ConnectAnchor object
    * @param type Type of the port group.
    * @param numPort number of ports to create.
    * @param policy the policy to be used.
    * @return DVPortgroupConfigSpec with given values set.
    */
   public static DVPortgroupConfigSpec buildDVPortgroupConfigSpec(final String type,
                                                                  final int numPort,
                                                                  final DVPortgroupPolicy policy)
   {
      final DVPortgroupConfigSpec cfg = new DVPortgroupConfigSpec();
      cfg.setType(type);
      cfg.setNumPorts(numPort);
      cfg.setPolicy(policy);
      return cfg;
   }

   /**
    * Method to verify the given VM. 1. Verify the config specs. 2. Verify by
    * power-ops.
    *
    * @connectAnchor Reference to the ConnectAnchor object
    * @param vmMor the mor of the VM to be verified.
    * @param deltaCfg the delta spec used while reconfiguring the VM.
    * @param originalCfg the orifinal spec used for cerating the VM.
    * @return true if both the checks are successful. false otherwise.
    * @throws MethodFault, Exception
    */
   public static boolean verify(final ConnectAnchor connectAnchor,
                                final ManagedObjectReference vmMor,
                                final VirtualMachineConfigSpec deltaCfg,
                                final VirtualMachineConfigSpec originalCfg)
      throws Exception
   {
      assertNotNull(connectAnchor,
               "Reference to the ConnectAnchor object is not null",
               "Reference to the ConnectAnchor object is null");
      final VirtualMachine ivm = new VirtualMachine(connectAnchor);
      final VirtualMachineConfigSpec newCfg = ivm.getVMConfigSpec(vmMor);
      assertTrue(ivm.compareVMConfigSpec(originalCfg, deltaCfg, newCfg),
               "Configspecs matches. verifying power-ops...",
               "Configspecs doesnot match.");
      assertTrue(ivm.verifyPowerOps(vmMor, false), "Powerops successful.",
               "Powerops failed.");
      return true;
   }

   /**
    * Returns the VM configuration spec to have only the required ethernet
    * adapter type, all the other ethernet adapters that do not match the
    * adapter type are removed if the updated virtual machine spec is applied in
    * the reconfigure VM operation.
    *
    * @connectAnchor Reference to the ConnectAnchor object
    * @param vmMor ManagedObjectReference
    * @param connectAnchor ConnectAnchor
    * @param deviceType String type of the ethernet adapter
    * @return VirtualMachineConfigSpec[]
    * @throws MethodFault, Exception
    */
   public VirtualMachineConfigSpec[] getVMReconfigSpec(final ManagedObjectReference vmMor,
                                                       final ConnectAnchor connectAnchor,
                                                       final String deviceType)
      throws Exception
   {
      assertNotNull(connectAnchor,
               "Reference to the ConnectAnchor object is not null",
               "Reference to the ConnectAnchor object is null");
      final VirtualMachine ivm = new VirtualMachine(connectAnchor);
      final VirtualMachineConfigSpec[] configSpec = new VirtualMachineConfigSpec[2];
      VirtualMachineConfigSpec originalConfigSpec = null;
      VirtualMachineConfigSpec updatedConfigSpec = null;
      List<VirtualDeviceConfigSpec> existingVDConfigSpecList = null;
      final List<VirtualDeviceConfigSpec> originalVDConfigSpecList = new ArrayList<VirtualDeviceConfigSpec>();
      final List<VirtualDeviceConfigSpec> updatedVDConfigSpecList = new ArrayList<VirtualDeviceConfigSpec>();
      VirtualDeviceConfigSpec updatedVDConfigSpec = null;
      boolean deviceFound = false;
      List<String> deviceTypes = null;
      List<VirtualDeviceConfigSpecOperation> operations = null;
      if (vmMor != null) {
         existingVDConfigSpecList = DVSUtil.getAllVirtualEthernetCardDevices(
                  vmMor, connectAnchor);
         if (existingVDConfigSpecList != null
                  && existingVDConfigSpecList.size() > 0) {
            updatedConfigSpec = new VirtualMachineConfigSpec();
            deviceTypes = new ArrayList<String>();
            operations = new ArrayList<VirtualDeviceConfigSpecOperation>();
            for (final VirtualDeviceConfigSpec vdConfigSpec : existingVDConfigSpecList) {
               deviceTypes.add("" + vdConfigSpec.getDevice().getKey());
               if (vdConfigSpec.getDevice().getClass().getName().equals(
                        deviceType)) {
                  if (deviceFound) {
                     operations.add(VirtualDeviceConfigSpecOperation.REMOVE);
                  } else {
                     operations.add(VirtualDeviceConfigSpecOperation.EDIT);
                     deviceFound = true;
                  }
               } else {
                  operations.add(VirtualDeviceConfigSpecOperation.REMOVE);
               }
            }
            if (!deviceFound) {
               deviceTypes.add(deviceType);
               operations.add(VirtualDeviceConfigSpecOperation.ADD);
            }
            ivm.reconfigVMSpec(ivm.getVMConfigSpec(vmMor), updatedConfigSpec,
                     deviceTypes, operations, ivm.getResourcePool(vmMor));
            if (updatedConfigSpec != null
                     && com.vmware.vcqa.util.TestUtil.vectorToArray(
                              updatedConfigSpec.getDeviceChange(),
                              com.vmware.vc.VirtualDeviceConfigSpec.class) != null
                     && com.vmware.vcqa.util.TestUtil.vectorToArray(
                              updatedConfigSpec.getDeviceChange(),
                              com.vmware.vc.VirtualDeviceConfigSpec.class).length > 0) {
               for (final VirtualDeviceConfigSpec vdConfigSpec : com.vmware.vcqa.util.TestUtil.vectorToArray(
                        updatedConfigSpec.getDeviceChange(),
                        com.vmware.vc.VirtualDeviceConfigSpec.class)) {
                  if (vdConfigSpec.getOperation().equals(
                           VirtualDeviceConfigSpecOperation.EDIT)) {
                     originalVDConfigSpecList.add(vdConfigSpec);
                  } else if (vdConfigSpec.getOperation().equals(
                           VirtualDeviceConfigSpecOperation.REMOVE)) {
                     updatedVDConfigSpec = (VirtualDeviceConfigSpec) TestUtil.deepCopyObject(vdConfigSpec);
                     updatedVDConfigSpecList.add(updatedVDConfigSpec);
                     vdConfigSpec.setOperation(VirtualDeviceConfigSpecOperation.ADD);
                     originalVDConfigSpecList.add(vdConfigSpec);
                  } else if (vdConfigSpec.getOperation().equals(
                           VirtualDeviceConfigSpecOperation.ADD)) {
                     updatedVDConfigSpec = (VirtualDeviceConfigSpec) TestUtil.deepCopyObject(vdConfigSpec);
                     updatedVDConfigSpecList.add(updatedVDConfigSpec);
                     vdConfigSpec.setOperation(VirtualDeviceConfigSpecOperation.REMOVE);
                     originalVDConfigSpecList.add(vdConfigSpec);
                  }
               }
            }
         }
      }
      if (updatedVDConfigSpecList.size() > 0) {
         updatedConfigSpec = new VirtualMachineConfigSpec();
         updatedConfigSpec.getDeviceChange().clear();
         updatedConfigSpec.getDeviceChange().addAll(
                  com.vmware.vcqa.util.TestUtil.arrayToVector(updatedVDConfigSpecList.toArray(new VirtualDeviceConfigSpec[updatedVDConfigSpecList.size()])));
         configSpec[0] = updatedConfigSpec;
      } else {
         configSpec[0] = null;
      }
      if (originalVDConfigSpecList.size() > 0) {
         originalConfigSpec = new VirtualMachineConfigSpec();
         originalConfigSpec.getDeviceChange().clear();
         originalConfigSpec.getDeviceChange().addAll(
                  com.vmware.vcqa.util.TestUtil.arrayToVector(originalVDConfigSpecList.toArray(new VirtualDeviceConfigSpec[originalVDConfigSpecList.size()])));
      }
      configSpec[1] = originalConfigSpec;
      return configSpec;
   }

   /**
    * Create a VM config spec for adding a new VM.
    *
    * @connectAnchor Reference to the ConnectAnchor object
    * @param connection DistributedVirtualSwitchPortConnection
    * @param deviceType type of the VirtualEthernetCard to use.
    * @param hostMor The MOR of the host where the VM has to be created.
    * @return VirtualMachineConfigSpec.
    * @throws MethodFault, Exception
    */
   public static VirtualMachineConfigSpec buildCreateVMCfg(final ConnectAnchor connectAnchor,
                                                           final DistributedVirtualSwitchPortConnection connection,
                                                           final String deviceType,
                                                           final ManagedObjectReference hostMor)
      throws Exception
   {
      assertNotNull(connectAnchor,
               "Reference to the ConnectAnchor object is not null",
               "Reference to the ConnectAnchor object is null");
      VirtualMachineConfigSpec vmConfigSpec = null;
      HashMap deviceSpecMap = null;
      Iterator deviceSpecItr = null;
      VirtualDeviceConfigSpec deviceSpec = null;
      VirtualEthernetCard ethernetCard = null;
      VirtualEthernetCardDistributedVirtualPortBackingInfo dvPortBacking;
      VirtualDeviceConnectInfo connectInfo = null;
      final VirtualMachine ivm = new VirtualMachine(connectAnchor);
      // create the VMCfg with the default devices.
      vmConfigSpec = DVSUtil.buildDefaultSpec(connectAnchor, hostMor,
               deviceType);
      // now chagnge the backing for the ethernet card.
      deviceSpecMap = ivm.getVirtualDeviceSpec(vmConfigSpec, deviceType);
      deviceSpecItr = deviceSpecMap.values().iterator();
      if (deviceSpecItr.hasNext()) {
         deviceSpec = (VirtualDeviceConfigSpec) deviceSpecItr.next();
         ethernetCard = VirtualEthernetCard.class.cast(deviceSpec.getDevice());
         connectInfo = new VirtualDeviceConnectInfo();
         connectInfo.setConnected(false);
         connectInfo.setAllowGuestControl(true);
         connectInfo.setStartConnected(true);
         ethernetCard.setConnectable(connectInfo);
         log.info("Got the ethernet card: " + ethernetCard);
         // create a DVS backing to set the backing for given device.
         dvPortBacking = new VirtualEthernetCardDistributedVirtualPortBackingInfo();
         dvPortBacking.setPort(connection);
         ethernetCard.setBacking(dvPortBacking);
      } else {
         log.error("Unable to find the given device type:" + deviceType);
      }
      return vmConfigSpec;
   }

   /**
    * Create a default VMConfigSpec.
    *
    * @param connectAnchor Reference to the ConnectAnchor object
    * @param hostMor The MOR of the host where the defaultVMSpec has to be
    *           created.
    * @param deviceType type of the device.
    * @return vmConfigSpec VirtualMachineConfigSpec.
    * @throws MethodFault, Exception
    */
   public static VirtualMachineConfigSpec buildDefaultSpec(final ConnectAnchor connectAnchor,
                                                           final ManagedObjectReference hostMor,
                                                           final String deviceType)
      throws Exception
   {
      assertNotNull(connectAnchor,
               "Reference to the ConnectAnchor object is not null",
               "Reference to the ConnectAnchor object is null");
      ManagedObjectReference poolMor = null;
      VirtualMachineConfigSpec vmConfigSpec = null;
      final Vector<String> deviceTypesVector = new Vector<String>();
      final HostSystem ihs = new HostSystem(connectAnchor);
      final VirtualMachine ivm = new VirtualMachine(connectAnchor);
      poolMor = ihs.getPoolMor(hostMor);
      assertNotNull(poolMor, "Unable to get the resource pool from the host.");
      deviceTypesVector.add(TestConstants.VM_VIRTUALDEVICE_DISK);
      deviceTypesVector.add(VM_VIRTUALDEVICE_SCSI_BUSL_CONTROLLER);
      deviceTypesVector.add(deviceType);
      // create the VMCfg with the default devices.
      vmConfigSpec = ivm.createVMConfigSpec(poolMor,
               TestUtil.getRandomizedTestId(TestUtil.getShortTime()),
               VM_DEFAULT_GUEST_WINDOWS, deviceTypesVector, null);
      ivm.setDiskCapacityInKB(vmConfigSpec, TestConstants.CLONEVM_DISK);
      return vmConfigSpec;
   }

   /**
    * Returns the virtualMachineConfigSpec to hot add the vm ethernet adapter
    *
    * @param vmConfigSpec VirtualMachineConfigSpec
    * @return VirtualMachineConfigSpec[]
    */
   private static VirtualMachineConfigSpec[] getHotAddVMSpec(VirtualMachineConfigSpec vmConfigSpec)
      throws Exception
   {
      VirtualMachineConfigSpec[] vmConfigSpecs = new VirtualMachineConfigSpec[2];
      VirtualMachineConfigSpec deltaConfigSpec = null;
      if (vmConfigSpec != null) {
         deltaConfigSpec = (VirtualMachineConfigSpec) TestUtil.deepCopyObject(vmConfigSpec);
         if (com.vmware.vcqa.util.TestUtil.vectorToArray(
                  vmConfigSpec.getDeviceChange(),
                  com.vmware.vc.VirtualDeviceConfigSpec.class) != null
                  && com.vmware.vcqa.util.TestUtil.vectorToArray(
                           vmConfigSpec.getDeviceChange(),
                           com.vmware.vc.VirtualDeviceConfigSpec.class).length > 0) {
            for (VirtualDeviceConfigSpec vdConfigSpec : com.vmware.vcqa.util.TestUtil.vectorToArray(
                     vmConfigSpec.getDeviceChange(),
                     com.vmware.vc.VirtualDeviceConfigSpec.class)) {
               if (vdConfigSpec.getDevice() != null
                        && vdConfigSpec.getDevice() instanceof VirtualEthernetCard) {
                  vdConfigSpec.setOperation(VirtualDeviceConfigSpecOperation.REMOVE);
                  vmConfigSpecs[0] = vmConfigSpec;
                  break;
               }
            }
            for (VirtualDeviceConfigSpec vdConfigSpec : com.vmware.vcqa.util.TestUtil.vectorToArray(
                     deltaConfigSpec.getDeviceChange(),
                     com.vmware.vc.VirtualDeviceConfigSpec.class)) {
               if (vdConfigSpec.getDevice() != null
                        && vdConfigSpec.getDevice() instanceof VirtualEthernetCard) {
                  vdConfigSpec.setOperation(VirtualDeviceConfigSpecOperation.ADD);
                  vmConfigSpecs[1] = deltaConfigSpec;
                  break;
               }
            }
         }
      }
      return vmConfigSpecs;
   }

   /**
    * Add pnic to uplink port key
    *
    * @param connectAnchor Reference to the ConnectAnchor object
    * @param hostMor ManagedObjectReference of the host to be added.
    * @param dvsMor Reference to the DV Switch.
    * @param pnicDevice pnic to be added to uplinkPortKey
    * @param uplinkPortgroupKey Reference to the uplink portgroup key
    * @param uplinkPortKey Reference to uplinkPortKey
    * @return true if successful, false otherwise
    * @throws MethodFault, Exception
    */
   public static boolean addPnicsToUplinkPortKey(final ConnectAnchor connectAnchor,
                                                 final ManagedObjectReference hostMor,
                                                 final ManagedObjectReference dvsMor,
                                                 final String pnicDevice,
                                                 final String uplinkPortgroupKey,
                                                 final String uplinkPortKey)
      throws Exception
   {
      boolean result = false;
      DistributedVirtualSwitchHostMemberPnicSpec pnicSpec1 = null;
      if (connectAnchor != null && hostMor != null && dvsMor != null) {
         String hostName = null;
         String dvsName = null;
         HostSystem ihs = null;
         DistributedVirtualSwitch iDVS = null;
         NetworkSystem ins = null;
         DistributedVirtualSwitchHostMemberPnicSpec pnicSpec = null;
         DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
         DistributedVirtualSwitchHostMember pnicHostMember = null;
         DVSConfigInfo dvsConfigInfo = null;
         String validConfigVersion = null;
         DVSConfigSpec deltaConfigSpec = null;
         ihs = new HostSystem(connectAnchor);
         ins = new NetworkSystem(connectAnchor);
         iDVS = new DistributedVirtualSwitch(connectAnchor);
         hostName = ihs.getHostName(hostMor);
         dvsConfigInfo = iDVS.getConfig(dvsMor);

         DistributedVirtualSwitchHostMember[] existingHostMembers = com.vmware.vcqa.util.TestUtil.vectorToArray(
                  dvsConfigInfo.getHost(),
                  com.vmware.vc.DistributedVirtualSwitchHostMember.class);
         for (DistributedVirtualSwitchHostMember existingHostMember : existingHostMembers) {
            if (existingHostMember.getConfig().getHost().equals(hostMor)) {
               pnicHostMember = existingHostMember;
               break;
            }
         }
         // get existing pnicDevices
         final DistributedVirtualSwitchHostMemberPnicBacking existingPnicBacking = (DistributedVirtualSwitchHostMemberPnicBacking) pnicHostMember.getConfig().getBacking();
         if (com.vmware.vcqa.util.TestUtil.vectorToArray(
                  existingPnicBacking.getPnicSpec(),
                  com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec.class) != null) {
            pnicSpec1 = com.vmware.vcqa.util.TestUtil.vectorToArray(
                     existingPnicBacking.getPnicSpec(),
                     com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec.class)[0];
         }
         dvsName = dvsConfigInfo.getName();
         deltaConfigSpec = new DVSConfigSpec();
         pnicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();
         pnicSpec.setPnicDevice(pnicDevice);
         pnicSpec.setUplinkPortKey(uplinkPortKey);
         pnicSpec.setUplinkPortgroupKey(uplinkPortgroupKey);
         final DistributedVirtualSwitchHostMemberConfigSpec hostMember = new DistributedVirtualSwitchHostMemberConfigSpec();
         hostMember.setOperation(TestConstants.CONFIG_SPEC_EDIT);
         hostMember.setHost(hostMor);
         pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
         if (pnicSpec1 != null && !pnicSpec1.getPnicDevice().equals(pnicDevice)) {
            pnicBacking.getPnicSpec().clear();
            pnicBacking.getPnicSpec().addAll(
                     com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] {
                              pnicSpec1, pnicSpec }));
         } else {
            pnicBacking.getPnicSpec().clear();
            pnicBacking.getPnicSpec().addAll(
                     com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] { pnicSpec }));
         }
         hostMember.setBacking(pnicBacking);
         deltaConfigSpec.getHost().clear();
         deltaConfigSpec.getHost().addAll(
                  com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostMember }));
         validConfigVersion = dvsConfigInfo.getConfigVersion();
         deltaConfigSpec.setConfigVersion(validConfigVersion);
         result = iDVS.reconfigure(dvsMor, deltaConfigSpec);
         if (result) {
            log.info("Successfully added " + pnicDevice + " " + hostName
                     + " to DVS " + dvsName);
         } else {
            log.error("Unable to add " + pnicDevice + " " + hostName
                     + " to DVS " + dvsName);
         }
      } else {
         log.warn("Host Mor and/or DVS list is null");
      }
      return result;
   }

   /**
    * Remove pnic from uplink port key
    *
    * @param connectAnchor Reference to the ConnectAnchor object
    * @param hostMor ManagedObjectReference of the host to be added.
    * @param dvsMor Reference to the DV Switch.
    * @param pnicDevice pnic to be added to uplinkPortKey
    * @param uplinkPortgroupKey Reference to the uplink portgroup key
    * @param uplinkPortKey Reference to uplinkPortKey
    * @return true if successful, false otherwise
    * @throws MethodFault, Exception
    */
   public static boolean removePnicFromUplinkPortKey(final ConnectAnchor connectAnchor,
                                                     final ManagedObjectReference hostMor,
                                                     final ManagedObjectReference dvsMor,
                                                     final String pnicDevice,
                                                     final String uplinkPortgroupKey,
                                                     final String uplinkPortKey)
      throws Exception
   {
      boolean result = false;
      if (connectAnchor != null && hostMor != null && dvsMor != null) {
         String hostName = null;
         String dvsName = null;
         HostSystem ihs = null;
         DistributedVirtualSwitch iDVS = null;
         DistributedVirtualSwitchHostMemberPnicSpec pnicSpec = null;
         DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
         DVSConfigInfo dvsConfigInfo = null;
         String validConfigVersion = null;
         DVSConfigSpec deltaConfigSpec = null;
         ihs = new HostSystem(connectAnchor);
         iDVS = new DistributedVirtualSwitch(connectAnchor);
         hostName = ihs.getHostName(hostMor);
         dvsConfigInfo = iDVS.getConfig(dvsMor);
         dvsName = dvsConfigInfo.getName();
         deltaConfigSpec = new DVSConfigSpec();
         pnicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();
         pnicSpec.setPnicDevice(pnicDevice);
         pnicSpec.setUplinkPortKey(uplinkPortKey);
         pnicSpec.setUplinkPortgroupKey(uplinkPortgroupKey);
         final DistributedVirtualSwitchHostMemberConfigSpec hostMember = new DistributedVirtualSwitchHostMemberConfigSpec();
         hostMember.setOperation(TestConstants.CONFIG_SPEC_REMOVE);
         hostMember.setHost(hostMor);
         pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
         pnicBacking.getPnicSpec().clear();
         pnicBacking.getPnicSpec().addAll(
                  com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] { pnicSpec }));
         hostMember.setBacking(pnicBacking);
         deltaConfigSpec.getHost().clear();
         deltaConfigSpec.getHost().addAll(
                  com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostMember }));
         validConfigVersion = dvsConfigInfo.getConfigVersion();
         deltaConfigSpec.setConfigVersion(validConfigVersion);
         result = iDVS.reconfigure(dvsMor, deltaConfigSpec);
         if (result) {
            log.info("Successfully removed " + pnicDevice + " " + hostName
                     + " to DVS " + dvsName);
         } else {
            log.error("Unable to remove" + pnicDevice + " " + hostName
                     + " to DVS " + dvsName);
         }
      } else {
         log.warn("Host Mor and/or DVS list is null");
      }
      return result;
   }

   /**
    * This method compares the portConnection on a VM with a given
    * DistributedVirtualSwitchPortConnection List
    *
    * @param connectAnchor Reference to the ConnectAnchor object
    * @param vmMor MOR of the VirtualMachine
    * @param portConnection DistributedVirtualSwitchPortConnection
    * @return true if successful, false otherwise
    * @throws MethodFault, Exception
    */
   public static boolean verifyPortConnectionOnVM(final ConnectAnchor connectAnchor,
                                                  final ManagedObjectReference vmMor,
                                                  final DistributedVirtualSwitchPortConnection portConnection)
      throws Exception
   {
      assertNotNull(connectAnchor,
               "Reference to the ConnectAnchor object is not null",
               "Reference to the ConnectAnchor object is null");
      assertNotNull(portConnection,
               "Reference to the DistributedVirtualSwitchPortConnection "
                        + " object is not null",
               "Reference to the DistributedVirtualSwitchPortConnection "
                        + " object is null");
      assertNotNull(vmMor, "Reference to the VirtualMachine"
               + " object is not null", "Reference to the VirtualMachine"
               + " object is null");
      boolean result = false;
      VirtualEthernetCardDistributedVirtualPortBackingInfo dvPortBacking = null;
      final List<VirtualDeviceConfigSpec> vdConfigSpec = DVSUtil.getAllVirtualEthernetCardDevices(
               vmMor, connectAnchor);
      assertNotNull(vdConfigSpec, "VirtualDeviceConfigSpec is not null",
               "VirtualDeviceConfigSpec object is null");
      assertTrue((vdConfigSpec != null && vdConfigSpec.size() > 0),
               "virtual ethernet cards on the VM are not null",
               "virtual ethernet cards on the VM is null");
      for (final VirtualDeviceConfigSpec config : vdConfigSpec) {
         assertTrue(
                  (config != null && config.getDevice() != null && config.getDevice().getBacking() != null),
                  "Device  Backing is null");
         if (config.getDevice().getBacking() instanceof VirtualEthernetCardDistributedVirtualPortBackingInfo) {
            dvPortBacking = (VirtualEthernetCardDistributedVirtualPortBackingInfo) config.getDevice().getBacking();
            final DistributedVirtualSwitchPortConnection vmDVPortConn = dvPortBacking.getPort();
            if (TestUtil.compareObject(portConnection, vmDVPortConn,
                     TestUtil.getIgnorePropertyList(portConnection, true))) {
               result = true;
               break;
            }
         }
      }
      if (result) {
         log.info("Successfully verified PortConnectionOnVM");
      } else {
         log.error("Failed to verify PortConnectionOnVM");
      }
      return result;
   }

   /**
    * This method returns the ConnecteeInfo for list of portKeys
    *
    * @param connectAnchor Reference to the ConnectAnchor object
    * @param dvsMor MOR of the DVS
    * @param portKeys portkeys of the moved DVPorts.
    * @return Map of portkeys and Connectee info
    * @throws MethodFault, Exception
    */
   public static Map<String, DistributedVirtualPort> getConnecteeInfo(final ConnectAnchor connectAnchor,
                                                                      final ManagedObjectReference dvsMor,
                                                                      final List<String> portKeys)
      throws Exception
   {
      DistributedVirtualSwitch iDVSwitch = null;
      DistributedVirtualSwitchPortCriteria portCriteria = null;
      DistributedVirtualSwitchPortConnectee connectee = null;
      List<DistributedVirtualPort> dvPorts = null;
      final Map<String, DistributedVirtualPort> connectedEntitiespMap = new HashMap<String, DistributedVirtualPort>();
      assertNotNull(connectAnchor,
               "Reference to the ConnectAnchor object is not null",
               "Reference to the ConnectAnchor object is null");
      assertNotNull(dvsMor,
               "Reference to the DistributedVirtualSwitch object is not null",
               "Reference to the DistributedVirtualSwitch object is null");
      assertNotNull((portKeys != null && portKeys.size() > 0),
               "portKeys is not null", "portKeys " + "  is null");
      iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
      portCriteria = new DistributedVirtualSwitchPortCriteria();
      portCriteria.getPortKey().clear();
      portCriteria.getPortKey().addAll(
               com.vmware.vcqa.util.TestUtil.arrayToVector((portKeys.toArray(new String[portKeys.size()]))));
      dvPorts = iDVSwitch.fetchPorts(dvsMor, portCriteria);
      assertTrue((dvPorts != null && dvPorts.size() > 0),
               "DistributedVirtualPort is not null", "DistributedVirtualPort "
                        + " object is null");
      for (final DistributedVirtualPort dvport : dvPorts) {
         connectee = dvport.getConnectee();
         if (connectee != null && connectee.getConnectedEntity() != null) {
            connectedEntitiespMap.put(dvport.getKey(), dvport);
         }
      }
      return connectedEntitiespMap;
   }

   /**
    * This method verifies the link layer discovery protocol parameters.
    *
    * @param connectAnchor
    * @param hostMor
    * @param vdsMor
    * @param expectedLldpInfo
    * @return boolean
    * @throws MethodFault,Exception
    */
   public static boolean verifyLldpInfo(final ConnectAnchor connectAnchor,
                                        final ManagedObjectReference hostMor,
                                        final ManagedObjectReference vdsMor,
                                        final LinkDiscoveryProtocolConfig expectedLldpInfo)
      throws Exception
   {
      boolean verifyLldp = true;
      assertNotNull(connectAnchor, "The connect anchor is null");
      assertNotNull(vdsMor, "The vds mor is null");
      assertNotNull(hostMor, "The host mor is null");
      final NetworkSystem networkSystem = new NetworkSystem(connectAnchor);
      final ManagedObjectReference nsMor = networkSystem.getNetworkSystem(hostMor);
      final DistributedVirtualSwitchHelper vmwareVds = new DistributedVirtualSwitchHelper(
               connectAnchor);
      /*
       * Check the lldp info on the vds
       */
      final LinkDiscoveryProtocolConfig actualLldpInfo = vmwareVds.getConfig(
               vdsMor).getLinkDiscoveryProtocolConfig();
      verifyLldp &= TestUtil.compareObject(actualLldpInfo, expectedLldpInfo,
               null);
      final String vdsUuid = vmwareVds.getConfig(vdsMor).getUuid();
      /*
       * Check the lldp info retrieved from the host dvs manager
       */
      verifyLldp &= InternalDVSHelper.verifyLldpConfigOnHost(connectAnchor,
               hostMor, vdsUuid, expectedLldpInfo);
      return verifyLldp;
   }

   /**
    * This method verifies the ConnecteeInfo after moveport operation
    *
    * @param connectAnchor Reference to the ConnectAnchor object
    * @param Map of portkeys and Connectee info
    * @param dvsMor MOR of the DVS
    * @param portKeys portkeys of the moved DVPorts.
    * @param destPgKey portgroupKey
    * @return true if successful, false otherwise
    * @throws MethodFault, Exception
    */
   public static boolean verifyConnecteeInfoAfterMovePort(final ConnectAnchor connectAnchor,
                                                          final Map<String, DistributedVirtualPort> connectedEntitiespMap,
                                                          final ManagedObjectReference dvsMor,
                                                          final List<String> portKeys,
                                                          final String destPgKey)
      throws Exception
   {
      DistributedVirtualSwitch iDVSwitch = null;
      boolean result = true;
      DistributedVirtualSwitchPortCriteria portCriteria = null;
      DistributedVirtualSwitchPortConnectee connectee = null;
      DistributedVirtualSwitchPortConnectee origConnectee = null;
      List<DistributedVirtualPort> dvPorts = null;
      DistributedVirtualPort connecteeInfo = null;
      assertNotNull(connectAnchor,
               "Reference to the ConnectAnchor object is not null",
               "Reference to the ConnectAnchor object is null");
      assertNotNull((portKeys != null && portKeys.size() > 0),
               "portKeys is not null", "portKeys " + "  is null");
      iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
      portCriteria = new DistributedVirtualSwitchPortCriteria();
      portCriteria.getPortKey().clear();
      portCriteria.getPortKey().addAll(
               com.vmware.vcqa.util.TestUtil.arrayToVector(portKeys.toArray(new String[portKeys.size()])));
      dvPorts = iDVSwitch.fetchPorts(dvsMor, portCriteria);
      assertTrue((dvPorts != null && dvPorts.size() > 0),
               "DistributedVirtualPort is not null", "DistributedVirtualPort "
                        + " object is null");
      if (connectedEntitiespMap != null && connectedEntitiespMap.size() > 0) {
         result = false;
         for (final DistributedVirtualPort dvport : dvPorts) {
            connectee = dvport.getConnectee();
            if (dvport.getKey() != null && connectee != null
                     && connectee.getConnectedEntity() != null) {
               connecteeInfo = connectedEntitiespMap.get(dvport.getKey());
               assertNotNull(
                        connecteeInfo,
                        "Map of portkeys and DistributedVirtualPort is not null",
                        "Map of portkeys and DistributedVirtualPort is null");
               origConnectee = connecteeInfo.getConnectee();
               assertNotNull(origConnectee, " Connectee info is not null",
                        "Map of portkeys and Connectee info is null");
               final ManagedObjectReference origConnectedEntity = origConnectee.getConnectedEntity();
               final String origType = origConnectee.getType();
               final DistributedVirtualSwitchPortConnection portconn = buildDistributedVirtualSwitchPortConnection(
                        connecteeInfo.getDvsUuid(), connecteeInfo.getKey(),
                        connecteeInfo.getPortgroupKey());
               portconn.setPortgroupKey(destPgKey);
               result = TestUtil.compareObject(connectee.getConnectedEntity(),
                        origConnectedEntity, null, null);
               result &= (connectee.getType().equals(origType));
               if (connectee.getType().equals(
                        DistributedVirtualSwitchPortConnecteeConnecteeType.VM_VNIC.value())) {
                  result &= verifyPortConnectionOnVM(connectAnchor,
                           origConnectedEntity, portconn);
               }
            }
         }
      }
      return result;
   }

   /**
    * Returns the dvs uuid from host proxy vswitch
    *
    * @param connectAnchor Reference to the ConnectAnchor object
    * @param nsMor ManagedObjectReference Object.
    * @return List of the dvs uuids.
    * @throws MethodFault, Exception
    */
   public static List<String> getHostProxyUUID(final ConnectAnchor connectAnchor,
                                               final ManagedObjectReference nsMor)
      throws Exception
   {
      NetworkSystem ins = null;
      String hostProxySwitchUUID = null;
      HostProxySwitch[] proxyVSwitch = null;
      HostNetworkInfo networkInfo = null;
      List<String> hostProxySwitchUUIDList = null;
      assertNotNull(connectAnchor,
               "Reference to the ConnectAnchor object is not null",
               "Reference to the ConnectAnchor object is null");
      assertNotNull(nsMor, "Reference to the NetworkSystem MOR  is not null",
               "Reference to the NetworkSystem MOR is null");
      ins = new NetworkSystem(connectAnchor);
      networkInfo = ins.getNetworkInfo(nsMor);
      assertNotNull(networkInfo, "NetworkInfo is null");
      proxyVSwitch = com.vmware.vcqa.util.TestUtil.vectorToArray(
               networkInfo.getProxySwitch(),
               com.vmware.vc.HostProxySwitch.class);
      if (proxyVSwitch != null) {
         log.info("Network config is null or the host does not"
                  + "have any proxy vswitche");
         hostProxySwitchUUIDList = new Vector<String>(proxyVSwitch.length);
         for (final HostProxySwitch vSwitch : proxyVSwitch) {
            hostProxySwitchUUID = vSwitch.getDvsUuid();
            if (hostProxySwitchUUID != null) {
               hostProxySwitchUUIDList.add(hostProxySwitchUUID);
            }
         }
      } else {
         log.warn("Network config is null or the host does not"
                  + "have any proxy vswitche");
      }
      return hostProxySwitchUUIDList;
   }

   /**
    * Method to reconfigure the Switch with TrafficShapingPolicy
    *
    * @param connectAnchor Reference to the ConnectAnchor object
    * @param dvsMOR DistributedVirtualSwitch MOR
    * @return true if successful, false otherwise.
    * @throws MethodFault, Exception
    */
   public static boolean reconfigureWithTrafficShapingPolicy(final ConnectAnchor connectAnchor,
                                                             final ManagedObjectReference dvsMOR)
      throws Exception
   {
      DistributedVirtualSwitch iDistributedVirtualSwitch = null;
      DVSTrafficShapingPolicy inShapingPolicy = null;
      DVSTrafficShapingPolicy outShapingPolicy = null;
      assertNotNull(connectAnchor,
               "Reference to the ConnectAnchor object is not null",
               "Reference to the ConnectAnchor object is null");
      assertNotNull(dvsMOR,
               "Reference to the DistributedVirtualSwitch object is not null",
               "Reference to the DistributedVirtualSwitch object is null");
      iDistributedVirtualSwitch = new DistributedVirtualSwitch(connectAnchor);
      log.info("Successfully created the DVSwitch");
      final DVSConfigSpec deltaConfigSpec = new DVSConfigSpec();
      final DVPortSetting portSetting = iDistributedVirtualSwitch.getConfig(
               dvsMOR).getDefaultPortConfig();
      inShapingPolicy = portSetting.getInShapingPolicy();
      if (inShapingPolicy == null) {
         inShapingPolicy = DVSUtil.getTrafficShapingPolicy(false, true,
                  new Long(102400), new Long(102400), new Long(102400));
      } else {
         inShapingPolicy.setEnabled(DVSUtil.getBoolPolicy(false, true));
         inShapingPolicy.setPeakBandwidth(DVSUtil.getLongPolicy(false,
                  new Long(102400)));
         inShapingPolicy.setAverageBandwidth(DVSUtil.getLongPolicy(false,
                  new Long(102400)));
         inShapingPolicy.setBurstSize(DVSUtil.getLongPolicy(false, new Long(
                  102400)));
      }
      outShapingPolicy = portSetting.getInShapingPolicy();
      if (outShapingPolicy == null) {
         outShapingPolicy = DVSUtil.getTrafficShapingPolicy(false, true,
                  new Long(102400), new Long(102400), new Long(102400));
      } else {
         outShapingPolicy.setEnabled(DVSUtil.getBoolPolicy(false, true));
         outShapingPolicy.setPeakBandwidth(DVSUtil.getLongPolicy(false,
                  new Long(102400)));
         outShapingPolicy.setAverageBandwidth(DVSUtil.getLongPolicy(false,
                  new Long(102400)));
         outShapingPolicy.setBurstSize(DVSUtil.getLongPolicy(false, new Long(
                  102400)));
      }
      final String validConfigVersion = iDistributedVirtualSwitch.getConfig(
               dvsMOR).getConfigVersion();
      deltaConfigSpec.setConfigVersion(validConfigVersion);
      portSetting.setBlocked(DVSUtil.getBoolPolicy(false, false));
      portSetting.setInShapingPolicy(inShapingPolicy);
      portSetting.setOutShapingPolicy(outShapingPolicy);
      deltaConfigSpec.setDefaultPortConfig(portSetting);
      Assert.assertTrue(
               iDistributedVirtualSwitch.reconfigure(dvsMOR, deltaConfigSpec),
               "Successfully reconfigured DVS", "Failed to reconfigure dvs");
      return true;
   }

   /**
    * Rejoins the host back to VC's vDs by rectifying the configuration
    * descrepencies of the host proxy vDs from the vDs configuration on the VC.
    *
    * @param connectAnchor Reference to the ConnectAnchor object
    * @param hostMors ManagedObjectReference of host
    * @return boolean true if successful, false otherwise
    * @throws MethodFault, Exception
    */
   public static synchronized boolean rejoinProxySwitch(final ConnectAnchor connectAnchor,
                                                        final ManagedObjectReference hostMor)
      throws Exception
   {
      NetworkSystem ins = null;
      Folder ifolder = null;
      String dcName = null;
      DistributedVirtualSwitch iDVS = null;
      ManagedObjectReference nsMor = null;
      List<String> hostProxySwitchUUIDList = null;
      List<ManagedObjectReference> vDsList = null;
      List<ManagedObjectReference> hostMors = null;
      boolean result = false;
      boolean hostExists = false;
      ins = new NetworkSystem(connectAnchor);
      nsMor = ins.getNetworkSystem(hostMor);
      hostProxySwitchUUIDList = DVSUtil.getHostProxyUUID(connectAnchor, nsMor);
      if (hostProxySwitchUUIDList != null && hostProxySwitchUUIDList.size() > 0) {
         iDVS = new DistributedVirtualSwitch(connectAnchor);
         ifolder = new Folder(connectAnchor);
         for (final String dvsuuid : hostProxySwitchUUIDList) {
            hostMors = new Vector<ManagedObjectReference>(1);
            final ManagedObjectReference dcMor = ifolder.getParentNode(hostMor,
                     MORConstants.DC_MOR_TYPE);
            dcName = ifolder.getName(dcMor);
            log.info("dcName :" + dcName);
            vDsList = ifolder.getAllDistributedVirtualSwitch(ifolder.getNetworkFolder(dcMor));
            if (vDsList != null && vDsList.size() > 0) {
               for (final ManagedObjectReference vDsMor : vDsList) {
                  if (dvsuuid.equalsIgnoreCase(iDVS.getConfig(vDsMor).getUuid())) {
                     log.info("Found matching UUID on host");
                     final DVSSummary summary = iDVS.getSummary(vDsMor);
                     if (summary != null) {
                        final ManagedObjectReference[] hosts = com.vmware.vcqa.util.TestUtil.vectorToArray(
                                 summary.getHostMember(),
                                 com.vmware.vc.ManagedObjectReference.class);
                        if (hosts != null && hosts.length > 0) {
                           for (final ManagedObjectReference mor : hosts) {
                              if (mor.equals(hostMor)) {
                                 hostExists = true;
                                 break;
                              }
                           }
                        }
                     }
                     if (!hostExists) {
                        hostMors.add(hostMor);
                        log.info("Rejoining the host to the VC's vDs ");
                        assertTrue(DVSUtil.addHostsUsingReconfigureDVS(vDsMor,
                                 hostMors, connectAnchor),
                                 "Successfully rejoined the host (which has proxy dvs switch )"
                                          + "to vc's VDS",
                                 " Failed rejoin the host (which has proxy dvs switch )"
                                          + "to vc's VDS");
                     } else {
                        log.warn("Host is already part of vDs");
                     }

                     result = true;
                     break;
                  }
               }
            } else {
               log.warn("Failed to find any distributed virtual switch in DC :"
                        + dcName);
               result = true;
            }

         }
      } else {
         log.warn("Failed to find any proxy distributed virtual switch in Host");
         result = true;
      }
      return result;
   }

   /**
    * This method verifies portPersistenceLocation and PorttConnection On VM
    *
    * @param connectAnchor Reference to the ConnectAnchor object
    * @param hostMor ManagedObjectReference for the host
    * @param hostMor ManagedObjectReference for the VM
    * @param portConnection DistributedVirtualSwitchPortConnection
    * @param vDsUUID UUID of the vDs
    * @return boolean true if successful, false otherwise.
    * @throws MethodFault
    * @throws Exception
    */
   public static boolean performVDSPortVerifcation(final ConnectAnchor connectAnchor,
                                                   final ManagedObjectReference hostMor,
                                                   final ManagedObjectReference vmMor,
                                                   final DistributedVirtualSwitchPortConnection portConnection,
                                                   final String vDsUUID)
      throws Exception
   {
      String vmName = null;
      VirtualMachine ivm = null;
      HostSystem ihs = null;

      assertNotNull(connectAnchor,
               "Reference to the ConnectAnchor object is not null",
               "Reference to the ConnectAnchor object is null");
      assertNotNull(hostMor, "Reference to the hostMor is not null",
               "Reference to the hostMor is null");
      assertNotNull(vmMor, "Reference to the vmMor is not null",
               "Reference to the vmMor is null");
      ivm = new VirtualMachine(connectAnchor);
      ihs = new HostSystem(connectAnchor);
      vmName = ivm.getName(vmMor);
      assertTrue(
               ivm.setVMState(vmMor, VirtualMachinePowerState.POWERED_ON, false),
               VM_POWERON_PASS + vmName, VM_POWERON_PASS + vmName);
      log.info("Verify Persistence Location of dvPort...");
      assertTrue(InternalDVSHelper.verifyPortPersistenceLocation(
               new ConnectAnchor(ihs.getHostName(hostMor),
                        connectAnchor.getPort()), vmName, vDsUUID),
               "Verification for PortPersistenceLocation failed");
      log.info("Now verify dvPort Connection on VM...");
      assertTrue(DVSUtil.verifyPortConnectionOnVM(connectAnchor, vmMor,
               portConnection), "Verification for PorttConnectionOnVM failed");
      assertTrue(ivm.setVMState(vmMor, VirtualMachinePowerState.POWERED_OFF,
               false), VM_POWEROFF_PASS + vmName, VM_POWEROFF_FAIL + vmName);
      return true;
   }

   /**
    * This method removes uplinks from vDs
    *
    * @param connectAnchor Reference to the ConnectAnchor object
    * @param hostMor ManagedObjectReference for the host
    * @param vDsMor ManagedObjectReference for the vDs
    * @return if removeUplinks succeeds , false otherwise
    * @throws MethodFault, Exception
    */
   public static boolean removeAllUplinks(final ConnectAnchor connectAnchor,
                                          final ManagedObjectReference hostMor,
                                          final ManagedObjectReference vDsMor)
      throws Exception
   {
      DistributedVirtualSwitch ivDs = null;
      NetworkSystem ins = null;
      ManagedObjectReference nsMor = null;
      HostProxySwitchConfig originalHostProxySwitchConfig = null;
      HostProxySwitchConfig updatedHostProxySwitchConfig = null;
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      final List<DistributedVirtualSwitchHostMemberPnicSpec> pnicSpecList = new ArrayList<DistributedVirtualSwitchHostMemberPnicSpec>();
      HostNetworkConfig updatedNetworkConfig = null;
      assertNotNull(connectAnchor,
               "Reference to the ConnectAnchor object is not null",
               "Reference to the ConnectAnchor object is null");
      assertNotNull(hostMor, "Reference to the hostMor is not null",
               "Reference to the hostMor is null");
      assertNotNull(vDsMor,
               "Reference to the DistributedVirtualSwitch object is not null",
               "Reference to the DistributedVirtualSwitch object is null");
      ins = new NetworkSystem(connectAnchor);
      ivDs = new DistributedVirtualSwitch(connectAnchor);
      nsMor = ins.getNetworkSystem(hostMor);
      assertNotNull(nsMor,
               "Reference to the NetworkSystem mor object is not null",
               "Reference to the NetworkSystem mor object is null");
      originalHostProxySwitchConfig = ivDs.getDVSVswitchProxyOnHost(vDsMor,
               hostMor);
      updatedHostProxySwitchConfig = (HostProxySwitchConfig) TestUtil.deepCopyObject(originalHostProxySwitchConfig);
      updatedHostProxySwitchConfig.setChangeOperation(HostConfigChangeOperation.EDIT.value());
      assertTrue(
               (updatedHostProxySwitchConfig.getSpec() != null
                        && updatedHostProxySwitchConfig.getSpec().getBacking() != null && updatedHostProxySwitchConfig.getSpec().getBacking() instanceof DistributedVirtualSwitchHostMemberPnicBacking),
               " Failed to get HostMemberPnicBacking on vDs");
      pnicBacking = (DistributedVirtualSwitchHostMemberPnicBacking) updatedHostProxySwitchConfig.getSpec().getBacking();
      pnicBacking.getPnicSpec().clear();
      pnicBacking.getPnicSpec().addAll(
               com.vmware.vcqa.util.TestUtil.arrayToVector(pnicSpecList.toArray(new DistributedVirtualSwitchHostMemberPnicSpec[pnicSpecList.size()])));
      updatedHostProxySwitchConfig.getSpec().setBacking(pnicBacking);
      updatedNetworkConfig = new HostNetworkConfig();
      assertNotNull(updatedHostProxySwitchConfig,
               "Failed to get HostProxySwitchConfig");
      updatedNetworkConfig.getProxySwitch().clear();
      updatedNetworkConfig.getProxySwitch().addAll(
               com.vmware.vcqa.util.TestUtil.arrayToVector(new HostProxySwitchConfig[] { updatedHostProxySwitchConfig }));
      return ins.updateNetworkConfig(nsMor, updatedNetworkConfig,
               TestConstants.CHANGEMODE_MODIFY);

   }

   /**
    * This method add uplinks to vDs
    *
    * @param connectAnchor Reference to the ConnectAnchor object
    * @param hostMor ManagedObjectReference for the host
    * @param vDsMor ManagedObjectReference for the vDs
    * @param hmUplinks map of vmnics and List. First element in List represents
    *           uplink portgroupkey and second element represents porykey for
    *           uplinkport
    * @return if addUplinks succeeds , false otherwise
    * @throws MethodFault, Exception
    */
   public static boolean addUplinks(final ConnectAnchor connectAnchor,
                                    final ManagedObjectReference hostMor,
                                    final ManagedObjectReference vDsMor,
                                    final Map<String, List<String>> hmUplinks)
      throws Exception
   {
      DistributedVirtualSwitch ivDs = null;
      NetworkSystem ins = null;
      ManagedObjectReference nsMor = null;
      HostProxySwitchConfig originalHostProxySwitchConfig = null;
      HostProxySwitchConfig updatedHostProxySwitchConfig = null;
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      DistributedVirtualSwitchHostMemberPnicSpec pnicSpec = null;
      final List<DistributedVirtualSwitchHostMemberPnicSpec> pnicSpecList = new ArrayList<DistributedVirtualSwitchHostMemberPnicSpec>();
      HostNetworkConfig updatedNetworkConfig = null;

      assertNotNull(connectAnchor,
               "Reference to the ConnectAnchor object is not null",
               "Reference to the ConnectAnchor object is null");
      assertNotNull(hostMor, "Reference to the hostMor is not null",
               "Reference to the hostMor is null");
      assertNotNull(vDsMor,
               "Reference to the DistributedVirtualSwitch object is not null",
               "Reference to the DistributedVirtualSwitch object is null");
      ins = new NetworkSystem(connectAnchor);
      ivDs = new DistributedVirtualSwitch(connectAnchor);
      nsMor = ins.getNetworkSystem(hostMor);
      assertNotNull(nsMor,
               "Reference to the NetworkSystem mor object is not null",
               "Reference to the NetworkSystem mor object is null");
      originalHostProxySwitchConfig = ivDs.getDVSVswitchProxyOnHost(vDsMor,
               hostMor);
      updatedHostProxySwitchConfig = (HostProxySwitchConfig) TestUtil.deepCopyObject(originalHostProxySwitchConfig);
      updatedHostProxySwitchConfig.setChangeOperation(HostConfigChangeOperation.EDIT.value());
      assertTrue(
               (updatedHostProxySwitchConfig.getSpec() != null
                        && updatedHostProxySwitchConfig.getSpec().getBacking() != null && updatedHostProxySwitchConfig.getSpec().getBacking() instanceof DistributedVirtualSwitchHostMemberPnicBacking),
               " Failed to get HostMemberPnicBacking on vDs");
      pnicBacking = (DistributedVirtualSwitchHostMemberPnicBacking) updatedHostProxySwitchConfig.getSpec().getBacking();
      for (final Map.Entry<String, List<String>> entry : hmUplinks.entrySet()) {
         pnicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();
         pnicSpec.setPnicDevice(entry.getKey());
         pnicSpec.setUplinkPortgroupKey(entry.getValue().get(0));
         pnicSpec.setUplinkPortKey(entry.getValue().get(1));
         pnicSpecList.add(pnicSpec);
      }

      pnicBacking.getPnicSpec().clear();
      pnicBacking.getPnicSpec().addAll(
               com.vmware.vcqa.util.TestUtil.arrayToVector(pnicSpecList.toArray(new DistributedVirtualSwitchHostMemberPnicSpec[pnicSpecList.size()])));
      updatedHostProxySwitchConfig.getSpec().setBacking(pnicBacking);
      updatedNetworkConfig = new HostNetworkConfig();
      assertNotNull(updatedHostProxySwitchConfig,
               "Failed to get HostProxySwitchConfig");

      updatedNetworkConfig.getProxySwitch().clear();
      updatedNetworkConfig.getProxySwitch().addAll(
               com.vmware.vcqa.util.TestUtil.arrayToVector(new HostProxySwitchConfig[] { updatedHostProxySwitchConfig }));
      return ins.updateNetworkConfig(nsMor, updatedNetworkConfig,
               TestConstants.CHANGEMODE_MODIFY);

   }

   /**
    * This method returns the Distributed Virtual Switch MOR
    *
    * @param connectAnchor Reference to the ConnectAnchor object
    * @param hostMors list of hosts to be added to DVS
    * @param maxports Max proxy switch ports
    * @param vDsName name of Distributed Virtual Switch
    * @return Distributed Virtual Switch MOR
    * @throws MethodFault, Exception
    */
   public static ManagedObjectReference createDVSWithMAXPorts(final ConnectAnchor connectAnchor,
                                                              final List<ManagedObjectReference> hostMors,
                                                              final int maxports,
                                                              String vDsName)
      throws Exception
   {
      String[] freePnics = null;
      ManagedObjectReference vDsMor = null;
      DistributedVirtualSwitch ivDs = null;
      NetworkSystem ins = null;
      HostSystem ihs = null;
      Folder ifolder = null;
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      DistributedVirtualSwitchHostMemberPnicSpec pnicSpec = null;
      DVSConfigSpec dvsConfigSpec = null;
      assertNotNull(connectAnchor,
               "Reference to the ConnectAnchor object is not null",
               "Reference to the ConnectAnchor object is null");
      ihs = new HostSystem(connectAnchor);
      ins = new NetworkSystem(connectAnchor);
      ivDs = new DistributedVirtualSwitch(connectAnchor);
      ifolder = new Folder(connectAnchor);
      final DistributedVirtualSwitchHostMemberConfigSpec[] hostMemberList = new DistributedVirtualSwitchHostMemberConfigSpec[hostMors.size()];
      for (int i = 0; i < hostMors.size(); i++) {
         final ManagedObjectReference hostMor = hostMors.get(i);
         assertNotNull(hostMor, "Reference to the hostMor is not null",
                  "Reference to the hostMor is null");
         freePnics = ins.getPNicIds(hostMor);
         Assert.assertTrue(freePnics != null && freePnics[0] != null,
                  "There are no free pnics on " + ihs.getHostName(hostMor));
         hostMemberList[i] = new DistributedVirtualSwitchHostMemberConfigSpec();
         hostMemberList[i].setOperation(TestConstants.CONFIG_SPEC_ADD);
         hostMemberList[i].setHost(hostMor);
         hostMemberList[i].setMaxProxySwitchPorts(maxports);
         pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
         pnicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();
         pnicSpec.setPnicDevice(freePnics[0]);
         pnicBacking.getPnicSpec().clear();
         pnicBacking.getPnicSpec().addAll(
                  com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] { pnicSpec }));
         hostMemberList[i].setBacking(pnicBacking);
      }
      dvsConfigSpec = new DVSConfigSpec();
      dvsConfigSpec.setConfigVersion("");
      vDsName = (vDsName == null) ? (connectAnchor.getHostName() + "_vDs")
               : vDsName;
      dvsConfigSpec.setName(vDsName);
      dvsConfigSpec.getHost().clear();
      dvsConfigSpec.getHost().addAll(
               com.vmware.vcqa.util.TestUtil.arrayToVector(hostMemberList));
      final String[] uplinkPortNames = new String[] { "Uplink1" };
      final DVSNameArrayUplinkPortPolicy uplinkPolicyInst = new DVSNameArrayUplinkPortPolicy();
      uplinkPolicyInst.getUplinkPortName().clear();
      uplinkPolicyInst.getUplinkPortName().addAll(
               com.vmware.vcqa.util.TestUtil.arrayToVector(uplinkPortNames));
      dvsConfigSpec.setUplinkPortPolicy(uplinkPolicyInst);
      vDsMor = ifolder.createDistributedVirtualSwitch(
               ifolder.getNetworkFolder(ifolder.getDataCenter()), dvsConfigSpec);
      Assert.assertTrue(
               vDsMor != null
                        && ivDs.validateDVSConfigSpec(vDsMor, dvsConfigSpec,
                                 null), "Created DVS Switch:" + vDsName,
               "Failed to Create DVS Switch: " + vDsName);
      return vDsMor;
   }

   /**
    * This method creates given number of VMs with ethernetCards on host
    *
    * @param connectAnchor Reference to the ConnectAnchor object
    * @param hostMor ManagedObjectReference of the host
    * @param vmCount Number of virtual machine to be created
    * @param ethernetCardCount Number of VirtualEthernetCards to be added to
    *           each VM
    * @return List of newly created vms
    * @throws MethodFault,Exception
    */
   public static Vector<ManagedObjectReference> createVms(final ConnectAnchor connectAnchor,
                                                          final ManagedObjectReference hostMor,
                                                          final int vmCount,
                                                          final int ethernetCardCount)
      throws Exception
   {
      VirtualMachine ivm = null;
      HostSystem ihs = null;
      final Vector<ManagedObjectReference> newVms = new Vector<ManagedObjectReference>(
               vmCount);
      ManagedObjectReference vmMor = null;
      String vmName = null;
      VirtualMachineConfigSpec vmConfigSpec = null;
      assertNotNull(connectAnchor,
               "Reference to the ConnectAnchor object is not null",
               "Reference to the ConnectAnchor object is null");
      assertNotNull(hostMor, "Reference to the hostMor is not null",
               "Reference to the hostMor is null");
      ivm = new VirtualMachine(connectAnchor);
      ihs = new HostSystem(connectAnchor);
      final ManagedObjectReference rpMor = ihs.getPoolMor(hostMor);
      for (int i = 0; i < vmCount; i++) {
         vmName = TestUtil.getRandomizedTestId("VM-" + i + "-");
         log.info("Creating VM '{}' with '{}' Nics.", vmName, ethernetCardCount);
         vmConfigSpec = DVSUtil.buildDefaultSpec(connectAnchor, rpMor,
                  VM_VIRTUALDEVICE_ETHERNET_PCNET32, vmName, ethernetCardCount);
         vmMor = new Folder(connectAnchor).createVM(ivm.getVMFolder(),
                  vmConfigSpec, rpMor, null);
         assertNotNull(vmMor, VM_CREATE_PASS + ":" + vmName, VM_CREATE_FAIL
                  + ":" + vmName);
         newVms.add(vmMor);
      }
      return newVms;
   }

   /**
    * This method creates given number of VMs with ethernetCards on host
    *
    * @param connectAnchor Reference to the ConnectAnchor object
    * @param hostMor ManagedObjectReference of the host
    * @param vmCount Number of virtual machine to be created
    * @param legacyNetworkCount
    * @param dvPortConnection List of DistributedVirtualSwitchPortConnection
    * @return List of newly created vms
    * @throws MethodFault,Exception
    */
   public static List<ManagedObjectReference> createVms(final ConnectAnchor connectAnchor,
                                                        final ManagedObjectReference hostMor,
                                                        final int vmCount,
                                                        final int legacyNetworkCount,
                                                        final List<DistributedVirtualSwitchPortConnection> dvPortConnection)
      throws Exception
   {
      VirtualMachine ivm = null;
      HostSystem ihs = null;
      final List<ManagedObjectReference> newVms = new Vector<ManagedObjectReference>(
               vmCount);
      ManagedObjectReference vmMor = null;
      String vmName = null;
      HashMap deviceSpecMap = null;
      Iterator deviceSpecItr = null;
      VirtualDeviceConfigSpec deviceSpec = null;
      VirtualEthernetCard ethernetCard = null;
      VirtualMachineConfigSpec vmConfigSpec = null;
      int ethernetCardCount = 0;
      assertNotNull(connectAnchor,
               "Reference to the ConnectAnchor object is not null",
               "Reference to the ConnectAnchor object is null");
      assertNotNull(hostMor, "Reference to the hostMor is not null",
               "Reference to the hostMor is null");
      ivm = new VirtualMachine(connectAnchor);
      ihs = new HostSystem(connectAnchor);
      final ManagedObjectReference rpMor = ihs.getPoolMor(hostMor);
      for (int i = 0; i < vmCount; i++) {
         vmName = TestUtil.getRandomizedTestId("VM-" + i + "-");
         if (dvPortConnection != null && dvPortConnection.size() > 0) {
            ethernetCardCount += dvPortConnection.size();
         }
         if (legacyNetworkCount > 0) {
            ethernetCardCount += (legacyNetworkCount - 1);
         }
         log.info("Creating VM '{}' with '{}' Nics.", vmName,
                  ethernetCardCount + 1);
         vmConfigSpec = DVSUtil.buildDefaultSpec(connectAnchor, rpMor,
                  VM_VIRTUALDEVICE_ETHERNET_PCNET32, vmName, ethernetCardCount);

         if (dvPortConnection != null && dvPortConnection.size() > 0) {
            log.info("Creating : " + dvPortConnection.size()
                     + "dvsPortCount on VM :" + vmName);
            // now change the backing for the ethernet card.
            deviceSpecMap = ivm.getVirtualDeviceSpec(vmConfigSpec,
                     VM_VIRTUALDEVICE_ETHERNET_PCNET32);
            deviceSpecItr = deviceSpecMap.values().iterator();
            int k = 0;
            while (deviceSpecItr.hasNext() && k < dvPortConnection.size()) {
               deviceSpec = (VirtualDeviceConfigSpec) deviceSpecItr.next();
               if (deviceSpec != null
                        && deviceSpec.getDevice() != null
                        && deviceSpec.getDevice() instanceof VirtualEthernetCard) {

                  VirtualDeviceConnectInfo connectInfo = null;
                  ethernetCard = VirtualEthernetCard.class.cast(deviceSpec.getDevice());
                  log.info("Got the ethernet card: " + ethernetCard);
                  // create a DVS backing to set the backing for given
                  // device.
                  VirtualEthernetCardDistributedVirtualPortBackingInfo dvPortBacking = new VirtualEthernetCardDistributedVirtualPortBackingInfo();
                  dvPortBacking.setPort(dvPortConnection.get(k));
                  ethernetCard.setBacking(dvPortBacking);
                  connectInfo = new VirtualDeviceConnectInfo();
                  connectInfo.setAllowGuestControl(false);
                  connectInfo.setConnected(true);
                  connectInfo.setStartConnected(true);
                  ethernetCard.setConnectable(connectInfo);
                  k++;
               }
            }
         }
         vmMor = new Folder(connectAnchor).createVM(ivm.getVMFolder(),
                  vmConfigSpec, rpMor, null);
         assertNotNull(vmMor, VM_CREATE_PASS + ":" + vmName, VM_CREATE_FAIL
                  + ":" + vmName);
         newVms.add(vmMor);
      }
      return newVms;
   }

   /**
    * This method creates new upLinkPortGroup
    *
    * @param connectAnchor Reference to the ConnectAnchor object
    * @param vDsMor ManagedObjectReference for the vDs
    * @param upLinkPortGroupName name of the upLinkPortGroup
    * @param numPort number of ports to create.
    * @return ManagedObjectReference of UplinkPortGroup
    * @throws MethodFault,Exception
    */
   public static ManagedObjectReference createUplinkPortGroup(final ConnectAnchor connectAnchor,
                                                              final ManagedObjectReference vDsMor,
                                                              String upLinkPortGroupName,
                                                              final int numPort)
      throws Exception
   {
      DistributedVirtualSwitch ivDs = null;
      List<ManagedObjectReference> dvPortgroupMorList = null;
      DVSConfigSpec deltaConfigSpec = null;
      DVPortgroupConfigSpec spec = null;
      ManagedObjectReference uplinkPortGroupMor = null;
      assertNotNull(connectAnchor,
               "Reference to the ConnectAnchor object is not null",
               "Reference to the ConnectAnchor object is null");
      assertNotNull(vDsMor,
               "Reference to the DistributedVirtualSwitch object is not null",
               "Reference to the DistributedVirtualSwitch object is null");
      ivDs = new DistributedVirtualSwitch(connectAnchor);
      deltaConfigSpec = new DVSConfigSpec();
      spec = DVSUtil.buildDVPortgroupConfigSpec(
               DistributedVirtualPortgroupPortgroupType.EARLY_BINDING.value(),
               numPort, null);
      upLinkPortGroupName = (upLinkPortGroupName != null) ? upLinkPortGroupName
               : connectAnchor.getHostName() + "UPG";
      spec.setName(upLinkPortGroupName);
      dvPortgroupMorList = ivDs.addPortGroups(vDsMor,
               new DVPortgroupConfigSpec[] { spec });
      assertNotNull(dvPortgroupMorList, " portgroups successfully"
               + " added to  dvswitch :" + upLinkPortGroupName,
               "Failed to add the portgroups to the" + " dvswitch : "
                        + upLinkPortGroupName);

      final List<ManagedObjectReference> dvUplinkPortgroupMorList = ivDs.getUplinkPortgroups(vDsMor);

      assertTrue(
               (dvUplinkPortgroupMorList != null && dvUplinkPortgroupMorList.size() > 0),
               "Failed to obtain  get :" + upLinkPortGroupName);

      dvUplinkPortgroupMorList.addAll(dvPortgroupMorList);
      deltaConfigSpec.getUplinkPortgroup().clear();
      deltaConfigSpec.getUplinkPortgroup().addAll(
               com.vmware.vcqa.util.TestUtil.arrayToVector((ManagedObjectReference[]) TestUtil.vectorToArray((Vector) dvUplinkPortgroupMorList)));
      deltaConfigSpec.setConfigVersion(ivDs.getConfig(vDsMor).getConfigVersion());
      Assert.assertTrue(ivDs.reconfigure(vDsMor, deltaConfigSpec),
               "Reconfigured dvs with new uplinkPortGroup",
               "Failure to reconfigure dvs with new uplinkPortGroup");
      uplinkPortGroupMor = dvPortgroupMorList.get(0);
      return uplinkPortGroupMor;

   }

   /**
    * Method to create IpfixConfig object with specified parameters
    *
    * @param collectorIpAddress - Ip address of the Collector
    * @param collectorPort - Port of the Collector
    * @param activeFlowTimeout - ActiveFlowTimeout value
    * @param idleFlowTimeout - idle Flow Timeout value
    * @param samplingRate - Sampling rate value
    * @param internalFloswOnly - InternalFlowOnly
    * @return VMwareIpfixConfig object
    * @throws Exception
    */
   public static VMwareIpfixConfig createIpfixConfig(final String collectorIpAddress,
                                                     final int collectorPort,
                                                     final int activeFlowTimeout,
                                                     final int idleFlowTimeout,
                                                     final int samplingRate,
                                                     final boolean internalFlowsOnly)
      throws Exception
   {
      final VMwareIpfixConfig ipfix = new VMwareIpfixConfig();
      ipfix.setCollectorIpAddress(collectorIpAddress);
      ipfix.setCollectorPort(collectorPort);
      ipfix.setActiveFlowTimeout(activeFlowTimeout);
      ipfix.setIdleFlowTimeout(idleFlowTimeout);
      ipfix.setSamplingRate(samplingRate);
      ipfix.setInternalFlowsOnly(internalFlowsOnly);
      return ipfix;
   }

   /**
    * Method to verify IpfixConfig Settings
    *
    * @param connectAnchor - Connect Anchor to the VC
    * @param hostName - Hostname
    * @param dvsUUID - UUID of the DVS created
    * @param dvsMor - DVS Mor
    * @param expectedIpfixConfig - expected IpfixConfig object
    * @return true - if the actual IpfixConfig Spec is equal to the expected
    *         false - otherwise
    * @throws Exception
    */
   public static boolean verifyIpfixConfig(final ConnectAnchor connectAnchor,
                                           final String hostName,
                                           final String dvsUUID,
                                           final ManagedObjectReference dvsMor,
                                           final VMwareIpfixConfig expectedIpfixConfig)
      throws Exception
   {
      boolean verified = false;
      final DistributedVirtualSwitchHelper iVMWareDVS = new DistributedVirtualSwitchHelper(
               connectAnchor);
      final VMwareIpfixConfig currentConfig = iVMWareDVS.getConfigSpec(dvsMor).getIpfixConfig();
      Vector<String> ignorePropertyList = TestUtil.getIgnorePropertyList(
               currentConfig, false);
      String newPropertyAfterOP = "VMwareIpfixConfig.ObservationDomainId";
      if (getvDsVersion().compareTo(DVSTestConstants.VDS_VERSION_60) < 0) {
         ignorePropertyList.add(newPropertyAfterOP);
      }
      Assert.assertTrue(TestUtil.compareObject(currentConfig,
               expectedIpfixConfig, ignorePropertyList, null),
               "Actual IpfixConfig differs from Expected IpfixConfig Object");
      verified = true;
      if (hostName != null) {
         verified &= InternalDVSHelper.verifyIpfixConfigOnHost(connectAnchor,
                  hostName, dvsUUID, expectedIpfixConfig);
      }
      return verified;
   }

   /**
    * Method to verify PortSettings from Parent
    *
    * @param connectAnchor
    * @param dvsMor
    * @param parentPortSetting
    * @param portKeys
    * @return true - if successfull otherwise false
    * @throws Exception
    */
   public static boolean verifyIpfixPortSettingFromParent(final ConnectAnchor connectAnchor,
                                                          final ManagedObjectReference dvsMor,
                                                          final VMwareDVSPortSetting parentPortSetting,
                                                          final List<String> portKeys)
      throws Exception
   {
      boolean verified = false;
      final DistributedVirtualSwitchHelper vmwareDVS = new DistributedVirtualSwitchHelper(
               connectAnchor);
      final DVPortConfigSpec[] specs = vmwareDVS.getPortConfigSpec(dvsMor,
               portKeys.toArray(new String[0]));
      for (final DVPortConfigSpec spec : specs) {
         if (((VMwareDVSPortSetting) spec.getSetting()).getIpfixEnabled().isInherited()) {
            final Vector<String> ignoreProp = TestUtil.getIgnorePropertyList(
                     parentPortSetting.getIpfixEnabled(), false);
            ignoreProp.add(DVSTestConstants.BOOLPOLICY_INHERITED);
            verified = TestUtil.compareObject(
                     ((VMwareDVSPortSetting) spec.getSetting()).getIpfixEnabled(),
                     parentPortSetting.getIpfixEnabled(), ignoreProp, null);
            if (verified == false) {
               break;
            }
         } else {
            // no verification to be done.
            verified = true;
            continue;
         }
      }
      return verified;
   }

   /**
    * Method to get FeatureCapability for given DVS
    *
    * @param connectAnchor
    * @param dvsMor
    * @return DVSFeatureCapability
    * @throws Exception
    */
   public static DVSFeatureCapability getFeatureCapability(final ConnectAnchor connectAnchor,
                                                           final ManagedObjectReference dvsMor)
      throws Exception
   {
      DistributedVirtualSwitchManager dvsManager = null;
      DistributedVirtualSwitchProductSpec productSpec = null;
      assertNotNull(connectAnchor,
               "Reference to the ConnectAnchor object is not null",
               "Reference to the ConnectAnchor object is null");
      assertNotNull(dvsMor,
               "Reference to the DistributedVirtualSwitch object is not null",
               "Reference to the DistributedVirtualSwitch object is null");
      productSpec = DVSUtil.getProductSpec(dvsMor, connectAnchor);
      assertNotNull(productSpec, "Vesrion :  " + productSpec.getVersion(),
               "ProductSpec is null");
      dvsManager = new DistributedVirtualSwitchManager(connectAnchor);
      return dvsManager.queryDvsFeatureCapability(
               dvsManager.getDvSwitchManager(), productSpec);
   }

   /**
    * Method to reconfigure dvs with IpfixConfig(netflow)
    *
    * @param connectAnchor
    * @param dvsMor
    * @param hostMor
    * @return true - if successfull otherwise false
    * @throws Exception
    */
   public static boolean addIpfixConfig(final ConnectAnchor connectAnchor,
                                        final ManagedObjectReference dvsMor,
                                        final ManagedObjectReference hostMor)
      throws Exception
   {
      DistributedVirtualSwitch DVS = null;
      VMwareDVSFeatureCapability featureCapability = null;
      HostSystem hostSystem = null;
      assertNotNull(connectAnchor,
               "Reference to the ConnectAnchor object is not null",
               "Reference to the ConnectAnchor object is null");
      assertNotNull(dvsMor,
               "Reference to the DistributedVirtualSwitch object is not null",
               "Reference to the DistributedVirtualSwitch object is null");
      DVS = new DistributedVirtualSwitch(connectAnchor);
      featureCapability = (VMwareDVSFeatureCapability) DVSUtil.getFeatureCapability(
               connectAnchor, dvsMor);
      assertNotNull(featureCapability,
               "Reference to the featureCapability object is null");
      if (featureCapability.isIpfixSupported()) {
         VMwareDVSConfigSpec deltaConfigSpec = new VMwareDVSConfigSpec();
         final DistributedVirtualSwitchHelper iVMWareDVS = new DistributedVirtualSwitchHelper(
                  connectAnchor);
         VMwareIpfixConfig expectedIpfixConfig = iVMWareDVS.getConfigSpec(
                  dvsMor).getIpfixConfig();
         expectedIpfixConfig.setCollectorIpAddress("100.100.100.100");
         expectedIpfixConfig.setCollectorPort(10);
         expectedIpfixConfig.setActiveFlowTimeout(300);
         expectedIpfixConfig.setIdleFlowTimeout(10);
         expectedIpfixConfig.setSamplingRate(10);
         expectedIpfixConfig.setInternalFlowsOnly(true);
         expectedIpfixConfig.setObservationDomainId(1L);
         deltaConfigSpec.setIpfixConfig(expectedIpfixConfig);
         deltaConfigSpec.setConfigVersion(DVS.getConfig(dvsMor).getConfigVersion());
         Assert.assertTrue(DVS.reconfigure(dvsMor, deltaConfigSpec),
                  "Failed to reconfigure dvs.");
         if (hostMor != null) {
            hostSystem = new HostSystem(connectAnchor);
            Assert.assertTrue(DVSUtil.verifyIpfixConfig(connectAnchor,
                     hostSystem.getHostName(hostMor),
                     DVS.getConfig(dvsMor).getUuid(), dvsMor,
                     expectedIpfixConfig),
                     " Successfully verified IpfixConfig Settings",
                     "Failed to verify IpfixConfig Settings");
         }
      } else {
         log.warn("IpfixConfig is not supported on DVS");
      }
      return true;
   }

   /**
    * Method to reconfigure dvs with lldp parameters
    *
    * @param connectAnchor
    * @param dvsMor
    * @param hostMor
    * @return true - if successfull otherwise false
    * @throws Exception
    */
   public static boolean addLLDP(final ConnectAnchor connectAnchor,
                                 final ManagedObjectReference dvsMor,
                                 final ManagedObjectReference hostMor)
      throws Exception
   {
      DistributedVirtualSwitch DVS = null;
      VMwareDVSFeatureCapability featureCapability = null;
      assertNotNull(connectAnchor,
               "Reference to the ConnectAnchor object is not null",
               "Reference to the ConnectAnchor object is null");
      assertNotNull(dvsMor,
               "Reference to the DistributedVirtualSwitch object is not null",
               "Reference to the DistributedVirtualSwitch object is null");
      DVS = new DistributedVirtualSwitch(connectAnchor);
      featureCapability = (VMwareDVSFeatureCapability) DVSUtil.getFeatureCapability(
               connectAnchor, dvsMor);
      assertNotNull(featureCapability,
               "Reference to the featureCapability object is null");
      if (featureCapability.isLldpSupported()) {
         VMwareDVSConfigSpec deltaConfigSpec = new VMwareDVSConfigSpec();
         deltaConfigSpec.setConfigVersion(DVS.getConfig(dvsMor).getConfigVersion());
         LinkDiscoveryProtocolConfig linkDiscoveryProtocolConfig = new LinkDiscoveryProtocolConfig();
         linkDiscoveryProtocolConfig.setOperation("both");
         linkDiscoveryProtocolConfig.setProtocol("lldp");
         deltaConfigSpec.setLinkDiscoveryProtocolConfig(linkDiscoveryProtocolConfig);
         /*
          * Reconfigure the vds to set the link layer discovery parameters
          */
         assertTrue(DVS.reconfigure(dvsMor, deltaConfigSpec),
                  "Successfully reconfigured the vds by setting LLDP",
                  "Failed to reconfigure " + "the vds by setting LLDP");
         if (hostMor != null) {
            assertTrue(DVSUtil.verifyLldpInfo(connectAnchor, hostMor, dvsMor,
                     linkDiscoveryProtocolConfig), "The expected "
                     + "and actual lldp parameters match",
                     "The expected and actual " + "lldp parameter do not match");
         }
      } else {
         log.warn("lldp is not supported on DVS");
      }
      return true;
   }

   /**
    * Method to enable Netiorm on DVS
    *
    * @param connectAnchor
    * @param dvsMor
    * @return true - if successfull otherwise false
    * @throws Exception
    */
   public static boolean enableNetiorm(final ConnectAnchor connectAnchor,
                                       final ManagedObjectReference dvsMor)
      throws Exception
   {
      DistributedVirtualSwitch DVS = null;
      DVSFeatureCapability featureCapability = null;
      assertNotNull(connectAnchor,
               "Reference to the ConnectAnchor object is not null",
               "Reference to the ConnectAnchor object is null");
      assertNotNull(dvsMor,
               "Reference to the DistributedVirtualSwitch object is not null",
               "Reference to the DistributedVirtualSwitch object is null");
      DVS = new DistributedVirtualSwitch(connectAnchor);
      featureCapability = DVSUtil.getFeatureCapability(connectAnchor, dvsMor);
      assertNotNull(featureCapability,
               "Reference to the featureCapability object is null");
      if (featureCapability.isNetworkResourceManagementSupported()) {
         // enable netiorm
         Assert.assertTrue(DVS.enableNetworkResourceManagement(dvsMor, true),
                  "Netiorm not enabled");
         Assert.assertTrue(
                  NetworkResourcePoolHelper.isNrpEnabled(connectAnchor, dvsMor),
                  "NRP enabled on the dvs", "NRP is not enabled on the dvs");
      } else {
         log.warn("NETIORM is not supported on DVS ");
      }
      return true;
   }

   /**
    * This method removes host from DVS
    *
    * @param connectAnchor Reference to the ConnectAnchor object
    * @param hostMor ManagedObjectReference of the host to be added.
    * @param dvsMor Reference to the DV Switch.
    * @return true if successful, false otherwise
    * @throws MethodFault, Exception
    */
   public static boolean removeHostFromDVS(final ConnectAnchor connectAnchor,
                                           final ManagedObjectReference hostMor,
                                           final ManagedObjectReference dvsMor)
      throws Exception
   {
      boolean result = false;
      assertNotNull(connectAnchor,
               "Reference to the ConnectAnchor object is not null",
               "Reference to the ConnectAnchor object is null");
      assertNotNull(dvsMor,
               "Reference to the DistributedVirtualSwitch object is not null",
               "Reference to the DistributedVirtualSwitch object is null");
      assertNotNull(hostMor, "Reference to the hostMor object is not null",
               "Reference to the hostMor object is null");
      String hostName = null;
      String dvsName = null;
      HostSystem hostSystem = null;
      DistributedVirtualSwitch DVS = null;
      DVSConfigInfo dvsConfigInfo = null;
      DVSConfigSpec deltaConfigSpec = null;
      hostSystem = new HostSystem(connectAnchor);
      DVS = new DistributedVirtualSwitch(connectAnchor);
      hostName = hostSystem.getHostName(hostMor);
      dvsConfigInfo = DVS.getConfig(dvsMor);
      dvsName = dvsConfigInfo.getName();
      deltaConfigSpec = new DVSConfigSpec();
      final DistributedVirtualSwitchHostMemberConfigSpec hostMember = new DistributedVirtualSwitchHostMemberConfigSpec();
      hostMember.setOperation(TestConstants.CONFIG_SPEC_REMOVE);
      hostMember.setHost(hostMor);
      deltaConfigSpec.getHost().clear();
      deltaConfigSpec.getHost().addAll(
               com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostMember }));
      deltaConfigSpec.setConfigVersion(dvsConfigInfo.getConfigVersion());
      result = DVS.reconfigure(dvsMor, deltaConfigSpec);
      if (result) {
         log.info("Successfully removed host " + hostName + " from DVS "
                  + dvsName);
      } else {
         log.error("Unable to remove host" + hostName + " from DVS " + dvsName);
      }
      return result;
   }

   /**
    * This method returns a VirtualMachineConfigSpec for changing a VM's VNIC to
    * have a DVPort Backing
    *
    * @param vmMor ManagedObjectReference for the VM
    * @param anchor ConnectAnchor object
    * @param mapNicNmeDVPortConnection Map of vnic and
    *           DistributedVirtualSwitchPortConnection
    * @return VirtualMachineConfigSpec[] deltaConfigSpec
    *         VirtualMachineConfigSpec[0] contains the updated delta config spec
    *         and VirtualMachineConfigSpec[1] contains the delta config spec to
    *         restore the original conifg spec of the VM to be updated in the
    *         test cleanup
    * @throws MethodFault
    * @throws Exception
    */
   public static VirtualMachineConfigSpec[] getVMConfigSpecForDVSPortForVNic(final ManagedObjectReference vmMor,
                                                                             final ConnectAnchor connectAnchor,
                                                                             final Map<String, DistributedVirtualSwitchPortConnection> mapNicNmeDVPortConnection)
      throws Exception
   {
      VirtualMachineConfigSpec[] deltaConfigSpec = null;
      VirtualMachineConfigSpec updatedDeltaConfigSpec = null;
      VirtualMachineConfigSpec originalDeltaConfigSpec = null;
      VirtualMachine ivm = null;
      VirtualMachineConfigInfo vmConfigInfo = null;
      VirtualDevice[] vds = null;
      VirtualDeviceConfigSpec updatedDeviceConfigSpec = null;
      VirtualDeviceConfigSpec originalDeviceConfigSpec = null;
      VirtualEthernetCardDistributedVirtualPortBackingInfo dvPortBacking = null;
      final List<VirtualDeviceConfigSpec> updatedDeviceChange = new ArrayList<VirtualDeviceConfigSpec>();
      final List<VirtualDeviceConfigSpec> originalDeviceChange = new ArrayList<VirtualDeviceConfigSpec>();
      VirtualDeviceConnectInfo vdConnectInfo = null;
      String nicName = null;
      DistributedVirtualSwitchPortConnection portConn = null;
      assertNotNull(connectAnchor,
               "Reference to the ConnectAnchor object is not null",
               "Reference to the ConnectAnchor object is null");
      ivm = new VirtualMachine(connectAnchor);
      assertTrue(
               (vmMor != null && mapNicNmeDVPortConnection != null && !mapNicNmeDVPortConnection.isEmpty()),
               " VMMor or mapNicNmeDVPortConnection is null");
      vmConfigInfo = ivm.getVMConfigInfo(vmMor);
      updatedDeltaConfigSpec = new VirtualMachineConfigSpec();
      originalDeltaConfigSpec = new VirtualMachineConfigSpec();
      assertTrue(
               (vmConfigInfo != null && vmConfigInfo.getHardware() != null && com.vmware.vcqa.util.TestUtil.vectorToArray(
                        vmConfigInfo.getHardware().getDevice(),
                        com.vmware.vc.VirtualDevice.class) != null),
               " Failed to get VirtualHardware");
      vds = com.vmware.vcqa.util.TestUtil.vectorToArray(
               vmConfigInfo.getHardware().getDevice(),
               com.vmware.vc.VirtualDevice.class);
      for (final VirtualDevice vd : vds) {
         if (vd != null && vd instanceof VirtualEthernetCard) {
            final VirtualEthernetCard vcCard = (VirtualEthernetCard) vd;
            for (Map.Entry<String, DistributedVirtualSwitchPortConnection> entry : mapNicNmeDVPortConnection.entrySet()) {
               nicName = entry.getKey();
               if (nicName != null
                        && nicName.equals(vd.getDeviceInfo().getLabel())) {
                  portConn = entry.getValue();
                  updatedDeviceConfigSpec = new VirtualDeviceConfigSpec();
                  originalDeviceConfigSpec = new VirtualDeviceConfigSpec();
                  originalDeviceConfigSpec.setOperation(VirtualDeviceConfigSpecOperation.EDIT);
                  originalDeviceConfigSpec.setDevice((VirtualDevice) TestUtil.deepCopyObject(vd));
                  originalDeviceChange.add(originalDeviceConfigSpec);
                  dvPortBacking = new VirtualEthernetCardDistributedVirtualPortBackingInfo();
                  dvPortBacking.setPort(portConn);
                  vcCard.setBacking(dvPortBacking);
                  vdConnectInfo = new VirtualDeviceConnectInfo();
                  vdConnectInfo.setStartConnected(true);
                  vdConnectInfo.setConnected(true);
                  vdConnectInfo.setAllowGuestControl(true);
                  vcCard.setConnectable(vdConnectInfo);
                  updatedDeviceConfigSpec.setOperation(VirtualDeviceConfigSpecOperation.EDIT);
                  updatedDeviceConfigSpec.setDevice(vcCard);
                  updatedDeviceChange.add(updatedDeviceConfigSpec);
               }
            }
         }
      }
      if (updatedDeviceConfigSpec != null) {
         updatedDeltaConfigSpec = new VirtualMachineConfigSpec();
         updatedDeltaConfigSpec.getDeviceChange().clear();
         updatedDeltaConfigSpec.getDeviceChange().addAll(
                  com.vmware.vcqa.util.TestUtil.arrayToVector(updatedDeviceChange.toArray(new VirtualDeviceConfigSpec[updatedDeviceChange.size()])));
         originalDeltaConfigSpec = new VirtualMachineConfigSpec();
         originalDeltaConfigSpec.getDeviceChange().clear();
         originalDeltaConfigSpec.getDeviceChange().addAll(
                  com.vmware.vcqa.util.TestUtil.arrayToVector(originalDeviceChange.toArray(new VirtualDeviceConfigSpec[originalDeviceChange.size()])));
         deltaConfigSpec = new VirtualMachineConfigSpec[2];
         deltaConfigSpec[0] = updatedDeltaConfigSpec;
         deltaConfigSpec[1] = originalDeltaConfigSpec;
      } else {
         log.warn("No matching VNIC found");
         return null;
      }
      return deltaConfigSpec;
   }

   /**
    * Utility method to migrate the VirtualNics nic on a host from legacy
    * network to the vds
    *
    * @param connectAnchor
    * @param host
    * @param mapPortConn Map of VirtualNic and
    *           DistributedVirtualSwitchPortConnection
    * @throws MethodFault,Exception
    */
   public static void migrateVnicsToVds(final ConnectAnchor connectAnchor,
                                        final ManagedObjectReference hostMor,
                                        final Map<String, DistributedVirtualSwitchPortConnection> mapPortConn)
      throws Exception
   {
      assertNotNull(connectAnchor,
               "Reference to the ConnectAnchor object is not null",
               "Reference to the ConnectAnchor object is null");
      assertNotNull(hostMor, "Reference to the hostMor is not null",
               "Reference to the hostMor is null");
      final HostSystem hostSystem = new HostSystem(connectAnchor);
      final NetworkSystem networkSystem = new NetworkSystem(connectAnchor);
      final String hostName = hostSystem.getHostName(hostMor);
      for (Map.Entry<String, DistributedVirtualSwitchPortConnection> entry : mapPortConn.entrySet()) {
         final HostVirtualNicSpec updatedVnicSpec = NetworkUtil.getVnicSpec(
                  connectAnchor, hostMor, entry.getKey());
         updatedVnicSpec.setDistributedVirtualPort(entry.getValue());
         updatedVnicSpec.setPortgroup(null);
         assertTrue(
                  networkSystem.updateVirtualNic(
                           networkSystem.getNetworkSystem(hostMor),
                           entry.getKey(), updatedVnicSpec),
                  "Successfully moved the " + "VirtualNic on host " + hostName
                           + " to the vds", "Failed to "
                           + "move the the VirtualNic on host " + hostName
                           + " to the " + "vds");
      }
   }

   /**
    * Utility method to get NetworkLabel associated with DVPortConnection
    *
    * @param connectAnchor
    * @param vmMor
    * @param portConnection
    * @return String NetworkLabel associated with DVPortConnection
    * @throws MethodFault,Exception
    */
   public static String getNetworkLabelForDVPortConnection(final ConnectAnchor connectAnchor,
                                                           final ManagedObjectReference vmMor,
                                                           DistributedVirtualSwitchPortConnection portConnection)
      throws Exception
   {
      String nicName = null;
      VirtualEthernetCardDistributedVirtualPortBackingInfo dvPortBacking = null;
      assertNotNull(connectAnchor,
               "Reference to the ConnectAnchor object is not null",
               "Reference to the ConnectAnchor object is null");
      assertNotNull(vmMor,
               "Reference to the virtualmachine object is not null",
               "Reference to the virtualmachine object is null");
      for (final VirtualDeviceConfigSpec config : DVSUtil.getAllVirtualEthernetCardDevices(
               vmMor, connectAnchor)) {
         assertTrue(
                  (config != null && config.getDevice() != null && config.getDevice().getBacking() != null),
                  "Device  Backing is null");
         if (config.getDevice().getBacking() instanceof VirtualEthernetCardDistributedVirtualPortBackingInfo) {
            dvPortBacking = (VirtualEthernetCardDistributedVirtualPortBackingInfo) config.getDevice().getBacking();
            final DistributedVirtualSwitchPortConnection vmDVPortConn = dvPortBacking.getPort();
            if (TestUtil.compareObject(portConnection, vmDVPortConn,
                     TestUtil.getIgnorePropertyList(portConnection, true))) {
               VirtualEthernetCard vcCard = (VirtualEthernetCard) config.getDevice();
               nicName = vcCard.getDeviceInfo().getLabel();
               break;
            }
         }
      }
      return nicName;
   }

   /**
    * Utility method to get pnics connected to host on DVS
    *
    * @param connectAnchor
    * @param dvsMor
    * @param hostMors List of hostMors
    * @return Map of host , nics connected to host on DVS
    * @throws MethodFault,Exception
    */
   public static Map<ManagedObjectReference, List<String>> getPnicsConnectedToHost(final ConnectAnchor connectAnchor,
                                                                                   final ManagedObjectReference dvsMor,
                                                                                   List<ManagedObjectReference> hostMors)
      throws Exception
   {
      assertNotNull(connectAnchor,
               "Reference to the ConnectAnchor object is not null",
               "Reference to the ConnectAnchor object is null");
      assertNotNull(dvsMor,
               "Reference to the DistributedVirtualSwitch object is not null",
               "Reference to the DistributedVirtualSwitch object is null");
      assertNotNull(hostMors, "Reference to the hostMors object is not null",
               "Reference to the hostMors object is null");
      Map<ManagedObjectReference, List<String>> mapPnicsAndHost = null;
      HostSystem hostSystem = null;
      DistributedVirtualSwitch DVS = null;
      DVSConfigInfo dvsConfigInfo = null;
      ManagedObjectReference hostMor = null;
      hostSystem = new HostSystem(connectAnchor);
      DVS = new DistributedVirtualSwitch(connectAnchor);
      dvsConfigInfo = DVS.getConfig(dvsMor);
      DistributedVirtualSwitchHostMember[] hostMembers = com.vmware.vcqa.util.TestUtil.vectorToArray(
               dvsConfigInfo.getHost(),
               com.vmware.vc.DistributedVirtualSwitchHostMember.class);
      if (hostMembers != null && hostMembers.length > 0) {
         mapPnicsAndHost = new HashMap<ManagedObjectReference, List<String>>();
         for (DistributedVirtualSwitchHostMember hostMember : hostMembers) {
            List<String> pnicDeviceList = null;
            DistributedVirtualSwitchHostMemberConfigInfo hostMemberConfigInfo = hostMember.getConfig();
            if (hostMors.contains(hostMemberConfigInfo.getHost())) {
               hostMor = hostMemberConfigInfo.getHost();
               log.info("Host : " + hostSystem.getHostName(hostMor));
               log.info("DVS : " + dvsConfigInfo.getName());
               DistributedVirtualSwitchHostMemberPnicBacking backing = (DistributedVirtualSwitchHostMemberPnicBacking) hostMemberConfigInfo.getBacking();
               DistributedVirtualSwitchHostMemberPnicSpec[] pnicSpecs = com.vmware.vcqa.util.TestUtil.vectorToArray(
                        backing.getPnicSpec(),
                        com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec.class);
               if (pnicSpecs != null && pnicSpecs.length > 0) {
                  pnicDeviceList = new Vector<String>();
                  for (DistributedVirtualSwitchHostMemberPnicSpec pnicSpec : pnicSpecs) {
                     String pnicDevice = pnicSpec.getPnicDevice();
                     if (pnicDevice != null) {
                        pnicDeviceList.add(pnicDevice);
                        log.info("PnicDevice : " + pnicDevice);
                     }
                  }
                  mapPnicsAndHost.put(hostMor, pnicDeviceList);
               }
            }
         }
      }
      return mapPnicsAndHost;
   }

   /**
    * This method checks disableHostReboot flag in the dvs property file.
    *
    * @return true if disableHostReboot is set to yes in dvs property file,
    *         false otherwise
    * @throws MethodFault, Exception
    */
   public static boolean disableHostReboot()
      throws Exception
   {
      boolean isHostRebootRequired = true;
      final String disableHostReboot = TestUtil.getPropertyValue(
               DVSTestConstants.DISABLE_HOST_REBOOT,
               DVSTestConstants.DVS_PROP_FILE);
      if (disableHostReboot == null
               || !disableHostReboot.equalsIgnoreCase("yes")) {
         isHostRebootRequired = false;
      }
      return isHostRebootRequired;
   }

   /**
    * This method returns maximum user specified NRP value defined in
    * dvsproperty file.
    *
    * @return maximum user defined NRPs on a vDS
    * @throws Exception
    */
   public static int getMaxNRPs()
      throws Exception
   {
      String maxNRPPropValue = TestUtil.getPropertyValue(
               DVSTestConstants.MAX_NRPS, DVSTestConstants.DVS_PROP_FILE);
      return (maxNRPPropValue == null) ? DVSTestConstants.NRP_MAX_COUNT
               : Integer.parseInt(maxNRPPropValue);
   }

   /**
    * This method creates the traffic resource allocation object out of
    * primitive parameters like reservation, limit and shares
    *
    * @param reservation
    * @param limit
    * @param shares
    * @return DvsHostInfrastructureTrafficResourceAllocation
    */
   public static DvsHostInfrastructureTrafficResourceAllocation getDvsHostInfrastructureTrafficResourceAllocation(long reservation,
                                                                                                                  long limit,
                                                                                                                  SharesInfo shares)
   {
      DvsHostInfrastructureTrafficResourceAllocation dvsHostInfrastructureTrafficResourceAllocation = new DvsHostInfrastructureTrafficResourceAllocation();
      dvsHostInfrastructureTrafficResourceAllocation.setReservation(reservation);
      dvsHostInfrastructureTrafficResourceAllocation.setLimit(limit);
      dvsHostInfrastructureTrafficResourceAllocation.setShares(shares);
      return dvsHostInfrastructureTrafficResourceAllocation;
   }

   /**
    * This method gets the VmVnicResourcePoolConfigSpec given the primitive
    * parameters
    *
    * @param key
    * @param operation
    * @param configVersion
    * @param reservation
    * @param name
    * @param desc
    * @return DvsVmVnicResourcePoolConfigSpec
    */
   public static DvsVmVnicResourcePoolConfigSpec getVmVnicResourcePoolConfigSpec(String key,
                                                                                 String operation,
                                                                                 String configVersion,
                                                                                 Long reservationQuota,
                                                                                 String name,
                                                                                 String desc)
   {
      DvsVmVnicResourcePoolConfigSpec vmvnicResourcePoolConfigSpec = new DvsVmVnicResourcePoolConfigSpec();
      vmvnicResourcePoolConfigSpec.setKey(key);
      vmvnicResourcePoolConfigSpec.setOperation(operation);
      DvsVmVnicResourceAllocation resourceAlloc = new DvsVmVnicResourceAllocation();
      resourceAlloc.setReservationQuota(reservationQuota);
      vmvnicResourcePoolConfigSpec.setAllocationInfo(resourceAlloc);
      vmvnicResourcePoolConfigSpec.setConfigVersion(configVersion);
      vmvnicResourcePoolConfigSpec.setName(name);
      vmvnicResourcePoolConfigSpec.setDescription(desc);
      return vmvnicResourcePoolConfigSpec;
   }

   /**
    * This method manipulates the DVSConfigSpec which can be used in a create
    * dvs or a reconfigure dvs call subsequently to set the required
    * reservation, limits and shares for a particular traffic key (key could be
    * virtualMachine, nfs, iscsi etc..)
    *
    * @param connectAnchor
    * @param dvsVmNwReservation
    * @param dvsVmNwLimit
    * @param dvsVmNwShares
    * @param key
    * @param configSpec
    */
   public static void createDVSConfigSpecWithHostInfrastructureTrafficResourceAllocation(ConnectAnchor connectAnchor,
                                                                                         long dvsVmNwReservation,
                                                                                         long dvsVmNwLimit,
                                                                                         SharesInfo dvsVmNwShares,
                                                                                         String key,
                                                                                         DVSConfigSpec configSpec)
   {
      DvsHostInfrastructureTrafficResource hostInfrastructureTrafficResource = new DvsHostInfrastructureTrafficResource();
      hostInfrastructureTrafficResource.setKey(key);
      DvsHostInfrastructureTrafficResourceAllocation trafficResourceAllocation = getDvsHostInfrastructureTrafficResourceAllocation(
               dvsVmNwReservation, dvsVmNwLimit, dvsVmNwShares);
      hostInfrastructureTrafficResource.setAllocationInfo(trafficResourceAllocation);
      List<DvsHostInfrastructureTrafficResource> hostInfrastructureTrafficResourceList = new ArrayList<DvsHostInfrastructureTrafficResource>();
      hostInfrastructureTrafficResourceList.add(hostInfrastructureTrafficResource);
      configSpec.setInfrastructureTrafficResourceConfig(hostInfrastructureTrafficResourceList);
   }

   /**
    * Method to remove specified Physical NIC(s) from host's vDS
    *
    * @param connectAnchor Reference to ConnectAnchor object
    * @param hostMor MOR of host
    * @param vDsMor MOR of vDS; host is part of
    * @param pNicsToRemove list of Physical NICs to remove from host's vDS
    * @return true if PNIC(s) removed from host's vDS, false otherwise
    * @throws Exception
    */
   public static boolean removePNicsFromvDS(final ConnectAnchor connectAnchor,
                                            final ManagedObjectReference hostMor,
                                            final ManagedObjectReference vDsMor,
                                            List<String> pNicsToRemove)
      throws Exception
   {
      DistributedVirtualSwitch ivDs = null;
      NetworkSystem ins = null;
      ManagedObjectReference nsMor = null;
      HostProxySwitchConfig hostProxySwitchConfig = null;
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      final List<DistributedVirtualSwitchHostMemberPnicSpec> pnicSpecList = new ArrayList<DistributedVirtualSwitchHostMemberPnicSpec>();
      HostNetworkConfig updatedNetworkConfig = null;
      assertNotNull(connectAnchor,
               "Reference to the ConnectAnchor object is not null",
               "Reference to the ConnectAnchor object is null");
      assertNotNull(hostMor, "Reference to the hostMor is not null",
               "Reference to the hostMor is null");
      assertNotNull(vDsMor,
               "Reference to the DistributedVirtualSwitch object is not null",
               "Reference to the DistributedVirtualSwitch object is null");
      ins = new NetworkSystem(connectAnchor);
      ivDs = new DistributedVirtualSwitch(connectAnchor);
      nsMor = ins.getNetworkSystem(hostMor);
      assertNotNull(nsMor,
               "Reference to the NetworkSystem mor object is not null",
               "Reference to the NetworkSystem mor object is null");

      hostProxySwitchConfig = ivDs.getDVSVswitchProxyOnHost(vDsMor, hostMor);

      hostProxySwitchConfig.setChangeOperation(HostConfigChangeOperation.EDIT.value());
      assertTrue(
               (hostProxySwitchConfig.getSpec() != null
                        && hostProxySwitchConfig.getSpec().getBacking() != null && hostProxySwitchConfig.getSpec().getBacking() instanceof DistributedVirtualSwitchHostMemberPnicBacking),
               " Failed to get HostMemberPnicBacking on vDs");
      pnicBacking = (DistributedVirtualSwitchHostMemberPnicBacking) hostProxySwitchConfig.getSpec().getBacking();

      int nicsFoundCount = 0;
      boolean nicFound = false;
      for (DistributedVirtualSwitchHostMemberPnicSpec dvsHostMemSpec : pnicBacking.getPnicSpec()) {
         String nicRetrievedFromvDs = dvsHostMemSpec.getPnicDevice();
         nicFound = false;
         for (String pnic : pNicsToRemove) {
            if (nicRetrievedFromvDs.equals(pnic)) {
               ++nicsFoundCount;
               nicFound = true;
               break;
            }
         }
         if (!nicFound) {
            pnicSpecList.add(dvsHostMemSpec);
         }
      }

      assertTrue(nicsFoundCount == pNicsToRemove.size(),
               "Could not find all specified nics on hosts vDS (proxy switch)");

      pnicBacking.getPnicSpec().clear();
      pnicBacking.getPnicSpec().addAll(
               com.vmware.vcqa.util.TestUtil.arrayToVector(pnicSpecList.toArray(new DistributedVirtualSwitchHostMemberPnicSpec[pnicSpecList.size()])));
      hostProxySwitchConfig.getSpec().setBacking(pnicBacking);
      updatedNetworkConfig = new HostNetworkConfig();
      assertNotNull(hostProxySwitchConfig,
               "Failed to get HostProxySwitchConfig");
      updatedNetworkConfig.getProxySwitch().clear();
      updatedNetworkConfig.getProxySwitch().addAll(
               com.vmware.vcqa.util.TestUtil.arrayToVector(new HostProxySwitchConfig[] { hostProxySwitchConfig }));

      return ins.updateNetworkConfig(nsMor, updatedNetworkConfig,
               TestConstants.CHANGEMODE_MODIFY);
   }

   /**
    * Creates a DVS with Extension key set in DVS config.
    *
    * @param connectAnchor - VC Connect Anchor
    * @param hostMor - HostMor
    * @param extnKey - Extension Key
    * @return DVS MOR.
    * @throws Exception
    */
   public static ManagedObjectReference createDvs(ConnectAnchor connectAnchor,
                                                  ManagedObjectReference hostMor,
                                                  String extnKey)
      throws Exception
   {
      Folder folder = new Folder(connectAnchor);
      NetworkSystem ns = new NetworkSystem(connectAnchor);
      /*
       * Create a Distributed Virtual switch by setting the extension key of
       * the test extension.
       */
      ManagedObjectReference networkFolder = folder.getNetworkFolder(folder.getDataCenter());
      DVSConfigSpec dvsCfg = new DVSConfigSpec();
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
      List<DistributedVirtualSwitchHostMemberPnicSpec> pNiclist = new Vector<DistributedVirtualSwitchHostMemberPnicSpec>();
      DistributedVirtualSwitchHostMemberPnicSpec pNicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();
      String[] freePnics = ns.getPNicIds(hostMor, false);
      assertTrue(freePnics != null && freePnics.length != 0,
               "Found free pnics", "Requires atleast one free pnic");
      pNicSpec.setPnicDevice(freePnics[0]);
      pNiclist.add(pNicSpec);
      pnicBacking.setPnicSpec(pNiclist);
      DistributedVirtualSwitchHostMemberConfigSpec hostMemberCfg = new DistributedVirtualSwitchHostMemberConfigSpec();
      hostMemberCfg.setOperation(TestConstants.CONFIG_SPEC_ADD);
      hostMemberCfg.setHost(hostMor);
      hostMemberCfg.setBacking(pnicBacking);
      List<DistributedVirtualSwitchHostMemberConfigSpec> hostMemberCfgList = new Vector<DistributedVirtualSwitchHostMemberConfigSpec>();
      hostMemberCfgList.add(hostMemberCfg);
      dvsCfg.setHost(hostMemberCfgList);
      dvsCfg.setName(TestUtil.getRandomizedTestId("vDS"));
      dvsCfg.setExtensionKey(extnKey);
      ManagedObjectReference dvsMor = folder.createDistributedVirtualSwitch(
               networkFolder, dvsCfg);
      assertNotNull(dvsMor,
               "Successful in adding the Distributed Virtual Switch ",
               "Error while adding the Distributed Virtual Switch.");
      log.info("dvsMor :" + dvsMor.getValue());
      return dvsMor;
   }

   /**
    * Creates a DVS.
    *
    * @param connectAnchor - VC Connect Anchor
    * @param hostMorList - Mor's of Hosts to add to DVS
    * @return DVS MOR.
    * @throws Exception
    */
   public static ManagedObjectReference createDvs(ConnectAnchor connectAnchor,
                                                  List<ManagedObjectReference> hostMorList,
                                                  String switchName)
      throws Exception
   {
      Folder folder = new Folder(connectAnchor);
      NetworkSystem ns = new NetworkSystem(connectAnchor);
      /*
       * Create a Distributed Virtual switch by setting the extension key of
       * the test extension.
       */
      ManagedObjectReference networkFolder = folder.getNetworkFolder(folder.getDataCenter());
      DVSConfigSpec dvsCfg = new DVSConfigSpec();
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
      List<DistributedVirtualSwitchHostMemberPnicSpec> pNiclist = new Vector<DistributedVirtualSwitchHostMemberPnicSpec>();
      DistributedVirtualSwitchHostMemberPnicSpec pNicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();

      List<DistributedVirtualSwitchHostMemberConfigSpec> hostMemberCfgList = new Vector<DistributedVirtualSwitchHostMemberConfigSpec>();
      DistributedVirtualSwitchHostMemberConfigSpec hostMemberCfg = null;
      for (ManagedObjectReference hostMor : hostMorList) {
         String[] freePnics = ns.getPNicIds(hostMor, false);
         assertTrue(freePnics != null && freePnics.length != 0,
                  "Found free pnics", "Requires atleast one free pnic");
         pNicSpec.setPnicDevice(freePnics[0]);
         pNiclist.add(pNicSpec);
         pnicBacking.setPnicSpec(pNiclist);
         hostMemberCfg = new DistributedVirtualSwitchHostMemberConfigSpec();
         hostMemberCfg.setOperation(TestConstants.CONFIG_SPEC_ADD);
         hostMemberCfg.setHost(hostMor);
         hostMemberCfg.setBacking(pnicBacking);
         hostMemberCfgList.add(hostMemberCfg);

      }
      dvsCfg.setHost(hostMemberCfgList);
      dvsCfg.setName(switchName);
      ManagedObjectReference dvsMor = folder.createDistributedVirtualSwitch(
               networkFolder, dvsCfg);
      assertNotNull(dvsMor,
               "Successful in adding the Distributed Virtual Switch ",
               "Error while adding the Distributed Virtual Switch.");
      log.info("dvsMor :" + dvsMor.getValue());
      return dvsMor;
   }

   /**
    * Method to add portgroup to DVS
    *
    * @param type portgroup type
    * @return ManagedObjectReference portgroup mor
    */
   public static ManagedObjectReference addPortgroupToDVS(ConnectAnchor connectAnchor,
                                                          ManagedObjectReference dvsMor,
                                                          String type,
                                                          String pgName)
      throws Exception
   {
      DVPortgroupConfigSpec pgConfigSpec = new DVPortgroupConfigSpec();
      DistributedVirtualSwitchHelper dvsHelper = new DistributedVirtualSwitchHelper(
               connectAnchor);
      List<ManagedObjectReference> pgList = null;
      pgConfigSpec.setName(pgName);
      pgConfigSpec.setType(type);
      pgConfigSpec.setNumPorts(new Integer(2));
      pgList = dvsHelper.addPortGroups(dvsMor,
               new DVPortgroupConfigSpec[] { pgConfigSpec });
      assertTrue((pgList != null && pgList.size() == 1),
               "Successfully added the " + type + " portgroup to the DVS "
                        + pgName, " Failed to add " + type + "portgroup");
      return pgList.get(0);
   }

   /**
    * This method returns the virtual nic associated with the given vnic device
    *
    * @param networkInfo - HostNetworkInfo - The Newtork information of the host
    * @param vnicDevice - String - Name of the vnic device
    * @return the hostVirtualNic if found else null
    */
   public static HostVirtualNic getVmknic(HostNetworkInfo networkInfo,
                                          String vnicDevice)
   {
      HostVirtualNic[] virtualNics = null;
      HostVirtualNic vmknic = null;
      virtualNics = com.vmware.vcqa.util.TestUtil.vectorToArray(
               networkInfo.getVnic(), com.vmware.vc.HostVirtualNic.class);

      for (HostVirtualNic virtualNic : virtualNics) {
         if (virtualNic.getDevice().equals(vnicDevice)) {
            vmknic = virtualNic;
            break;
         }
      }

      return vmknic;
   }

   /**
    * This method returns the virtual switch associated with the given switch
    * Name or key
    *
    * @param networkInfo- HostNetworkInfo - The Newtork information of the host
    * @param vSwitch- String - Name of the virtual Switch or key
    * @param isKey - boolean - is the passed vSwitch is either name(false) or
    *           key(true)
    * @return the hostVirtualSwitch if found else null
    */
   public static HostVirtualSwitch getVsiwtch(HostNetworkInfo networkInfo,
                                              String vSwitch,
                                              boolean isKey)
   {
      HostVirtualSwitch vmkNicVirtualSwitch = null;
      HostVirtualSwitch[] virtualSwitches = null;
      virtualSwitches = com.vmware.vcqa.util.TestUtil.vectorToArray(
               networkInfo.getVswitch(), com.vmware.vc.HostVirtualSwitch.class);
      if (networkInfo != null) {
         if (virtualSwitches != null && virtualSwitches.length != 0) {
            for (HostVirtualSwitch virtualSwitch : virtualSwitches) {
               if (virtualSwitch != null) {
                  String vSwitchName = virtualSwitch.getName();
                  String vSwitchKey = virtualSwitch.getKey();
                  if (!isKey && vSwitch.equalsIgnoreCase(vSwitchName)) {
                     vmkNicVirtualSwitch = virtualSwitch;
                     break;
                  } else if (isKey && vSwitch.equalsIgnoreCase(vSwitchKey)) {
                     vmkNicVirtualSwitch = virtualSwitch;
                     break;
                  }
               }
            }
         }
      }
      return vmkNicVirtualSwitch;

   }

   /**
    * This method returns the proxy switch associated with the given dvswitch
    * UID
    *
    * @param networkInfo - HostNetworkInfo - The Newtork information of the host
    * @param dvSwitchUuid - String - UID of the dvSwitch
    * @return the hostProxySwitch if found else null
    */
   public static HostProxySwitch getProxySiwtch(HostNetworkInfo networkInfo,
                                                String dvSwitchUuid)
   {
      HostProxySwitch proxySwitch = null;
      HostProxySwitch[] proxySwitches = null;
      proxySwitches = com.vmware.vcqa.util.TestUtil.vectorToArray(
               networkInfo.getProxySwitch(),
               com.vmware.vc.HostProxySwitch.class);

      for (HostProxySwitch proxyswitch : proxySwitches) {
         if (proxyswitch.getDvsUuid().equals(dvSwitchUuid)) {
            proxySwitch = proxyswitch;
            break;
         }
      }

      return proxySwitch;
   }

   /**
    * Update the PnicBacking with the gievn set of Physical Nics on a given host
    * and DVSwitch
    *
    * @param pnicBacking - DistributedVirtualSwitchHostMemberPnicBacking - The
    *           original pincBacking object
    * @param pnics - List<PhysicalNic> - the list of physical nics that has to
    *           be updated in the pnicBacking
    * @param dvsMOR - ManagedObjectReference - the MOR of the dvswitch
    * @param morHost - ManagedObjectReference - the MOR of the host
    * @param DVS - DistributedVirtualSwitch object of the VC
    * @return the updated the pincbacking if successfully reconfigured else Null
    * @throws Exception
    */
   public static DistributedVirtualSwitchHostMemberPnicBacking updatePnicBacking(DistributedVirtualSwitchHostMemberPnicBacking pnicBacking,
                                                                                 List<PhysicalNic> pnics,
                                                                                 ManagedObjectReference dvsMOR,
                                                                                 ManagedObjectReference morHost,
                                                                                 ConnectAnchor connectAnchor)
      throws Exception
   {
      DistributedVirtualSwitch DVS = new DistributedVirtualSwitch(connectAnchor);
      if (pnics != null && pnics.size() > 0) {
         Vector<DistributedVirtualSwitchHostMemberPnicSpec> pnicSpecs = new Vector<DistributedVirtualSwitchHostMemberPnicSpec>();
         for (PhysicalNic pnic : pnics) {
            String freePort = DVS.getFreeUplinkPortKey(dvsMOR, morHost, null);
            DistributedVirtualSwitchHostMemberPnicSpec pnicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();
            if (freePort != null) {
               pnicSpec.setPnicDevice(pnic.getDevice());
               pnicSpec.setUplinkPortKey(freePort);
               pnicSpecs.add(pnicSpec);
            } else {
               log.error("unable to find free uplink port on the DVSwitch");
               return null;
            }

         }
         pnicBacking.getPnicSpec().clear();
         pnicBacking.getPnicSpec().addAll(pnicSpecs);
      } else {
         log.error("The physical Nics is either empty or null");
         return null;
      }
      return pnicBacking;
   }

   /**
    * Generate updated virtualSwitch configuration with the physical nics either
    * added or removed
    *
    * @param vSwitch - HostVirtualSwitch - virtualswitch which has to be updated
    * @param pnicBacking - DistributedVirtualSwitchHostMemberPnicBacking -
    *           pnicbacking containg the information of the physical nics to be
    *           added or null if all the physical nics to be removed
    * @param removePnics - boolean - true if all pnics to be removed else false
    * @return - Updated host virtualSwitchConfig
    */
   public static HostVirtualSwitchConfig[] updateVswitchPnics(HostVirtualSwitch vSwitch,
                                                              DistributedVirtualSwitchHostMemberPnicBacking pnicBacking,
                                                              boolean removePnics)
   {
      HostVirtualSwitchSpec hvsSpec = vSwitch.getSpec();
      if (removePnics) {
         hvsSpec.getPolicy().getNicTeaming().getNicOrder().getStandbyNic().clear();
         hvsSpec.getPolicy().getNicTeaming().getNicOrder().getActiveNic().clear();
         hvsSpec.setBridge(null);
      } else {
         if (pnicBacking != null) {
            HostVirtualSwitchBondBridge bondBridge = new HostVirtualSwitchBondBridge();
            HostNicOrderPolicy nicOrderPolicy = new HostNicOrderPolicy();
            Vector<String> nicDevices = new Vector<String>();
            List<DistributedVirtualSwitchHostMemberPnicSpec> pnicSpecs = pnicBacking.getPnicSpec();
            for (DistributedVirtualSwitchHostMemberPnicSpec pnicSpec : pnicSpecs) {
               nicDevices.add(pnicSpec.getPnicDevice());
            }
            bondBridge.setNicDevice(nicDevices);
            nicOrderPolicy.setActiveNic(nicDevices);
            hvsSpec.setBridge(bondBridge);
            hvsSpec.getPolicy().getNicTeaming().setNicOrder(nicOrderPolicy);
         } else {
            log.error("Pnic backing provided is null");
            return null;
         }
      }
      HostVirtualSwitchConfig hvs[] = new HostVirtualSwitchConfig[1];
      hvs[0] = new HostVirtualSwitchConfig();
      hvs[0].setChangeOperation(TestConstants.NETWORKCFG_OP_EDIT);
      hvs[0].setName(vSwitch.getName());
      hvs[0].setSpec(hvsSpec);

      return hvs;
   }

   /**
    * The method migrates the vnic device from the standard virtualswitch to
    * DVSwitch with its associated physicalNics on the given host
    *
    * @param morHost - ManageObjectReference of the host
    * @param vnicDevice - Name of the vnic device to migrate
    * @param dvsMOR - ManageObjectReference of the DVSwitch
    * @param networkSystem - Networksystem of the VC
    * @return true if successfully migrated else false
    * @throws Exception
    */
   @SuppressWarnings({ "unused", "null" })
   public static boolean MigrateVmknicLegacyToDvs(final ConnectAnchor connectAnchor,
                                                  final ManagedObjectReference morHost,
                                                  final String vnicDevice,
                                                  final ManagedObjectReference dvsMOR)
      throws Exception
   {
      NetworkSystem networkSystem = new NetworkSystem(connectAnchor);
      HostSystem hostSystem = new HostSystem(connectAnchor);
      DistributedVirtualSwitch DVS = new DistributedVirtualSwitch(connectAnchor);
      DistributedVirtualPortgroup iDVPG = new DistributedVirtualPortgroup(
               connectAnchor);
      ManagedObjectReference hostNetworkSystem = networkSystem.getNetworkSystem(morHost);
      DVSConfigInfo info = DVS.getConfig(dvsMOR);
      String dvSwitchUuid = info.getUuid();

      /*
       * Get switch and pnics of the vmknic
       */
      log.info("Obtaning the Vswitch and pinc associated with the vmknic");
      String pnicKeys[] = null;
      HostNetworkInfo networkInfo = null;
      HostVirtualSwitch vmkNicVirtualSwitch = null;
      networkInfo = networkSystem.getNetworkInfo(hostNetworkSystem);

      HostVirtualNic vmknic = getVmknic(networkInfo, vnicDevice);
      if (vmknic == null) {
         log.error("Unable to find the associated vmknic");
         return false;
      }
      log.info("Successfully found the associated vmkNic");

      String portgroup = vmknic.getPortgroup();
      String vSwitch = networkSystem.getPortGroupSpec(hostNetworkSystem,
               portgroup).getVswitchName();

      vmkNicVirtualSwitch = getVsiwtch(networkInfo, vSwitch, false);
      pnicKeys = com.vmware.vcqa.util.TestUtil.vectorToArray(
               vmkNicVirtualSwitch.getPnic(), java.lang.String.class);

      if (vmkNicVirtualSwitch == null) {
         log.error("Unable to switch associated with the given vmknic");
         return false;
      }
      log.info("Successfully found the vswitch associated with the vnic");

      if (pnicKeys == null) {
         log.error("Unable to pnics associated with the given vmknic");
         return false;
      }
      log.info("Successfully found the pnics associated with the vnic");

      /*
       * Create/get new portgroup on the DVSwitch
       */
      String dvsName = hostSystem.getHostName(dvsMOR);
      String dvPortgroup = dvsName + '-' + portgroup + '-' + vnicDevice;
      boolean createDvPortgroup = true;
      String dvpgkey = null;
      List<ManagedObjectReference> pgMors = DVS.getPortgroup(dvsMOR);
      log.info("Create/get protgroup " + dvPortgroup + " on dvswitch");
      if (pgMors != null || pgMors.size() > 0) {
         for (ManagedObjectReference pgMor : pgMors) {
            if (iDVPG.getConfigInfo(pgMor).getName().equals(dvPortgroup)) {
               createDvPortgroup = false;
               dvpgkey = iDVPG.getKey(pgMor);
               break;
            }
         }
      }

      if (createDvPortgroup) {
         dvpgkey = DVS.addPortGroup(dvsMOR, DVPORTGROUP_TYPE_EARLY_BINDING, 2,
                  dvPortgroup);
      }

      if (dvpgkey == null) {
         log.error("Unable to create protgroup " + dvPortgroup
                  + " on the DVSwitch");
         return false;
      }
      log.info("Successfully created portgroup " + dvPortgroup + " on DVSwitch");

      List<PhysicalNic> pnics = null;
      if (pnicKeys != null) {
         pnics = networkSystem.getPhysicalNic(hostNetworkSystem, pnicKeys);
      }

      /*
       * Update the proxy switch configuration details
       */
      log.info("Update the proxyswitch confguration of the vmknic");
      HostNetworkConfig updatedNetworkConfig = new HostNetworkConfig();

      HostProxySwitchConfig originalHostProxySwitchConfig = null;
      HostProxySwitchConfig updatedHostProxySwitchConfig = null;
      originalHostProxySwitchConfig = DVS.getDVSVswitchProxyOnHost(dvsMOR,
               morHost);
      updatedHostProxySwitchConfig = (HostProxySwitchConfig) TestUtil.deepCopyObject(originalHostProxySwitchConfig);
      updatedHostProxySwitchConfig.setChangeOperation(HostConfigChangeOperation.EDIT.value());
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;

      /*
       * Create the pnic backing configurations
       */

      if (updatedHostProxySwitchConfig.getSpec() != null
               && updatedHostProxySwitchConfig.getSpec().getBacking() != null
               && updatedHostProxySwitchConfig.getSpec().getBacking() instanceof DistributedVirtualSwitchHostMemberPnicBacking) {
         pnicBacking = (DistributedVirtualSwitchHostMemberPnicBacking) updatedHostProxySwitchConfig.getSpec().getBacking();
         pnicBacking = updatePnicBacking(pnicBacking, pnics, dvsMOR, morHost,
                  connectAnchor);
         if (pnicBacking == null) {
            log.error("Update Pnic backing specification of DVSwitch failed");
            return false;
         }
         updatedHostProxySwitchConfig.getSpec().setBacking(pnicBacking);

         if (updatedHostProxySwitchConfig != null) {
            updatedNetworkConfig.getProxySwitch().clear();
            updatedNetworkConfig.getProxySwitch().addAll(
                     com.vmware.vcqa.util.TestUtil.arrayToVector(new HostProxySwitchConfig[] { updatedHostProxySwitchConfig }));
         }
      }

      /*
       * Remove the pnic from the vswitch
       */
      HostVirtualSwitchConfig hvs[] = updateVswitchPnics(vmkNicVirtualSwitch,
               null, true);
      if (hvs == null) {
         log.error("unable to create the HostvirtualSwitchConfig with given parameters");
         return false;
      }

      updatedNetworkConfig.getVswitch().clear();
      updatedNetworkConfig.getVswitch().addAll(
               com.vmware.vcqa.util.TestUtil.arrayToVector(hvs));

      /*
       * Update the Vnic configuration
       */
      List<HostVirtualNicConfig> vnicConfigs = new ArrayList<HostVirtualNicConfig>();
      HostVirtualNicSpec updatedVnicSpec = new HostVirtualNicSpec();
      HostVirtualNicConfig virtualNicConfig = new HostVirtualNicConfig();
      virtualNicConfig.setChangeOperation(TestConstants.HOSTCONFIG_CHANGEOPERATION_EDIT);

      log.info("Create dvs portconnection for the vmknic on the dvswitch");
      DistributedVirtualSwitchPortConnection dvsPortConnection = DVSUtil.buildDistributedVirtualSwitchPortConnection(
               dvSwitchUuid, null, dvpgkey);
      updatedVnicSpec.setDistributedVirtualPort(dvsPortConnection);
      updatedVnicSpec.setPortgroup(null);
      virtualNicConfig.setSpec(updatedVnicSpec);
      virtualNicConfig.setDevice(vmknic.getDevice());
      virtualNicConfig.setPortgroup("");
      vnicConfigs.add(virtualNicConfig);

      updatedNetworkConfig.getVnic().clear();
      updatedNetworkConfig.getVnic().addAll(
               com.vmware.vcqa.util.TestUtil.arrayToVector(vnicConfigs.toArray(new HostVirtualNicConfig[vnicConfigs.size()])));

      /*
       * Update the host network with the updated Network configuration
       */
      log.info("Update the Network configuration of host with the new configuration");
      if (!networkSystem.updateNetworkConfig(hostNetworkSystem,
               updatedNetworkConfig, TestConstants.CHANGEMODE_MODIFY)) {
         log.error("Failed to update the network configuration of the host: "
                  + hostSystem.getHostName(morHost));
         return false;
      }

      /*
       * Update the DVSwitch with the pnic details
       */
      log.info("Update the DVSwitch configuration");
      DVSConfigSpec deltaConfigSpec = new DVSConfigSpec();
      deltaConfigSpec.setConfigVersion(DVS.getConfigSpec(dvsMOR).getConfigVersion());
      DistributedVirtualSwitchHostMemberConfigSpec dvsHostSpec = new DistributedVirtualSwitchHostMemberConfigSpec();
      dvsHostSpec.setOperation(TestConstants.CONFIG_SPEC_EDIT);
      dvsHostSpec.setHost(morHost);
      dvsHostSpec.setBacking(pnicBacking);
      deltaConfigSpec.getHost().clear();
      if (!DVS.reconfigure(dvsMOR, deltaConfigSpec)) {
         log.error("Reconfiguration of DVSwitch failed");
         return false;
      }

      return networkSystem.refresh(hostNetworkSystem);
   }

   /**
    * The method revert the MigrateVmknicToDVs changes by migrating the vnic
    * device from the DVSwitch back to standard virtualswitch with its
    * associated physicalNics on the given host
    *
    * @param morHost - ManageObjectReference of the host
    * @param vnicDevice - Name of the vnic device to migrate
    * @param dvsMOR - ManageObjectReference of the DVSwitch
    * @param networkSystem - Networksystem of the VC
    * @return true if successfully migrated else false
    * @throws Exception
    */
   public static boolean MigrateVmknicDvsToLegacy(final ConnectAnchor connectAnchor,
                                                  final ManagedObjectReference morHost,
                                                  final String vnicDevice,
                                                  final ManagedObjectReference dvsMOR)
      throws Exception
   {
      /*
       * TODO Migrate the vnic device from the dvs to vswitch by creating new vswitch
       * if one does not exists
       */
      NetworkSystem networkSystem = new NetworkSystem(connectAnchor);
      HostSystem hostSystem = new HostSystem(connectAnchor);
      DistributedVirtualSwitch DVS = new DistributedVirtualSwitch(connectAnchor);
      DistributedVirtualPortgroup iDVPG = new DistributedVirtualPortgroup(
               connectAnchor);
      ManagedObjectReference hostNetworkSystem = networkSystem.getNetworkSystem(morHost);
      DVSConfigInfo info = DVS.getConfig(dvsMOR);
      String dvSwitchUuid = info.getUuid();
      String dvsName = hostSystem.getHostName(dvsMOR);

      HostNetworkInfo networkInfo = null;
      HostPortGroup[] portGroups = null;
      HostVirtualNic vmknic = null;
      HostPortGroup portGroup = null;
      HostVirtualSwitch vmkNicVirtualSwitch = null;
      ManagedObjectReference dvpgMor = null;
      networkInfo = networkSystem.getNetworkInfo(hostNetworkSystem);

      /*
       * Get the vswitch, portgroup and proxyswitch associated with the vmknic
       */

      vmknic = getVmknic(networkInfo, vnicDevice);
      if (vmknic == null) {
         log.error("Unable to find the associated vmknic");
         return false;
      }
      log.info("Successfully found the associated vmkNic");

      HostVirtualNicSpec virtualNicSpec = vmknic.getSpec();
      DistributedVirtualSwitchPortConnection portConnection = virtualNicSpec.getDistributedVirtualPort();
      String dvpgKey = portConnection.getPortgroupKey();
      dvpgMor = iDVPG.getPortgroupMor(dvsMOR, dvpgKey);

      portGroups = com.vmware.vcqa.util.TestUtil.vectorToArray(
               networkInfo.getPortgroup(), com.vmware.vc.HostPortGroup.class);

      for (HostPortGroup portgroup : portGroups) {
         String pgName = portgroup.getSpec().getName();
         if (iDVPG.getConfigInfo(dvpgMor).getName().equals(
                  dvsName + '-' + pgName + '-' + vnicDevice)) {
            portGroup = portgroup;
            break;
         }
      }

      if (portGroup == null) {
         log.error("Unable to find the associated portgroup");
         return false;
      }
      log.info("Successfully found the associated portgroup");

      String vSwitch = portGroup.getVswitch();

      vmkNicVirtualSwitch = getVsiwtch(networkInfo, vSwitch, true);
      if (vmkNicVirtualSwitch == null) {
         log.error("Unable to switch associated with the given vmknic");
         return false;
      }
      log.info("Successfully found the vswitch associated with the vnic");

      HostProxySwitch proxySwitch = getProxySiwtch(networkInfo, dvSwitchUuid);
      if (proxySwitch == null) {
         log.error("Unable to find the associated proxyswitch");
         return false;
      }
      log.info("Successfully found the associated proxyswitch");

      /*
       * Update the vswitch with the physical nics
       */
      log.info("Update the vswitch configuration with the uplink physical nics");
      HostNetworkConfig updatedNetworkConfig = new HostNetworkConfig();

      DistributedVirtualSwitchHostMemberPnicBacking pnicBackingVswitch = (DistributedVirtualSwitchHostMemberPnicBacking) proxySwitch.getSpec().getBacking();
      HostVirtualSwitchConfig hvs[] = updateVswitchPnics(vmkNicVirtualSwitch,
               pnicBackingVswitch, false);
      if (hvs == null) {
         log.error("unable to create the HostvirtualSwitchConfig with given parameters");
         return false;
      }

      updatedNetworkConfig.getVswitch().clear();
      updatedNetworkConfig.getVswitch().addAll(
               com.vmware.vcqa.util.TestUtil.arrayToVector(hvs));

      /*
       * Update the vnic dvs configuration
       */
      log.info("Update the vnic dvs configuration");
      HostProxySwitchConfig originalHostProxySwitchConfig = null;
      HostProxySwitchConfig updatedHostProxySwitchConfig = null;
      originalHostProxySwitchConfig = DVS.getDVSVswitchProxyOnHost(dvsMOR,
               morHost);
      updatedHostProxySwitchConfig = (HostProxySwitchConfig) TestUtil.deepCopyObject(originalHostProxySwitchConfig);
      updatedHostProxySwitchConfig.setChangeOperation(HostConfigChangeOperation.EDIT.value());
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
      updatedHostProxySwitchConfig.setUuid(dvSwitchUuid);

      updatedHostProxySwitchConfig.getSpec().setBacking(pnicBacking);

      if (updatedHostProxySwitchConfig != null) {
         updatedNetworkConfig.getProxySwitch().clear();
         updatedNetworkConfig.getProxySwitch().addAll(
                  com.vmware.vcqa.util.TestUtil.arrayToVector(new HostProxySwitchConfig[] { updatedHostProxySwitchConfig }));
      }

      /*
       * Update the vnic vswitch configurations
       */
      log.info("Update the vnic vswitch configuration");
      List<HostVirtualNicConfig> vnicConfigs = new ArrayList<HostVirtualNicConfig>();
      HostVirtualNicSpec updatedVnicSpec = new HostVirtualNicSpec();
      HostVirtualNicConfig virtualNicConfig = new HostVirtualNicConfig();
      virtualNicConfig.setChangeOperation(TestConstants.HOSTCONFIG_CHANGEOPERATION_EDIT);

      updatedVnicSpec.setPortgroup(portGroup.getSpec().getName());
      virtualNicConfig.setSpec(updatedVnicSpec);
      virtualNicConfig.setDevice(vmknic.getDevice());
      virtualNicConfig.setPortgroup(portGroup.getSpec().getName());
      vnicConfigs.add(virtualNicConfig);

      updatedNetworkConfig.getVnic().clear();
      updatedNetworkConfig.getVnic().addAll(
               com.vmware.vcqa.util.TestUtil.arrayToVector(vnicConfigs.toArray(new HostVirtualNicConfig[vnicConfigs.size()])));

      log.info("Update the Network configuration of host with the new configuration");
      if (!networkSystem.updateNetworkConfig(hostNetworkSystem,
               updatedNetworkConfig, TestConstants.CHANGEMODE_MODIFY)) {
         log.error("Failed to update the network configuration of the host: "
                  + hostSystem.getHostName(morHost));
         return false;
      }

      /*
       * Remove the pnics from DVSwitch
       */
      log.info("Update the DVSwitch configuration");
      DVSConfigSpec deltaConfigSpec = new DVSConfigSpec();
      deltaConfigSpec.setConfigVersion(DVS.getConfigSpec(dvsMOR).getConfigVersion());
      DistributedVirtualSwitchHostMemberConfigSpec dvsHostSpec = new DistributedVirtualSwitchHostMemberConfigSpec();
      dvsHostSpec.setOperation(TestConstants.CONFIG_SPEC_EDIT);
      dvsHostSpec.setHost(morHost);
      dvsHostSpec.setBacking(new DistributedVirtualSwitchHostMemberPnicBacking());
      deltaConfigSpec.getHost().clear();
      if (!DVS.reconfigure(dvsMOR, deltaConfigSpec)) {
         log.error("Reconfiguration of DVSwitch failed");
         return false;
      }

      return networkSystem.refresh(hostNetworkSystem);
   }


   public static boolean startNsxa(ConnectAnchor connectAnchor, String username, String password) throws Throwable {
       return startNsxa(connectAnchor, username, password, "", null,
               "http://vmweb.vmware.com/~netfvt/nsxa/files.txt");
   }

    public static boolean startNsxa(ConnectAnchor connectAnchor, String username,
            String password, String vmnic) throws Exception {
        boolean result = startNsxa(connectAnchor, username, password, vmnic, null,
                "http://vmweb.vmware.com/~netfvt/nsxa/files.txt");
        List<HostOpaqueNetworkInfo> opaqueNetworkInfo = null;
        ManagedObjectReference nsMor = null;
        NetworkSystem ins = new NetworkSystem(connectAnchor);
        HostSystem hs = new HostSystem(connectAnchor);

        List<ManagedObjectReference> hostMorList =
                hs.getAllHost();
         nsxaFailCount = 0;
        for (ManagedObjectReference hostMor: hostMorList) {
            while (true) {
                if (nsxaFailCount > 25) {
                    break;
                }
                try {
                    nsMor = ins.getNetworkSystem(hostMor);
                    opaqueNetworkInfo =
                            ins.getNetworkInfo(nsMor).getOpaqueNetwork();
                    assertTrue(opaqueNetworkInfo != null &&
                            opaqueNetworkInfo.size() > 0,
                          "The list of opaque networks is not null",
                          "The list of opaque networks is null attempt "
                          + nsxaFailCount + " of 25");
                    break;
                } catch (Exception e) {
                    nsxaFailCount++;
                    e.printStackTrace();
                    DVSUtil.stopNsxaOnHost(connectAnchor, username, password, true, hostMor);
                    Thread.sleep(60000*nsxaFailCount);
                    result = DVSUtil.startNsxa(connectAnchor, username, password,
                            vmnic, hostMor, "http://vmweb.vmware.com/~netfvt/nsxa/files.txt");
                }
            }
        }
        return result;
    }

    public static String getDestVCIP() throws Exception {
        String log_dir = System.getenv("ZOO_LOG_DIR");
        if (log_dir == null) {
            log_dir = "../../";
        } else {
            log_dir = log_dir + "/../";
        }
        InputStreamReader isr = new InputStreamReader(
                new FileInputStream(log_dir + "testbed.json"));
        char[] buf = new char[2500];
        int i = isr.read(buf);
        String testbedJson = new String(buf);
        JSONObject jo = new JSONObject(testbedJson);
        return jo.getJSONObject("vc").getJSONObject("2").getString("ip");
    }

    public static String getl3HostIP() throws Exception {
        String log_dir = System.getenv("ZOO_LOG_DIR");
        if (log_dir == null) {
            log_dir = "../../";
        } else {
            log_dir = log_dir + "/../";
        }
        InputStreamReader isr = new InputStreamReader(
                new FileInputStream(log_dir + "testbed.json"));
        char[] buf = new char[2500];
        int i = isr.read(buf);
        String testbedJson = new String(buf);
        JSONObject jo = new JSONObject(testbedJson);
        return jo.getJSONObject("esx").getJSONObject("3").getString("ip");
    }

   public static boolean startNsxa(ConnectAnchor connectAnchor,
                                   String username,
                                   String password,
                                   String vmnic,
                                   ManagedObjectReference inpHostMor,
                                   String nsxa_url) throws Exception {
        NetworkSystem ins = new NetworkSystem(connectAnchor);
        HostSystem hostSystem = new HostSystem(connectAnchor);
        List<ManagedObjectReference> hostMorList = hostSystem.getAllHost();
        if (inpHostMor != null) {
            List<ManagedObjectReference> newHostMorList
            = new ArrayList<ManagedObjectReference>();
            newHostMorList.add(inpHostMor);
            hostMorList = newHostMorList;
        }
        for (ManagedObjectReference hostMor: hostMorList) {
            NetworkSystem ns = new NetworkSystem(connectAnchor);
            String ip = ns.getManagementNwIpConfig(hostMor).getIpAddress();
            log.info("ip of host to ssh to is " + ip);
            Connection conn = SSHUtil.getSSHConnection(ip, username, password);

            URL nsxaFilesURL = new URL(nsxa_url);
            String line = "";
            BufferedReader in = new BufferedReader(
                new InputStreamReader(nsxaFilesURL.openStream()));
            String temp = nsxa_url;
            String nsxpy_url = "";
            nsxa_url = "";
            while ((line = in.readLine()) != null)
            {
                if (nsxa_url.equals("")) {
                    nsxa_url = temp;
                    nsxa_url = temp.replace("/files.txt", "/" + line);
                }
                if (line.contains(".py")) {
                    nsxpy_url = temp;
                    nsxpy_url = temp.replace("/files.txt", "/" + line);
                }
            }

            URL nsxa = new URL(nsxa_url);
            URL nsxpy = new URL(nsxpy_url);
            nsxa_url = temp;
            HttpURLConnection connNSXA = (HttpURLConnection) nsxa.openConnection();
            InputStream input = connNSXA.getInputStream();
            File f = new File("nsxa2");
            f.createNewFile();
            byte[] buffer = new byte[4096];
            int c = -1;
            OutputStream output = new FileOutputStream(f);
            while ((c = input.read(buffer)) != -1)
            {
                if (c > 0) {
                    output.write(buffer, 0, c);
                }
            }
            output.close();

            in = new BufferedReader(
                    new InputStreamReader(nsxpy.openStream()));
            f = new File("nsxaVim2.py");
            f.createNewFile();
            FileWriter content = new FileWriter(f);
            while ((line = in.readLine()) != null)
            {
                content.append(line + "\n");
            }
            content.flush();
            content.close();
            //stopNsxa(connectAnchor, username, password);
            Map<String, String> output1 = SSHUtil.
                    getRemoteSSHCmdOutput(conn, "ps | grep nsxa");
            output1 = null;
            SSHUtil.moveFileToVM(conn, "nsxaVim2.py", "/tmp");
            SSHUtil.moveFileToVM(conn, "nsxa2", "/tmp");
            SSHUtil.getRemoteSSHCmdOutput(conn, "chmod +x /tmp/nsxa2", 30);
            //SSHUtil.getRemoteSSHCmdOutput(conn, "cd /tmp; /tmp/nsxa2 clear", 30);
            String pnicArg = "";

            if (vmnic != null) {
                String vmnicCmd = vmnic;
                if (System.getenv("OPAQUE_NETWORK_UPLINK") != null) {
                    vmnicCmd = System.getenv("OPAQUE_NETWORK_UPLINK");
                }
                pnicArg = " -pnic=\"" + vmnicCmd + "\"";
            }

            Thread.sleep(10000);
            try {
                SSHUtil.getRemoteSSHCmdOutput(conn, "cd /tmp; rm /etc/vmware/.nsxuser", 30);
            } catch (Exception e) {
            }
            try {
                SSHUtil.getRemoteSSHCmdOutput(conn, "cd /tmp; /usr/lib/vmware/auth/bin/deluser nsx-user", 30);
            } catch (Exception e) {
            }
            Thread.sleep(30000);

            SSHUtil.executeRemoteSSHCommand(conn,"sh -c 'cd /tmp; nohup /tmp/nsxa2"
                                           + pnicArg + " > /dev/null 2>&1 &'", 30);
        }
        Thread.sleep(30000);
        return true;
   }

   public static boolean startNsxa(ConnectAnchor connectAnchor,
           String username,
           String password,
           String vmnic,
           int[] host_indexes)
   throws Exception
   {
       boolean startSuccess = false;
       try {
        HostSystem hostSystem = new HostSystem(connectAnchor);
        List<ManagedObjectReference> hostMorList = hostSystem.getAllHost();
        if (host_indexes != null) {
            List<ManagedObjectReference> newHostMorList = new ArrayList<ManagedObjectReference>();
            for (int host_index : host_indexes) {
                newHostMorList.add(hostMorList.get(host_index));
            }
            hostMorList = newHostMorList;
        }
        for (ManagedObjectReference hostMor : hostMorList) {
            NetworkSystem ns = new NetworkSystem(connectAnchor);
            String ip = ns.getName(hostMor);
            log.info("\n ip of host to ssh to is " + ip);
            Connection conn = SSHUtil.getSSHConnection(ip, username, password);

            SSHUtil.executeRemoteSSHCommand(conn, DOWNLOAD_NSXA2_SCRIPT);
            SSHUtil.executeRemoteSSHCommand(conn,
            DOWNLOAD_NSXA_VIM_PYTHON_SCRIPT);

            SSHUtil.getRemoteSSHCmdOutput(conn,
            CHANGE_PERMISSION_NSXA2_EXECUTABLE);

            String pnicArg = "";
            if (vmnic != "") {
                pnicArg = " -pnic=\"" + vmnic + "\"";
            }
            SSHUtil.executeRemoteSSHCommand(conn, START_NSXA2_SIMULATOR
            + pnicArg + REDIRECT_OUTPUT, 30);
            SSHUtil.closeSSHConnection(conn);
          }
          Thread.sleep(30000);
          startSuccess = true;
       } catch (Exception e) {
          log.error("Error while starting nsxa hosts:{}", e.getMessage());
          TestUtil.handleException(e);
       }
       return startSuccess;
   }

   /**
    * Starts nsxa on multiple hosts. The host list can be greater than the
    * number of hosts on which nsxa has to be started. e.g. you can pass in all
    * the hosts in inventory and get n hosts (<= inventory no) with nsxa started
    *
    * @param : ConnectAnchor
    * @param : vmnic to create switch with
    * @param : HostMor's list
    * @param : number of hosts to start nsxa on from the list of hosts (picks 0
    *        to n)
    * @return : list of hosts on which nsxa was started
    */
   public static Vector<ManagedObjectReference> startNsxa(ConnectAnchor connectAnchor,
           String vmnic,
           Vector<ManagedObjectReference> hosts,
           int numberOfHostsToStartNsxa)
      throws Exception
   {
        Vector<ManagedObjectReference> nsxaHosts = new Vector<ManagedObjectReference>();

        Assert.assertTrue(
        hosts.size() >= numberOfHostsToStartNsxa,
        "Number of hosts in the list are less than desired number of hosts to start nsxa on");

        for (int i = 0; i < numberOfHostsToStartNsxa; i++) {
            NetworkSystem ns = new NetworkSystem(connectAnchor);
            ManagedObjectReference hostMor = hosts.get(i);
            String ip = ns.getName(hostMor);
            log.info("\n ip of host to ssh to is " + ip);
            Connection conn = SSHUtil.getSSHConnection(ip,
            TestConstants.ESX_USERNAME, TestConstants.ESX_PASSWORD);

            SSHUtil.executeRemoteSSHCommand(conn, DOWNLOAD_NSXA2_SCRIPT);
            SSHUtil.executeRemoteSSHCommand(conn, DOWNLOAD_NSXA_VIM_PYTHON_SCRIPT);

            SSHUtil.getRemoteSSHCmdOutput(conn, CHANGE_PERMISSION_NSXA2_EXECUTABLE);

            String pnicArg = "";
            if (vmnic != "") {
                pnicArg = " -pnic=\"" + vmnic + "\"";
            }
            SSHUtil.executeRemoteSSHCommand(conn, START_NSXA2_SIMULATOR + pnicArg
            + REDIRECT_OUTPUT, 30);

            SSHUtil.closeSSHConnection(conn);
            nsxaHosts.add(hostMor);
        }

        Thread.sleep(30000);

        if (nsxaHosts.size() > 0) {
            return nsxaHosts;
        } else {
            return null;
        }
   }

   public static boolean checkOpaquePortCreation(ConnectAnchor connectAnchor,
                                            ManagedObjectReference hostMor,
                                            String username,
                                            String password,
                                            int numPorts) throws Exception {

        HostSystem hs = new HostSystem(connectAnchor);
        String ip = hs.getHostName(hostMor);
        Connection conn = SSHUtil.getSSHConnection(ip, username, password);

        Map<String, String> netDVSOutput = SSHUtil.
                getRemoteSSHCmdOutput(conn, "net-dvs");

        int foundPorts = 0;
        for (String key : netDVSOutput.keySet()) {
            if (key.equals("SSHOutputStream")) {
                if (netDVSOutput.get(key).contains
                        ("com.vmware.port.extraConfig.vnic.external.id")) {
                    log.info("opaque network port found");
                    foundPorts++;
                }
            }
        }

        if (foundPorts != numPorts) {
            return false;
        }

       return true;
   }

   public static boolean stopNsxa(ConnectAnchor vcConnectAnchor,
           String username, String password) throws Exception {
       return stopNsxa(vcConnectAnchor, username, password, true);
   }

   /**
    * Stops nsxa on multiple hosts
    *
    * @param : ConnectAnchor
    * @param : host list to stop nsxa
    * @return : true if stopping was succesful else false
    */
   public static boolean stopNsxa(ConnectAnchor connectAnchor,
                                  ArrayList<ManagedObjectReference> hostMorList)
      throws Exception
   {
      boolean isStopped = false;
      try {

         for (ManagedObjectReference hostMor : hostMorList) {
            NetworkSystem ns = new NetworkSystem(connectAnchor);
            String ip = ns.getManagementNwIpConfig(hostMor).getIpAddress();
            Connection conn = SSHUtil.getSSHConnection(ip,
                     TestConstants.ESX_USERNAME, TestConstants.ESX_PASSWORD);
            Map<String, String> output = SSHUtil.getRemoteSSHCmdOutput(conn,
                     GET_NSXA2_PROCESS);
            if (output != null) {
               for (String key : output.keySet()) {
                  if (key.equals(TestConstants.SSH_OUTPUT_STREAM)) {
                     String pid = output.get(key).split(" ")[0];
                     log.info("\n ##### pid = " + pid);
                     SSHUtil.executeRemoteSSHCommand(conn, KILL_PROCESS + pid);
                     // clears opaque switch and opaque network
                     SSHUtil.executeRemoteSSHCommand(conn, CLEAR_NSXA2);

                  }
               }
            }
            SSHUtil.closeSSHConnection(conn);
         }
         Thread.sleep(30000);
         isStopped = true;
      } catch (Exception e) {
         log.error("Error while stopping nsxa {}", e.getMessage());
         TestUtil.handleException(e);
      }
      return isStopped;
   }

   public static boolean isNsxaRunningOnHost(ConnectAnchor connectAnchor,
           ManagedObjectReference hostMor)
      throws Exception
   {
      boolean isRunning = false;
      NetworkSystem ns = new NetworkSystem(connectAnchor);
      String ip = ns.getName(hostMor);
      Connection conn = SSHUtil.getSSHConnection(ip,
               TestConstants.ESX_USERNAME, TestConstants.ESX_PASSWORD);
      Map<String, String> output = SSHUtil.getRemoteSSHCmdOutput(conn,
               GET_NSXA2_PROCESS);
      String pid = null;
      if (output != null) {
         for (String key : output.keySet()) {
            if (key.equals(TestConstants.SSH_OUTPUT_STREAM)) {
                pid = output.get(key).split(" ")[0];
                log.info("\n ##### pid = " + pid);
            }
         }
      }
      if (pid != null || !pid.isEmpty()) {
          isRunning = true;
      }
      SSHUtil.closeSSHConnection(conn);
      return isRunning;
   }

   public static boolean stopNsxaOnHost(ConnectAnchor vcConnectAnchor,
       String username, String password, boolean clear, ManagedObjectReference hostMor)
               throws Exception {

       Boolean failed = false;
       Exception exc = null;
       HostSystem hostSystem = new HostSystem(vcConnectAnchor);
       NetworkSystem ns = new NetworkSystem(vcConnectAnchor);
       String ip = ns.getName(hostMor);
       Connection conn = SSHUtil.getSSHConnection(ip, username, password);

       Map<String, String> netDVSOutput = SSHUtil.
               getRemoteSSHCmdOutput(conn, "net-dvs");

       for (String key : netDVSOutput.keySet()) {
           if (key.equals("SSHOutputStream")) {
               if (netDVSOutput.get(key).contains
                       ("com.vmware.port.extraConfig.vnic.external.id")) {
                   log.info("opaque network port found");
                   exc = new DestroyFailedException();
                   //failed = true;
               }
           }
       }

       Map<String, String> output = SSHUtil.
               getRemoteSSHCmdOutput(conn, "ps | grep nsxa2");
       if (output != null) {
           for (String key : output.keySet()) {
               if (key.equals("SSHOutputStream")) {
                   String pid = output.get(key).split(" ")[0];
                   log.info("pid = " + pid);
                   SSHUtil.executeRemoteSSHCommand(conn, "kill " + pid);
               }
           }
       }
       if (clear) {
           SSHUtil.getRemoteSSHCmdOutput(conn, "cd /tmp; /tmp/nsxa2 clear", 30);
       }

       if (exc != null) {
           throw exc;
       }
       return true;
   }

   public static boolean stopNsxa(ConnectAnchor vcConnectAnchor,
           String username, String password, boolean clear) throws Exception {

       Boolean failed = false;
       Exception exc = null;

        HostSystem hostSystem = new HostSystem(vcConnectAnchor);
        List<ManagedObjectReference> hostMorList = hostSystem.getAllHost();
        for (ManagedObjectReference hostMor: hostMorList) {
            stopNsxaOnHost(vcConnectAnchor, username, password, clear, hostMor);
        }

        return true;
   }

   public static boolean testbedTeardown(ConnectAnchor connectAnchor, boolean recreateNics)
           throws Exception {

        Thread.sleep(3000);

        VirtualMachine vm = new VirtualMachine(connectAnchor);
        Vector<ManagedObjectReference> vmMorList = vm.getAllVM();
        int index = 0;
        if (vmMorList == null) {
            return true;
        }
        recreateNics =  false;
        if (recreateNics) {
            //PrintWriter writer = new PrintWriter("vmList.txt", "UTF-8");
            for (ManagedObjectReference vmMor : vmMorList) {
                index++;
                List<VirtualDevice> vd_list = vm.getDevicesByType
                        (vmMor, VirtualEthernetCard.class.getName());
                if (vd_list != null) {
                    for(VirtualDevice vd : vd_list) {
                        vm.removeVirtualDevice(vmMor, vd.getKey());
                    }
                }
                VirtualMachineConfigSpec vmConfigSpec = new VirtualMachineConfigSpec();
                List<VirtualDeviceConfigSpec> spec = new ArrayList<VirtualDeviceConfigSpec>();
                VirtualEthernetCard vd = new VirtualVmxnet3();
                VirtualEthernetCardNetworkBackingInfo backing
                = new VirtualEthernetCardNetworkBackingInfo();
                backing.setDeviceName("VM Network");
                vd.setBacking(backing);
                VirtualDeviceConfigSpec element = new VirtualDeviceConfigSpec();
                element.setDevice(vd);
                spec.add(0, element);
                spec.add(1, element);
                vmConfigSpec.setDeviceChange(spec);
                vmConfigSpec = getHotAddVMSpec(vmConfigSpec)[1];
                vm.reconfigVM(vmMor, vmConfigSpec);
                //writer.println(
                //      vm.getConfigInfo(vmMor).getFiles().getVmPathName());
                vm.unregisterVM(vmMor);
            }
            //writer.close();
        }
        Thread.sleep(3000);
        return true;
   }

   public static void powerOffVMsOnHost(ConnectAnchor connectAnchor) throws Exception {
       VirtualMachine vm = new VirtualMachine(connectAnchor);

       List<ManagedObjectReference> vmMorList = vm.getAllVM();
       if (vmMorList != null) {
           for (ManagedObjectReference vmMor : vmMorList) {
               try {
                   if (vm.getVMState(vmMor) == VirtualMachinePowerState.POWERED_ON){
                       vm.setVMState(vmMor, VirtualMachinePowerState.POWERED_OFF, false);
                   }
               } catch (Exception e){

               }
               Thread.sleep(10000);
           }
       }
   }

   public static VirtualMachineConfigSpec[] testbedSetup(ConnectAnchor connectAnchor) throws Exception {
       return testbedSetup(connectAnchor, 0);
   }

   public static boolean vdnetVMCheck(ConnectAnchor connectAnchor,
                                      ManagedObjectReference hostMor,
                                      int index) throws Exception {
        VirtualMachine vm = new VirtualMachine(connectAnchor);
        HostSystem hostSystem = new HostSystem(connectAnchor);

        List<ManagedObjectReference> vmMorList
        = hostSystem.getAllVirtualMachine(hostMor);

        if (vmMorList != null) {
            for (ManagedObjectReference vmMor : vmMorList) {
                VirtualMachineFileInfo vmConfigFileInfo =
                        vm.getVMConfigInfo(vmMor).getFiles();
                String path = vmConfigFileInfo.getVmPathName();
                vm.unregisterVM(vmMor);
                vdnetVMReregister(connectAnchor, hostMor, path);
            }
        }

       return true;
   }

   public static VirtualMachineConfigSpec vdnetVMReregister(ConnectAnchor connectAnchor,
                                      ManagedObjectReference hostMor,
                                      String path) throws Exception {
        VirtualMachine vm = new VirtualMachine(connectAnchor);
        HostSystem hostSystem = new HostSystem(connectAnchor);
        Folder folder = new Folder(connectAnchor);
        List<ManagedObjectReference> poolMorList =
                hostSystem.getResourcePool(hostMor);
        ManagedObjectReference vmMor =
                folder.registerVm(vm.getVMFolder(hostMor), path, null, false,
                poolMorList.get(0), hostMor);
        return vm.getVMConfigSpec(vmMor);
   }

   public static VirtualMachineConfigSpec[] registerVMsToHost(
                                            ConnectAnchor connectAnchor,
                                            ManagedObjectReference hostMor,
                                            int index) throws Exception {
        DatastoreSystem dataStoreSystem = new DatastoreSystem(connectAnchor);
        VirtualMachine vm = new VirtualMachine(connectAnchor);
        ManagedObjectReference vmMor1;
        VmHelper vmHelper = new VmHelper(connectAnchor);
        int vmIndex = 0;
        VirtualMachineConfigSpec[] existingVMConfigSpecs
        = new VirtualMachineConfigSpec[2];
        ManagedObjectReference datastoreSystemMor
        = dataStoreSystem.getDatastoreSystem(hostMor);
        try {
            dataStoreSystem.addNasVol("fvt-1/vimapi_vms",
                    "10.115.160.201", "vimapi_vms",
                datastoreSystemMor);
        } catch (Exception e){
            log.info("Datastore already present");
        }

        VirtualMachineConfigSpec[] tempVMConfigSpecs = isSetupDone(connectAnchor, hostMor);
        if (tempVMConfigSpecs != null) {
            return tempVMConfigSpecs;
        }

        vmMor1 = vmHelper.registerVmFromDatastore
                ("rhel-vim-api-regression-" + index + "-standalone",
                        "vimapi_vms", hostMor);
        existingVMConfigSpecs[vmIndex] = vm.getVMConfigSpec(vmMor1);
        index++;
        vmIndex++;
        vmMor1 = vmHelper.registerVmFromDatastore
                ("rhel-vim-api-regression-" + index + "-standalone",
                        "vimapi_vms", hostMor);
        existingVMConfigSpecs[vmIndex] = vm.getVMConfigSpec(vmMor1);

        return existingVMConfigSpecs;
   }

   public static boolean testbedReset(ConnectAnchor connectAnchor)
           throws Exception {
        HostSystem hostSystem = new HostSystem(connectAnchor);
        List<ManagedObjectReference> hostMorList = hostSystem.getAllHost();

        int vmIndex = 0;
        int index = 0;
        for (ManagedObjectReference hostMor : hostMorList) {
            vdnetVMCheck(connectAnchor,hostMor,index);
        }
       return true;
   }

   public static VirtualMachineConfigSpec[] testbedSetup(
           ConnectAnchor connectAnchor, int vmIndexOffset) throws Exception {
        HostSystem hostSystem = new HostSystem(connectAnchor);
        List<ManagedObjectReference> hostMorList = hostSystem.getAllHost();
        VirtualMachine vm = new VirtualMachine(connectAnchor);
        VirtualMachineConfigSpec[] existingVMConfigSpecs
                        = new VirtualMachineConfigSpec[4];

        int index = vmIndexOffset;
        int vmIndex = 0;

        List<ManagedObjectReference> vmMorList = vm.getAllVM();
        if (vmMorList != null) {
            for (ManagedObjectReference vmMor : vmMorList) {
                try {
                vm.setVMState(vmMor, VirtualMachinePowerState.POWERED_OFF, false);
                } catch (Exception e){

                }
            }
        }

        Thread.sleep(10000);

        try {
            BufferedReader br =
                    new BufferedReader(new FileReader("vmList.txt"));
            vmMorList = vm.getAllVM();
            if (vmMorList == null || vmMorList.size() != 4) {
                if (vmMorList != null) {
                    for (ManagedObjectReference vmMor : vmMorList) {
                        vm.unregisterVM(vmMor);
                    }
                }
                for (ManagedObjectReference indHostMor: hostMorList) {
                    try {
                        String path = br.readLine();
                        existingVMConfigSpecs[vmIndex] =
                            vdnetVMReregister(connectAnchor, indHostMor, path);
                        vmIndex++;

                        path = br.readLine();
                        existingVMConfigSpecs[vmIndex] =
                            vdnetVMReregister(connectAnchor, indHostMor, path);
                        vmIndex++;
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                    index++;
                }
                br.close();
            }
        } catch (Exception e) {
            e.printStackTrace();
            PrintWriter writer = new PrintWriter("vmList.txt", "UTF-8");
            for (ManagedObjectReference hostMor : hostMorList) {
                vmMorList
                = hostSystem.getAllVirtualMachine(hostMor);
                if (vmMorList != null) {
                    for (ManagedObjectReference vmMor : vmMorList) {
                        writer.println(
                            vm.getConfigInfo(vmMor).getFiles().getVmPathName());
                    }
                }
            }
            ResetNics(connectAnchor, hostMorList);
            writer.close();
        }

        return existingVMConfigSpecs;
   }

   private static boolean ResetNics(ConnectAnchor connectAnchor,
                                    List<ManagedObjectReference> hostMorList)
                                                throws Exception {
       HostSystem hostSystem = new HostSystem(connectAnchor);
       VirtualMachine vm = new VirtualMachine(connectAnchor);
       for (ManagedObjectReference hostMor : hostMorList) {
            List<ManagedObjectReference> vmMorList
            = hostSystem.getAllVirtualMachine(hostMor);
            if (vmMorList != null) {
                for (ManagedObjectReference vmMor : vmMorList) {
                   List<VirtualDevice> vd_list = vm.getDevicesByType
                            (vmMor, VirtualEthernetCard.class.getName());
                    if (vd_list != null) {
                        if (vd_list.size() != 1) {
                            for(VirtualDevice vd : vd_list) {
                                vm.removeVirtualDevice(vmMor, vd.getKey());
                            }
                        } else {
                            continue;
                        }
                    }
                    VirtualMachineConfigSpec vmConfigSpec = new VirtualMachineConfigSpec();
                    List<VirtualDeviceConfigSpec> spec = new ArrayList<VirtualDeviceConfigSpec>();
                    VirtualEthernetCard vd = new VirtualVmxnet3();
                    VirtualEthernetCardNetworkBackingInfo backing
                    = new VirtualEthernetCardNetworkBackingInfo();
                    backing.setDeviceName("VM Network");
                    vd.setBacking(backing);
                    VirtualDeviceConfigSpec element = new VirtualDeviceConfigSpec();
                    element.setDevice(vd);
                    spec.add(0, element);
                    vmConfigSpec.setDeviceChange(spec);
                    vmConfigSpec = getHotAddVMSpec(vmConfigSpec)[1];
                    vm.reconfigVM(vmMor, vmConfigSpec);
                }
            }
       }
       return true;
   }

   private static VirtualMachineConfigSpec[] isSetupDone(ConnectAnchor connectAnchor,
                                                        ManagedObjectReference hostMor) throws Exception {
       log.info("Starting isSetupDone for host");
        HostSystem hostSystem = new HostSystem(connectAnchor);
        List<ManagedObjectReference> vmMorList
        = hostSystem.getAllVirtualMachine(hostMor);
        VirtualMachine vm = new VirtualMachine(connectAnchor);
        VirtualMachineConfigSpec[] existingVMConfigSpecs
        = new VirtualMachineConfigSpec[2];
        if (vmMorList == null) {
            log.info("Setup not done for host");
            return null;
        }
        if (vmMorList.size() < 2) {
            log.info("Setup not done for host");
            return null;
        }
        existingVMConfigSpecs[0] = vm.getVMConfigSpec(vmMorList.get(0));
        existingVMConfigSpecs[1] = vm.getVMConfigSpec(vmMorList.get(1));
        log.info("Setup is already done for host");
        return existingVMConfigSpecs;
   }

    private static VirtualMachineConfigSpec[] isSetupDone(ConnectAnchor connectAnchor)
            throws Exception {
        HostSystem hostSystem = new HostSystem(connectAnchor);
        List<ManagedObjectReference> hostMorList = hostSystem.getAllHost();
        VirtualMachineConfigSpec[] existingVMConfigSpecs
        = new VirtualMachineConfigSpec[4];

        int index = 0;
        if (hostMorList.size() < 2) {
            ManagedObjectReference hostMor = hostMorList.get(0);

            List<ManagedObjectReference> vmMorList
            = hostSystem.getAllVirtualMachine(hostMor);
            VirtualMachine vm = new VirtualMachine(connectAnchor);

            if (vmMorList == null || vmMorList.size() < 2) {
                return null;
            }
            existingVMConfigSpecs[index] = vm.getVMConfigSpec(vmMorList.get(0));
            index++;
            existingVMConfigSpecs[index] = vm.getVMConfigSpec(vmMorList.get(1));
        } else {
            for (ManagedObjectReference hostMor : hostMorList) {
                List<ManagedObjectReference> vmMorList
                = hostSystem.getAllVirtualMachine(hostMor);
                VirtualMachine vm = new VirtualMachine(connectAnchor);
                if (vmMorList == null) {
                    return null;
                }
                if (vmMorList.size() < 2) {
                    return null;
                }
                existingVMConfigSpecs[index] = vm.getVMConfigSpec(vmMorList.get(0));
                index++;
                existingVMConfigSpecs[index] = vm.getVMConfigSpec(vmMorList.get(1));
            }
        }
        log.info("Setup is already done");

        return existingVMConfigSpecs;
    }

    public static void testbedTeardown(ConnectAnchor connectAnchor)
            throws Exception {
        testbedTeardown(connectAnchor, false);
    }

    public static void cleanupVm(ConnectAnchor connectAnchor,
            ManagedObjectReference vmMor)
      throws Exception{
      Map<String,String> ethernetCardNetworkMap = NetworkUtil.
               getEthernetCardNetworkMap(vmMor, connectAnchor);
      for(String deviceLabel : ethernetCardNetworkMap.keySet()){
         ethernetCardNetworkMap.put(deviceLabel, "VM Network");
      }
      NetworkUtil.reconfigureVMConnectToPortgroup(vmMor,
                           connectAnchor, ethernetCardNetworkMap);
    }

   /**
    * This method is used for spanning a host with pnic across multiple DVS.
    *
    * @param connectAnchor Reference to the ConnectAnchor object
    * @param hostMor ManagedObjectReference of the host to be added.
    * @param dvsMorList List of ManagedObjectReference of the DV Switch.
    * @return true if successful, false otherwise
    * @throws MethodFault, Exception
    */
   public static boolean addSingleFreePnicAndHostToDVS(final ConnectAnchor connectAnchor,
                                                       final ManagedObjectReference hostMor,
                                                       final List<ManagedObjectReference> dvsMorList)
      throws Exception
   {
      boolean result = false;
      int noOfDvs = 0;
      if (connectAnchor != null && hostMor != null && dvsMorList != null) {
         NetworkSystem ins = null;
         ManagedObjectReference dvsMor = null;
         String[] pnicDevices = new String[1];
         ins = new NetworkSystem(connectAnchor);
         noOfDvs = dvsMorList.size();
         /*
          * Check free pnics on the host
          */

         pnicDevices[0] = ins.getPNicIds(hostMor, false)[0];
         if (pnicDevices != null && pnicDevices.length >= noOfDvs) {
            result = true;
            log.info("Found free pnics :" + noOfDvs);
            for (int i = 0; i < noOfDvs; i++) {
               final Map<ManagedObjectReference, String> pNicMap = new HashMap<ManagedObjectReference, String>();
               dvsMor = dvsMorList.get(i);
               pNicMap.put(hostMor, pnicDevices[i]);
               if (!addHostsWithPnicsToDVS(connectAnchor, dvsMor, pNicMap)) {
                  result &= false;
                  break;
               } else {
                  result &= true;
               }
            }
         } else {
            log.warn("Number of free pnics should match"
                     + " with number of DVS");
            result = false;
         }
      } else {
         log.warn("Host Mor and/or DVS list is null");
      }
      return result;
   }

}
