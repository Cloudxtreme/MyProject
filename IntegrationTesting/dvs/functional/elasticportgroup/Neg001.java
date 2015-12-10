/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.functional.elasticportgroup;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.InvalidRequest;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.ResourceNotAvailable;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;

import dvs.ElasticPortgroupHelper;

/**
 * DESCRIPTION:<BR>
 * TARGET: VC <BR>
 * SETUP:<BR>
 * 1.Create a vDS with host <BR>
 * 2.Create VM <BR>
 * TEST:<BR>
 * 3.Create static type of DVPortgroup with autoExpand flag to false and<BR>
 * set number of ports as 1 <BR>
 * 4.Reconfigure a VM to connect to above DVPG <BR>
 * 5.CloneVM<BR>
 * CLEANUP:<BR>
 * 6. Delete VMs<BR>
 * 7. Destroy vDs<BR>
 */
public class Neg001 extends TestBase
{
   private final ElasticPortgroupHelper helper = new ElasticPortgroupHelper();

   @Override
   public void setTestDescription()
   {
      super
               .setTestDescription("Clone a vm from a power off VM that is"
                        + " connected to an  early binding port group which  has number of ports exactly equal to 1 ");
   }

   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   { 
      helper.init(connectAnchor);
      helper.createDvsWithHostAttached();
      helper.createVm(1, false);
      helper.getDVPGConfigSpec().setType(
               DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
      helper.getDVPGConfigSpec().setNumPorts(1);
      helper.getDVPGConfigSpec().setAutoExpand(false);
      return true;
   }

   @Test(description = "Clone a vm from a power off VM that is"
                        + " connected to an  early binding port group which  has number of ports exactly equal to 1 ")
   public void test()
      throws Exception
   {
      try {
         helper.addDVPG();
         helper.reconfigVM();
         helper.cloneVM(2);
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

   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      return helper.destroyVM() && helper.destroyDVS();
   }
}
