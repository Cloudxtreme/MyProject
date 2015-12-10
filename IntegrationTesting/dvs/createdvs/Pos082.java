
/*
 * ************************************************************************
 *
 * Copyright 2009-2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.createdvs;

import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.MessageConstants.VM_DEL_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.VM_DEL_PASS;
import static com.vmware.vcqa.vim.MessageConstants.VM_POWEROFF_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.VM_POWEROFF_PASS;

import java.util.Arrays;
import java.util.List;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Factory;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;

import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.IDataDrivenTest;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.execution.TestExecutionUtils;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * DESCRIPTION:<br>
 * Data-driven test to create DistributedVirtualSwitch with a ipfixEnabled to
 * true/false in DVSPortSetting without any IpfixConfig parameter <br>
 * SETUP:<br>
 * TEST:<br>
 * 1. Create a DVS with a host adding to it,
 * 2. Add standalone port to the created DVS.
 * 3. Create a VM and reconfigure it to add the DVPort created before.
 * 4. Verify PortPersistenceLocation on that VM and the IpfixConfig settings <br>
 * CLEANUP:<br>
 * 5. Destroy the created VM and DVS<br>
 *
 */

public class Pos082 extends TestBase implements IDataDrivenTest
{
   private Folder folder = null;
   private VMwareDVSConfigSpec configSpec = null;
   private HostSystem hs = null;
   private DistributedVirtualSwitch dvs = null;
   private ManagedObjectReference networkFolderMor = null;
   private ManagedObjectReference dvsMor = null;
   private ManagedObjectReference hostMor = null;
   private VMwareDVSPortSetting dvPort = null;
   private String dvsUUID = null;
   private Vector<ManagedObjectReference> vmMors = null;
   private DistributedVirtualSwitchPortConnection dvsConn = null;
   private VirtualMachine vm = null;
   private ManagedObjectReference vmMor = null;

   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      this.vm = new VirtualMachine(connectAnchor);
      this.folder = new Folder(connectAnchor);
      this.hs = new HostSystem(connectAnchor);
      this.dvs = new DistributedVirtualSwitch(connectAnchor);
      this.hostMor = this.hs.getConnectedHost(null);
      this.configSpec = new VMwareDVSConfigSpec();
      this.networkFolderMor = (ManagedObjectReference) this.folder.getNetworkFolder(this.folder.getDataCenter());
      this.configSpec.setConfigVersion("");
      this.configSpec.setName(this.getClass().getName());
      this.configSpec = (VMwareDVSConfigSpec) DVSUtil.addHostsToDVSConfigSpec(
               configSpec, Arrays.asList(this.hostMor));
      dvPort = new VMwareDVSPortSetting();
      dvPort.setIpfixEnabled(DVSUtil.getBoolPolicy(
               this.data.getBoolean(DVSTestConstants.IP_FIX_INHERITED_KEY),
               this.data.getBoolean(DVSTestConstants.IP_FIX_ENABLED_KEY)));
      this.configSpec.setDefaultPortConfig(dvPort);
      return true;
   }

   /**
    * Test.
    */
   @Test(description = "Data-driven test to create DistributedVirtualSwitch with a "
            + "ipfixEnabled to true/false in DVSPortSetting without any IpfixConfig parameter")
   public void test()
      throws Exception
   {
      dvsMor = folder.createDistributedVirtualSwitch(networkFolderMor,
               this.configSpec);
      this.dvsUUID = this.dvs.getConfig(dvsMor).getUuid();
      // Add a standalone port to the dvs created.
      List<String> keys = this.dvs.addStandaloneDVPorts(dvsMor, 1);
      // Create a VM and connect it to the dvs.
      this.vmMors = DVSUtil.createVms(connectAnchor, hostMor, 1, 0);
      vmMor = vmMors.firstElement();
      dvsConn = new DistributedVirtualSwitchPortConnection();
      dvsConn.setPortgroupKey(null);
      dvsConn.setSwitchUuid(this.dvsUUID);
      dvsConn.setPortKey(keys.get(0));
      VirtualMachineConfigSpec[] vmConfigSpec = null;
      vmConfigSpec = DVSUtil.getVMConfigSpecForDVSPort(
               vmMor,
               connectAnchor,
               new DistributedVirtualSwitchPortConnection[] { DVSUtil.buildDistributedVirtualSwitchPortConnection(
                        dvsUUID, keys.get(0), null) });
      Assert.assertTrue((vmConfigSpec != null && vmConfigSpec.length == 2
               && vmConfigSpec[0] != null && vmConfigSpec[1] != null),
               "Successfully obtained the original and the updated virtual"
                        + " machine config spec",
               "Cannot reconfigure the virtual machine to use the " + "DV port");
      Assert.assertTrue(this.vm.reconfigVM(vmMor, vmConfigSpec[0]),
               "Successfully reconfigured the virtual machine to use "
                        + "the DV port",
               "Failed to  reconfigured the virtual machine to use "
                        + "the DV port");
      Assert.assertTrue(DVSUtil.performVDSPortVerifcation(connectAnchor,
               this.hostMor, vmMor, dvsConn, this.dvsUUID),
               " Failed to verify port connection  and/or PortPersistenceLocation for VM : "
                        + vm.getName(vmMor));
      Assert.assertTrue(
               (dvs.validateDVSConfigSpec(this.dvsMor, this.configSpec, null)),
               "Successfully verified DVS ConfigSpec",
               "DVS config spec is not valid");
      // Verify PortSettings
      dvPort = (VMwareDVSPortSetting) this.dvs.getConfig(dvsMor).getDefaultPortConfig();
      Assert.assertTrue(DVSUtil.verifyIpfixPortSettingFromParent(connectAnchor,
               dvsMor, dvPort, keys), "Verification of IpfixPortSetting failed");
   }

   /**
    * Method to cleanup the test.
    */
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      /*
       * Destroy VM
       */
      if (vmMor != null) {
         assertTrue((this.vm.setVMState(vmMor, VirtualMachinePowerState.POWERED_OFF, false)),
                  VM_POWEROFF_PASS, VM_POWEROFF_FAIL);
         assertTrue(this.vm.destroy(vmMor), VM_DEL_PASS, VM_DEL_FAIL);

      }
      if (dvsMor != null) {
         folder.destroy(dvsMor);
         log.info("Destroyed DVS successfully");
      }
      return true;
   }

   /**
    * This method retrieves either all the data-driven tests or one
    * test based on the presence of test id in the execution properties
    * file.
    *
    * @return Object[]
    *
    * @throws Exception
    */
   @Factory
   @Parameters({"dataFile"})
   public Object[] getTests(@Optional("") String dataFile)
      throws Exception {
      Object[] tests = TestExecutionUtils.getTests(this.getClass().getName(),
         dataFile);
      /*
       * Load the dvs execution properties file
       */
      String testId = TestUtil.getPropertyValue(this.getClass().getName(),
         DVSTestConstants.DVS_EXECUTION_PROP_FILE);
      if(testId == null){
         return tests;
      } else {
         for(Object test : tests){
            if(test instanceof TestBase){
               TestBase testBase = (TestBase)test;
               if(testBase.getTestId().equals(testId)){
                  return new Object[]{testBase};
               }
            } else {
               log.error("The current test is not an instance of TestBase");
            }
         }
         log.error("The test id " + testId + "could not be found");
      }
      /*
       * TODO : Examine the possibility of a custom exception here since
       * the test id provided is wrong and the user needs to be notified of
       * that.
       */
      return null;
   }
   public String getTestName()
   {
      return getTestId();
   }
}
