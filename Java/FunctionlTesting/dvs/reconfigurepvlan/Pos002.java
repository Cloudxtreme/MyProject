/*
 * ************************************************************************
 *
 * Copyright 2008-2009 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfigurepvlan;

import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.PVLAN_TYPE_COMMINITY;

import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;



/**
 * Add a secondary PVLAN map entry to the DVS by providing valid primary ID and
 * secondary ID with port type as community. <br>
 * Procedure:<br>
 * 1. Create a DVS.<br>
 * 2. Reconfigure the PVLAN to add the primary PVLAN entry. <br>
 * 4. Reconfigure the PVLAN to add the secondary PVLAN entry. <br>
 * 3. Verify the availability.<br>
 */
public class Pos002 extends PvlanBase
{
   @Override
   public void setTestDescription()
   {
      setTestDescription("Add a secondary PVLAN map entry to the DVS "
               + "by providing valid primary ID and secondary ID "
               + "with port type as community.");
   }

   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      assertTrue(super.testSetUp(), "Super setup failed.");
      dvsMor = iFolder.createDistributedVirtualSwitch(dvsName);
      assertNotNull(dvsMor, "Created vDS", "Failed to create vDS");
      return true;
   }

   @Override
   @Test(description = "Add a secondary PVLAN map entry to the DVS "
               + "by providing valid primary ID and secondary ID "
               + "with port type as community.")
   public void test()
      throws Exception
   {
      assertTrue(iVmwareDVS.addSecondaryPvlan(dvsMor, PVLAN_TYPE_COMMINITY,
               PVLAN1_PRI_1, PVLAN1_SEC_1, true), "Failed to add PVLAN");
      log.info("Added the secondary PVLAN successfully");
      assertTrue(iVmwareDVS.isPvlanIdPresent(dvsMor, PVLAN1_PRI_1),
               "Added PVLAN entry is not present in vDS");
      log.info("Added PVLAN entry is present in vDS");
   }
}
