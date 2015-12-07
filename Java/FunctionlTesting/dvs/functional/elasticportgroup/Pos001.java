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

import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.sm.StorageManagerHelper;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;

import dvs.ElasticPortgroupHelper;

/**
 * DESCRIPTION:<BR>
 * TARGET: VC <BR>
 * SETUP:<BR>
 * 1.Create a vDS with host <BR>
 * 2.Create VM  <BR>
 * TEST:<BR>
 * 3.Create static type of DVPortgroup with autoExpand flag to true and<BR>
 * set number of ports as 0 <BR>
 * 4.Reconfigure a VM to connect to above DVPG <BR>
 * 5.CloneVM<BR>
 * CLEANUP:<BR>
 * 6. Delete VMs<BR>
 * 7. Destroy vDs<BR>
 */
public class Pos001 extends TestBase
{
   private final ElasticPortgroupHelper helper = new ElasticPortgroupHelper();

   @Override
   public void setTestDescription()
   {
      super.setTestDescription("Clone a vm from a power off VM that is" +
      		" connected to an elastic early binding port group  ");
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
      helper.getDVPGConfigSpec().setNumPorts(0);
      helper.getDVPGConfigSpec().setAutoExpand(true);
      return true;
   }

   @Test(description = "Clone a vm from a power off VM that is" +
      		" connected to an elastic early binding port group  ")
   public void test()
      throws Exception
   {
      helper.addDVPG();
      helper.reconfigVM();
      helper.cloneVM(1);

   }

   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      return helper.destroyVM() && helper.destroyDVS();
   }
}
