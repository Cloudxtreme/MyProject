/*
 * ************************************************************************
 *
 * Copyright 2009-2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.performproductspecoperation;

import com.vmware.vcqa.IDataDrivenTest;
import static com.vmware.vcqa.util.Assert.assertFalse;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.Factory;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;
import java.util.List;
import java.util.Vector;

import com.vmware.vc.DVSCreateSpec;
import com.vmware.vc.DistributedVirtualSwitchProductSpec;
import com.vmware.vc.InvalidArgument;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vcqa.IDataDrivenTest;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.execution.TestExecutionUtils;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchManager;

/**
 * DESCRIPTION:<br>
 * (Test case for ProductSpecOperation ) <br>
 * TARGET: VC <br>
 * SETUP:<br>
 * 1.Create DVS with older vDs version <br>
 * 2.Add hosts compatible with old vDs version  to above Vds
 * 3.Create new vDs version product spec
 * TEST:<br>>
 * 4.Invoke perform ProductSpecOperation. <br>
 * CLEANUP:<br>
 * 5. Destroy vDs<br>
 */
public class Neg009 extends TestBase implements IDataDrivenTest 
{

   /*
    * private data variables
    */
   private ManagedObjectReference[] allHosts = null;
   private ManagedObjectReference dvsManagerMor = null;
   private DistributedVirtualSwitch DVS = null;
   private DistributedVirtualSwitchManager dvsManager = null;
   private DistributedVirtualSwitchProductSpec newProductSpec = null;
   private DistributedVirtualSwitchProductSpec oldProductSpec = null;
   private String oldVdsVersion = null;
   private String newVdsVersion = null;
   private Folder folder = null;
   private ManagedObjectReference dvsMor = null;

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

   public void setTestDescription()
   {
      super.setTestDescription("1.Create DVS with older vDs version and"
               + " add hosts compatible with new vDs version  to it.\n "
               + "2.Create new vDs version product spec"
               + " 3.Invoke perform ProductSpecOperation");
   }

   /**
    * Method to setup the environment for the test.
    *
    * @return boolean true if successful, false otherwise.
    */
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      List<ManagedObjectReference> hostMors =
               new Vector<ManagedObjectReference>(1);
      log.info("Test setup Begin:");
      this.DVS = new DistributedVirtualSwitch(connectAnchor);
      folder =  new Folder(connectAnchor);
      dvsManager = new DistributedVirtualSwitchManager(connectAnchor);
      dvsManagerMor = dvsManager.getDvSwitchManager();
      oldVdsVersion = this.data.getString(DVSTestConstants.OLD_VDS_VERSION);
      newVdsVersion = this.data.getString(DVSTestConstants.NEW_VDS_VERSION);
      
      log.info("version info");
      log.info(oldVdsVersion);
      log.info(newVdsVersion);
      
      oldProductSpec =
         DVSUtil.getProductSpec(connectAnchor, this.oldVdsVersion);
      assertNotNull(oldProductSpec,
               "Successfully obtained  the productSpec for : " + oldProductSpec,
               "Null returned for productSpec for :" + oldProductSpec);
      newProductSpec = DVSUtil.getProductSpec(connectAnchor, newVdsVersion);
      assertNotNull(newProductSpec,
               "Successfully obtained  the productSpec for : " + newProductSpec,
               "Null returned for productSpec for :" + newProductSpec);
      allHosts =
               this.dvsManager.queryCompatibleHostForNewDVS(dvsManagerMor,
                        this.folder.getDataCenter(), true, oldProductSpec);
      assertNotNull(allHosts, "Valid Host MOR not found");
      for(ManagedObjectReference hostMor : allHosts ) {
         hostMors.add(hostMor);
      }

      /*
       * Create DVS with older vDs version
       */
      DVSCreateSpec createSpec =
               DVSUtil
                        .createDVSCreateSpec(DVSUtil
                                 .createDefaultDVSConfigSpec(null),
                                 oldProductSpec, null);
      dvsMor = DVSUtil.createDVSFromCreateSpec(connectAnchor, createSpec);
      assertNotNull(dvsMor, "Successfully created the DVSwitch",
               "Cannot create the distributed virtual "
                        + "switch with the config spec passed");
      assertTrue(DVSUtil.addHostsUsingReconfigureDVS(this.dvsMor, hostMors,
               connectAnchor), "Failed to add host to DVS");
      return true;
   }

   @Test(description = "1.Create DVS with older vDs version and"
               + " add hosts compatible with new vDs version  to it.\n "
               + "2.Create new vDs version product spec"
               + " 3.Invoke perform ProductSpecOperation")
   public void test()
      throws Exception
   {
      try {
         /*assertFalse(this.DVS.performProductSpecOperation(
                  dvsMor, DVSTestConstants.OPERATION_UPGRADE, newProductSpec),
                  " performProductSpecOperation failed",
                  " Successfully completed performProductSpecOperation");*/
    	  assertTrue(this.DVS.performProductSpecOperation(
                  dvsMor, DVSTestConstants.OPERATION_UPGRADE, newProductSpec),
                  " Successfully completed performProductSpecOperation",
                  " performProductSpecOperation failed");
         log.info("tag1");
        // com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
         log.info("tag2");
      } catch (Exception excep) {
    	  log.info("tag3");
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         log.info("tag4");
         com.vmware.vc.MethodFault expectedMethodFault = new InvalidArgument();
         log.info("tag5");
         com.vmware.vcqa.util.Assert.assertTrue(
                  com.vmware.vcqa.util.TestUtil.checkMethodFault(
                           actualMethodFault, expectedMethodFault),
                  "MethodFault mismatch!");
         log.info("tag6");
      }

   }

   /**
    * Setting the expected Exception.
    */
   @Override
   public MethodFault getExpectedMethodFault()
   {
      return new InvalidArgument();
   }
   /**
    * Method to restore the state as it was before the test is started.
    *
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      if (this.dvsMor != null) {
         assertTrue(this.DVS.destroy(this.dvsMor),
                  "dvsMor destroyed successfully",
                  "dvsMor could not be removed");
      }
      return true;

   }
   
}