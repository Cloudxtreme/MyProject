/*
 * ************************************************************************
 *
 * Copyright 2009 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.createdvs;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.ArrayList;
import java.util.List;
import java.util.Vector;

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
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.ManagedEntity;

/**
 * Create a DVSwitch inside a valid folder with I18N string as name
 */
public class I18N001 extends TestBase
{
   /*
    * private data variables
    */
   private Folder iFolder = null;
   // i18n: iDataProvider object
   private I18NDataProvider iDataProvider = null;
   private DistributedVirtualSwitch iDVSwitch = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference dcMor = null;
   private ManagedObjectReference nwFolder = null;
   private ManagedObjectReference dvsMor = null;
   private List<ManagedObjectReference> dvsMorList = new Vector<ManagedObjectReference>();
   private ArrayList<String> dvsNameArr = null;

   /**
    * This method will set the Description
    */
   public void setTestDescription()
   {
      setTestDescription("Create a DVSwitch inside a valid folder with "
               + "I18N string as name");
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
         this.iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
         this.iFolder = new Folder(connectAnchor);
         this.iManagedEntity = new ManagedEntity(connectAnchor);
         this.dcMor = this.iFolder.getDataCenter();
         this.nwFolder = this.iFolder.getNetworkFolder(dcMor);
         Assert.assertNotNull(this.nwFolder,
                  "Successfully found  the NetworkFolder ",
                  "Failed to find the NetworkFolder");
         status = true;

     
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Test Logic
    * 
    * @param connectAnchor - Reference to the ConnectAnchor object
    */

   @Test(description = "Create a DVSwitch inside a valid folder with "
               + "I18N string as name")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;

     
         dvsNameArr = iDataProvider.getData(
                  I18NDataProviderConstants.MULTI_LANG_KEY,
                  I18NDataProviderConstants.MAX_STRING_LENGTH);
         for (String dvsName : dvsNameArr) {
            log.info("dvsName = " + dvsName);
            dvsMor = this.createDvs(dvsName);
            Assert.assertNotNull(dvsMor,
                     "Successfully created the distributed "
                              + "virtual switch :" + dvsName,
                     "Failed to create the distributed " + "virtual switch:"
                              + dvsName);
            assertTrue(
                     (iDVSwitch.getConfig(dvsMor).getName().equals(dvsName)),
                     " Verified the name", " Unable to verify the name");

            dvsMorList.add(dvsMor);
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
     
         for (String dvsName : dvsNameArr) {
            dvsMor = this.iFolder.getDistributedVirtualSwitch(this.nwFolder,
                     dvsName);
            assertTrue(this.iManagedEntity.destroy(dvsMor),
                     "Successfully deleted DVS", "Unable to delete DVS");
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
