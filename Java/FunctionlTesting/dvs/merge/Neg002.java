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
import com.vmware.vc.InvalidRequest;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.ManagedEntity;

/**
 * Merge a destination DVS inside a valid folder with a source DVS with null MOR
 */
public class Neg002 extends TestBase
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
      setTestDescription("Merge a destination DVS inside a valid folder "
               + "with a source DVS which has a null DVS MOR");
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
      log.info("Test setup Begin:");
     
         this.iFolder = new Folder(connectAnchor);
         this.iManagedEntity = new ManagedEntity(connectAnchor);
         this.iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
         this.dcMor = this.iFolder.getDataCenter();
         this.rootFolder = this.iFolder.getRootFolder();
         if (this.rootFolder != null) {
            this.configSpec = new DVSConfigSpec();
            this.configSpec.setConfigVersion("");
            this.configSpec.setName(this.getClass().getName());
            destDvsMor = this.iFolder.createDistributedVirtualSwitch(
                     this.iFolder.getNetworkFolder(dcMor), configSpec);
            if (destDvsMor != null) {
               log.info("Successfully created the destination "
                        + "distributed virtual switch");
               status = true;
            } else {
               log.error("Could not create the destination "
                        + "distributed virtual switch");
            }
         }
     
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that merges two distributed virtual switches.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Merge a destination DVS inside a valid folder "
               + "with a source DVS which has a null DVS MOR")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      try {
         if (this.iDVSwitch.merge(destDvsMor, srcDvsMor)) {
            log.error("Successfully merged the switches but the API "
                     + "did not throw an exception");
         } else {
            log.error("Failed to merge the switches but the API "
                     + "did not throw an exception");
         }
      } catch (Exception actualMethodFaultExcep) {
         MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(actualMethodFaultExcep);
         MethodFault expectedMethodFault = new InvalidRequest();
         status = TestUtil.checkMethodFault(actualMethodFault,
                  expectedMethodFault);
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