/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfigureportgroups;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.MethodFault;
import com.vmware.vc.ResourceNotAvailable;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;

import dvs.ElasticPortgroupHelper;

/**
 * DESCRIPTION:<BR>
 * TARGET: VC <BR>
 * SETUP:<BR>
 * 1. Create a vDS with host <BR>
 * TEST:<BR>
 * 2.Create static type of DVPortgroup with autoExpand flag to true and<BR>
 * set number of ports as 0 <BR>
 * 3.Create a VM to connect to above DVPG <BR>
 * CLEANUP:<BR>
 * 4. Delete VMs<BR>
 * 5. Destroy vDs<BR>
 */
public class Pos068 extends TestBase
{
   private final ElasticPortgroupHelper helper = new ElasticPortgroupHelper();

   @Override
   public void setTestDescription()
   {
      super.setTestDescription("Reconfigure  static  DVPG by  setting "
               + "autoExpand  flag to true and set number of ports as 0."
               + "Reconfigure  a VM  to connect to above DVPG  ");
   }

   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      helper.init(connectAnchor);
      helper.createDvsWithHostAttached();
      helper.getDVPGConfigSpec().setType(
               DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
      helper.getDVPGConfigSpec().setNumPorts(0);
      helper.addDVPG();
      helper.createVm(1, false);
      return true;
   }

   @Test(description = "Reconfigure  static  DVPG by  setting "
               + "autoExpand  flag to true and set number of ports as 0."
               + "Reconfigure  a VM  to connect to above DVPG  ")
   public void test()
      throws Exception
   {
      try {
         helper.reconfigVM();
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         com.vmware.vc.MethodFault expectedMethodFault = new ResourceNotAvailable();
         com.vmware.vcqa.util.Assert.assertTrue(
                  com.vmware.vcqa.util.TestUtil.checkMethodFault(
                           actualMethodFault, expectedMethodFault),
                  "MethodFault mismatch!");
      }

   }

   /**
    * Setting the expected Exception.
    */
   @Override
   public MethodFault getExpectedMethodFault()
   {
      return new ResourceNotAvailable();

   }

   public void postTest()
      throws Exception
   {
      helper.resetDVPGConfigSpec();
      helper.getDVPGConfigSpec().setNumPorts(0);
      helper.getDVPGConfigSpec().setAutoExpand(true);
      helper.reconfigDVPG();
      helper.reconfigVM();

   }

   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      postTest();
      return helper.destroyVM() && helper.destroyDVS();
   }
}
