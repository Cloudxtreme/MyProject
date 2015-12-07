/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.moveport;

import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING;

import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.ManagedObjectNotFound;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vcqa.util.TestUtil;

/**
 * Move a DVPort by providing an empty MOR. This test is a Functional Feature
 * Acceptance Test (FFAT).
 */
public class Neg002 extends MovePortBase
{
   /**
    * Set the brief description of this test.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Move a DVPort by providing an empty MOR.");
   }

   /**
    * Test setup. 1. Create DVS. 2. Create early binding DVPortgroup with one
    * port in it. 3. Create a standalone port and use the port key as source. 4.
    * Use the key of DVPortgroup as destination.
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
            dvsMor = iFolder.createDistributedVirtualSwitch(dvsName);
            if (dvsMor != null) {
               portgroupKey = iDVSwitch.addPortGroup(dvsMor,
                        DVPORTGROUP_TYPE_EARLY_BINDING, 1, prefix + "PG-Early");
               if (portgroupKey != null) {
                  portKeys = iDVSwitch.addStandaloneDVPorts(dvsMor, 1);
                  if ((portKeys != null) && (portKeys.size() >= 1)) {
                     log.info("Successfully got the port key.");
                     status = true;
                  } else {
                     log.error("Failed to get the port key of the DVPort.");
                  }
               } else {
                  log.error("Failed to add the port group.");
               }
            }
         }
     
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Test. Move the DVPort in the DVPortgroup by providing empty DVS MOR.
    * 
    * @param connectAnchor ConnectAnchor.
    */
   @Override
   @Test(description = "Move a DVPort by providing an empty MOR.")
   public void test()
      throws Exception
   {
      boolean status = false;
      MethodFault expectedFault = new ManagedObjectNotFound();
      try {
         movePort(new ManagedObjectReference(), portKeys, portgroupKey);
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
