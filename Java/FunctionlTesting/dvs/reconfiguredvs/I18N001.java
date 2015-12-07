/*
 * ************************************************************************
 *
 * Copyright 2009 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvs;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.ArrayList;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigSpec;
import com.vmware.vcqa.i18n.I18NDataProvider;
import com.vmware.vcqa.i18n.I18NDataProviderConstants;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;

import dvs.CreateDVSTestBase;

/**
 * Reconfigure an existing DVS by setting the - DVSConfigSpec.configVersion to a
 * valid config version string - DVSConfigSpec.name to i18n string
 */
public class I18N001 extends CreateDVSTestBase
{

   /*
    * private data variables
    */
   // i18n: iDataProvider object
   private I18NDataProvider iDataProvider = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      super.setTestDescription("Reconfigure an existing DVS by setting the \n"
               + "  - DVSConfigSpec.configVersion to a valid config version string\n"
               + "  - DVSConfigSpec.name to i18n string.");
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
     
         if (super.testSetUp()) {
            // i18n: get DataProvider object from factory implementation.
            iDataProvider = new I18NDataProvider();
            this.networkFolderMor = this.iFolder.getNetworkFolder(this.dcMor);
            Assert.assertNotNull(this.networkFolderMor,
                     "Failed to create the network folder");
            this.iDistributedVirtualSwitch = new DistributedVirtualSwitch(
                     connectAnchor);
            this.configSpec = new DVSConfigSpec();
            this.configSpec.setName(this.getClass().getName());
            this.dvsMOR = this.iFolder.createDistributedVirtualSwitch(
                     this.networkFolderMor, this.configSpec);
            Assert.assertNotNull(dvsMOR,
                     "Successfully created the distributed virtual switch ",
                     "Failed to create the distributed virtual switch:");
            status = true;
         }
     
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that creates the DVS.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Reconfigure an existing DVS by setting the \n"
               + "  - DVSConfigSpec.configVersion to a valid config version string\n"
               + "  - DVSConfigSpec.name to i18n string.")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      DVSConfigSpec deltaConfigSpec = null;
     

         // i18n: call into getData with the propertyKey and length of
         // substrings
         ArrayList<String> dvsNameArr = iDataProvider.getData(
                  I18NDataProviderConstants.MULTI_LANG_KEY,
                  I18NDataProviderConstants.MAX_STRING_LENGTH);
         // i18n: looping through all the substrings to verify the displayName
         for (String dvsName : dvsNameArr) {
            deltaConfigSpec = new DVSConfigSpec();
            String validConfigVersion = this.iDistributedVirtualSwitch.getConfig(
                     dvsMOR).getConfigVersion();
            validConfigVersion = this.iDistributedVirtualSwitch.getConfig(
                     dvsMOR).getConfigVersion();
            deltaConfigSpec.setConfigVersion(validConfigVersion);
            deltaConfigSpec.setName(dvsName);
            assertTrue(this.iDistributedVirtualSwitch.reconfigure(
                     this.dvsMOR, deltaConfigSpec),
                     "Successfully reconfigured DVS",
                     "Failed to reconfigure dvs");
            assertTrue(
                     (iDistributedVirtualSwitch.getConfig(dvsMOR).getName().equals(dvsName)),
                     " Verified the name", " Unable to verify the name");
         }
         status = true;
     
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
      boolean status = true;
     
         status &= super.testCleanUp();
     
      assertTrue(status, "Cleanup failed");
      return status;
   }
}