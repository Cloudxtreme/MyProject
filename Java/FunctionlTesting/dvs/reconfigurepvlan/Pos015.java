/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfigurepvlan;

import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.MAX_PVLAN_ID;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.MIN_PVLAN_ID;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.PVLAN_TYPE_COMMINITY;

import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vcqa.util.TestUtil;

/**
 * Add a PVLAN map entry to the DVS by providing primary VLAN ID as 4094 and
 * secondary PVLAN ID as 1 with port type as community. Procedure:<br>
 * Setup: 1. Create a DVS.<br>
 * Test:<br>
 * 2.a. Add a primary PVLAN map entry to DVS with PVLAN ID as 4094.<br>
 * 2.b. Add a secondary PVLAN map entry to DVS with PVLAN ID as 1 of type
 * community.<br>
 * Cleanup:<br>
 * 3. Deleted the DVS.<br>
 * 4. Log off from VC.<br>
 */
public class Pos015 extends PvlanBase
{
   /**
    * Set test description.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Add a PVLAN map entry to the DVS with primary "
               + "PVLAN ID as 4094 and secondary PVLAN ID as 1 with "
               + "port type as community.");
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
   @Test(description = "Add a PVLAN map entry to the DVS with primary "
               + "PVLAN ID as 4094 and secondary PVLAN ID as 1 with "
               + "port type as community.")
   public void test()
      throws Exception
   {
      boolean status = false;
     
         status = iVmwareDVS.addSecondaryPvlan(dvsMor, PVLAN_TYPE_COMMINITY,
                  MAX_PVLAN_ID, MIN_PVLAN_ID, true);
     
      assertTrue(status, "Test Failed");
   }
}
