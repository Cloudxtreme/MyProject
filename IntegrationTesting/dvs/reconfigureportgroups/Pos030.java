/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfigureportgroups;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.HostNetworkTrafficShapingPolicy;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VmwareUplinkPortTeamingPolicy;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * Reconfigure a portgroup to an existing distributed virtual switch with a
 * valid uplinkteaming policy
 */
public class Pos030 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference rootFolderMor = null;
   private ManagedObjectReference dvsMor = null;
   private VMwareDVSConfigSpec dvsConfigSpec = null;
   private DistributedVirtualSwitch iDVSwitch = null;
   private ManagedObjectReference dvPortgroupMor = null;
   private DVPortgroupConfigSpec dvPortgroupConfigSpec = null;
   private List<ManagedObjectReference> dvPortgroupMorList = null;
   private DVPortgroupConfigSpec[] dvPortgroupConfigSpecArray = null;
   private VMwareDVSPortSetting dvPortSetting = null;
   private DistributedVirtualPortgroup iDVPortgroup = null;
   private ManagedObjectReference dcMor = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      setTestDescription("Reconfigure a portgroup to an existing"
               + "distributed virtual switch with a valid "
               + "uplinkteaming policy");
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
      log.info("Test setup Begin:");
      try {
         this.iFolder = new Folder(connectAnchor);
         this.iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
         this.iManagedEntity = new ManagedEntity(connectAnchor);
         this.iDVPortgroup = new DistributedVirtualPortgroup(connectAnchor);
         this.rootFolderMor = this.iFolder.getRootFolder();
         this.dcMor = this.iFolder.getDataCenter();
         if (this.rootFolderMor != null) {
            this.dvsConfigSpec = new VMwareDVSConfigSpec();
            this.dvsConfigSpec.setConfigVersion("");
            this.dvsConfigSpec.setName(this.getTestId());
            dvsMor = this.iFolder.createDistributedVirtualSwitch(
                     this.iFolder.getNetworkFolder(dcMor), dvsConfigSpec);
            if (dvsMor != null) {
               log.info("Successfully created the distributed "
                        + "virtual switch");
               this.dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
               this.dvPortgroupConfigSpec.setConfigVersion("");

               this.dvPortgroupConfigSpec.setName(this.getTestId() + "-pg1");
               this.dvPortgroupConfigSpec.setDescription(DVSTestConstants.DVPORTGROUP_VALID_DESCRIPTION);
               this.dvPortgroupConfigSpec.setNumPorts(1);
               this.dvPortgroupConfigSpec.setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
               this.dvPortgroupMorList = this.iDVSwitch.addPortGroups(
                        dvsMor,
                        new DVPortgroupConfigSpec[] { this.dvPortgroupConfigSpec });
               if (this.dvPortgroupMorList != null
                        && this.dvPortgroupMorList.size() == 1) {
                  log.info("Successfully added the portgroup");
                  status = true;
               } else {
                  log.error("Failed to add the portgroup");
               }
            } else {
               log.error("Failed to create the distributed "
                        + "virtual switch");
            }
         } else {
            log.error("Failed to find a folder");
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
      }
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that reconfigures a portgroup
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Reconfigure a portgroup to an existing"
               + "distributed virtual switch with a valid "
               + "uplinkteaming policy")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      HostNetworkTrafficShapingPolicy outShapingPolicy = null;
      VmwareUplinkPortTeamingPolicy uplinkPolicy = null;
      boolean status = false;
      try {
         dvPortSetting = (VMwareDVSPortSetting) this.iDVSwitch.getConfig(dvsMor).getDefaultPortConfig();
         uplinkPolicy = dvPortSetting.getUplinkTeamingPolicy();
         uplinkPolicy.setNotifySwitches(DVSUtil.getBoolPolicy(false, true));
         uplinkPolicy.setPolicy(DVSUtil.getStringPolicy(false, "loadbalance_ip"));
         uplinkPolicy.setReversePolicy(DVSUtil.getBoolPolicy(false, true));
         uplinkPolicy.setRollingOrder(DVSUtil.getBoolPolicy(false, true));
         dvPortSetting.setUplinkTeamingPolicy(uplinkPolicy);
         this.dvPortgroupConfigSpec.setDefaultPortConfig(dvPortSetting);
         this.dvPortgroupConfigSpec.setConfigVersion(this.iDVPortgroup.getConfigInfo(
                  dvPortgroupMorList.get(0)).getConfigVersion());
         if (this.iDVPortgroup.reconfigure(dvPortgroupMorList.get(0),
                  this.dvPortgroupConfigSpec)) {
            log.info("Successfully reconfigured the portgroup");
            status = TestUtil.compareObject(this.iDVPortgroup.getConfigInfo(
                     dvPortgroupMorList.get(0)).getDefaultPortConfig(),
                     dvPortSetting, null);
         } else {
            log.error("Failed to reconfigure the portgroup");
         }
      } catch (Exception e) {
         status = false;
         TestUtil.handleException(e);
      }
      assertTrue(status, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test is started. Destroy
    * the portgroup, followed by the distributed virtual switch
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      try {
         /*if(this.dvPortgroupMorList != null){
            for(ManagedObjectReference mor: dvPortgroupMorList){
               status &= this.iManagedEntity.destroy(mor);
            }  
         }*/
         if (this.dvsMor != null) {
            status = this.iManagedEntity.destroy(dvsMor);
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
         status = false;
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
