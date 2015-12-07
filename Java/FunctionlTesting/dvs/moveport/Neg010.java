/*
 * ************************************************************************
 *
 * Copyright 2008-2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.moveport;

import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING;

import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.InvalidType;

/**
 * Move a DVPort by providing invalid MOR for DVS MOR.
 */
public class Neg010 extends MovePortBase
{

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
    * Test. Move the DVPort in the DVPortgroup by providing invalid DVS MOR.
    *
    * @param connectAnchor ConnectAnchor.
    */
   @Override
   @Test(description = "Move a DVPort by providing invalid MOR for DVS MOR.")
   public void test()
      throws Exception
   {
      try {
         movePort(iFolder.getRootFolder(), portKeys, portgroupKey);
         ;
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         com.vmware.vc.MethodFault expectedMethodFault = new InvalidType();
         com.vmware.vcqa.util.Assert.assertTrue(
                  com.vmware.vcqa.util.TestUtil.checkMethodFault(
                           actualMethodFault, expectedMethodFault),
                  "MethodFault mismatch!");
      }
   }
}
