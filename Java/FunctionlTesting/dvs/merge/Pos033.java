/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.merge;

import static com.vmware.vcqa.util.Assert.*;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortConfigSpec;
import com.vmware.vc.DVPortSetting;
import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualPort;
import com.vmware.vc.DistributedVirtualSwitchHostMember;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.DistributedVirtualSwitchPortCriteria;
import com.vmware.vc.HostIpConfig;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.HostNetworkInfo;
import com.vmware.vc.HostProxySwitchConfig;
import com.vmware.vc.HostVirtualNic;
import com.vmware.vc.HostVirtualNicSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.VirtualDeviceConfigSpec;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.MessageConstants;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.NetworkSystem;

/**
 * Create a dvswitch( destination) with one standalone host connected to it and
 * another dvswitch (source) with another standalone host connected to it. There
 * exists a VM on the host whose vnic is connected to a standalone DVPort. The
 * host pnic, vmkernelnic and serviceconsolevnic are connected to three
 * different standalone DVPorts
 */
public class Pos033 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference destDvsMor = null;
   private ManagedObjectReference srcDvsMor = null;
   private DistributedVirtualSwitch iDVSwitch = null;
   private HostSystem iHostSystem = null;
   private NetworkSystem iNetworkSystem = null;
   private VirtualMachine ivm = null;
   private ManagedObjectReference destnDvsHostMor = null;
   private ManagedObjectReference srcDvsHostMor = null;
   private ManagedObjectReference firstNetworkMor = null;
   private ManagedObjectReference secondNetworkMor = null;
   private ManagedObjectReference srcfolder = null;
   private ManagedObjectReference destfolder = null;
   private HostNetworkConfig[][] hostNetworkConfig = null;
   private DVSConfigSpec dvsConfigSpec = null;
   private Vector<ManagedObjectReference> hosts = null;
   private int srcMaxPorts = 0;
   private int destnMaxPorts = 0;
   // variables for vm on the host on src dvs
   private ManagedObjectReference vmMor = null;
   private VirtualMachinePowerState oldPowerState = null;
   private VirtualMachineConfigSpec originalVMConfigSpec = null;
   private String vmName = null;
   private DistributedVirtualPort[] srcPorts = null;
   private final DistributedVirtualPort[] destPorts = null;
   private String scVNicId = null;
   private String vmkNicId = null;
   private DistributedVirtualSwitchHostMemberConfigSpec hostConfigSpecElement = null;
   private DistributedVirtualSwitchHostMember[] srcHostMembers = null;
   private boolean merged;
   private String srcDvsName;
   private String dstDvsName;

   @Override
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      boolean destDvsConfigured = false;
      boolean srcDvsConfigured = false;
      final String dvsName = getTestId();
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      iFolder = new Folder(connectAnchor);
      iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
      iHostSystem = new HostSystem(connectAnchor);
      iManagedEntity = new ManagedEntity(connectAnchor);
      iNetworkSystem = new NetworkSystem(connectAnchor);
      ivm = new VirtualMachine(connectAnchor);
      hosts = iHostSystem.getAllHost();
      assertTrue(hosts.size() >= 2, MessageConstants.HOST_GET_FAIL);
      boolean gotSrc = false;
      boolean gotDst = false;
      for (int i = 0; i < hosts.size(); i++) {
         if (!gotSrc && !iHostSystem.isEesxHost(hosts.get(i))) {
            srcDvsHostMor = hosts.get(i);
            gotSrc = true;
            continue;
         }
         if (!gotDst) {
            destnDvsHostMor = hosts.get(i);
            gotDst = true;
            continue;
         }
      }
      assertTrue(gotSrc && gotDst, "Failed to get the hosts.");
      // create the dvs spec
      dvsConfigSpec = new DVSConfigSpec();
      dvsConfigSpec.setConfigVersion("");
      srcDvsName = dvsName + "-src";
      dstDvsName = dvsName + "-dst";
      dvsConfigSpec.setName(srcDvsName);
      hostConfigSpecElement = new DistributedVirtualSwitchHostMemberConfigSpec();
      hostConfigSpecElement.setHost(destnDvsHostMor);
      hostConfigSpecElement.setOperation(TestConstants.CONFIG_SPEC_ADD);
      pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
      pnicBacking.getPnicSpec().clear();
      pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] {}));
      hostConfigSpecElement.setBacking(pnicBacking);
      dvsConfigSpec.getHost().clear();
      dvsConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostConfigSpecElement }));
      final ManagedObjectReference networkFolder = iFolder.getNetworkFolder(iFolder.getDataCenter());
      destfolder = iFolder.createFolder(networkFolder, getTestId()
               + "-destFolder");
      // create the destn dvs
      destDvsMor = iFolder.createDistributedVirtualSwitch(destfolder,
               dvsConfigSpec);
      // get the max ports
      destnMaxPorts = iDVSwitch.getConfig(destDvsMor).getMaxPorts();
      if (destDvsMor != null) {
         log.info("Successfully created the dvswitch");
         hostNetworkConfig = new HostNetworkConfig[2][2];
         hostNetworkConfig[0] = iDVSwitch.getHostNetworkConfigMigrateToDVS(
                  destDvsMor, destnDvsHostMor);
         firstNetworkMor = iNetworkSystem.getNetworkSystem(destnDvsHostMor);
         if (firstNetworkMor != null) {
            if (iNetworkSystem.updateNetworkConfig(firstNetworkMor,
                     hostNetworkConfig[0][0], TestConstants.CHANGEMODE_MODIFY)) {
               // add the ports
               destDvsConfigured = true;
            } else {
               log.error("Update network config " + "failed");
            }
         } else {
            log.error("Network config null");
         }
         hostConfigSpecElement.setHost(srcDvsHostMor);
         dvsConfigSpec = new DVSConfigSpec();
         dvsConfigSpec.getHost().clear();
         dvsConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostConfigSpecElement }));
         dvsConfigSpec.setName(dstDvsName);
         dvsConfigSpec.setNumStandalonePorts(10);
         srcfolder = iFolder.createFolder(networkFolder, getTestId()
                  + "-srcFolder");
         // create the src dvs
         srcDvsMor = iFolder.createDistributedVirtualSwitch(srcfolder,
                  dvsConfigSpec);
         if (srcDvsMor != null) {
            log.info("Successfully created the "
                     + "second distributed virtual switch");
            hostNetworkConfig[1] = iDVSwitch.getHostNetworkConfigMigrateToDVS(
                     srcDvsMor, srcDvsHostMor);
            secondNetworkMor = iNetworkSystem.getNetworkSystem(srcDvsHostMor);
            if (secondNetworkMor != null) {
               iNetworkSystem.updateNetworkConfig(secondNetworkMor,
                        hostNetworkConfig[1][0],
                        TestConstants.CHANGEMODE_MODIFY);
               final DVSConfigInfo srcDvsConfigInfo = iDVSwitch.getConfig(srcDvsMor);
               srcHostMembers = com.vmware.vcqa.util.TestUtil.vectorToArray(srcDvsConfigInfo.getHost(), com.vmware.vc.DistributedVirtualSwitchHostMember.class);
               // get the max ports
               srcMaxPorts = iDVSwitch.getConfig(srcDvsMor).getMaxPorts();
               // create the pg, set the vm to connect to pg
               srcDvsConfigured = configureSrcDvs(connectAnchor);
            } else {
               log.error("Network config null");
            }
         }
      }
      return (destDvsConfigured && srcDvsConfigured);
   }

   /**
    * Method that merges two distributed virtual switches, each containing one
    * host with two uplink portgroups on each switch with the same name
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @Test(description = "Create a dvswitch( destination) with one standalone "
            + "host connected to it and another dvswitch (source) with another "
            + "standalone host connected to it. There exists a VM on the host "
            + "whose vnic is connected to a standalone  DVPort. The host pnic, "
            + "vmkernelnic and serviceconsolevnic are connected to three "
            + "different standalone DVPorts")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      if (iDVSwitch.merge(destDvsMor, srcDvsMor)) {
         log.info("Successfully merged the two switches");
         merged = true;
         if (iNetworkSystem.refresh(secondNetworkMor)) {
            log.info("Successfully refreshed the network system of the host");
            if (iDVSwitch.validateMergedMaxPorts(srcMaxPorts, destnMaxPorts,
                     destDvsMor)) {
               log.info("Hosts max ports verified");
               if (iDVSwitch.validateMergeHostsJoin(srcHostMembers, destDvsMor)) {
                  log.info("Hosts join on merge verified");
                  if (iDVSwitch.validateMergePorts(srcPorts, destPorts,
                           destDvsMor)) {
                     status = true;
                  } else {
                     log.info("Port verification failed");
                  }
               } else {
                  log.info("Hosts join on merge verification failed");
               }
            } else {
               log.info("Max ports verification failed");
            }
         } else {
            log.error("Can not refresh the network system of the host");
         }
      } else {
         log.error("Failed to merge the two switches");
      }
      assertTrue(status, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test was started. Restore
    * the original state of the VM. Destroy the portgroup, followed by the
    * distributed virtual switch
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      /*
       * Restore the original network config
       */
      status = iNetworkSystem.updateNetworkConfig(firstNetworkMor,
               hostNetworkConfig[0][1], TestConstants.CHANGEMODE_MODIFY);
      final HostProxySwitchConfig config = iDVSwitch.getDVSVswitchProxyOnHost(
               destDvsMor, srcDvsHostMor);
      if (config != null) {
         config.setSpec(com.vmware.vcqa.util.TestUtil.vectorToArray(hostNetworkConfig[1][1].getProxySwitch(), com.vmware.vc.HostProxySwitchConfig.class)[0].getSpec());
         hostNetworkConfig[1][1].getProxySwitch().clear();
         hostNetworkConfig[1][1].getProxySwitch().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new HostProxySwitchConfig[] { config }));
      }
      status &= iNetworkSystem.updateNetworkConfig(secondNetworkMor,
               hostNetworkConfig[1][1], TestConstants.CHANGEMODE_MODIFY);
      // restore the vm's state
      status &= cleanUpServiceConsoleNic(connectAnchor);
      status &= cleanUpVmkernelNic(connectAnchor);
      if (vmMor != null) {
         if (originalVMConfigSpec != null) {
            if (ivm.reconfigVM(vmMor, originalVMConfigSpec)) {
               log.info("Successfully reconfigured the VM to its "
                        + "original state");
            } else {
               status &= false;
               log.error("Can not restore the VM back to its original "
                        + "state");
            }
         }
         if (oldPowerState != null) {
            if (ivm.setVMState(vmMor, oldPowerState, false)) {
               log.info("Successfully restored the VM to its original state");
            } else {
               status &= false;
               log.error("Can not restore the original state of the VM");
            }
         }
      }
      // check if src dvs exists
      if (!merged && srcDvsMor == null) {
         srcDvsMor = iFolder.getDistributedVirtualSwitch(srcfolder, srcDvsName);
      }
      if (!merged && srcDvsMor != null) {
         status &= iManagedEntity.destroy(srcDvsMor);
      }
      // check if destn dvs exists
      if (destDvsMor == null) {
         destDvsMor = iFolder.getDistributedVirtualSwitch(destfolder,
                  dstDvsName);
      }
      if (destDvsMor != null) {
         status &= iManagedEntity.destroy(destDvsMor);
      }
      if (destfolder != null) {
         if (iFolder.destroy(destfolder)) {
            log.info("Succesfully destroyed the destination folder");
         } else {
            status &= false;
            log.error("Can not destroy the destination folder");
         }
      }
      if (srcfolder != null) {
         if (iFolder.destroy(srcfolder)) {
            log.info("Succesfully destroyed the source folder");
         } else {
            status &= false;
            log.error("Can not destroy the source folder");
         }
      }
      return status;
   }

   private boolean cleanUpServiceConsoleNic(final ConnectAnchor connectAnchor)
      throws Exception
   {
      boolean status = false;
      if (scVNicId != null
               && iNetworkSystem.removeServiceConsoleVirtualNic(
                        secondNetworkMor, scVNicId)) {
         log.info("Successfully removed the service console Virtual NIC "
                  + scVNicId);
         status = true;
      } else {
         log.error("Unable to remove the service console Virtual NIC "
                  + scVNicId);
      }
      return status;
   }

   private boolean cleanUpVmkernelNic(final ConnectAnchor connectAnchor)
      throws Exception
   {
      boolean status = false;
      if (vmkNicId != null
               && iNetworkSystem.removeVirtualNic(secondNetworkMor, vmkNicId)) {
         log.info("Successfully removed the service console Virtual NIC "
                  + vmkNicId);
         status = true;
      } else {
         log.error("Unable to remove the service console Virtual NIC "
                  + vmkNicId);
      }
      return status;
   }

   private boolean configureSrcDvs(final ConnectAnchor connectAnchor)
      throws Exception
   {
      return configureSrcVm(connectAnchor)
               && configureServiceConsoleVnic(connectAnchor)
               && configureVmkernelNic(connectAnchor);
   }

   /**
    * Configures the src DVS. Retrieve a vm on the src host. Add a portgroup
    * with the num of ports equal to the number of ethernet cards on the vm.
    * Configure the VM to connect to ports on this portgroup.
    *
    * @throws MethodFault,Exception
    */
   private boolean configureSrcVm(final ConnectAnchor connectAnchor)
      throws Exception
   {
      final Map<String, List<String>> excludedPorts = new HashMap<String, List<String>>();
      final List<ManagedObjectReference> allVms = iHostSystem.getVMs(
               srcDvsHostMor, null);
      List<VirtualDeviceConfigSpec> vdConfigSpec = null;
      DistributedVirtualSwitchPortConnection portConnection = null;
      ArrayList<DistributedVirtualSwitchPortConnection> portConnectionList = null;
      VirtualMachineConfigSpec[] vmConfigSpec = null;
      List<String> freePorts = null;
      List<DistributedVirtualPort> ports = null;
      DistributedVirtualSwitchPortCriteria portCriteria = null;
      boolean setUpDone = false;
      DVSConfigInfo dvsConfigInfo = null;
      dvsConfigInfo = iDVSwitch.getConfig(srcDvsMor);
      if (allVms != null && allVms.size() > 0) {
         vmMor = allVms.get(0);
         if (vmMor != null) {
            oldPowerState = ivm.getVMState(vmMor);
            vmName = ivm.getVMName(vmMor);
            setUpDone = ivm.setVMState(vmMor, VirtualMachinePowerState.POWERED_OFF, false);
            if (setUpDone) {
               log.info("Succesfully powered off the vm " + vmName);
               vdConfigSpec = DVSUtil.getAllVirtualEthernetCardDevices(vmMor,
                        connectAnchor);
               if (vdConfigSpec != null) {
                  final int numCards = vdConfigSpec.size();
                  // create a DVPortgroup with number of ports equal to vm
                  // ethernet cards
                  if (numCards > 0) {
                     // these many ports are to be reconfigured for the VM to
                     // connect
                     srcPorts = new DistributedVirtualPort[numCards];
                     for (int i = 0; i < numCards; i++) {
                        final String portKey = iDVSwitch.getFreeStandaloneDVPortKey(
                                 srcDvsMor, excludedPorts);
                        // since the DVPorts are not named, we need to
                        // reconfigure
                        // and provide names.
                        if (portKey != null) {
                           final String dvsPortName = DVSTestConstants.DVS_SOURCE_SUFFIX
                                    + i;
                           /*
                            * For the purpose of this test case, we do not have
                            * ports with same names. Hence reconfigure the port
                            * with the name and store it as the source ports
                            */
                           final DistributedVirtualPort port = reconfigureSrcPort(
                                    portKey, dvsPortName);
                           if (port != null) {
                              if (freePorts == null) {
                                 freePorts = new ArrayList<String>();
                              }
                              freePorts.add(portKey); // add the key
                           }
                        }
                     }
                     if (freePorts != null && freePorts.size() == numCards) {
                        portConnectionList = new ArrayList<DistributedVirtualSwitchPortConnection>(
                                 numCards);
                        for (int i = 0; i < numCards; i++) {
                           portConnection = new DistributedVirtualSwitchPortConnection();
                           portConnection.setPortKey(freePorts.get(i));
                           portConnection.setSwitchUuid(iDVSwitch.getConfig(
                                    srcDvsMor).getUuid());
                           portConnectionList.add(portConnection);
                        }
                        vmConfigSpec = DVSUtil.getVMConfigSpecForDVSPort(
                                 vmMor,
                                 connectAnchor,
                                 portConnectionList.toArray(new DistributedVirtualSwitchPortConnection[portConnectionList.size()]));
                        if (vmConfigSpec != null && vmConfigSpec.length == 2
                                 && vmConfigSpec[0] != null
                                 && vmConfigSpec[1] != null) {
                           originalVMConfigSpec = vmConfigSpec[1];
                           setUpDone = ivm.reconfigVM(vmMor, vmConfigSpec[0]);
                           if (setUpDone) {
                              log.info("Successfully reconfigured"
                                       + " the VM to use the DV " + "Ports");
                              if (iDVSwitch.refreshPortState(
                                       srcDvsMor,
                                       freePorts.toArray(new String[freePorts.size()]))) {
                                 portCriteria = iDVSwitch.getPortCriteria(
                                          true,
                                          null,
                                          null,
                                          null,
                                          freePorts.toArray(new String[freePorts.size()]),
                                          null);
                                 ports = iDVSwitch.fetchPorts(srcDvsMor,
                                          portCriteria);
                                 if (ports != null && ports.size() > 0) {
                                    srcPorts = ports.toArray(new DistributedVirtualPort[ports.size()]);
                                 } else {
                                    log.error("Can not fetch the ports "
                                             + "based on the port "
                                             + "crtieria passed");
                                    setUpDone = false;
                                 }
                              } else {
                                 setUpDone &= false;
                                 log.error("Can not refresh the port state of "
                                          + "the ports");
                              }
                           } else {
                              log.error("Can not reconfigure the"
                                       + " VM to use the DV Ports");
                           }
                        } else {
                           log.error("Can not generate the VM config spec"
                                    + " to connect to the DVPort");
                        }
                     } else {
                        setUpDone = false;
                        log.error("Can not find enough free "
                                 + "standalone ports to "
                                 + "reconfigure the VM");
                     }
                  } else {
                     setUpDone = false;
                     log.error("There are no ethernet cards"
                              + " configured on the vm");
                  }
               } else {
                  setUpDone = false;
                  log.error("The vm does not have any ethernet"
                           + " cards configured");
               }
            }
         } else {
            setUpDone = false;
            log.error("The vm mor object is null");
         }
      } else {
         setUpDone = false;
         log.error("Can not find any vm's on the host");
      }
      assertTrue(setUpDone, "Setup failed");
      return setUpDone;
   }

   /**
    * Configures the src DVS. Setup a service console nic on a DVPort
    *
    * @throws MethodFault,Exception
    */
   private boolean configureServiceConsoleVnic(final ConnectAnchor connectAnchor)
      throws Exception
   {
      boolean status = false;
      String subnetMask = null;
      HostNetworkInfo networkInfo = null;
      HostVirtualNicSpec vnicSpec = null;
      String portkey = null;
      portkey = iDVSwitch.getFreeStandaloneDVPortKey(srcDvsMor, null);
      if (portkey != null) {
         log.info("Successfully get the standalone DVPortkeys");
         final DVSConfigInfo info = iDVSwitch.getConfig(srcDvsMor);
         final String dvSwitchUuid = info.getUuid();
         // create the DistributedVirtualSwitchPortConnection object.
         final DistributedVirtualSwitchPortConnection dvsPortConnection = buildDistributedVirtualSwitchPortConnection(
                  dvSwitchUuid, portkey, null);
         // Get the alternateIPAddress of the host.
         final String ipAddress = iHostSystem.getIPAddress(srcDvsHostMor);
         final String alternateIPAddress = TestUtil.getAlternateServiceConsoleIP(ipAddress);
         networkInfo = iNetworkSystem.getNetworkInfo(secondNetworkMor);
         if (networkInfo != null && com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getConsoleVnic(), com.vmware.vc.HostVirtualNic.class) != null
                  && com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getConsoleVnic(), com.vmware.vc.HostVirtualNic.class).length != 0
                  && com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getConsoleVnic(), com.vmware.vc.HostVirtualNic.class)[0] != null
                  && com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getConsoleVnic(), com.vmware.vc.HostVirtualNic.class)[0].getSpec() != null) {
            vnicSpec = com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getConsoleVnic(), com.vmware.vc.HostVirtualNic.class)[0].getSpec();
            if (vnicSpec != null && vnicSpec.getIp() != null) {
               subnetMask = vnicSpec.getIp().getSubnetMask();
            }
         }
         log.info("AlternateIPAddress : " + alternateIPAddress);
         final HostVirtualNicSpec hostVNicSpec = buildVnicSpec(
                  dvsPortConnection, alternateIPAddress, subnetMask, false);
         scVNicId = iNetworkSystem.addServiceConsoleVirtualNic(
                  secondNetworkMor, "", hostVNicSpec);
         if (scVNicId != null) {
            log.info("Successfully added the service console Virtual NIC "
                     + scVNicId);
            if (DVSUtil.checkNetworkConnectivity(alternateIPAddress, null)) {
               log.info("Successfully established the Network Connection.");
               status = true;
            } else {
               log.error("Failed to establish the Network Connection.");
            }
         } else {
            log.error("Unable to add the service console Virtual NIC");
         }
      } else {
         log.error("Failed to get the standalone DVPortkeys ");
      }
      return status;
   }

   /**
    * Configures the src DVS. Setup a service console nic on a DVPort
    *
    * @throws MethodFault,Exception
    */
   private boolean configureVmkernelNic(final ConnectAnchor connectAnchor)
      throws Exception
   {
      boolean status = false;
      final List<String> portKeys = iDVSwitch.addStandaloneDVPorts(srcDvsMor, 1);
      if (portKeys != null && portKeys.size() > 0) {
         log.info("Successfully get the standalone DVPortkeys");
         final String portKey = portKeys.get(0);
         final DVSConfigInfo info = iDVSwitch.getConfig(srcDvsMor);
         final String dvSwitchUuid = info.getUuid();
         // create the DistributedVirtualSwitchPortConnection object.
         final DistributedVirtualSwitchPortConnection dvsPortConnection = buildDistributedVirtualSwitchPortConnection(
                  dvSwitchUuid, portKey, null);
         vmkNicId = addVnic(srcDvsHostMor, dvsPortConnection);
         if (vmkNicId != null) {
            log.info("Successfully added the vm kernel NIC " + vmkNicId);
            status = true;
         } else {
            log.error("Unable to add the vmkernel NIC");
         }
      } else {
         log.error("Failed to get the standalone DVPortkeys ");
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }

   /**
    * Configures the src DVS. Setup a vmkernel nic on a DVPort
    *
    * @throws MethodFault,Exception
    */
   private String addVnic(final ManagedObjectReference aHostMor,
                          final DistributedVirtualSwitchPortConnection portConnection)
      throws Exception
   {
      String device = null;
      HostVirtualNicSpec hostVnicSpec = null; // use to create VNIC.
      String vnicId = null;
      ManagedObjectReference nsMor = null;// Network System of give host.
      HostNetworkInfo networkInfo = null;
      DistributedVirtualSwitchPortConnection newConn = null;
      try {
         hostVnicSpec = buildVmkernelNicSpec(portConnection, aHostMor);
         nsMor = iNetworkSystem.getNetworkSystem(aHostMor);
         vnicId = iNetworkSystem.addVirtualNic(nsMor, "", hostVnicSpec);
         if (vnicId != null) {
            log.info("Successfully added the virtual Nic.");
            networkInfo = iNetworkSystem.getNetworkInfo(nsMor);
            if (networkInfo != null) {
               final HostVirtualNic[] vNics = com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getVnic(), com.vmware.vc.HostVirtualNic.class);
               if (vNics != null) {
                  for (final HostVirtualNic vnic : vNics) {
                     log.info("Vnic Key: " + vnic.getKey());
                     log.info("Vnic Device: " + vnic.getDevice());
                     if (vnic.getSpec() != null) {
                        newConn = vnic.getSpec().getDistributedVirtualPort();
                        if (newConn != null
                                 && TestUtil.compareObject(portConnection,
                                          newConn,
                                          TestUtil.getIgnorePropertyList(
                                                   portConnection, false))) {
                           device = vnic.getDevice();
                        } else {
                           log.error("Failed to match the PortConnections");
                        }
                     } else {
                        log.error("Failed to get the HostVirtualNicSpec.");
                     }
                  }
               } else {
                  log.error("Failed to get the HostVirtualnic.");
               }
            } else {
               log.error("There are no vnics on the host");
            }
         } else {
            log.error("Failed to  add the virtula Nic.");
         }
      } catch (final Exception e) {
      }
      return device;
   }

   private HostVirtualNicSpec buildVmkernelNicSpec(final DistributedVirtualSwitchPortConnection portConnection,
                                                   final ManagedObjectReference hostMor)
      throws Exception
   {
      HostVirtualNicSpec hostVNicSpec = null;
      if (iHostSystem.isEesxHost(hostMor)) {
         hostVNicSpec = buildVnicSpec(portConnection, null, null, true);
      } else {
         hostVNicSpec = iNetworkSystem.createVNicSpecification();
         hostVNicSpec.setDistributedVirtualPort(portConnection);
      }
      return hostVNicSpec;
   }

   /**
    * Create the DVPortconnection object and set the values.
    *
    * @param switchUuid DVS switch uuid.
    * @param portKey Key of the given port.
    * @param portgroupKey Key of the portgroup.
    * @return connection DistributedVirtualSwitchPortConnection.
    */
   private DistributedVirtualSwitchPortConnection buildDistributedVirtualSwitchPortConnection(final String switchUuid,
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
    * Create HostVirtualNicSpec Object and set the values.
    *
    * @param portConnection DistributedVirtualSwitchPortConnection
    * @param ipAddress IPAddress
    * @param subnetMask subnetMask
    * @param dhcp boolean
    * @return HostVirtualNicSpec
    * @throws MethodFault, Exception
    */
   public HostVirtualNicSpec buildVnicSpec(final DistributedVirtualSwitchPortConnection portConnection,
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
    * Reconfigure the port to set a name to it
    *
    * @param portKey
    * @param portName
    * @return
    * @throws MethodFault
    * @throws Exception
    */
   private DistributedVirtualPort reconfigureSrcPort(final String portKey,
                                                     final String portName)
      throws Exception
   {
      DistributedVirtualPort vp = null;
      DVPortConfigSpec spec = null;
      final DVPortSetting[] portSettingArray = new DVPortSetting[2];
      // get the port config spec
      final DVPortConfigSpec[] specs = iDVSwitch.getPortConfigSpec(srcDvsMor,
               new String[] { portKey });
      if (specs != null && specs.length > 0) {
         spec = specs[0];
         spec.setName(portName);
         spec.setOperation(TestConstants.CONFIG_SPEC_EDIT);
         // reconfigure the port to set the name
         if (iDVSwitch.reconfigurePort(srcDvsMor,
                  new DVPortConfigSpec[] { spec })) {
            // fetch the port config info for storing
            final DistributedVirtualSwitchPortCriteria criteria = iDVSwitch.getPortCriteria(
                     false, null, null, null, new String[] { portKey }, false);
            final List<DistributedVirtualPort> allPorts = iDVSwitch.fetchPorts(
                     srcDvsMor, criteria);
            if (allPorts != null && !allPorts.isEmpty() && allPorts.size() == 1) {
               vp = allPorts.get(0);
               portSettingArray[0] = vp.getConfig().getSetting();
               portSettingArray[1] = iDVSwitch.getConfig(srcDvsMor).getDefaultPortConfig();
               vp.getConfig().setSetting(
                        DVSUtil.computeEffectivePortSetting(portSettingArray));
            }
         }
      }
      return vp;
   }
}
