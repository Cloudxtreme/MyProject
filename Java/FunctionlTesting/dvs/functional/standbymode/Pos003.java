/*
 * ************************************************************************
 *
 * Copyright 2009 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.functional.standbymode;

import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING;

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
import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.DrsBehavior;
import com.vmware.vc.HostIpConfig;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.HostSystemConnectionState;
import com.vmware.vc.HostVirtualNicConfig;
import com.vmware.vc.HostVirtualNicSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.util.VersionConstants;
import com.vmware.vcqa.vim.ClusterComputeResource;

import dvs.VNicBase;

/**
 * Test entering, then exiting standby mode on one of the hosts when one host's
 * vmkernel portgroup on the DVS, and the other host's vmkernel on the regular
 * vswitch
 */
public class Pos003 extends VNicBase
{
   private String dvSwitchUuid = null;
   private HostVirtualNicSpec origVnicSpec = null;
   private String vNicdevice = null;
   private String aPortKey = null;
   private String portgroupKey = null;
   private String hostName;
   private Vector<ManagedObjectReference> hostMorsList = new Vector<ManagedObjectReference>();
   private ManagedObjectReference hostFolderMor = null;
   private ClusterComputeResource icr = null;
   private ManagedObjectReference clusterMor = null;
   private String clusterName = getTestId() + "-cluster";

   /**
    * Set test description.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Test entering, then exiting standby mode on one of the hosts when "
               + " one host's vmkernel portgroup on the DVS, and the other host's vmkernel on "
               + " * the regular vswitch");
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
      DVSConfigSpec dvsConfigSpec = null;
      List<String> portKeys = null;
      DistributedVirtualSwitchHostMemberConfigSpec hostMember = null;
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      DistributedVirtualSwitchHostMemberPnicSpec pnicSpec = null;
      HashMap allHosts = null;
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
            if (hostMor != null) {
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
               /*
                * Check for free Pnics
                */
               String[] freePnics = ins.getFreeWakeOnLanEnabledPhysicalNicIds(hostMor);
               if ((freePnics != null) && (freePnics.length > 0)) {
                  nwSystemMor = ins.getNetworkSystem(hostMor);
                  if (nwSystemMor != null) {
                     hostMember = new DistributedVirtualSwitchHostMemberConfigSpec();
                     hostMember.setOperation(TestConstants.CONFIG_SPEC_ADD);
                     hostMember.setHost(hostMor);
                     pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
                     pnicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();
                     pnicSpec.setPnicDevice(freePnics[0]);
                     pnicBacking.getPnicSpec().clear();
                     pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] { pnicSpec }));
                     hostMember.setBacking(pnicBacking);
                     dvsConfigSpec = new DVSConfigSpec();
                     dvsConfigSpec.setConfigVersion("");
                     dvsConfigSpec.setName(getTestId());
                     dvsConfigSpec.getHost().clear();
                     dvsConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostMember }));
                     dvsMor = iFolder.createDistributedVirtualSwitch(
                              iFolder.getNetworkFolder(iFolder.getDataCenter()),
                              dvsConfigSpec);
                     if ((dvsMor != null)
                              && ins.refresh(nwSystemMor)
                              && iDVSwitch.validateDVSConfigSpec(dvsMor,
                                       dvsConfigSpec, null)) {
                        log.info("Successfully created the distributed "
                                 + "virtual switch");
                        portgroupKey = iDVSwitch.addPortGroup(dvsMor,
                                 DVPORTGROUP_TYPE_EARLY_BINDING, 1, getTestId()
                                          + "-pg1");
                        if (portgroupKey != null) {
                           // Get the existing DVPortkey on earlyBinding
                           // DVPortgroup.
                           portKeys = fetchPortKeys(dvsMor, portgroupKey);
                           aPortKey = portKeys.get(0);
                           HostNetworkConfig nwCfg = ins.getNetworkConfig(nwSystemMor);
                           if ((nwCfg != null) && (com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getVnic(), com.vmware.vc.HostVirtualNicConfig.class) != null)
                                    && (com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getVnic(), com.vmware.vc.HostVirtualNicConfig.class).length > 0)
                                    && (com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getVnic(), com.vmware.vc.HostVirtualNicConfig.class)[0] != null)) {
                              HostVirtualNicConfig vnicConfig = com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getVnic(), com.vmware.vc.HostVirtualNicConfig.class)[0];
                              origVnicSpec = vnicConfig.getSpec();
                              vNicdevice = vnicConfig.getDevice();
                              log.info("VnicDevice : " + vNicdevice);
                              status = true;
                           } else {
                              log.error("Unable to find valid Vnic");
                           }
                        }
                     } else {
                        log.error("Unable to create DistributedVirtualSwitch");
                     }
                  } else {
                     log.error("The network system Mor is null");
                  }
               } else {
                  log.error("Unable to get free pnics");
               }
            } else {
               log.error("Unable to find the host.");
            }
        
      }
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Test.
    * 
    * @param connectAnchor ConnectAnchor.
    */
   @Override
   @Test(description = "Test entering, then exiting standby mode on one of the hosts when "
               + " one host's vmkernel portgroup on the DVS, and the other host's vmkernel on "
               + " * the regular vswitch")
   public void test()
      throws Exception
   {
      boolean status = false;
      DistributedVirtualSwitchPortConnection portConnection = null;
      HostVirtualNicSpec updatedVNicSpec = null;
      log.info("test setup Begin:");
     
         DVSConfigInfo info = iDVSwitch.getConfig(dvsMor);
         dvSwitchUuid = info.getUuid();
         // create the DistributedVirtualSwitchPortConnection object.
         portConnection = buildDistributedVirtualSwitchPortConnection(
                  dvSwitchUuid, aPortKey, portgroupKey);
         ;
         if (portConnection != null) {
            updatedVNicSpec = (HostVirtualNicSpec) TestUtil.deepCopyObject(origVnicSpec);
            updatedVNicSpec.setDistributedVirtualPort(portConnection);
            updatedVNicSpec.setPortgroup(null);
            HostIpConfig ipconfig = updatedVNicSpec.getIp();
            ipconfig.setIpV6Config(null);
            if (ins.updateVirtualNic(nwSystemMor, vNicdevice, updatedVNicSpec)) {
               log.info("Successfully updated VirtualNic " + vNicdevice);
               status = standByModeOps();
            } else {
               log.info("Unable to update VirtualNic " + vNicdevice);
               status = false;
            }
         } else {
            status = false;
            log.error("can not get a free port on the dvswitch");
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
     
         if (clusterMor != null) {
            setEnterMaintenanceMode(hostMorsList, false);
            assertTrue(
                     (iFolder.moveInto(
                              hostFolderMor,
                              (ManagedObjectReference[]) TestUtil.vectorToArray(hostMorsList))),
                     "Moved hosts  successfully", " Move hosts failed ");
            setExitMaintenanceMode(hostMorsList);
            assertTrue((iFolder.destroy(clusterMor)),
                     "Successfully destroyed host", "Unable to  destroy host");
         }
         try {
            if (origVnicSpec != null) {
               if (ins.updateVirtualNic(nwSystemMor, vNicdevice, origVnicSpec)) {
                  log.info("Successfully restored original VirtualNic "
                           + "config: " + vNicdevice);
               } else {
                  log.info("Unable to update VirtualNic " + vNicdevice);
                  status = false;
               }
            }
         } catch (Exception e) {
            status = false;
            TestUtil.handleException(e);
         }
         status &= super.testCleanUp();
     
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
}
