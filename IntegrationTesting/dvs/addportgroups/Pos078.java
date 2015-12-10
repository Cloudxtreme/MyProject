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
public class Pos078 extends TestBase
{
   private final ElasticPortgroupHelper helper = new ElasticPortgroupHelper();

   @Override
   public void setTestDescription()
   {
      super.setTestDescription("Add static  DVPG by  setting autoExpand  flag "
               + "to true and set number of ports as 0.Create  a VM  to"
               + " connect to above DVPG ");
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
      helper.getDVPGConfigSpec().setAutoExpand(true);
      return true;
   }

   @Test(description = "Add static  DVPG by  setting autoExpand  flag "
               + "to true and set number of ports as 0.Create  a VM  to"
               + " connect to above DVPG ")
   public void test()
      throws Exception
   {
      helper.addDVPG();
      helper.createVm(1, true);
   }

   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      return helper.destroyVM() && helper.destroyDVS();
   }
}
