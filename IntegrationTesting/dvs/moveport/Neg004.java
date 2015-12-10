/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.moveport;

import static com.vmware.vcqa.util.Assert.*;
import static com.vmware.vcqa.vim.MessageConstants.*;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.*;

import java.util.ArrayList;

import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.InvalidRequest;
import com.vmware.vc.MethodFault;
import com.vmware.vcqa.util.TestUtil;

/**
 * Move a DVPort by providing an empty portKey.<br>
 * This test is a Functional Feature Acceptance Test (FFAT).<br>
 */
public class Neg004 extends MovePortBase
{
   /**
    * Test setup. <br>
    * 1. Create DVS.<br>
    * 2. Create early binding DVPortgroup with one port in it. <br>
    * 3. Use null in port key array.<br>
    * 4. Use the key of DVPortgroup as destination.<br>
    *
    * @param connectAnchor ConnectAnchor.
    * @return boolean true, if test setup was successful. false, otherwise.
    */
   @Override
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      assertTrue(super.testSetUp(), TB_SETUP_PASS, TB_SETUP_FAIL);
      dvsMor = iFolder.createDistributedVirtualSwitch(dvsName);
      assertNotNull(dvsMor, DVS_CREATE_PASS, DVS_CREATE_FAIL);
      portgroupKey = iDVSwitch.addPortGroup(dvsMor,
               DVPORTGROUP_TYPE_EARLY_BINDING, 1, prefix + "PG-Early");
      assertNotNull(portgroupKey, "Failed to add DVPortgroup");
      portKeys = new ArrayList<String>();
      portKeys.add(null); // set null as a port key.
      return true;
   }

   /**
    * Test.<br>
    * Move the DVPort in the DVPortgroup by providing empty port key.<br>
    *
    * @param connectAnchor ConnectAnchor.
    */
   @Override
   @Test(description = "Move a DVPort by providing an empty portKey.")
   public void test()
      throws Exception
   {
      boolean status = false;
      final MethodFault expectedFault = new InvalidRequest();
      try {
         movePort(dvsMor, portKeys, portgroupKey);
         log.error("API didn't throw any exception.");
      } catch (final Exception actualMethodFaultExcep) {
         MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(actualMethodFaultExcep);
         status = TestUtil.checkMethodFault(actualMethodFault, expectedFault);
      }
      if (!status) {
         log.error("API didn't throw expected exception: "
                  + expectedFault.getClass().getSimpleName());
      }
      assertTrue(status, "Test Failed");
   }
}
