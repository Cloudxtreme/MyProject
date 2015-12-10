/*
 * ************************************************************************
 *
 * Copyright 2009 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.merge;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.ArrayList;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.i18n.I18NDataProvider;
import com.vmware.vcqa.i18n.I18NDataProviderConstants;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchHelper;

/**
 * I18N001. Create two dvswitches with the following configuration: a. dest_name
 * = Valid I18N String b. src_name = Valid I18N String Merge the two dvswitches
 */
public class I18N001 extends TestBase
{
   /*
    * private data variables
    */
   private Folder iFolder = null;
   // i18n: iDataProvider object
   private I18NDataProvider iDataProvider = null;
   private DistributedVirtualSwitchHelper iDVS = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference dcMor = null;
   private ManagedObjectReference nwFolder = null;
   private ArrayList<String> dvsNameArr = null;

   /**
    * This method will set the Description
    */
   public void setTestDescription()
   {
      setTestDescription("I18N001. Create two dvswitches with the following configuration\n "
               + " a. dest_name = Valid I18N String \n"
               + " b. src_name = Valid I18N String\n"
               + " Merge the two dvswitches");
   }

   /**
    * Method to set up the Environment for the test.
    * 
    * @param connectAnchor Reference to the ConnectAnchor object.
    * @return True, if test set up was successful False, if test set up was not
    *         successful
    */
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      log.info("Test setup Begin:");

     
         // i18n: get DataProvider object from factory implementation.
         iDataProvider = new I18NDataProvider();
         this.iFolder = new Folder(connectAnchor);
         iDVS = new DistributedVirtualSwitchHelper(connectAnchor);
         this.iManagedEntity = new ManagedEntity(connectAnchor);
         this.dcMor = this.iFolder.getDataCenter();
         this.nwFolder = this.iFolder.getNetworkFolder(dcMor);
         Assert.assertNotNull(this.nwFolder,
                  "Successfully found  the NetworkFolder ",
                  "Failed to find the NetworkFolder");

         // i18n: call into getData with the propertyKey and length of
         // substrings
         dvsNameArr = iDataProvider.getData(
                  I18NDataProviderConstants.MULTI_LANG_KEY,
                  I18NDataProviderConstants.MAX_STRING_LENGTH);
         for (String dvsName : dvsNameArr) {
            log.info("DVSname = " + dvsName);
            ManagedObjectReference dvsMor = this.createDvs(dvsName);
            assertTrue(
                     (iDVS.getConfig(dvsMor).getName().equals(dvsName)),
                     " Verified the name", " Unable to verify the name");
            Assert.assertNotNull(dvsMor,
                     "Successfully created the source distributed "
                              + "virtual switch :" + dvsName,
                     "Failed to create the source distributed "
                              + "virtual switch:" + dvsName);
            dvsName = new StringBuffer(dvsName).reverse().toString();
            dvsMor = this.createDvs(dvsName);
            assertTrue(
                     (iDVS.getConfig(dvsMor).getName().equals(dvsName)),
                     " Verified the name", " Unable to verify the name");
            Assert.assertNotNull(dvsMor, "Successfully created the destination"
                     + " distributed " + "virtual switch :" + dvsName,
                     "Failed to create the destination distributed "
                              + "virtual switch:" + dvsName);
         }
         status = true;

     
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Test Logic
    * 
    * @param connectAnchor - Reference to the ConnectAnchor object
    */

   @Test(description = "I18N001. Create two dvswitches with the following configuration\n "
               + " a. dest_name = Valid I18N String \n"
               + " b. src_name = Valid I18N String\n"
               + " Merge the two dvswitches")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;

     
         for (String dvsName : dvsNameArr) {
            ManagedObjectReference destDvsMor = this.iFolder.getDistributedVirtualSwitch(
                     this.nwFolder, dvsName);
            dvsName = new StringBuffer(dvsName).reverse().toString();
            ManagedObjectReference srcDvsMor = this.iFolder.getDistributedVirtualSwitch(
                     this.nwFolder, dvsName);
            assertTrue((this.iDVS.merge(destDvsMor, srcDvsMor)),
                     "Successfully merged the switches",
                     "Failed to merge the switches");
         }
         status = true;
     
      assertTrue(status, "Test Failed");
   }

   /**
    * Method to restore the state, as it was, before setting up the test
    * environment.
    * 
    * @param connectAnchor Reference to the ConnectAnchor object
    * @return True, if test clean up was successful False, if test clean up was
    *         not successful
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      ManagedObjectReference dvsMor = null;
     
         for (String dvsName : dvsNameArr) {
            dvsMor = this.iFolder.getDistributedVirtualSwitch(this.nwFolder,
                     dvsName);
            status &= this.iManagedEntity.destroy(dvsMor);
         }
     
      assertTrue(status, "Cleanup failed");
      return status;
   }

   /**
    * This method creates DVS
    */
   private ManagedObjectReference createDvs(String name)
      throws Exception
   {
      ManagedObjectReference dvsMor = null;
      DVSConfigSpec dvsConfigSpec = null;
      dvsConfigSpec = new DVSConfigSpec();
      dvsConfigSpec.setConfigVersion("");
      dvsConfigSpec.setName(name);
      dvsMor = this.iFolder.createDistributedVirtualSwitch(this.nwFolder,
               dvsConfigSpec);
      return dvsMor;

   }

}
