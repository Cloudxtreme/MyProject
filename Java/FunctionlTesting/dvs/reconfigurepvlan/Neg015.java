/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfigurepvlan;

import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.PVLAN_TYPE_COMMINITY;

import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.AlreadyExists;
import com.vmware.vc.MethodFault;
import com.vmware.vcqa.util.TestUtil;

/**
 * Add duplicate secondary PVLAN map entries to the DVS with One secondary PVLAN
 * in PVLAN-10 (10,101,C) another secondary PVLAN in PVLAN-20 with same
 * secondary ID as in PVALN-10 (20,101,C).
 */
public class Neg015 extends PvlanBase
{
   /**
    * Set test description.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Add duplicate secondary PVLAN map entries to the DVS "
               + "with One secondary PVLAN in PVLAN-10  (10,101,C) "
               + "another secondary PVLAN in PVLAN-20 with same secondary ID "
               + "as in PVALN-10 (20,101,C).");
   }

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
               status = iVmwareDVS.addSecondaryPvlan(dvsMor,
                        PVLAN_TYPE_COMMINITY, PVLAN1_PRI_1, PVLAN1_SEC_1, true);
            }
         }
     
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Test. Add PLVAN map entry by providing same secondary ID as before.
    * 
    * @param connectAnchor ConnectAnchor.
    */
   @Override
   @Test(description = "Add duplicate secondary PVLAN map entries to the DVS "
               + "with One secondary PVLAN in PVLAN-10  (10,101,C) "
               + "another secondary PVLAN in PVLAN-20 with same secondary ID "
               + "as in PVALN-10 (20,101,C).")
   public void test()
      throws Exception
   {
      boolean status = false;
      MethodFault expectedFault = new AlreadyExists();
      try {
         iVmwareDVS.addSecondaryPvlan(dvsMor, PVLAN_TYPE_COMMINITY,
                  PVLAN2_PRI_1, PVLAN1_SEC_1, true);
         log.error("API didn't throw any exception.");
      } catch (Exception actualMethodFaultExcep) {
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
