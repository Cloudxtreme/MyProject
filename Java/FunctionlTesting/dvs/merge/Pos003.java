/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.merge;

import static com.vmware.vcqa.util.Assert.assertTrue;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;

/**
 * Merge a source DVS with a detination DVS with valid maxPorts
 */
public class Pos003 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference rootFolder = null;
   private ManagedObjectReference destDvsMor = null;
   private ManagedObjectReference srcDvsMor = null;
   private DVSConfigSpec configSpec = null;
   private DistributedVirtualSwitch iDVSwitch = null;
   private ManagedObjectReference dcMor = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      setTestDescription("Merge a source DVS with a destination DVS "
               + "with valid maxPorts");
   }

   /**
    * Method to setup the environment for the test.
    * 
    * @param connectAnchor ConnectAnchor object
    * @return boolean true if successful, false otherwise.
    */
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      String destDvsName = DVSTestConstants.DVS_CREATE_NAME_PREFIX
               + this.getTestId() + DVSTestConstants.DVS_DESTINATION_SUFFIX;
      String srcDvsName = DVSTestConstants.DVS_CREATE_NAME_PREFIX
               + this.getTestId() + DVSTestConstants.DVS_SOURCE_SUFFIX;
      log.info("Test setup Begin:");
     
         this.iFolder = new Folder(connectAnchor);
         this.iManagedEntity = new ManagedEntity(connectAnchor);
         this.iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
         this.rootFolder = this.iFolder.getRootFolder();
         this.dcMor = this.iFolder.getDataCenter();
         if (this.rootFolder != null) {
            this.configSpec = new DVSConfigSpec();
            this.configSpec.setConfigVersion("");
            this.configSpec.setName(destDvsName);
            this.configSpec.setMaxPorts(DVSTestConstants.DVS_MAXNUMPORTS);
            destDvsMor = this.iFolder.createDistributedVirtualSwitch(
                     this.iFolder.getNetworkFolder(dcMor), configSpec);
            this.configSpec.setName(srcDvsName);
            this.configSpec.setMaxPorts(DVSTestConstants.DVS_MAXNUMPORTS);
            srcDvsMor = this.iFolder.createDistributedVirtualSwitch(
                     this.iFolder.getNetworkFolder(dcMor), configSpec);
            if (srcDvsMor != null && destDvsMor != null) {
               log.info("Successfully created the source "
                        + "and destination distributed virtual " + "switches");
               status = true;
            } else {
               log.error("Could not create the source or "
                        + "destination distributed virtual " + "switches");
            }
         }
     
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that merges two distributed virtual switches
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Merge a source DVS with a destination DVS "
               + "with valid maxPorts")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
     
         if (this.iDVSwitch.merge(destDvsMor, srcDvsMor)) {
            log.info("Successfully merged the switches");
            status = true;
         } else {
            log.error("Failed to merge the switches");
         }
     
      assertTrue(status, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test is started.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = false;
     
         if (this.destDvsMor != null) {
            status = this.iManagedEntity.destroy(destDvsMor);
         }
     
      assertTrue(status, "Cleanup failed");
      return status;
   }
}