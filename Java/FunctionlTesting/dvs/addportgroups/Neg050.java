/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.addportgroups;

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
 * 2.Add static DVPG by setting autoExpand flag to false and set number of<BR>
 * ports as 0.<BR>
 * 3. Reconfigure a VM to connect to above DVPG <BR>
 * CLEANUP:<BR>
 * 4. Destroy vDs<BR>
 */
public class Neg050 extends TestBase
{
   private final ElasticPortgroupHelper helper = new ElasticPortgroupHelper();

   @Override
   public void setTestDescription()
   {
      super
               .setTestDescription("Add static  DVPG by  setting autoExpand  flag to"
                        + " false and set number of ports as 0.Reconfigure  a VM "
                        + " to connect to above DVPG  ");
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
      helper.getDVPGConfigSpec().setAutoExpand(false);
      return true;
   }

   @Test(description = "Add static  DVPG by  setting autoExpand  flag to"
                        + " false and set number of ports as 0.Reconfigure  a VM "
                        + " to connect to above DVPG  ")
   public void test()
      throws Exception
   {
      try {
         helper.addDVPG();
         helper.createVm(1, true);
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

   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      return helper.destroyDVS();
   }
}
