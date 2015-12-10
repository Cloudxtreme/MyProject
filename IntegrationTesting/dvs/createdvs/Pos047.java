/*
 * ************************************************************************
 *
 * Copyright 2008-2009 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.createdvs;

import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.MessageConstants.HOST_GET_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.HOST_GET_PASS;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.dvs.DVSUtil;

import dvs.CreateDVSTestBase;

/**
 * Create a DVSwitch inside a valid folder with
 * DVSConfigSpec.defaultPortConfig.blocked = true. <br>
 * Procedure:<br>
 * 1. Create DVSConfigSpec with defaultPortConfig.blocked set to true.<br>
 * 2. Create the DVS with the configSpec.<br>
 * 3. Verify that the given config matches with created DVS.<br>
 * 4. Verify that the port settings are reflected on host as well.<br>
 * 5. Destroy the DVS.<br>
 */
public class Pos047 extends CreateDVSTestBase
{
   private VMwareDVSPortSetting dvPort = null;
   private HostSystem ihs = null;
   private ManagedObjectReference hostMor = null;

   @Override
   public void setTestDescription()
   {
      super.setTestDescription("Create a DVSwitch inside a valid folder with"
               + " DVSConfigSpec.defaultPortConfig.blocked = true");
   }

   /**
    * Method to setup the environment for the test.
    * 
    * @param connectAnchor ConnectAnchor object
    * @return boolean true if successful, false otherwise.
    */
   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      assertTrue(super.testSetUp(), "Super setup successful",
               "Super setup failed.");
      this.ihs = new HostSystem(connectAnchor);
      this.hostMor = ihs.getConnectedHost(false);
      assertNotNull(this.hostMor, HOST_GET_PASS, HOST_GET_FAIL);
      this.networkFolderMor = this.iFolder.getNetworkFolder(this.dcMor);
      this.configSpec = new DVSConfigSpec();
      this.configSpec.setConfigVersion("");
      this.configSpec.setName(this.getTestId());
      dvPort = new VMwareDVSPortSetting();
      dvPort.setBlocked(DVSUtil.getBoolPolicy(false, false));
      this.configSpec.setDefaultPortConfig(dvPort);
      return true;
   }

   /**
    * Method that creates the DVS.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @Test(description = "Create a DVSwitch inside a valid folder with"
               + " DVSConfigSpec.defaultPortConfig.blocked = true")
   public void test()
      throws Exception
   {
      this.dvsMOR = this.iFolder.createDistributedVirtualSwitch(
               this.networkFolderMor, this.configSpec);
      assertNotNull(dvsMOR, "Successfully created DVS", "Failed to create DVS");
      assertTrue(iDistributedVirtualSwitch.validateDVSConfigSpec(this.dvsMOR,
               this.configSpec, null),
               "Successfully verified the dvs config spec",
               "Config spec verification failed.");
      assertTrue(super.verifyPortSettingOnHost(connectAnchor, dvPort, true),
               "Verified the DVPort setting on the host",
               "Failed to verify the DVPort setting on the host");
   }

   /**
    * Method to restore the state as it was before the test is started.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      return super.testCleanUp();
   }
}