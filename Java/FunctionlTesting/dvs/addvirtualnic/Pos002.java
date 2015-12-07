/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.addvirtualnic;

import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.CHECK_GUEST;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Set;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.HostSystemConnectionState;
import com.vmware.vc.HostVirtualNic;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualDeviceConfigSpec;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachineMovePriority;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.util.VersionConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;

import dvs.VNicBase;

/**
 * Add a vnic to connect to an existing earlyBinding DVPortgroup on an existing
 * DVSwitch.The distributedVirtualPort is of type
 * DistributedVirtualSwitchPortConnection. Select this vnic to be the Vmkernel
 * nic to be used in vMotion.
 */
public class Pos002 extends VNicBase
{
   private ManagedObjectReference othernwSystemMor = null;
   private HostNetworkConfig origHostNetworkConfig = null;
   private HostNetworkConfig destHostNetworkConfig = null;
   private ManagedObjectReference vmMor = null;
   private VirtualMachinePowerState originalPowerState = null;
   private VirtualMachineConfigSpec originalVMConfigspec = null;
   private ManagedObjectReference vMotionSystemMor = null;
   private List<DistributedVirtualSwitchPortConnection> ports = null;
   private List<String> portKeys = null;
   private String portgroupKey = null;
   private String origHostVnicId = null;
   private String destHostVnicId = null;
   private String origHostVnicDevice = null;
   private String destHostVnicDevice = null;
   private String dvSwitchUuid = null;
   private boolean migrated = false;
   private boolean reconfigured = false;

   /**
    * Set test description.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Add a vmkernel vnic to connect to an "
               + "existing earlyBinding DVPortgroup on an existing DVSwitch. "
               + "The distributedVirtualPort is of type DistributedVirtualSwitchPortConnection. "
               + "Select this vnic to be the Vmkernel nic to be used in vMotion.");
   }

   /**
    * Method to setup the environment for the test. 1.Get the
    * hostMor(source/destination). 2.Create the DVS and update the Network.
    * 3.Get the VMMors. 4.Create the DVPortconnection and reconfigure the VM.
    * 5.Varify the PowerOps of VM.
    * 
    * @param connectAnchor ConnectAnchor object
    * @return <code>true</code> if setup is successful.
    */
   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      Vector<ManagedObjectReference> allVMs = null;
      List<VirtualDeviceConfigSpec> vdConfigSpec = null;
      VirtualMachineConfigSpec[] vmConfigSpec = null;
      DistributedVirtualSwitchPortConnection prtConnection = null;
      HashMap allHosts = null;
      String vmName = null;
      String portKey = null;
      int noOfEthernetCards = 0;
      int numPorts = 0;
      log.info("test setup Begin:");
      if (super.testSetUp()) {
        
            // Get the hostMors(source/destination)
            allHosts = ihs.getAllHosts(VersionConstants.ESX4x, HostSystemConnectionState.CONNECTED);
            Set hostsSet = allHosts.keySet();
            if ((hostsSet != null) && (hostsSet.size() > 0)) {
               Iterator hostsItr = hostsSet.iterator();
               if (hostsItr.hasNext()) {
                  hostMor = (ManagedObjectReference) hostsItr.next();
               }
               if (hostsItr.hasNext()) {
                  desthostMor = (ManagedObjectReference) hostsItr.next();
               }
            }
            if ((hostMor != null) && (desthostMor != null)) {
               nwSystemMor = ins.getNetworkSystem(hostMor);
               othernwSystemMor = ins.getNetworkSystem(desthostMor);
               if ((nwSystemMor != null) && (othernwSystemMor != null)) {
                  // create the DVS by using source and destination host.
                  dvsMor = iFolder.createDistributedVirtualSwitch(dvsName,
                           hostMor, desthostMor);
                  if (dvsMor != null) {
                     // Add the pNics to the DVS.
                     hostNetworkConfig = iDVSwitch.getHostNetworkConfigMigrateToDVS(
                              dvsMor, hostMor);
                     if ((hostNetworkConfig != null)
                              && (hostNetworkConfig.length == 2)
                              && (hostNetworkConfig[0] != null)
                              && (hostNetworkConfig[1] != null)) {
                        origHostNetworkConfig = hostNetworkConfig[1];
                        // Update the Network to use the DVS.
                        status = ins.updateNetworkConfig(nwSystemMor,
                                 hostNetworkConfig[0],
                                 TestConstants.CHANGEMODE_MODIFY);
                        if (status) {
                           hostNetworkConfig = iDVSwitch.getHostNetworkConfigMigrateToDVS(
                                    dvsMor, desthostMor);
                           if ((hostNetworkConfig != null)
                                    && (hostNetworkConfig.length == 2)
                                    && (hostNetworkConfig[0] != null)
                                    && (hostNetworkConfig[1] != null)) {
                              destHostNetworkConfig = hostNetworkConfig[1];
                              status = ins.updateNetworkConfig(
                                       othernwSystemMor, hostNetworkConfig[0],
                                       TestConstants.CHANGEMODE_MODIFY);
                              if (status) {
                                 log.info("successfully connected the host"
                                          + " to the DVS");
                              } else {
                                 log.error("Can not connect the host to the "
                                          + " DVS");
                              }
                           } else {
                              status = false;
                              log.error("Can not retrieve the original and"
                                       + " updated network config info");
                           }
                           // Get the vmMor from host.
                           allVMs = ihs.getAllVirtualMachine(hostMor);
                           if ((allVMs != null) && (allVMs.size() > 0)) {
                              vmMor = allVMs.get(0);
                           }
                           if (vmMor != null) {
                              vmName = ivm.getName(vmMor);
                              vdConfigSpec = DVSUtil.getAllVirtualEthernetCardDevices(
                                       vmMor, connectAnchor);
                              if (vdConfigSpec != null) {
                                 noOfEthernetCards = vdConfigSpec.size();
                                 numPorts += noOfEthernetCards;
                                 // Get the standaloneDVPorts.
                                 portKeys = iDVSwitch.addStandaloneDVPorts(
                                          dvsMor, numPorts);
                                 if ((portKeys != null)
                                          && (portKeys.size() == noOfEthernetCards)) {
                                    DVSConfigInfo info = iDVSwitch.getConfig(dvsMor);
                                    dvSwitchUuid = info.getUuid();
                                    Iterator<String> portIterator = portKeys.iterator();
                                    while (portIterator.hasNext()) {
                                       portKey = portIterator.next();
                                       prtConnection = buildDistributedVirtualSwitchPortConnection(
                                                dvSwitchUuid, portKey, null);
                                       if (prtConnection != null) {
                                          if (ports == null) {
                                             ports = new ArrayList<DistributedVirtualSwitchPortConnection>();
                                          }
                                          ports.add(prtConnection);
                                       } else {
                                          break;
                                       }
                                    }
                                    if ((ports != null)
                                             && (ports.size() == noOfEthernetCards)) {
                                       // Get the deltaconfigspec
                                       vmConfigSpec = DVSUtil.getVMConfigSpecForDVSPort(
                                                vmMor,
                                                connectAnchor,
                                                ports.toArray(new DistributedVirtualSwitchPortConnection[ports.size()]));
                                       if ((vmConfigSpec != null)
                                                && (vmConfigSpec.length == 2)
                                                && (vmConfigSpec[0] != null)
                                                && (vmConfigSpec[1] != null)) {
                                          originalPowerState = ivm.getVMState(vmMor);
                                          status = ivm.setVMState(
                                                   vmMor, VirtualMachinePowerState.POWERED_OFF, false);
                                          if (status) {
                                             // Reconfigure the VM.
                                             originalVMConfigspec = vmConfigSpec[1];
                                             status = ivm.reconfigVM(
                                                      this.vmMor,
                                                      vmConfigSpec[0]);
                                             if (status) {
                                                reconfigured = true;
                                                log.info("Successfully "
                                                         + "reconfigured the VM "
                                                         + vmName);
                                                status = ivm.powerOnVM(vmMor,
                                                         null, CHECK_GUEST);
                                                if (status) {
                                                   log.info("Powerops successful.");
                                                } else {
                                                   log.error("Powerops failed.");
                                                   status = false;
                                                }
                                             } else {
                                                log.error("cannot reconfigure "
                                                         + "the VM. " + vmName);
                                                status = false;
                                             }
                                          }
                                       }
                                    } else {
                                       status = false;
                                    }
                                 }
                              } else {
                                 status = false;
                                 log.error("The vm does not have ethernet "
                                          + "cards configured");
                              }
                           } else {
                              status = false;
                              log.error("Can not find a VM on the host");
                           }
                        }
                     } else {
                        log.error("Can not generate the network config "
                                 + "to update the host DVS");
                     }
                  }
               } else {
                  log.error("The network system Mor is null");
               }
            } else {
               log.error("Unable to find the host.");
            }
        
      }
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Test. 1. Create the hostVirtualNic and add the VirtualNic to the
    * NetworkSystem. 2. Get the HostVNic Id and select the VNic for VMotion 3.
    * Migrate the VM.
    * 
    * @param connectAnchor ConnectAnchor.
    */
   @Override
   @Test(description = "Add a vmkernel vnic to connect to an "
               + "existing earlyBinding DVPortgroup on an existing DVSwitch. "
               + "The distributedVirtualPort is of type DistributedVirtualSwitchPortConnection. "
               + "Select this vnic to be the Vmkernel nic to be used in vMotion.")
   public void test()
      throws Exception
   {
      boolean status = false;
      DistributedVirtualSwitchPortConnection portConnection = null;
      HostVirtualNic vNic = null;
      log.info("test setup Begin:");
     
         // Get the earlyBinding portgroup and build portconnection.
         portgroupKey = iDVSwitch.addPortGroup(dvsMor,
                  DVPORTGROUP_TYPE_EARLY_BINDING, 2, getTestId() + "-PG.");
         if (portgroupKey != null) {
            portConnection = buildDistributedVirtualSwitchPortConnection(
                     dvSwitchUuid, null, portgroupKey);
            if (portConnection != null) {
               origHostVnicDevice = addVnic(hostMor, portConnection);
               if (origHostVnicDevice != null) {
                  vMotionSystemMor = ivmotionSystem.getVMotionSystem(hostMor);
                  vNic = ivmotionSystem.getVmotionVirtualNic(vMotionSystemMor,
                           hostMor);
                  origHostVnicId = (vNic != null) ? vNic.getDevice() : null;
                  status = ivmotionSystem.selectVnic(vMotionSystemMor,
                           origHostVnicDevice);
                  if (status) {
                     log.info("Successfully selected the added vnic to be "
                              + "vmotion virtual nic");
                     destHostVnicDevice = addVnic(desthostMor, portConnection);
                     if (destHostVnicDevice != null) {
                        vMotionSystemMor = ivmotionSystem.getVMotionSystem(desthostMor);
                        vNic = ivmotionSystem.getVmotionVirtualNic(
                                 vMotionSystemMor, desthostMor);
                        destHostVnicId = (vNic != null) ? vNic.getDevice()
                                 : null;
                        status = ivmotionSystem.selectVnic(vMotionSystemMor,
                                 destHostVnicDevice);
                        if (status) {
                           log.info("Successfully selected the newly added "
                                    + "vnic to be the vmotion virtual nic");
                           log.info("Sleeping for 60 seconds for the "
                                    + "vnics to get proper IP's");
                           Thread.sleep(60 * 1000);
                           status = ivm.migrateVM(vmMor, ihs.getResourcePool(
                                             desthostMor).get(0), desthostMor, VirtualMachineMovePriority.DEFAULT_PRIORITY, null);
                           if (status) {
                              migrated = true;
                              log.info("Successfully migrated the VM");
                           } else {
                              log.error("Can not migrate the VM");
                           }
                        } else {
                           log.error("Can not select the newly added "
                                    + "vnic to be the vmotion virtual nic");
                        }
                     } else {
                        status = false;
                        log.error("Can not find the newly added vnic");
                     }
                  } else {
                     log.error("Can not selct the added vnic to be the "
                              + "vmotion virtual nic");
                  }
               } else {
                  log.error("Can not add the virtula nic");
               }
            } else {
               status = false;
               log.error("Failed to get the DVPorts in the portgroup.");
            }
         } else {
            log.error("Failed to get the DVPortKeys.");
         }
     
      assertTrue(status, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test is started. 1.
    * Migrate the VM back to Source host. 3. Remove the vNic and DVSMor.
    * 
    * @param connectAnchor ConnectAnchor object
    * @return <code>true</code> if successful.
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
     
         try {
            if (migrated) { // Migrate the VM back to source host.
               status &= ivm.migrateVM(vmMor, ihs.getResourcePool(hostMor).get(
                                 0), hostMor, VirtualMachineMovePriority.DEFAULT_PRIORITY, null);
               if (status) {
                  log.info("VM Migrated successfully back to source host.");
               } else {
                  log.error("Failed to migrate the VM back to source host.");
               }
            }
         } catch (Exception e) {
            status = false;
            TestUtil.handleException(e);
         }
         try {
            if (reconfigured) {
               status &= ivm.setVMState(vmMor, VirtualMachinePowerState.POWERED_OFF, false);
               if (status && (originalVMConfigspec != null)) {
                  status &= ivm.reconfigVM(vmMor, originalVMConfigspec);
                  if (status) {
                     log.info("Successfully reconfigured the VM back to it's "
                              + "original state");
                     status &= ivm.setVMState(vmMor, originalPowerState, false);
                  } else {
                     log.error("Can not reconfigure the VM back to it's original"
                              + " state");
                  }
               }
            }
         } catch (Exception e) {
            status = false;
            TestUtil.handleException(e);
         }
         // Remove the virtualNic.
         if (destHostVnicDevice != null) {
            status &= ins.removeVirtualNic(othernwSystemMor, destHostVnicDevice);
            if (status) {
               log.info("Successfully remove the existing destHostVnicDevice");
            } else {
               log.error("Failed to remove the existing destHostVnicDevice");
            }
         }
         if (origHostVnicDevice != null) {
            status &= ins.removeVirtualNic(nwSystemMor, origHostVnicDevice);
            if (status) {
               log.info("Successfully remove the existing origHostVnicDevice");
            } else {
               log.error("Failed to remove the existing origHostVnicDevice");
            }
         }
         if (origHostNetworkConfig != null) {
            status &= ins.updateNetworkConfig(nwSystemMor,
                     origHostNetworkConfig, TestConstants.CHANGEMODE_MODIFY);
         }
         if (destHostNetworkConfig != null) {
            status &= ins.updateNetworkConfig(othernwSystemMor,
                     destHostNetworkConfig, TestConstants.CHANGEMODE_MODIFY);
         }
         if (origHostVnicId != null) {
            status &= ivmotionSystem.selectVnic(
                     ivmotionSystem.getVMotionSystem(hostMor), origHostVnicId);
         }
         if (destHostVnicId != null) {
            status &= ivmotionSystem.selectVnic(
                     ivmotionSystem.getVMotionSystem(desthostMor),
                     destHostVnicId);
         }
         status &= super.testCleanUp();
     
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
