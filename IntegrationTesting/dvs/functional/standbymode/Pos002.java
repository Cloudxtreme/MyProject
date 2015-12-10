/*
 * ************************************************************************
 *
 * Copyright 2009 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.functional.standbymode;

import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.CHECK_GUEST;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.ClusterConfigSpec;
import com.vmware.vc.ClusterDrsConfigInfo;
import com.vmware.vc.ClusterRuleSpec;
import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.DrsBehavior;
import com.vmware.vc.HostIpConfig;
import com.vmware.vc.HostPortGroupSpec;
import com.vmware.vc.HostSystemConnectionState;
import com.vmware.vc.HostVirtualNic;
import com.vmware.vc.HostVirtualNicSpec;
import com.vmware.vc.HostVirtualSwitchSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.VirtualDeviceConfigSpec;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachineMovePriority;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.util.VersionConstants;
import com.vmware.vcqa.vim.ClusterComputeResource;
import com.vmware.vcqa.vim.dvs.DVSUtil;

import dvs.VNicBase;

/**
 * Test case for DVS+StandbyMode functionality
 */
public class Pos002 extends VNicBase
{
   private ManagedObjectReference othernwSystemMor = null;
   private ManagedObjectReference vmMor = null;
   private VirtualMachinePowerState originalPowerState = null;
   private VirtualMachineConfigSpec originalVMConfigspec = null;
   private ManagedObjectReference vMotionSystemMor = null;
   private List<DistributedVirtualSwitchPortConnection> ports = null;
   private String portgroupKey = null;
   private String origHostVnicId = null;
   private String destHostVnicId = null;
   private String origHostVnicDevice = null;
   private String destHostVnicDevice = null;
   private String dvSwitchUuid = null;
   private boolean reconfigured = false;
   private boolean migrated = false;
   private ManagedObjectReference clusterMor = null;
   private String clusterName = getTestId() + "-cluster";
   private ManagedObjectReference hostFolderMor = null;
   private ClusterComputeResource icr = null;
   private String hostName = null;
   private Vector<ManagedObjectReference> hostMorsList = new Vector<ManagedObjectReference>();
   private String srcPnicDevice = null;
   private String destPnicDevice = null;
   private Map<ManagedObjectReference, String> hostPnicMap = new HashMap<ManagedObjectReference, String>();
   private String srcVswitchID = null;
   private String destvswitchID = null;
   private boolean standByModeOps = false;

   /**
    * Set test description.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("1. Add 2 hosts to a cluster\n "
               + "2.Setup DVS, add the 2 hosts' spare nic to the DVS\n "
               + "3.Add a vmkernel switch w/ vmotion enabled onto the DVS for each host\n"
               + "4.Test migrating a powered on VM between the two hosts "
               + "(to make sure vmotion works) \n" + "5.Power off the vm\n "
               + "6.Test entering, then exiting standby mode on one of the "
               + "hosts & verify both tasks complete successfully "
               + "7.Remove the vmkernel switch from the DVS for each host\n"
               + "8.Remove the DVS from VC\n"
               + "9.Add a legacy vmkernel vnic for vmotion on each host using "
               + "same pnic as was used for the DVS vmkernel nic\n"
               + "10.Test enter/exit standby mode on one of the hosts\n");
   }

   /**
    * Method to setup the environment for the test. 1.Get the
    * hostMor(source/destination). <br>
    * 2.Create the DVS and update the Network. <br>
    * 3.Get the VMMors. <br>
    * 4.Create the DVPortconnection and reconfigure the VM.<br>
    * 5.Varify the PowerOps of VM.<br>
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
      List<String> portKeys = null;
      VirtualMachineConfigSpec[] vmConfigSpec = null;
      DistributedVirtualSwitchPortConnection prtConnection = null;
      HashMap allHosts = null;
      String vmName = null;
      String portKey = null;
      int noOfEthernetCards = 0;
      int numPorts = 0;
      String[] pnicDevices = null;
      log.info("test setup Begin:");
      if (super.testSetUp()) {
        
            // Get the hostMors(source/destination)
            allHosts = ihs.getAllHosts(VersionConstants.ESX4x, HostSystemConnectionState.CONNECTED);
            Set hostsSet = allHosts.keySet();
            if ((hostsSet != null) && (hostsSet.size() > 0)) {
               Iterator hostsItr = hostsSet.iterator();
               if (hostsItr.hasNext()) {
                  hostMor = (ManagedObjectReference) hostsItr.next();
                  hostName = ihs.getHostName(hostMor);
                  hostMorsList.add(hostMor);
               }
               if (hostsItr.hasNext()) {
                  desthostMor = (ManagedObjectReference) hostsItr.next();
                  hostMorsList.add(desthostMor);
               }
            }
            if ((hostMor != null) && (desthostMor != null)) {
               icr = new ClusterComputeResource(connectAnchor);
               /*
                * Create a cluster HA and DRS in auto mode
                */
               hostFolderMor = iFolder.getHostFolder(iFolder.getDataCenter());
               clusterMor = createCluster(clusterName);
               Assert.assertNotNull(clusterMor,
                        "Successfully created cluster  : " + clusterName,
                        "Failed to create a cluster : " + clusterName);
               /*
                * Move two hosts to cluster
                */
               assertTrue(icr.moveInto(clusterMor,
                        new ManagedObjectReference[] { hostMor, desthostMor }),
                        "hosts  moved successfully ",
                        "Unable to move the hosts to cluster");
               nwSystemMor = ins.getNetworkSystem(hostMor);
               othernwSystemMor = ins.getNetworkSystem(desthostMor);
               if ((nwSystemMor != null) && (othernwSystemMor != null)) {
                  // create the DVS by using source and destination host.
                  pnicDevices = ins.getFreeWakeOnLanEnabledPhysicalNicIds(hostMor);
                  if ((pnicDevices != null) && (pnicDevices.length > 0)) {
                     srcPnicDevice = pnicDevices[0];
                     hostPnicMap.put(hostMor, srcPnicDevice);
                  }
                  pnicDevices = ins.getFreeWakeOnLanEnabledPhysicalNicIds(desthostMor);
                  if ((pnicDevices != null) && (pnicDevices.length > 0)) {
                     destPnicDevice = pnicDevices[0];
                     hostPnicMap.put(desthostMor, destPnicDevice);
                  }
                  dvsMor = createDVS(hostPnicMap);
                  if (dvsMor != null) {
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
                           // Get the Standalone DVPortKeys.
                           portKeys = iDVSwitch.addStandaloneDVPorts(dvsMor,
                                    numPorts);
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
                                       status = ivm.reconfigVM(vmMor,
                                                vmConfigSpec[0]);
                                       if (status) {
                                          reconfigured = true;
                                          log.info("Successfully "
                                                   + "reconfigured the VM "
                                                   + vmName);
                                          status = ivm.powerOnVM(vmMor, null,
                                                   CHECK_GUEST);
                                          if (status) {
                                             log.info("Powerops successful.");
                                          } else {
                                             log.error("Powerops failed.");
                                             status = false;
                                          }
                                       } else {
                                          log.error("cannot reconfigure "
                                                   + "the VM." + vmName);
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
   @Test(description = "1. Add 2 hosts to a cluster\n "
               + "2.Setup DVS, add the 2 hosts' spare nic to the DVS\n "
               + "3.Add a vmkernel switch w/ vmotion enabled onto the DVS for each host\n"
               + "4.Test migrating a powered on VM between the two hosts "
               + "(to make sure vmotion works) \n" + "5.Power off the vm\n "
               + "6.Test entering, then exiting standby mode on one of the "
               + "hosts & verify both tasks complete successfully "
               + "7.Remove the vmkernel switch from the DVS for each host\n"
               + "8.Remove the DVS from VC\n"
               + "9.Add a legacy vmkernel vnic for vmotion on each host using "
               + "same pnic as was used for the DVS vmkernel nic\n"
               + "10.Test enter/exit standby mode on one of the hosts\n")
   public void test()
      throws Exception
   {
      boolean status = false;
      DistributedVirtualSwitchPortConnection portConnection = null;
      HostVirtualNic vNic = null;
      log.info("test setup Begin:");
      List<String> portKeys = null;
     
         // Get the DVPorts on an earlyBinding portgroup and build
         // portconnection.
         portgroupKey = iDVSwitch.addPortGroup(dvsMor,
                  DVPORTGROUP_TYPE_EARLY_BINDING, 2, getTestId() + "-PG");
         if (portgroupKey != null) {
            portKeys = fetchPortKeys(dvsMor, portgroupKey);
            portConnection = buildDistributedVirtualSwitchPortConnection(
                     dvSwitchUuid, portKeys.get(0), portgroupKey);
            if (portConnection != null) {
               origHostVnicDevice = ins.addVirtualNic(nwSystemMor, "",
                        this.buildVnicSpec(portConnection, null, null, true));
               if (origHostVnicDevice != null) {
                  vMotionSystemMor = ivmotionSystem.getVMotionSystem(hostMor);
                  vNic = ivmotionSystem.getVmotionVirtualNic(vMotionSystemMor,
                           hostMor);
                  origHostVnicId = vNic.getDevice();
                  status = ivmotionSystem.selectVnic(vMotionSystemMor,
                           origHostVnicDevice);
                  if (status) {
                     log.info("Successfully selected the added vnic to be "
                              + "vmotion virtual nic");
                     portConnection = buildDistributedVirtualSwitchPortConnection(
                              dvSwitchUuid, portKeys.get(1), portgroupKey);
                     if (portConnection != null) {
                        destHostVnicDevice = ins.addVirtualNic(
                                 othernwSystemMor, "", this.buildVnicSpec(
                                          portConnection, null, null, true));
                        if (destHostVnicDevice != null) {
                           vMotionSystemMor = ivmotionSystem.getVMotionSystem(desthostMor);
                           vNic = ivmotionSystem.getVmotionVirtualNic(
                                    vMotionSystemMor, desthostMor);
                           destHostVnicId = vNic.getDevice();
                           status = ivmotionSystem.selectVnic(vMotionSystemMor,
                                    destHostVnicDevice);
                           if (status) {
                              log.info("Successfully selected the newly added "
                                       + "vnic to be the vmotion virtual nic");
                              log.info("Sleeping for 60 seconds for the "
                                       + "vnics to get proper IP's");
                              Thread.sleep(60 * 1000);
                              status = ivm.migrateVM(
                                       vmMor, ihs.getResourcePool(desthostMor).get(0), desthostMor, VirtualMachineMovePriority.DEFAULT_PRIORITY, null);
                              if (status) {
                                 migrated = true;
                                 log.info("Successfully migrated the VM");
                                 /*
                                  * Power off the vm
                                  */
                                 assertTrue(ivm.setVMState(vmMor, VirtualMachinePowerState.POWERED_OFF, false), "Failed to PowerOff VM");
                                 Thread.sleep(1000);
                                 standByModeOps = standByModeOps();
                                 // Remove the virtualNic.
                                 if (destHostVnicDevice != null) {
                                    status &= ins.removeVirtualNic(
                                             othernwSystemMor,
                                             destHostVnicDevice);
                                    if (status) {
                                       destHostVnicDevice = null;
                                       log.info("Successfully remove the existing destHostVnicDevice");
                                    } else {
                                       log.error("Failed to remove the existing destHostVnicDevice");
                                    }
                                 }
                                 if (origHostVnicDevice != null) {
                                    status &= ins.removeVirtualNic(nwSystemMor,
                                             origHostVnicDevice);
                                    if (status) {
                                       origHostVnicDevice = null;
                                       log.info("Successfully remove the existing origHostVnicDevice");
                                    } else {
                                       log.error("Failed to remove the existing origHostVnicDevice");
                                    }
                                 }
                                 if (status && reconfigured) {
                                    if (originalVMConfigspec != null) {
                                       status &= ivm.reconfigVM(vmMor,
                                                originalVMConfigspec);
                                       if (status) {
                                          log.info("Successfully reconfigured the VM back to it's "
                                                   + "original state");
                                          status &= ivm.setVMState(vmMor,
                                                   originalPowerState, false);
                                       } else {
                                          log.error("Can not reconfigure the VM back to it's original"
                                                   + " state");
                                       }
                                    }
                                 }
                                 status = destroy(dvsMor);
                                 /*
                                  *
                                  */
                                 srcVswitchID = "vswitch-src";
                                 HostVirtualSwitchSpec srcSpec = ins.createVSwitchSpecification(
                                          srcVswitchID, hostMor,
                                          new String[] { srcPnicDevice });
                                 status &= ins.addVirtualSwitch(nwSystemMor,
                                          srcVswitchID, srcSpec);
                                 destvswitchID = "vswitch-dst";
                                 HostVirtualSwitchSpec destSpec = ins.createVSwitchSpecification(
                                          destvswitchID, desthostMor,
                                          new String[] { destPnicDevice });
                                 status &= ins.addVirtualSwitch(
                                          othernwSystemMor, destvswitchID,
                                          destSpec);
                                 /*
                                  * add PG
                                  */
                                 String srcPGName = getTestId() + "-src";
                                 HostPortGroupSpec srcPgspec = ins.createPortGroupSpec(srcPGName);
                                 srcPgspec.setVswitchName(srcVswitchID);
                                 status &= ins.addPortGroup(nwSystemMor,
                                          srcPgspec);
                                 String destPGName = getTestId() + "-dst";
                                 HostPortGroupSpec destPgspec = ins.createPortGroupSpec(destPGName);
                                 destPgspec.setVswitchName(destvswitchID);
                                 status &= ins.addPortGroup(othernwSystemMor,
                                          destPgspec);
                                 /*
                                  * add vmknics
                                  */
                                 HostVirtualNicSpec srcVnicSpec = buildVnicSpec(srcPGName);
                                 origHostVnicDevice = ins.addVirtualNic(
                                          nwSystemMor, srcPGName, srcVnicSpec);
                                 vMotionSystemMor = ivmotionSystem.getVMotionSystem(hostMor);
                                 status &= ivmotionSystem.selectVnic(
                                          vMotionSystemMor, origHostVnicDevice);
                                 HostVirtualNicSpec destVnicSpec = buildVnicSpec(destPGName);
                                 destHostVnicDevice = ins.addVirtualNic(
                                          othernwSystemMor, destPGName,
                                          destVnicSpec);
                                 vMotionSystemMor = ivmotionSystem.getVMotionSystem(desthostMor);
                                 status = ivmotionSystem.selectVnic(
                                          vMotionSystemMor, destHostVnicDevice);
                                 /*
                                  * Migratevm
                                  */
                                 if (migrated) {
                                    // Migrate the VM back to source host.
                                    status &= ivm.powerOnVM(vmMor, null,
                                             CHECK_GUEST);
                                    if (status) {
                                       log.info("Powerops successful.");
                                    } else {
                                       log.error("Powerops failed.");
                                       status = false;
                                    }
                                    status &= ivm.migrateVM(
                                             vmMor, ihs.getResourcePool(hostMor).get(0), hostMor, VirtualMachineMovePriority.DEFAULT_PRIORITY, null);
                                    if (status) {
                                       log.info("VM Migrated successfully back to source host.");
                                       assertTrue(
                                                ivm.setVMState(
                                                         vmMor, VirtualMachinePowerState.POWERED_OFF, false),
                                                "Failed to PowerOff VM");
                                       standByModeOps &= standByModeOps();
                                    } else {
                                       log.error("Failed to migrate the VM back to source host.");
                                    }
                                 }
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
                        status = false;
                        log.error("Can not get a free port on the dv switch");
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
               log.error("can not get a free port on the dvswitch");
            }
         } else {
            log.error("Failed to get the DVPortKeys.");
         }
     
      assertTrue(status & standByModeOps, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test is started. 1.
    * Migrate the VM back to Source host. 3. Remove the vNic and DVSMor.
    * 
    * @param connectAnchor ConnectAnchor object
    * @return <code>true</code> if successful.
    */
   @Override
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
     
         if (clusterMor != null) {
            setEnterMaintenanceMode(hostMorsList, false);
            assertTrue((iFolder.moveInto(hostFolderMor,
                     TestUtil.vectorToArray(hostMorsList))),
                     "Moved hosts  successfully", " Move hosts failed ");
            setExitMaintenanceMode(hostMorsList);
            assertTrue((iFolder.destroy(clusterMor)),
                     "Successfully destroyed host", "Unable to  destroy host");
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
         ins.removeVirtualSwitch(nwSystemMor, srcVswitchID, true);
         ins.removeVirtualSwitch(othernwSystemMor, destvswitchID, true);
         assertTrue(ins.refresh(nwSystemMor),
                  "Successfully refreshed  network information",
                  "Unable to   refresh  network information");
         assertTrue(ins.refresh(othernwSystemMor),
                  "Successfully refreshed  network information ",
                  "Unable to   refresh  network information");
     
      return status;
   }

   private boolean standByModeOps()
   {
      boolean status = false;
      try {
         assertTrue(ihs.enterStandbyMode(hostMor,
                  TestConstants.ENTERSTANDBYMODE_NO_TIMEOUT, Boolean.FALSE),
                  "Host entered standby mode: " + hostName,
                  "Host failed to enter standby mode " + hostName);
         status = true;
         /*
          * exit the host out of standby mode
          */
         if (ihs.isHostInStandbyMode(hostMor)) {
            log.info("Issuing exitStandbyMode task to the host "
                     + hostName);
            boolean isExitedStandbyMode = ihs.exitStandbyMode(hostMor,
                     TestConstants.EXITSTANDBYMODE_NO_TIMEOUT);
            if (isExitedStandbyMode) {
               log.info("Host exited standby mode successfully");
               status &= true;
            } else {
               log.error("Host did not exit standby "
                        + "mode successfully");
               status = false;
            }
         } else {
            log.warn("Host not in standby mode");
            log.info("Current power state: "
                     + ihs.getHostPowerState(hostMor));
         }
      } catch (Exception e) {
         e.printStackTrace();
         log.error("standByModeOps  failed");
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }

   /**
    * Method to create the cluster
    * 
    * @param clusterName name of the cluster
    * @return clusterMor
    */
   private ManagedObjectReference createCluster(String clusterName)
      throws Exception
   {
      ManagedObjectReference clusterMor = null;
      if (hostFolderMor != null) {
         log.info("Got the host folder");
         ClusterConfigSpec clusterSpec = iFolder.createClusterSpec();
         ClusterDrsConfigInfo drsConfig = new ClusterDrsConfigInfo();
         drsConfig.setEnabled(false);
         drsConfig.setDefaultVmBehavior(DrsBehavior.FULLY_AUTOMATED);
         clusterSpec.setDrsConfig(drsConfig);
         ClusterRuleSpec ruleSpec[] = new ClusterRuleSpec[0];
         clusterSpec.getRulesSpec().clear();
         clusterSpec.getRulesSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(ruleSpec));
         clusterSpec.getDasConfig().setEnabled(new Boolean(false));
         clusterSpec.getDasConfig().setAdmissionControlEnabled(
                  new Boolean(false));
         clusterMor = iFolder.createCluster(hostFolderMor, clusterName,
                  clusterSpec);
      }
      return clusterMor;
   }

   /**
    * Method to perform enterMaintenanceMode for hosts
    * 
    * @param hostMorsList List of host mors
    * @return
    */
   private void setEnterMaintenanceMode(List<ManagedObjectReference> hostMorsList,
                                        boolean evacuate)
      throws Exception
   {
      String hostName = null;
      for (ManagedObjectReference mor : hostMorsList) {
         hostName = ihs.getHostName(mor);
         if (!ihs.isHostInMaintenanceMode(mor)) {
            if (ihs.enterMaintenanceMode(mor,
                     TestConstants.ENTERMAINTENANCEMODE_TIMEOUT, evacuate)) {
               log.info("Host is in  maintenanceMode:" + hostName);
            } else {
               log.error("Unable to set the "
                        + "enterMaintenanceMode for host :" + hostName);
               throw (new Exception("Unable to set the "
                        + "  enterMaintenanceMode  : " + hostName));
            }
         }
      }
   }

   /**
    * Method to perform exitMaintenanceMode
    * 
    * @param hostMorsList List of host mors
    * @return
    */
   private void setExitMaintenanceMode(List<ManagedObjectReference> hostMorsList)
      throws Exception
   {
      String hostName = null;
      for (ManagedObjectReference mor : hostMorsList) {
         hostName = ihs.getHostName(mor);
         if (ihs.isHostInMaintenanceMode(mor)) {
            if (ihs.exitMaintenanceMode(mor,
                     TestConstants.EXIT_MAINTMODE_DEFAULT_TIMEOUT_SECS)) {
               log.info("Host is in  exitMaintenanceMode :" + hostName);
            } else {
               log.error("Unable to set the exitMaintenanceMode :"
                        + hostName);
               throw (new Exception("Unable to set the exitMaintenanceMode "));
            }
         }
      }
   }

   private ManagedObjectReference createDVS(Map<ManagedObjectReference, String> hostPnicMap)
      throws Exception
   {
      ManagedObjectReference dvsMor = null;
      DistributedVirtualSwitchHostMemberConfigSpec[] hostMembers = new DistributedVirtualSwitchHostMemberConfigSpec[hostPnicMap.size()];
      Set ketSet = hostPnicMap.keySet();
      Iterator itr = ketSet.iterator();
      int i = 0;
      while (itr.hasNext()) {
         ManagedObjectReference hostMor = (ManagedObjectReference) itr.next();
         hostMembers[i] = new DistributedVirtualSwitchHostMemberConfigSpec();
         hostMembers[i].setOperation(TestConstants.CONFIG_SPEC_ADD);
         hostMembers[i].setHost(hostMor);
         DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
         DistributedVirtualSwitchHostMemberPnicSpec pnicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();
         pnicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();
         pnicSpec.setPnicDevice(hostPnicMap.get(hostMor));
         pnicBacking.getPnicSpec().clear();
         pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] { pnicSpec }));
         hostMembers[i].setBacking(pnicBacking);
         i++;
      }
      DVSConfigSpec dvsConfigSpec = new DVSConfigSpec();
      dvsConfigSpec.setConfigVersion("");
      dvsConfigSpec.setName(dvsName);
      dvsConfigSpec.setNumStandalonePorts(1);
      dvsConfigSpec.getHost().clear();
      dvsConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(hostMembers));
      dvsMor = iFolder.createDistributedVirtualSwitch(
               iFolder.getNetworkFolder(iFolder.getDataCenter()), dvsConfigSpec);
      return dvsMor;
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
   public HostVirtualNicSpec buildVnicSpec(String pgName)
      throws Exception
   {
      HostVirtualNicSpec spec = new HostVirtualNicSpec();
      spec.setDistributedVirtualPort(null);
      spec.setPortgroup(pgName);
      HostIpConfig ip = new HostIpConfig();
      ip.setDhcp(true);
      ip.setIpAddress(null);
      ip.setSubnetMask(null);
      spec.setIp(ip);
      return spec;
   }
}
