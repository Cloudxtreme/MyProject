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
 * 5.Convert above VM into template.
 * 6.Clone two VMs from template.<BR>
 * CLEANUP:<BR>
 * 7. Delete VMs<BR>
 * 8. Destroy vDs<BR>
 */
public class Pos002 extends TestBase
{
   private final ElasticPortgroupHelper helper = new ElasticPortgroupHelper();

   @Override
   public void setTestDescription()
   {
      super.setTestDescription(" Convert a VM that connects to elastic early" +
      		" binding DVPortgroup into template. " +
      		"The tempalte will contain the information of the portgroup to" +
      		" connect to. Clone two VM's from the template and power on the two VM's. ");
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

   @Test(description = " Convert a VM that connects to elastic early" +
      		" binding DVPortgroup into template. " +
      		"The tempalte will contain the information of the portgroup to" +
      		" connect to. Clone two VM's from the template and power on the two VM's. ")
   public void test()
      throws Exception
   {
      helper.addDVPG();
      helper.reconfigVM();
      helper.markAsTemplate();
      helper.cloneVM(2);
   }

   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      return helper.destroyVM() && helper.destroyDVS();
   }
}
