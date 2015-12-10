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

import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;



/**
 * Add a PVLAN map entry to the DVS by providing valid primary ID and port type
 * as promiscuous. <br>
 * Procedure:<br>
 * 1. Create a DVS.<br>
 * 2. Reconfigure the PVLAN to add the PVLAN entry. <br>
 * 3. Verify the availability.<br>
 */
public class Pos001 extends PvlanBase
{
   @Override
   public void setTestDescription()
   {
      setTestDescription("Add a PVLAN map entry to the DVS by providing"
               + " valid primary ID and port type as promiscuous.");
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
   @Test(description = "Add a PVLAN map entry to the DVS by providing"
               + " valid primary ID and port type as promiscuous.")
   public void test()
      throws Exception
   {
      assertTrue(iVmwareDVS.addPrimaryPvlan(dvsMor, PVLAN1_PRI_1),
               "Unable to add primary PVLAN.");
      log.info("Added the primary PVLAN successfully");
      assertTrue(iVmwareDVS.isPvlanIdPresent(dvsMor, PVLAN1_PRI_1),
               "The added PVLAN entry was not found.");
      log.info("Added PVLAN entry is present in vDS");
   }
}
