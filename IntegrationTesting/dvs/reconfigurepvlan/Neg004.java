/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfigurepvlan;

import static com.vmware.vcqa.TestConstants.CONFIG_SPEC_ADD;
import static com.vmware.vcqa.util.Assert.assertTrue;

import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.InvalidRequest;
import com.vmware.vc.VMwareDVSPvlanConfigSpec;
import com.vmware.vcqa.util.TestUtil;

/**
 * Add a PVLAN map entry to DVS by providing valid DVS MOR but null
 * VMwareDVSPvlanMapEntry in config spec.
 */
public class Neg004 extends PvlanBase
{
   /**
    * Test setup. 1. Create a DVS.
    *
    * @param connectAnchor ConnectAnchor.
    * @return <code>true</code> if setup is successful.
    */
   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;

         if (super.testSetUp()) {
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
   @Test(description = "Add a PVLAN map entry to DVS by providing valid "
               + "DVS MOR but null VMwareDVSPvlanMapEntry in config spec.")
   public void test()
      throws Exception
   {
      try {
         VMwareDVSPvlanConfigSpec[] configSpecs = new VMwareDVSPvlanConfigSpec[1];
         configSpecs[0] = new VMwareDVSPvlanConfigSpec();
         configSpecs[0].setOperation(CONFIG_SPEC_ADD);
         configSpecs[0].setPvlanEntry(null);
         iVmwareDVS.reconfigurePvlan(dvsMor, configSpecs);
         log.error("API didn't throw any exception.");
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
}
