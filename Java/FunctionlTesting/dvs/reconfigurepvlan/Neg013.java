/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfigurepvlan;

import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.PVLAN_TYPE_ISOLATED;

import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.InvalidArgument;
import com.vmware.vc.MethodFault;
import com.vmware.vcqa.util.TestUtil;

/**
 * Add a PVLAN map entry to DVS by providing same primary and secondary ID and
 * port type as isolated.
 */
public class Neg013 extends PvlanBase
{
   /**
    * Set test description.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Add a PVLAN map entry to DVS by providing same "
               + "primary and secondary ID and port type as isolated.");
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
   @Test(description = "Add a PVLAN map entry to DVS by providing same "
               + "primary and secondary ID and port type as isolated.")
   public void test()
      throws Exception
   {
      boolean status = false;
      MethodFault expectedFault = new InvalidArgument();
      try {
         iVmwareDVS.addPvlan(dvsMor, PVLAN_TYPE_ISOLATED, PVLAN1_PRI_1,
                  PVLAN1_PRI_1);
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
