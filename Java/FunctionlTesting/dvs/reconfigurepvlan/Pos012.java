/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfigurepvlan;

import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.MIN_PVLAN_ID;

import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vcqa.util.TestUtil;

/**
 * Add a PVLAN map entry to the DVS with PVLAN ID as 1. Procedure:<br>
 * Setup: 1. Create a DVS.<br>
 * Test:<br>
 * 2. Add a primary PVLAN map entry to DVS with PVLAN ID as 1.<br>
 * Cleanup:<br>
 * 3. Deleted the DVS.<br>
 * 4. Log off from VC.<br>
 */
public class Pos012 extends PvlanBase
{
   /**
    * Set test description.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Add a PVLAN map entry to the DVS with PVLAN ID as 1.");
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
               status = true;
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
   @Test(description = "Add a PVLAN map entry to the DVS with PVLAN ID as 1.")
   public void test()
      throws Exception
   {
      boolean status = false;
      log.info("Test Begin:");
     
         if (iVmwareDVS.addPrimaryPvlan(dvsMor, MIN_PVLAN_ID)) {
            log.info("Successfully added primary PVLAN with ID as "
                     + MIN_PVLAN_ID);
            status = true;
         }
     
      assertTrue(status, "Test Failed");
   }
}
