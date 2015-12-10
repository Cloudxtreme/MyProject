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

import com.vmware.vc.InvalidRequest;
import com.vmware.vc.MethodFault;

/**
 * Add a PVLAN map entry to DVS by providing null MOR and other parameters
 * intact.
 */
public class Neg001 extends PvlanBase
{
   @Override
   public void setTestDescription()
   {
      setTestDescription("Add a PVLAN map entry to DVS by providing null MOR "
               + "and other parameters intact.");
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
   @Test(description = "Add a PVLAN map entry to DVS by providing null MOR "
               + "and other parameters intact.")
   public void test()
      throws Exception
   {
      try {
         iVmwareDVS.addPrimaryPvlan(null, PVLAN1_PRI_1);
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         com.vmware.vc.MethodFault expectedMethodFault = new InvalidRequest();
         com.vmware.vcqa.util.Assert.assertTrue(
                  com.vmware.vcqa.util.TestUtil.checkMethodFault(
                           actualMethodFault, expectedMethodFault),
                  "MethodFault mismatch!");
      }
   }

   @Override
   public MethodFault getExpectedMethodFault()
   {
      return new InvalidRequest();
   }
}
