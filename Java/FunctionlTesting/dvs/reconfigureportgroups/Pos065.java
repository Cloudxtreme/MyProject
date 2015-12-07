/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfigureportgroups;

import com.vmware.vcqa.IDataDrivenTest;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Factory;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;

import com.vmware.vcqa.IDataDrivenTest;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.execution.TestExecutionUtils;
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
public class Pos065 extends TestBase  implements IDataDrivenTest
{
   private final ElasticPortgroupHelper helper = new ElasticPortgroupHelper();

   /**
    * Factory method to create the data driven tests.
    *
    * @return Object[] TestBase objects.
    *
    * @throws Exception
    */
   @Factory
   @Parameters({"dataFile"})
   public Object[] getTests(@Optional("")String dataFile) throws Exception {
      return TestExecutionUtils.getTests(this.getClass().getName(), dataFile);
   }
   public String getTestName()
   {
      return getTestId();
   }
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
      String dvpgType =
               this.data.getString(DVSTestConstants.DVPORTGROUP_TYPE,
                        DVSTestConstants.DVPORTGROUP_TYPE_EPHEMERAL);
      log.info(" DVPORTGROUP_TYPE :" + dvpgType);
      helper.init(connectAnchor);
      helper.createDvsWithHostAttached();
      helper.getDVPGConfigSpec().setType(dvpgType);
      helper.getDVPGConfigSpec().setNumPorts(0);
      helper.addDVPG();
      return true;
   }

   @Test(description = "Add static  DVPG by  setting autoExpand  flag "
               + "to true and set number of ports as 0.Create  a VM  to"
               + " connect to above DVPG ")
   public void test()
      throws Exception
   {
      helper.resetDVPGConfigSpec();
      helper.getDVPGConfigSpec().setType(
               DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
      helper.getDVPGConfigSpec().setNumPorts(0);
      helper.getDVPGConfigSpec().setAutoExpand(true);
      helper.reconfigDVPG();
      helper.createVm(1, true);
   }

   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      return helper.destroyVM() && helper.destroyDVS();
   }
  

}
