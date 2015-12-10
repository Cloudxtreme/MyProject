/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfigurepvlan;

import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.PVLAN_TYPE_PROMISCUOUS;

import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vcqa.util.TestUtil;

/**
 * Remove a PVLAN map entry in DVS by providing valid primary PVLAN ID and type
 * is promiscuous. Procedure:<br>
 * Setup: 1. Create a DVS.<br>
 * 2. Add a primary PVLAN map entry to DVS. Test:<br>
 * 3. Remove the added primary PVLAN. Cleanup:<br>
 * 3. Deleted the DVS.<br>
 * 4. Log off from VC.<br>
 */
public class Pos018 extends PvlanBase
{
   /**
    * Set test description.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Remove a PVLAN map entry in DVS by providing valid "
               + "primary PVLAN ID and type is promiscuous.");
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
               if (iVmwareDVS.addPrimaryPvlan(dvsMor, PVLAN1_PRI_1)) {
                  log.info("Scccessfully added primary PVLAN.");
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
               + "primary PVLAN ID and type is promiscuous.")
   public void test()
      throws Exception
   {
      boolean status = false;
     
         if (iVmwareDVS.removePvlan(dvsMor, PVLAN_TYPE_PROMISCUOUS,
                  PVLAN1_PRI_1, PVLAN1_PRI_1, false)) {
            log.info("Successfully removed the PVLAN.");
            log.info("Verifying ...");
            try {
               iVmwareDVS.assignPvlanToPort(dvsMor, PVLAN1_PRI_1);
            } catch (Exception e) {
               log.info("Verification successful as we couldnot assign "
                        + "deleted PVLAN to a DVPort.");
               status = true;
            }
         }
     
      assertTrue(status, "Test Failed");
   }
}
