/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.addportgroups;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.Arrays;
import java.util.List;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.util.VersionConstants;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.NetworkSystem;

/**
 * Add a ephemeral portgroup to an existing distributed virtual switch and
 * reconfigure 2 VMs to connect its VNICs to this portgroup
 */
public class Pos063 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference rootFolderMor = null;
   private ManagedObjectReference dvsMor = null;
   private DVSConfigSpec dvsConfigSpec = null;
   private DistributedVirtualSwitch iDVSwitch = null;
   private VirtualMachine iVirtualMachine = null;
   private HostSystem iHostSystem = null;
   private NetworkSystem iNetworkSystem = null;
   private ManagedObjectReference hostMor = null;
   private ManagedObjectReference[] vmMor = null;
   private ManagedObjectReference nsMor = null;
   private DVPortgroupConfigSpec dvPortgroupConfigSpec = null;
   private HostNetworkConfig[] hostNetworkConfig = null;
   private HostNetworkConfig originalNetworkConfig = null;
   private VirtualMachinePowerState[] vmPowerState = null;
   private DistributedVirtualSwitchHostMemberConfigSpec hostConfigSpecElement = null;
   private List<ManagedObjectReference> dvPortgroupMorList = null;
   private DVPortgroupConfigSpec[] dvPortgroupConfigSpecArray = null;
   private DistributedVirtualSwitchPortConnection portConnection = null;
   private VirtualMachineConfigSpec[] origVMConfigSpec = null;
   private DistributedVirtualPortgroup iDVPortgroup = null;
   private String portgroupKey = null;
   private VirtualMachineConfigSpec[][] updatedDeltaConfigSpec = null;
   private ManagedObjectReference dcMor = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      setTestDescription("Add a ephemeral portgroup to an existing"
               + "distributed virtual switch and reconfigure"
               + "two VMs to connect to this portgroup");
   }

   /**
    * Method to setup the environment for the test. This method creates a
    * distributed virtual switch.
    * 
    * @param connectAnchor ConnectAnchor object
    * @return boolean true if successful, false otherwise.
    */
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      final String dvsName = DVSTestConstants.DVS_CREATE_NAME_PREFIX
               + getTestId();
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      Vector allVMs = null;

      log.info("Test setup Begin:");
     
         this.iFolder = new Folder(connectAnchor);
         this.iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
         this.iDVPortgroup = new DistributedVirtualPortgroup(connectAnchor);
         this.iVirtualMachine = new VirtualMachine(connectAnchor);
         this.iHostSystem = new HostSystem(connectAnchor);
         this.iManagedEntity = new ManagedEntity(connectAnchor);
         this.iNetworkSystem = new NetworkSystem(connectAnchor);
         dcMor = this.iFolder.getDataCenter();
         /*
          * Get a standalone host of version 4.0
          */
         this.hostMor = this.iHostSystem.getAllHost().get(0);
         /*
          * If there is no standalone host available,  try to 
          * get a clustered host of version 4.0
          */
         if (this.hostMor == null) {
            this.hostMor = this.iHostSystem.getClusteredHost();
            if (TestUtil.compareVersion(
                     this.iHostSystem.getHostVersion(this.hostMor),
                     VersionConstants.ESX400) != VersionConstants.EQUAL_VERSION) {
               this.hostMor = null;
            }
         }
         if (hostMor != null) {
            this.rootFolderMor = this.iFolder.getRootFolder();
            if (this.rootFolderMor != null) {
               this.dvsConfigSpec = new DVSConfigSpec();
               this.dvsConfigSpec.setConfigVersion("");
               this.dvsConfigSpec.setName(dvsName);
               hostConfigSpecElement = new DistributedVirtualSwitchHostMemberConfigSpec();
               hostConfigSpecElement.setHost(hostMor);
               hostConfigSpecElement.setOperation(TestConstants.CONFIG_SPEC_ADD);
               pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
               pnicBacking.getPnicSpec().clear();
               pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] {}));
               hostConfigSpecElement.setBacking(pnicBacking);
               this.dvsConfigSpec.getHost().clear();
               this.dvsConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostConfigSpecElement }));
               dvsMor = this.iFolder.createDistributedVirtualSwitch(
                        this.iFolder.getNetworkFolder(dcMor), dvsConfigSpec);
               if (dvsMor != null) {
                  log.info("Successfully created the distributed "
                           + "virtual switch");
                  hostNetworkConfig = this.iDVSwitch.getHostNetworkConfigMigrateToDVS(
                           this.dvsMor, this.hostMor);
                  this.nsMor = this.iNetworkSystem.getNetworkSystem(hostMor);
                  if (nsMor != null) {
                     this.iNetworkSystem.updateNetworkConfig(nsMor,
                              hostNetworkConfig[0],
                              TestConstants.CHANGEMODE_MODIFY);
                     this.originalNetworkConfig = hostNetworkConfig[1];
                     allVMs = this.iHostSystem.getVMs(hostMor, null);
                     /*
                      * Get the first VM in the list of VMs.
                      */
                     if (allVMs != null && allVMs.size() >= 2) {
                        this.vmMor = new ManagedObjectReference[] {
                                 (ManagedObjectReference) allVMs.get(0),
                                 (ManagedObjectReference) allVMs.get(1) };
                     }
                     if (this.vmMor != null) {
                        this.vmPowerState = new VirtualMachinePowerState[vmMor.length];
                        for (int j = 0; j < vmMor.length; j++) {
                           this.vmPowerState[j] = this.iVirtualMachine.getVMState(vmMor[j]);
                        }
                        if (this.iVirtualMachine.setVMsState(
                                 new Vector<ManagedObjectReference>(
                                          Arrays.asList(vmMor)), VirtualMachinePowerState.POWERED_OFF, false)) {
                           log.info("Successfully powered off the"
                                    + " virtual machines");
                           this.dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
                           this.dvPortgroupConfigSpec.setConfigVersion("");
                           this.dvPortgroupConfigSpec.setName(this.getTestId());
                           this.dvPortgroupConfigSpec.setDescription(DVSTestConstants.DVPORTGROUP_VALID_DESCRIPTION);
                           this.dvPortgroupConfigSpec.setNumPorts(0);
                           this.dvPortgroupConfigSpec.setType(DVSTestConstants.DVPORTGROUP_TYPE_EPHEMERAL);
                           status = true;
                        }
                     }
                  }
               } else {
                  log.error("Failed to create the distributed "
                           + "virtual switch");
               }
            } else {
               log.error("Failed to find a folder");
            }
         } else {
            log.error("Failed to login");
         }
     
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that adds a late binding portgroup to the distributed virtual
    * switch and 2 VMs are reconfigured to connect its VNICs to the created
    * portgroup
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Add a ephemeral portgroup to an existing"
               + "distributed virtual switch and reconfigure"
               + "two VMs to connect to this portgroup")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      DVSConfigInfo dvsConfigInfo = null;
      String ipAddress = null;
     
         if (dvPortgroupConfigSpec != null) {
            dvPortgroupConfigSpecArray = new DVPortgroupConfigSpec[] { dvPortgroupConfigSpec };
            dvPortgroupMorList = iDVSwitch.addPortGroups(dvsMor,
                     dvPortgroupConfigSpecArray);
            if (dvPortgroupMorList != null) {
               if (dvPortgroupMorList.size() == dvPortgroupConfigSpecArray.length) {
                  log.info("Successfully added all the portgroups");
                  portgroupKey = this.iDVPortgroup.getKey(dvPortgroupMorList.get(0));
                  if (portgroupKey != null) {
                     dvsConfigInfo = this.iDVSwitch.getConfig(this.dvsMor);
                     portConnection = new DistributedVirtualSwitchPortConnection();
                     portConnection.setSwitchUuid(dvsConfigInfo.getUuid());
                     portConnection.setPortgroupKey(portgroupKey);
                     updatedDeltaConfigSpec = new VirtualMachineConfigSpec[2][2];
                     origVMConfigSpec = new VirtualMachineConfigSpec[vmMor.length];
                     status = true;
                     for (int j = 0; j < vmMor.length; j++) {
                        origVMConfigSpec[j] = this.iVirtualMachine.getVMConfigSpec(vmMor[j]);
                        updatedDeltaConfigSpec[j] = DVSUtil.getVMConfigSpecForDVSPort(
                                 vmMor[j],
                                 connectAnchor,
                                 new DistributedVirtualSwitchPortConnection[] { portConnection });
                        if (updatedDeltaConfigSpec[j] != null) {
                           if (this.iVirtualMachine.reconfigVM(vmMor[j],
                                    updatedDeltaConfigSpec[j][0])) {
                              log.info("Successfully reconfigured the "
                                       + "VM " + j + "to connect to "
                                       + "the late binding " + "portgroup");
                              if (this.iVirtualMachine.setVMState(vmMor[j], VirtualMachinePowerState.POWERED_ON, false)) {
                                 ipAddress = this.iVirtualMachine.getIPAddress(vmMor[j]);
                                 if (ipAddress != null) {
                                    status &= DVSUtil.checkNetworkConnectivity(
                                             this.iHostSystem.getIPAddress(hostMor),
                                             ipAddress);
                                 } else {
                                    status = false;
                                 }
                              } else {
                                 status = false;
                                 log.error("Unable to power on the "
                                          + "VM");
                              }
                           } else {
                              status = false;
                              log.error("Could not reconfigure the "
                                       + "VM " + j + "to connect to "
                                       + "the late binding " + "portgroup");
                           }
                        } else {
                           status = false;
                           log.error("Delta config spec is null");
                        }
                     }
                  } else {
                     log.error("Portgroup key is null");
                  }
               } else {
                  log.error("Could not add all the portgroups");
               }
            } else {
               log.error("No portgroups were added");
            }
         }
     
      assertTrue(status, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test was started. Restore
    * the original state of the VM.Destroy the portgroup, followed by the
    * distributed virtual switch
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
     
         /*
          * Restore the original power states of the respective VMs 
          */
         for (int i = 0; i < vmMor.length; i++) {
            status &= this.iVirtualMachine.setVMState(vmMor[i],
                     this.vmPowerState[i], false);
            if (updatedDeltaConfigSpec != null) {
               if (updatedDeltaConfigSpec[i] != null
                        && updatedDeltaConfigSpec[i][1] != null) {
                  status &= this.iVirtualMachine.reconfigVM(vmMor[i],
                           updatedDeltaConfigSpec[i][1]);
               }
            }
         }

         /*
          * Restore the original network config
          */
         if (this.originalNetworkConfig != null) {
            status &= this.iNetworkSystem.updateNetworkConfig(nsMor,
                     originalNetworkConfig, TestConstants.CHANGEMODE_MODIFY);
         }
         if (this.dvsMor != null) {
            status &= this.iManagedEntity.destroy(dvsMor);
         }
     
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
