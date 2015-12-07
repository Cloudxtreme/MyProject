/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfigurepvlan;

import static com.vmware.vcqa.util.Assert.assertTrue;

import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.ManagedObjectNotFound;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vcqa.util.TestUtil;

/**
 * Add a PVLAN map entry to DVS by providing empty MOR and other parameters
 * intact.
 */
public class Neg002 extends PvlanBase
{
   /**
    * Set test description.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Add a PVLAN map entry to DVS by providing empty MOR"
               + " and other parameters intact.");
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
   @Test(description = "Add a PVLAN map entry to DVS by providing empty MOR"
               + " and other parameters intact.")
   public void test()
      throws Exception
   {
      boolean status = false;
      MethodFault expectedFault = new ManagedObjectNotFound();
      try {
         iVmwareDVS.addPrimaryPvlan(new ManagedObjectReference(), PVLAN1_PRI_1);
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
