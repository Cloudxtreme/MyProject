/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfigurepvlan;

import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.PVLAN_TYPE_ISOLATED;

import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vcqa.util.TestUtil;

/**
 * Remove a PVLAN map entry in DVS by providing valid secondary PVLAN ID and
 * type being isolated. Procedure:<br>
 * Setup: 1. Create a DVS.<br>
 * 2.a. Add a primary PVLAN map entry to DVS.<br>
 * 2.b. Add a secondary PVLAN map entry to type isolated to DVS.<br>
 * Test:<br>
 * 3. Remove the added secondary PVLAN. Cleanup:<br>
 * 3. Deleted the DVS.<br>
 * 4. Log off from VC.<br>
 */
public class Pos020 extends PvlanBase
{
   /**
    * Set test description.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Remove a PVLAN map entry in DVS by providing valid "
               + "secondary PVLAN ID and type being isolated.");
   }

   /**
    * Test setup.
    * 
    * @param connectAnchor ConnectAnchor.
    * @return boolean true, if test setup was successful. false, otherwise.
    */
   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
     
         if (super.testSetUp()) {
            log.info("Creating DVS: " + dvsName);
            dvsMor = iFolder.createDistributedVirtualSwitch(dvsName);
            if (dvsMor != null) {
               if (iVmwareDVS.addSecondaryPvlan(dvsMor, PVLAN_TYPE_ISOLATED,
                        PVLAN1_PRI_1, PVLAN1_SEC_1, true)) {
                  log.info("Successfully added secondary PVLAN.");
                  status = true;
               }
            }
         }
     
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Test.
    * 
    * @param connectAnchor ConnectAnchor.
    */
   @Override
   @Test(description = "Remove a PVLAN map entry in DVS by providing valid "
               + "secondary PVLAN ID and type being isolated.")
   public void test()
      throws Exception
   {
      boolean status = false;
     
         if (iVmwareDVS.removePvlan(dvsMor, PVLAN_TYPE_ISOLATED, PVLAN1_PRI_1,
                  PVLAN1_SEC_1, false)) {
            log.info("Successfully removed the PVLAN.");
            log.info("Verifying ...");
            try {
               iVmwareDVS.assignPvlanToPort(dvsMor, PVLAN1_SEC_1);
            } catch (Exception e) {
               log.info("Verification successful as we couldnot assign "
                        + "deleted PVLAN to a DVPort.");
               status = true;
            }
         }
     
      assertTrue(status, "Test Failed");
   }
}
