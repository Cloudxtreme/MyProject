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
 * Add a secondary PVLAN map entry to DVS by providing a secondary PVLAN ID as a
 * primary ID. (10,101,C), (101,102,C).
 */
public class Neg018 extends PvlanBase
{
   /**
    * Set test description.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Add a secondary PVLAN map entry to DVS by providing "
               + "a secondary PVLAN ID as a primary ID. "
               + "(10,101,C), (101,102,C).");
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
   @Test(description = "Add a secondary PVLAN map entry to DVS by providing "
               + "a secondary PVLAN ID as a primary ID. "
               + "(10,101,C), (101,102,C).")
   public void test()
      throws Exception
   {
      boolean status = false;
      MethodFault expectedFault = new AlreadyExists();
      try {
         iVmwareDVS.addSecondaryPvlan(dvsMor, PVLAN_TYPE_COMMINITY,
                  PVLAN1_SEC_1, PVLAN1_SEC_2, true);
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
