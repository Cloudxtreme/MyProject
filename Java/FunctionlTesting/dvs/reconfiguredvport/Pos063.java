/*
 * ************************************************************************
 *
 * Copyright 2009-2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvport;

import java.util.Arrays;
import static com.vmware.vcqa.vim.MessageConstants.VM_POWEROFF_PASS;
import java.util.List;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Factory;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;

import com.vmware.vc.ConfigSpecOperation;
import com.vmware.vc.DVPortConfigSpec;
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
 * Reconfigure DVPort to a DistributedVirtualSwitch with IpfixEnabled parameter
 * set to true/false in VMPortConfigPolicy<br>
 * SETUP:<br>
 * 1. Create a DVS by adding a host to VC.<br>
 * 2. Create portConfigSpecs object with IpfixEnabled parameter set <br>
 * TEST:<br>
 * 3. reconfigurePort with the PortConfigSpecs created before.
 * 4. Create a VM and reconfigure the VM to connect to the DV Port <br>
 * 5. Verify the IpfixConfig Settings <br>
 * CLEANUP:<br>
 * 6. Destroy the created VM<br>
 * 7. Destroy the created DVS <br>
 *
 */
public class Pos063 extends TestBase implements IDataDrivenTest
{
   private DistributedVirtualSwitch dvs = null;
   private Folder folder = null;
   private DVPortConfigSpec[] portConfigSpecs = null;
   private final int DVS_PORT_NUM = 1;
   private String dvSwitchUuid = null;
   private VMwareDVSConfigSpec configSpec = null;
   private ManagedObjectReference dcMor = null;
   private ManagedObjectReference networkFolderMor = null;
   private ManagedObjectReference dvsMor = null;
   private ManagedObjectReference hostMor = null;
   private HostSystem hs = null;
   private VMwareDVSPortSetting dvPort = null;
   private VirtualMachine vm = null;
   private Vector<ManagedObjectReference> vmMors = null;
   private DistributedVirtualSwitchPortConnection dvsConn = null;
   private List<String> portKeyList= null;

   /**
    *Set Test Setup
    */
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean setUpDone = false;
      this.folder = new Folder(connectAnchor);
      this.hs = new HostSystem(connectAnchor);
      this.hostMor = this.hs.getConnectedHost(null);
      this.vm = new VirtualMachine(connectAnchor);
      this.dcMor = this.folder.getDataCenter();
      this.networkFolderMor = this.folder.getNetworkFolder(this.dcMor);
      Assert.assertNotNull(this.networkFolderMor,
               "Unable to get Networkfolder Mor");
      this.dvs = new DistributedVirtualSwitch(connectAnchor);
      // Create DVS by adding a host
      this.configSpec = new VMwareDVSConfigSpec();
      this.configSpec = (VMwareDVSConfigSpec) DVSUtil.addHostsToDVSConfigSpec(
               configSpec, Arrays.asList(this.hostMor));
      this.configSpec.setName(this.getClass().getName());
      this.dvsMor = this.folder.createDistributedVirtualSwitch(
               this.networkFolderMor, this.configSpec);
      this.dvSwitchUuid = dvs.getConfig(dvsMor).getUuid();
      this.portKeyList = dvs.addStandaloneDVPorts(dvsMor, DVS_PORT_NUM);
      dvPort = new VMwareDVSPortSetting();
      // Set IpfixEnabled to true/false
      dvPort.setIpfixEnabled(DVSUtil.getBoolPolicy(
               this.data.getBoolean(DVSTestConstants.IP_FIX_INHERITED_KEY),
               this.data.getBoolean(DVSTestConstants.IP_FIX_ENABLED_KEY)));
      if (portKeyList != null && portKeyList.size() == DVS_PORT_NUM) {
         portConfigSpecs = new DVPortConfigSpec[DVS_PORT_NUM];
         portConfigSpecs[0] = new DVPortConfigSpec();
         portConfigSpecs[0].setKey(portKeyList.get(0));
         portConfigSpecs[0].setOperation(ConfigSpecOperation.EDIT.value());
         portConfigSpecs[0].setSetting(dvPort);
      }
      setUpDone = true;
      return setUpDone;
   }

   /**
    * Test
    */
   @Test(description="Reconfigure DVPort to a DistributedVirtualSwitch with IpfixEnabled " +
   		"parameter set to true/false in VMPortConfigPolicy")
   public void test()
      throws Exception
   {
      // Reconfigure DVPort
      Assert.assertTrue(this.dvs.reconfigurePort(this.dvsMor,
               this.portConfigSpecs), "Failed to reconfigure port");
      //Create a VM
      this.vmMors = DVSUtil.createVms(connectAnchor, hostMor, 1, 0);
      //Connect VMs to DVPort
      for (ManagedObjectReference vmMor : this.vmMors) {
         dvsConn = new DistributedVirtualSwitchPortConnection();
         dvsConn.setPortKey(portKeyList.get(0));
         dvsConn.setSwitchUuid(this.dvSwitchUuid);
         VirtualMachineConfigSpec[] vmConfigSpec = null;
         vmConfigSpec = DVSUtil.getVMConfigSpecForDVSPort(
                  vmMor,
                  connectAnchor,
                  new DistributedVirtualSwitchPortConnection[]
                          { DVSUtil.buildDistributedVirtualSwitchPortConnection(
                          dvSwitchUuid, portKeyList.get(0), null) });
         Assert.assertTrue(
                  (vmConfigSpec != null && vmConfigSpec.length == 2
                           && vmConfigSpec[0] != null && vmConfigSpec[1] != null),
                  "Successfully obtained the original and the updated virtual"
                           + " machine config spec",
                  "Can not reconfigure the virtual machine to use the "
                           + "DV port");
         Assert.assertTrue(this.vm.reconfigVM(vmMor, vmConfigSpec[0]),
                  "Successfully reconfigured the virtual machine to use "
                           + "the DV port",
                  "Failed to  reconfigured the virtual machine to use "
                           + "the DV port");
         Assert.assertTrue(DVSUtil.performVDSPortVerifcation(connectAnchor,
                  this.hostMor, vmMor, dvsConn, this.dvSwitchUuid),
                  " Failed to verify port connection  and/or PortPersistenceLocation for VM : "
                           + vm.getName(vmMor));
         // Verify PortSettings from VC & hostd side.
         dvPort =(VMwareDVSPortSetting) this.dvs.getConfig(dvsMor).getDefaultPortConfig();
         Assert.assertTrue(DVSUtil.verifyIpfixPortSettingFromParent(
                  connectAnchor, dvsMor, dvPort, portKeyList),
                  "Verification of IpfixPortSetting failed");
      }
   }

   /**
    * Test Cleanup
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      if (this.vmMors != null) {
         Assert.assertTrue(vm.setVMsState(vmMors, VirtualMachinePowerState.POWERED_OFF, false),
                  VM_POWEROFF_PASS, VM_POWEROFF_PASS);
         vm.destroy(vmMors);
      }
      if (this.dvsMor != null) {
         status &= this.folder.destroy(dvsMor);
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
