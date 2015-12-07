/*
 * ************************************************************************
 *
 * Copyright 2009 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvport;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.ArrayList;
import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.ConfigSpecOperation;
import com.vmware.vc.DVPortConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vcqa.i18n.I18NDataProvider;
import com.vmware.vcqa.i18n.I18NDataProviderConstants;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;

import dvs.CreateDVSTestBase;

/**
 * Reconfigure DVPort. See setTestDescription for detailed description
 */
public class I18N001 extends CreateDVSTestBase
{

   /*
    * private data variables
    */
   private DistributedVirtualSwitch iDVS = null;
   private DVPortConfigSpec[] portConfigSpecs = null;
   // i18n: iDataProvider object
   private I18NDataProvider iDataProvider = null;
   private ArrayList<String> dvPortNameArr = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      super.setTestDescription("Reconfigure DVPort name with a i18n string");
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
            this.networkFolderMor = this.iFolder.getNetworkFolder(this.dcMor);
            Assert.assertNotNull(this.networkFolderMor,
                     "Failed to create the network folder");
            // i18n: get DataProvider object from factory implementation.
            iDataProvider = new I18NDataProvider();
            this.iDVS = new DistributedVirtualSwitch(connectAnchor);
            // i18n: call into getData with the propertyKey and length of
            // substrings
            dvPortNameArr = iDataProvider.getData(
                     I18NDataProviderConstants.MULTI_LANG_KEY,
                     I18NDataProviderConstants.MAX_STRING_LENGTH);

            configSpec = new DVSConfigSpec();
            configSpec.setName(this.getClass().getName());
            configSpec.setNumStandalonePorts(dvPortNameArr.size());
            dvsMOR = this.iFolder.createDistributedVirtualSwitch(
                     this.networkFolderMor, this.configSpec);

            Assert.assertNotNull(dvsMOR,
                     "Successfully created the distributed "
                              + "virtual switch ",
                     "Failed to create the distributed " + "virtual switch:");
            List<String> portKeyList = iDVS.fetchPortKeys(dvsMOR, null);
            if (portKeyList != null
                     && portKeyList.size() == dvPortNameArr.size()) {
               int i = 0;
               portConfigSpecs = new DVPortConfigSpec[dvPortNameArr.size()];
               for (String dvPortName : dvPortNameArr) {
                  portConfigSpecs[i] = new DVPortConfigSpec();
                  portConfigSpecs[i].setKey(portKeyList.get(i));
                  portConfigSpecs[i].setName(dvPortName);
                  portConfigSpecs[i].setOperation(ConfigSpecOperation.EDIT.value());
                  i++;
               }
               status = true;
            } else {
               log.error("Can't get correct port keys");
            }
         }
     
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that creates the DVS.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Reconfigure DVPort name with a i18n string")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
     
         assertTrue(
                  (this.iDVS.reconfigurePort(dvsMOR, portConfigSpecs)),
                  "Successfully reconfigured DVS", "Failed to reconfigure dvs");
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