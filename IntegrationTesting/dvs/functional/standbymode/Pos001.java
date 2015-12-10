/*
 * ************************************************************************
 *
 * Copyright 2009 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.functional.standbymode;

import static com.vmware.vc.HostSystemConnectionState.CONNECTED;
import static com.vmware.vc.VirtualMachineMovePriority.DEFAULT_PRIORITY;
import static com.vmware.vc.VirtualMachinePowerState.POWERED_OFF;
import static com.vmware.vcqa.util.Assert.assertNotEmpty;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.util.VersionConstants.ESX4x;
import static com.vmware.vcqa.vim.MessageConstants.VM_GET_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.VM_GET_PASS;
import static com.vmware.vcqa.vim.MessageConstants.VM_POWEROFF_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.VM_POWEROFF_PASS;
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

import com.vmware.vc.ClusterConfigSpec;
import com.vmware.vc.ClusterDrsConfigInfo;
import com.vmware.vc.ClusterRuleSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.DrsBehavior;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.HostVirtualNic;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualDeviceConfigSpec;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.util.ThreadUtil;
import com.vmware.vcqa.vim.ClusterComputeResource;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.HostSystemInformation;

import dvs.VNicBase;

/**
 * DESCRIPTION:<br>
 * Test case for DVS+StandbyMode functionality<br>
 * FIXME Need to check why we need VMotion in these tests.<br>
 * <br>
 * TARGET: VC<br>
 * NOTE : Wake on LAN should be enabled for all nics / IPMI should be configured
 * on the host<br>
 * <br>
 * SETUP:<br>
 * 1.Add 2 hosts to a cluster.<br>
 * 2.Setup DVS, add the 2 hosts' spare nic to the DVS <br>
 * TEST:<br>
 * 3.Add a vmkernel switch with vmotion enabled onto the DVS for each host.<br>
 * 4.Test migrating a powered on VM between the two hosts (to make sure vmotion
 * works) <br>
 * 5.Power off the vm <br>
 * 6.Test entering, then exiting standby mode on one of the hosts & verify both
 * tasks complete successfully.<br>
 * CLEANUP:<br>
 * 7. Select the previously select vNICS's for VMotion on both hosts.<br>
 * 8. Delete the cluster after moving the hosts out of it.<br>
 * 9. Remove the added vNIC's<br>
 * 10.Remove the DVS.<br>
 */
public class Pos001 extends VNicBase
{
   private ManagedObjectReference othernwSystemMor = null;
   private HostNetworkConfig origHostNetworkConfig = null;
   private HostNetworkConfig destHostNetworkConfig = null;
   private ManagedObjectReference vmMor = null;
   private VirtualMachineConfigSpec originalVMConfigspec = null;
   private ManagedObjectReference vMotionSystemMor = null;
   private List<DistributedVirtualSwitchPortConnection> portConns = null;
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
   private Vector<ManagedObjectReference> hostMors = new Vector<ManagedObjectReference>();

   /**
    * Set test description.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("1. Add 2 hosts to a cluster \n "
               + "2.Setup DVS, add the 2 hosts' spare nic to the DVS \n "
               + "3.Add a vmkernel switch w/ vmotion enabled onto the DVS for each host \n"
               + "4.Test migrating a powered on VM between the two hosts "
               + "(to make sure vmotion works) \n" + "5.Power off the vm \n "
               + "6.Test entering, then exiting standby mode on one of the "
               + "hosts & verify both tasks complete successfully \n ");
   }

   /**
    * Method to setup the environment for the test.
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
      Vector<ManagedObjectReference> allVMs;
      List<VirtualDeviceConfigSpec> vdCfgSpec;
      List<String> portKeys;
      VirtualMachineConfigSpec[] vmCfgSpecs;
      HashMap<ManagedObjectReference, HostSystemInformation> allHosts;
      String vmName;
      String portKey;
      assertTrue(super.testSetUp(), "Super setup failed");
      allHosts = ihs.getAllHosts(ESX4x, CONNECTED);
      assertNotNull(allHosts, "No hosts found");
      Set<ManagedObjectReference> hostsSet = allHosts.keySet();
      assertTrue(hostsSet.size() >= 2, "Found required number of hosts",
               "Required number of hosts not found");
      final Iterator<ManagedObjectReference> hostsItr = hostsSet.iterator();
      if (hostsItr.hasNext()) {
         hostMor = hostsItr.next();
         hostName = ihs.getHostName(hostMor);
         hostMors.add(hostMor);
      }
      if (hostsItr.hasNext()) {
         desthostMor = hostsItr.next();
         hostMors.add(desthostMor);
      }
      icr = new ClusterComputeResource(connectAnchor);
      hostFolderMor = iFolder.getHostFolder(iFolder.getDataCenter());
      clusterMor = createCluster(clusterName);
      Assert.assertNotNull(clusterMor, "Successfully created cluster  : "
               + clusterName, "Failed to create a cluster : " + clusterName);
      log.info("Moveing both hosts in to the cluster.");
      // assertTrue(ihs.enterMaintenanceMode(hostMor,
      // TestConstants.ENTERMAINTENANCEMODE_TIMEOUT, false),
      // "Could not enter host into maintenance mode");
      // assertTrue(ihs.enterMaintenanceMode(desthostMor,
      // TestConstants.ENTERMAINTENANCEMODE_TIMEOUT, false),
      // "Could not enter host into maintenance mode");
      assertTrue(icr.moveInto(clusterMor, new ManagedObjectReference[] {
               hostMor, desthostMor }), "hosts  moved successfully ",
               "Unable to move the hosts in to cluster");
      // assertTrue(ihs.exitMaintenanceMode(hostMor,
      // TestConstants.EXIT_MAINTMODE_DEFAULT_TIMEOUT_SECS),
      // "Could not exit maintenance mode");
      // assertTrue(ihs.exitMaintenanceMode(desthostMor,
      // TestConstants.EXIT_MAINTMODE_DEFAULT_TIMEOUT_SECS),
      // "Could not exit maintenance mode");
      nwSystemMor = ins.getNetworkSystem(hostMor);
      assertNotNull(nwSystemMor, "NetworkSystem is null");
      othernwSystemMor = ins.getNetworkSystem(desthostMor);
      assertNotNull(othernwSystemMor, "NetworkSystem of other host is null");
      // create the DVS by using source and destination host.
      dvsMor = iFolder.createDistributedVirtualSwitch(dvsName, hostMor,
               desthostMor);
      assertNotNull(dvsMor, "Failed to create the DVS");
      log.info("Successfully create DVS: " + dvsName);
      log.info("Adding pnics of first host to DVS...");
      hostNetworkConfig = iDVSwitch.getHostNetworkConfigMigrateToDVS(dvsMor,
               hostMor);
      assertNotNull(hostNetworkConfig[0],
               "Failed to get new network cfg to migrate to DVS");
      assertNotNull(hostNetworkConfig[1], "Failed to get original network cfg");
      origHostNetworkConfig = hostNetworkConfig[1];
      log.info("Updating the Network to use the DVS.");
      status = ins.updateNetworkConfig(nwSystemMor, hostNetworkConfig[0],
               TestConstants.CHANGEMODE_MODIFY);
      assertTrue(status, "Updated netcfg", "Failed to update netcfg.");
      log.info("Done adding pnics of first host to DVS");
      log.info("Adding pnics of destination host to DVS...");
      hostNetworkConfig = iDVSwitch.getHostNetworkConfigMigrateToDVS(dvsMor,
               desthostMor);
      assertNotNull(hostNetworkConfig[0],
               "Failed to get new network cfg to migrate to DVS");
      assertNotNull(hostNetworkConfig[1], "Failed to get original network cfg");
      destHostNetworkConfig = hostNetworkConfig[1];
      status = ins.updateNetworkConfig(othernwSystemMor, hostNetworkConfig[0],
               TestConstants.CHANGEMODE_MODIFY);
      assertTrue(status, "Updated netcfg", "Failed to update netcfg.");
      log.info("Done adding pnics of destination host to DVS");
      allVMs = ihs.getAllVirtualMachine(hostMor);
      assertNotEmpty(allVMs, VM_GET_PASS, VM_GET_FAIL);
      vmMor = allVMs.get(0);
      vmName = ivm.getName(vmMor);
      status = ivm.setVMState(vmMor, POWERED_OFF, false);
      assertTrue(status, "Failed to power off the VM.");
      vdCfgSpec = DVSUtil.getAllVirtualEthernetCardDevices(vmMor, connectAnchor);
      assertNotNull(vdCfgSpec, "VM does not have ethernet cards configured");
      int numOfEthCards = vdCfgSpec.size();
      log.info("Adding " + numOfEthCards + " standalone DVPorts...");
      portKeys = iDVSwitch.addStandaloneDVPorts(dvsMor, numOfEthCards);
      assertNotEmpty(portKeys, "Failed to add standalone DVPorts");
      // portKeys.size() == numOfEthCards
      dvSwitchUuid = iDVSwitch.getConfig(dvsMor).getUuid();
      Iterator<String> portIterator = portKeys.iterator();
      DistributedVirtualSwitchPortConnection portConn;
      portConns = new ArrayList<DistributedVirtualSwitchPortConnection>();
      while (portIterator.hasNext()) {
         portKey = portIterator.next();
         portConn = buildDistributedVirtualSwitchPortConnection(dvSwitchUuid,
                  portKey, null);
         portConns.add(portConn);
      }
      assertTrue(portConns.size() == numOfEthCards,
               "Failed to create required port connections.");
      vmCfgSpecs = DVSUtil.getVMConfigSpecForDVSPort(vmMor, connectAnchor,
               portConns.toArray(new DistributedVirtualSwitchPortConnection[0]));
      assertNotEmpty(vmCfgSpecs, "Failed to get VM reconfig specs.");
      log.info("Recongigure the vm to use the standalone DVPorts");
      originalVMConfigspec = vmCfgSpecs[1];
      status = ivm.reconfigVM(vmMor, vmCfgSpecs[0]);
      assertTrue(status, "Reconfig VM successful", "Failed to reconfigure VM");
      reconfigured = true;
      log.info("Power on the VM: " + vmName);
      status = ivm.powerOnVM(vmMor, null, CHECK_GUEST);
      assertTrue(status, "Failed to power on the vm");
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Test.
    * 
    * @param connectAnchor ConnectAnchor.
    */
   @Override
   @Test(description = "1. Add 2 hosts to a cluster \n "
               + "2.Setup DVS, add the 2 hosts' spare nic to the DVS \n "
               + "3.Add a vmkernel switch w/ vmotion enabled onto the DVS for each host \n"
               + "4.Test migrating a powered on VM between the two hosts "
               + "(to make sure vmotion works) \n" + "5.Power off the vm \n "
               + "6.Test entering, then exiting standby mode on one of the "
               + "hosts & verify both tasks complete successfully \n ")
   public void test()
      throws Exception
   {
      boolean status = false;
      DistributedVirtualSwitchPortConnection portConnection = null;
      HostVirtualNic vNic = null;
      List<String> portKeys = null;
      // Get the DVPorts on earlyBinding portgroup and build portconnection.
      portgroupKey = iDVSwitch.addPortGroup(dvsMor,
               DVPORTGROUP_TYPE_EARLY_BINDING, 2, getTestId() + "-PG");
      assertNotNull(portgroupKey, "Failed to add the DVPortGroup.");
      portKeys = fetchPortKeys(dvsMor, portgroupKey);
      log.info("Adding VNIC to first host...");
      portConnection = buildDistributedVirtualSwitchPortConnection(
               dvSwitchUuid, portKeys.get(0), portgroupKey);
      origHostVnicDevice = addVnic(hostMor, portConnection);
      assertNotNull(origHostVnicDevice, "Failed to add VNIC.");
      vMotionSystemMor = ivmotionSystem.getVMotionSystem(hostMor);
      vNic = ivmotionSystem.getVmotionVirtualNic(vMotionSystemMor, hostMor);
      if (vNic != null) {
         origHostVnicId = vNic.getDevice();
      }
      status = ivmotionSystem.selectVnic(vMotionSystemMor, origHostVnicDevice);
      assertTrue(status, "Failed to enable VMotion on the added VNIC.");
      log.info("Successfully selected the added vnic as vmotion virtual nic");
      log.info("Adding VNIC to destination host...");
      portConnection = buildDistributedVirtualSwitchPortConnection(
               dvSwitchUuid, portKeys.get(1), portgroupKey);
      destHostVnicDevice = addVnic(desthostMor, portConnection);
      assertNotNull(destHostVnicDevice, "Failed to add VNIC to dest host.");
      vMotionSystemMor = ivmotionSystem.getVMotionSystem(desthostMor);
      vNic = ivmotionSystem.getVmotionVirtualNic(vMotionSystemMor, desthostMor);
      if (vNic != null) {
         destHostVnicId = vNic.getDevice();
      }
      status = ivmotionSystem.selectVnic(vMotionSystemMor, destHostVnicDevice);
      assertTrue(status, "Failed to enable VMotion on the added VNIC.");
      log.info("Successfully selected the added vNIC for VMotion.");
      log.info("Sleeping for 60 seconds for the vNICs to get proper IP's");
      ThreadUtil.sleep(60 * 1000);
      status = ivm.migrateVM(vmMor, ihs.getResourcePool(desthostMor).get(0), desthostMor, DEFAULT_PRIORITY, null);
      assertTrue(status, "Can not migrate the VM");
      migrated = true;
      log.info("Successfully migrated the VM, now power off the VM...");
      assertTrue(ivm.setVMState(vmMor, POWERED_OFF, false), VM_POWEROFF_PASS,
               VM_POWEROFF_FAIL);
      // Thread.sleep(1000);// FIXME why this sleep!
      log.info("Enter standby mode...");
      assertTrue(ihs.enterStandbyMode(hostMor,
               TestConstants.ENTERSTANDBYMODE_NO_TIMEOUT, Boolean.FALSE),
               "Host entered standby mode: " + hostName,
               "Host failed to enter standby mode " + hostName);
      assertTrue(ihs.isHostInStandbyMode(hostMor), "Host in standby mode",
               "Host not in standby mode! CURRENT STATE: "
                        + ihs.getHostPowerState(hostMor));
      log.info("Issuing exitStandbyMode to the host " + hostName);
      status = ihs.exitStandbyMode(hostMor,
               TestConstants.EXITSTANDBYMODE_NO_TIMEOUT);
      assertTrue(status, "Host out of standby", "Host did not exit standby");
   }

   /**
    * Method to restore the state as it was before the test is started.
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
     
         try {
            if (origHostVnicId != null) {
               status &= ivmotionSystem.selectVnic(
                        ivmotionSystem.getVMotionSystem(hostMor),
                        origHostVnicId);
            }
            if (destHostVnicId != null) {
               status &= ivmotionSystem.selectVnic(
                        ivmotionSystem.getVMotionSystem(desthostMor),
                        destHostVnicId);
            }
            if (clusterMor != null) {
               setEnterMaintenanceMode(hostMors, false);
               assertTrue((iFolder.moveInto(hostFolderMor,
                        TestUtil.vectorToArray(hostMors))),
                        "Moved hosts  successfully", "Move hosts failed ");
               setExitMaintenanceMode(hostMors);
               assertTrue((iFolder.destroy(clusterMor)),
                        "Successfully destroyed cluster",
                        "Unable to destroy cluster");
            }
            if (migrated) { // Migrate the VM back to source host.
               status &= ivm.migrateVM(vmMor, ihs.getResourcePool(hostMor).get(
                                 0), hostMor, DEFAULT_PRIORITY, null);
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
                     // status &= ivm.setVMState(vmMor, originalPowerState,
                     // false);
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
         status &= super.testCleanUp();
     
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
}
