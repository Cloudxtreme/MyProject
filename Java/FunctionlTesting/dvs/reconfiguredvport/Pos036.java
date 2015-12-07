/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvport;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.ConfigSpecOperation;
import com.vmware.vc.DVPortConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DVPortSetting;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;

import dvs.CreateDVSTestBase;

/**
 * Reconfigure DVPort. See setTestDescription for detailed description
 */
public class Pos036 extends CreateDVSTestBase
{

   /*
    * private data variables
    */
   private DistributedVirtualSwitch iDVS = null;
   private DVPortConfigSpec[] portConfigSpecs = null;
   private final int DVS_PORT_NUM = 1;

   /**
    * Sets the test description.
    *
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      super.setTestDescription("Reconfigure DVPort name with  string "
               + "of length 80 characters");
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
            if (this.networkFolderMor != null) {
               this.iDVS = new DistributedVirtualSwitch(connectAnchor);
               configSpec = new DVSConfigSpec();
               configSpec.setName(this.getClass().getName());
               configSpec.setNumStandalonePorts(DVS_PORT_NUM);
               dvsMOR = this.iFolder.createDistributedVirtualSwitch(
                        this.networkFolderMor, this.configSpec);
               if (this.dvsMOR != null) {
                  log.info("Successfully created the DVSwitch");
                  List<String> portKeyList = iDVS.fetchPortKeys(dvsMOR, null);
                  if (portKeyList != null && portKeyList.size() == DVS_PORT_NUM) {
                     portConfigSpecs = new DVPortConfigSpec[DVS_PORT_NUM];
                     portConfigSpecs[0] = new DVPortConfigSpec();
                     portConfigSpecs[0].setKey(portKeyList.get(0));
                     portConfigSpecs[0].setName((DVSTestConstants.DVPORTGROUP_VALID_NAME_31_CHARS
                              + DVSTestConstants.DVPORTGROUP_VALID_NAME_31_CHARS + DVSTestConstants.DVPORTGROUP_VALID_NAME_31_CHARS).substring(
                              0, 80));
                     portConfigSpecs[0].setOperation(ConfigSpecOperation.EDIT.value());
                     DVPortSetting dvPortSetting =
                                    portConfigSpecs[0].getSetting();
                     if (dvPortSetting instanceof VMwareDVSPortSetting) {
                        VMwareDVSPortSetting VMwareDVSPort =
                                    (VMwareDVSPortSetting) dvPortSetting;
                        VMwareDVSPort.setLacpPolicy(null);
                        portConfigSpecs[0].setSetting(VMwareDVSPort);
                     }
                     status = true;
                  } else {
                     log.error("Can't get correct port keys");
                  }
               } else {
                  log.error("Cannot create the distributed virtual "
                           + "switch with the config spec passed");
               }
            } else {
               log.error("Failed to create the network folder");
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
   @Test(description = "Reconfigure DVPort name with  string "
               + "of length 80 characters")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;

         status = this.iDVS.reconfigurePort(this.dvsMOR, this.portConfigSpecs);
         assertTrue(status, "Test Failed");

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
