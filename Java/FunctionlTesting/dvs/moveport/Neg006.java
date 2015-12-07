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

import java.util.ArrayList;

import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.MethodFault;
import com.vmware.vc.NotFound;
import com.vmware.vcqa.util.TestUtil;

/**
 * Move DVPort by providing a valid and an invalid portKey. {-1,100}. This test
 * is a Functional Feature Acceptance Test (FFAT).
 */
public class Neg006 extends MovePortBase
{
   /**
    * Set the brief description of this test.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Move DVPort by providing a valid and an invalid "
               + "portKey.");
   }

   /**
    * Test setup. 1. Create DVS. 2. Create early binding DVPortgroup with one
    * port in it. 3. Create a standalone port in DVS but add a invalid port
    * key(-1) to it. 4. Use the key of DVPortgroup as destination.
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
                  portKeys = new ArrayList<String>();
                  portKeys.addAll(iDVSwitch.addStandaloneDVPorts(dvsMor, 1));
                  portKeys.add("-1");// add the invalid port key.
                  status = true;
               } else {
                  log.error("Failed to add the port group.");
               }
            }
         }
     
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Test. Move the DVPort in the DVPortgroup by providing null port key.
    * 
    * @param connectAnchor ConnectAnchor.
    */
   @Override
   @Test(description = "Move DVPort by providing a valid and an invalid "
               + "portKey.")
   public void test()
      throws Exception
   {
      boolean status = false;
      MethodFault expectedFault = new NotFound();
      try {
         movePort(dvsMor, portKeys, portgroupKey);
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
