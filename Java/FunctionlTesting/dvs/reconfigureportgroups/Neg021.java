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

import com.vmware.vc.DVPortSetting;
import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DVSTrafficShapingPolicy;
import com.vmware.vc.InvalidArgument;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * Reconfigure a portgroup with an invalid outshaping policy
 */
public class Neg021 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference rootFolderMor = null;
   private ManagedObjectReference dvsMor = null;
   private DVSConfigSpec dvsConfigSpec = null;
   private DistributedVirtualSwitch iDVSwitch = null;
   private ManagedObjectReference dvPortgroupMor = null;
   private List<ManagedObjectReference> dvPortgroupMorList = null;
   private DVPortgroupConfigSpec[] dvPortgroupConfigSpecArray = null;
   private DVPortgroupConfigSpec dvPortgroupConfigSpec = null;
   private ManagedObjectReference dcMor = null;
   private DistributedVirtualPortgroup iDVPortgroup = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      setTestDescription("Reconfigure a portgroup with an invalid "
               + "outshaping policy");
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
         this.iDVPortgroup = new DistributedVirtualPortgroup(connectAnchor);
         this.iManagedEntity = new ManagedEntity(connectAnchor);
         this.rootFolderMor = this.iFolder.getRootFolder();
         this.dcMor = this.iFolder.getDataCenter();
         if (this.dcMor != null) {
            log.info("Successfully found the datacenter");
            this.dvsConfigSpec = new DVSConfigSpec();
            this.dvsConfigSpec.setName(this.getClass().getName());
            this.dvsMor = this.iFolder.createDistributedVirtualSwitch(
                     this.iFolder.getNetworkFolder(dcMor), dvsConfigSpec);
            if (dvsMor != null) {
               log.info("Successfully created the distributed "
                        + "virtual switch");
               this.dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
               this.dvPortgroupConfigSpec.setName(this.getTestId());
               this.dvPortgroupConfigSpec.setDescription(DVSTestConstants.DVPORTGROUP_VALID_DESCRIPTION);
               this.dvPortgroupConfigSpec.setNumPorts(2);
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
    * Method that reconfigures a portgroup with an invalid outshaping policy
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Reconfigure a portgroup with an invalid "
               + "outshaping policy")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      DVSTrafficShapingPolicy outShapingPolicy = null;
      DVPortSetting portSetting = null;
      boolean status = false;

      try {
         portSetting = this.iDVSwitch.getConfig(dvsMor).getDefaultPortConfig();
         outShapingPolicy = portSetting.getInShapingPolicy();
         if (outShapingPolicy == null) {
            outShapingPolicy = DVSUtil.getTrafficShapingPolicy(false, true,
                     new Long(-98), null, null);
         } else {
            outShapingPolicy.setEnabled(DVSUtil.getBoolPolicy(false, true));
            outShapingPolicy.setAverageBandwidth(DVSUtil.getLongPolicy(false,
                     new Long(-98)));
         }
         portSetting.setInShapingPolicy(outShapingPolicy);
         this.dvPortgroupConfigSpec.setDefaultPortConfig(portSetting);
         this.dvPortgroupConfigSpec.setConfigVersion(this.iDVPortgroup.getConfigInfo(
                  dvPortgroupMorList.get(0)).getConfigVersion());
         if (this.iDVPortgroup.reconfigure(dvPortgroupMorList.get(0),
                  this.dvPortgroupConfigSpec)) {
            log.error("Successfully reconfigured the portgroup "
                     + "but the API did not throw an exception");
         } else {
            log.error("Failed to reconfigure the portgroup but "
                     + "the API did not throw any exception");
         }
      } catch (Exception actualMethodFaultExcep) {
         MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(actualMethodFaultExcep);
         InvalidArgument expectedMethodFault = new InvalidArgument();
         status = TestUtil.checkMethodFault(actualMethodFault,
                  expectedMethodFault);
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
      boolean status = false;
      try {
         /*if(this.dvPortgroupMorList != null){
            for(ManagedObjectReference mor: dvPortgroupMorList){
               status = this.iManagedEntity.destroy(mor);
            }  
         }*/
         status = this.iManagedEntity.destroy(dvsMor);
      } catch (Exception e) {
         TestUtil.handleException(e);
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
