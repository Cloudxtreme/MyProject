/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.functional.standbymode;

import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING;

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
import com.vmware.vc.HostSystemConnectionState;
import com.vmware.vc.HostVirtualNic;
import com.vmware.vc.HostVirtualNicSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.util.VersionConstants;
import com.vmware.vcqa.vim.ClusterComputeResource;

import dvs.VNicBase;

/**
 * Test case for DVS+StandbyMode functionality. Have each host's vmkernel
 * portgroup on a different DVS.
 */
public class Pos004 extends VNicBase
{
   private ManagedObjectReference othernwSystemMor = null;
   private ManagedObjectReference vMotionSystemMor = null;
   private String portgroupKey = null;
   private String origHostVnicId = null;
   private String destHostVnicId = null;
   private String origHostVnicDevice = null;
   private String destHostVnicDevice = null;
   private String dvSwitchUuid = null;
   private ManagedObjectReference clusterMor = null;
   private String clusterName = getTestId() + "-cluster";
   private ManagedObjectReference hostFolderMor = null;
   private ClusterComputeResource icr = null;
   private String hostName = null;
   private Vector<ManagedObjectReference> hostMorsList = new Vector<ManagedObjectReference>();
   private String srcPnicDevice = null;
   private String destPnicDevice = null;
   private Map<ManagedObjectReference, String> hostPnicMap = new HashMap<ManagedObjectReference, String>();
   private ManagedObjectReference destDvsMor = null;
   private String destDvSwitchUuid = null;

   /**
    * Set test description.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("1. Add 2 hosts to a cluster\n "
               + "2.Setup two DVS , add the each hosts' spare nic to the each DVS\n "
               + "3.Test entering, then exiting standby mode on one of the "
               + "hosts ");
   }

   /**
    * Method to setup the environment for the test. 1.Get the
    * hostMor(source/destination). 2.Create the DVS and update the Network.
    * 3.Get the VMMors. 4.Create the DVPortconnection and reconfigure the VM.
    * 5.Verify the PowerOps of VM.
    * 
    * @param connectAnchor ConnectAnchor object
    * @return <code>true</code> if setup is successful.
    */
   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = true;
      HashMap allHosts = null;
      String[] pnicDevices = null;
     
         assertTrue(super.testSetUp(), "Failed to setup the "
                  + "test environment");
         allHosts = ihs.getAllHosts(VersionConstants.ESX4x, HostSystemConnectionState.CONNECTED);
         Set hostsSet = allHosts.keySet();
         assertTrue(hostsSet != null && hostsSet.size() >= 2,
                  "Successfully found the required number of hosts",
                  "Failed to " + "find the required number of hosts");
         Iterator hostsItr = hostsSet.iterator();
         hostMor = (ManagedObjectReference) hostsItr.next();
         hostMorsList.add(hostMor);
         desthostMor = (ManagedObjectReference) hostsItr.next();
         hostMorsList.add(desthostMor);
         assertTrue(hostMor != null && desthostMor != null, "The source and "
                  + "destination host mor need to be valid");
         icr = new ClusterComputeResource(connectAnchor);
         hostFolderMor = iFolder.getHostFolder(iFolder.getDataCenter());
         clusterMor = createCluster(clusterName);
         assertNotNull(clusterMor, "Successfully created " + "cluster  : "
                  + clusterName, "Failed to create a cluster : " + clusterName);
         /*
          * Move two hosts to cluster
          */
         assertTrue(icr.moveInto(clusterMor, new ManagedObjectReference[] {
                  hostMor, desthostMor }),
                  "Successfully moved hosts into cluster ",
                  "Unable to move the hosts to cluster");
         nwSystemMor = ins.getNetworkSystem(hostMor);
         othernwSystemMor = ins.getNetworkSystem(desthostMor);
         assertTrue(
                  nwSystemMor != null && othernwSystemMor != null,
                  "The "
                           + "network system of the source and the destination hosts should "
                           + "not be null ");
         /*
          * Get the free physical nics which have wake on lan support
          */
         pnicDevices = ins.getFreeWakeOnLanEnabledPhysicalNicIds(hostMor);
         assertTrue(
                  pnicDevices != null && pnicDevices.length >= 1,
                  "Failed "
                           + "to find a free pnic with wake on lan support on the source host");
         srcPnicDevice = pnicDevices[0];
         hostPnicMap.put(hostMor, srcPnicDevice);
         dvsMor = createDVS(hostPnicMap);
         hostPnicMap.clear();
         DVSConfigInfo info = iDVSwitch.getConfig(dvsMor);
         dvSwitchUuid = info.getUuid();
         pnicDevices = ins.getFreeWakeOnLanEnabledPhysicalNicIds(desthostMor);
         assertTrue(
                  pnicDevices != null && pnicDevices.length >= 1,
                  "Failed "
                           + "to find a free pnic with wake on lan support on the destination "
                           + "host");
         destPnicDevice = pnicDevices[0];
         hostPnicMap.put(desthostMor, destPnicDevice);
         destDvsMor = createDVS(hostPnicMap);
         info = iDVSwitch.getConfig(destDvsMor);
         destDvSwitchUuid = info.getUuid();
         assertTrue(dvsMor != null && destDvsMor != null, "Both the source "
                  + "and destination vdses were created successfully",
                  "Failed to " + "create the source and the destination vds");
     
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
               + "2.Setup two DVS , add the each hosts' spare nic to the each DVS\n "
               + "3.Test entering, then exiting standby mode on one of the "
               + "hosts ")
   public void test()
      throws Exception
   {
      boolean status = false;
      DistributedVirtualSwitchPortConnection portConnection = null;
      HostVirtualNic vNic = null;
      log.info("test setup Begin:");
      List<String> portKeys = null;
      String destPGKey = null;
     
         // Get the DVPorts on an earlyBinding portgroup and build
         // portconnection.
         portgroupKey = iDVSwitch.addPortGroup(dvsMor,
                  DVPORTGROUP_TYPE_EARLY_BINDING, 1, getTestId() + "-pg");
         assertNotNull(portgroupKey, "The portgroup key is null");
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
                     destPGKey = iDVSwitch.addPortGroup(destDvsMor,
                              DVPORTGROUP_TYPE_EARLY_BINDING, 1, getTestId()
                                       + "-pg1");
                     portKeys = fetchPortKeys(destDvsMor, destPGKey);
                     portConnection = buildDistributedVirtualSwitchPortConnection(
                              destDvSwitchUuid, portKeys.get(0), destPGKey);
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
                              status &= standByModeOps();
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
     
      assertTrue(status, "Test Failed");
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
         if (origHostVnicId != null) {
            status &= ivmotionSystem.selectVnic(
                     ivmotionSystem.getVMotionSystem(hostMor), origHostVnicId);
         }
         if (destHostVnicId != null) {
            status &= ivmotionSystem.selectVnic(
                     ivmotionSystem.getVMotionSystem(desthostMor),
                     destHostVnicId);
         }
         assertTrue((iDVSwitch.destroy(dvsMor)), "Successfully destroyed DVS",
                  "Unable to  destroy DVS");
         assertTrue((iDVSwitch.destroy(destDvsMor)),
                  "Successfully destroyed destDvs",
                  "Unable to  destroy destDvs");
     
      return status;
   }

   private boolean standByModeOps()
   {
      boolean status = false;
      try {
         assertTrue(ihs.enterStandbyMode(hostMor,
                  TestConstants.ENTERSTANDBYMODE_TIMEOUT, Boolean.FALSE),
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
                     TestConstants.EXITSTANDBYMODE_TIMEOUT);
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
      dvsConfigSpec.setName(getTestId() + TestUtil.getShortTime());
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
