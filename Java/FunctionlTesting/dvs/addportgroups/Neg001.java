/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.addportgroups;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.InvalidRequest;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.ManagedEntity;

/**
 * Add a portgroup to an existing distributed virtual switch with the following
 * parameters set: DVPortgroupConfigSpec set to null
 */
public class Neg001 extends TestBase
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
   private ManagedObjectReference dcMor = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      setTestDescription("Add a portgroup to an existing"
               + "distributed virtual switch with null config spec");
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
      boolean setupDone = false;
      log.info("Test setup Begin:");
     
         this.iFolder = new Folder(connectAnchor);
         this.iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
         this.iManagedEntity = new ManagedEntity(connectAnchor);
         this.rootFolderMor = this.iFolder.getRootFolder();
         if (this.rootFolderMor != null) {
            this.dvsConfigSpec = new DVSConfigSpec();
            this.dvsConfigSpec.setConfigVersion("");
            this.dvsConfigSpec.setName(this.getClass().getName());
            this.dcMor = this.iFolder.getDataCenter();
            dvsMor = this.iFolder.createDistributedVirtualSwitch(
                     this.iFolder.getNetworkFolder(dcMor), dvsConfigSpec);
            if (dvsMor != null) {
               log.info("Successfully created the distributed "
                        + "virtual switch");
               setupDone = true;
            } else {
               log.error("Failed to create the distributed "
                        + "virtual switch");
            }
         } else {
            log.error("Failed to find a folder");
         }
     
      assertTrue(setupDone, "Setup failed");
      return setupDone;
   }

   /**
    * Method that adds a portgroup to the distributed virtual switch with null
    * config spec array
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Add a portgroup to an existing"
               + "distributed virtual switch with null config spec")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean testDone = false;
      try {
         dvPortgroupMorList = iDVSwitch.addPortGroups(dvsMor,
                  dvPortgroupConfigSpecArray);
         log.error("API did not throw an exception");
      } catch (Exception actualMethodFaultExcep) {
         MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(actualMethodFaultExcep);
         MethodFault expectedMethodFault = new InvalidRequest();
         testDone = TestUtil.checkMethodFault(actualMethodFault,
                  expectedMethodFault);
      }
      assertTrue(testDone, "Test Failed");
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
      boolean cleanUpDone = true;
     
         /*if(this.dvPortgroupMorList != null){
            for(ManagedObjectReference mor: dvPortgroupMorList){
               cleanUpDone = this.iManagedEntity.destroy(mor);
            }  
         }*/
         if (this.dvsMor != null) {
            cleanUpDone &= this.iManagedEntity.destroy(dvsMor);
         }
     
      assertTrue(cleanUpDone, "Cleanup failed");
      return cleanUpDone;
   }
}
