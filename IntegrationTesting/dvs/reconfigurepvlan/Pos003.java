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

import com.vmware.vcqa.util.TestUtil;

/**
 * Add a PVLAN map entry to the DVS by providing valid primary ID and secondary
 * ID with port type as isolated.
 */
public class Pos003 extends PvlanBase
{
   /**
    * Set test description.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription(" Add a PVLAN map entry to the DVS"
               + " by providing valid primary ID and secondary ID"
               + " with port type as isolated.");
   }

   /**
    * Test setup.
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
   @Test(description = " Add a PVLAN map entry to the DVS"
               + " by providing valid primary ID and secondary ID"
               + " with port type as isolated.")
   public void test()
      throws Exception
   {
      boolean status = false;
     
         if (iVmwareDVS.addSecondaryPvlan(dvsMor, PVLAN_TYPE_ISOLATED,
                  PVLAN1_PRI_1, PVLAN1_SEC_1, true)) {
            if (iVmwareDVS.isPvlanIdPresent(dvsMor, PVLAN1_PRI_1)) {
               status = true;
            } else {
               log.error("The added PVLAN entry was not found.");
            }
         } else {
            log.error("Failed to add the PVLAN entry.");
         }
     
      assertTrue(status, "Test Failed");
   }
}
