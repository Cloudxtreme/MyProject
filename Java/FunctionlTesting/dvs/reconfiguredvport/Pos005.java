/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvport;

import static com.vmware.vc.HostSystemConnectionState.CONNECTED;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.MessageConstants.HOST_GET_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.VM_CREATE_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.VM_CREATE_PASS;
import static com.vmware.vcqa.vim.MessageConstants.VM_DEL_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.VM_DEL_PASS;
import static com.vmware.vcqa.vim.MessageConstants.VM_POWEROFF_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.VM_POWEROFF_PASS;

import java.util.HashMap;
import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.ConfigSpecOperation;
import com.vmware.vc.DVPortConfigSpec;
import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.DistributedVirtualSwitchPortCriteria;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.util.VersionConstants;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.HostSystemInformation;
import com.vmware.vcqa.vim.host.NetworkSystem;

import dvs.CreateDVSTestBase;

/**
 * DESCRIPTION:<br>
 * (Reconfigure DVPort and set a valid VM Mor in scope property) <br>
 * TARGET: VC <br>
 * NOTE : PR#494773 <br>
 * <br>
 * SETUP:<br>
 * 1. Create a vDS with host <br>
 * 2. Create one VM on this host H1 TEST:<br>
 * 3. Reconfigure DVPort and set a valid VM Mor in scope property <br>
 * 4. Verify port connection and/or PortPersistenceLocation for VM <br>
 * CLEANUP:<br>
 * 5. Delete VM<br>
 * 6. Destroy vD<br>
 */
public class Pos005 extends CreateDVSTestBase
{

   /*
    * private data variables
    */
   private DVPortConfigSpec[] portConfigSpecs = null;
   private final int DVS_PORT_NUM = 1;
   private ManagedObjectReference vmMor = null;
   private ManagedObjectReference networkMor = null;
   private String portKey = null;
   private VirtualMachine ivm = null;
   private HostSystem ihs = null;
   private ManagedObjectReference hostMor = null;
   private ManagedObjectReference dvsMor = null;
   private String vmName = null;
   private HostNetworkConfig orgHostNetworkConfig = null;
   private NetworkSystem ins = null;
   private String hostName;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   @Override
   public void setTestDescription()
   {
      super.setTestDescription("Reconfigure DVPort and set a valid VM Mor "
               + "in scope property");
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
      HashMap<ManagedObjectReference, HostSystemInformation> hostsMap = null;
      DistributedVirtualSwitchHostMemberConfigSpec hostMemberConfigSpec = null;
      DistributedVirtualSwitchPortCriteria portCriteria = null;
      HostNetworkConfig[] hostNetworkConfig = null;
      this.ihs = new HostSystem(connectAnchor);
      this.ins = new NetworkSystem(connectAnchor);
      assertTrue(super.testSetUp(), "testSetUp failed");
      this.networkFolderMor = this.iFolder.getNetworkFolder(this.dcMor);
      hostsMap = this.ihs.getAllHosts(VersionConstants.ESX4x, CONNECTED);
      assertNotNull(hostsMap, "The host map is null");
      this.hostMor = hostsMap.keySet().iterator().next();
      assertNotNull(this.hostMor, HOST_GET_FAIL);
      hostName = this.ihs.getHostName(hostMor);
      this.networkMor = this.ins.getNetworkSystem(this.hostMor);
      assertNotNull(this.networkMor, "The network system MOR is null");
      this.networkMor = this.ins.getNetworkSystem(this.hostMor);
      this.configSpec = new DVSConfigSpec();
      this.configSpec.setName(this.getClass().getName());
      this.configSpec.setNumStandalonePorts(DVS_PORT_NUM);
      hostMemberConfigSpec = new DistributedVirtualSwitchHostMemberConfigSpec();
      hostMemberConfigSpec.setHost(this.hostMor);
      hostMemberConfigSpec.setOperation(TestConstants.CONFIG_SPEC_ADD);
      DistributedVirtualSwitchHostMemberPnicBacking pnicBaking = new DistributedVirtualSwitchHostMemberPnicBacking();
      pnicBaking.getPnicSpec().clear();
      pnicBaking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] {}));
      hostMemberConfigSpec.setBacking(pnicBaking);
      this.configSpec.getHost().clear();
      this.configSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostMemberConfigSpec }));
      this.dvsMor = this.iFolder.createDistributedVirtualSwitch(
               this.networkFolderMor, this.configSpec);
      assertNotNull(this.dvsMor, "Cannot create the distributed virtual "
               + "switch with the config spec passed");

      assertTrue(this.ins.refresh(this.networkMor),
               "Refreshed the network system of the host",
               "Failed to refresh the network information and settings");

      hostNetworkConfig = this.iDistributedVirtualSwitch.getHostNetworkConfigMigrateToDVS(
               this.dvsMor, this.hostMor);
      assertTrue(
               (hostNetworkConfig != null && hostNetworkConfig.length == 2
                        && hostNetworkConfig[0] != null && hostNetworkConfig[1] != null),
               "Successfully retrieved the original and the "
                        + "updated network config of the host",
               "Can not retrieve the original and the updated "
                        + "network config");
      this.orgHostNetworkConfig = hostNetworkConfig[1];
      assertTrue(this.ins.updateNetworkConfig(this.networkMor,
               hostNetworkConfig[0], TestConstants.CHANGEMODE_MODIFY),
               "Successfully updated the host network config",
               "Can not update the host network config");

      portCriteria = this.iDistributedVirtualSwitch.getPortCriteria(false,
               null, null, null, null, false);
      List<String> portKeyList = this.iDistributedVirtualSwitch.fetchPortKeys(
               this.dvsMor, portCriteria);
      assertTrue((portKeyList != null && portKeyList.size() == DVS_PORT_NUM),
               "Can't get correct port keys");
      this.portKey = portKeyList.get(0);
      this.ivm = new VirtualMachine(connectAnchor);
      vmName = TestUtil.getRandomizedTestId(this.getTestId());
      vmMor = this.ivm.createDefaultVM(vmName,
               this.ihs.getPoolMor(this.hostMor), this.hostMor);
      assertNotNull(vmMor, VM_CREATE_PASS + ":" + vmName, VM_CREATE_FAIL + ":"
               + vmName);
      portConfigSpecs = new DVPortConfigSpec[DVS_PORT_NUM];
      portConfigSpecs[0] = new DVPortConfigSpec();
      portConfigSpecs[0].setKey(portKeyList.get(0));
      portConfigSpecs[0].getScope().clear();
      portConfigSpecs[0].getScope().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new ManagedObjectReference[] { this.vmMor }));
      portConfigSpecs[0].setOperation(ConfigSpecOperation.EDIT.value());
      return true;
   }

   /**
    * Method that creates the DVS.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @Test(description = "Reconfigure DVPort and set a valid VM Mor "
               + "in scope property")
   public void test()
      throws Exception
   {
      DVSConfigInfo configInfo = null;
      String switchUUID = null;
      DistributedVirtualSwitchPortConnection portConnection = null;
      VirtualMachineConfigSpec[] vmConfigSpec = null;
      assertTrue(iDistributedVirtualSwitch.reconfigurePort(this.dvsMor,
               this.portConfigSpecs), "Successfully reconfigured DVS",
               "Failed to reconfigure dvs");
      configInfo = this.iDistributedVirtualSwitch.getConfig(this.dvsMor);
      assertNotNull(configInfo, "The DVS config info is null");
      switchUUID = configInfo.getUuid();
      assertNotNull(switchUUID, "The switch UIID is null ");
      portConnection = new DistributedVirtualSwitchPortConnection();
      portConnection.setSwitchUuid(switchUUID);
      portConnection.setPortKey(this.portKey);

      vmConfigSpec = DVSUtil.getVMConfigSpecForDVSPort(this.vmMor,
               connectAnchor,
               new DistributedVirtualSwitchPortConnection[] { portConnection });
      assertTrue((vmConfigSpec != null && vmConfigSpec.length == 2
               && vmConfigSpec[0] != null && vmConfigSpec[1] != null),
               "Successfully obtained the original and the updated virtual"
                        + " machine config spec",
               "Can not reconfigure the virtual machine to use the "
                        + "DV port");
      assertTrue(this.ivm.reconfigVM(vmMor, vmConfigSpec[0]),
               "Successfully reconfigured the virtual machine to use "
                        + "the DV port",
               "Failed to  reconfigured the virtual machine to use "
                        + "the DV port");
      assertTrue(DVSUtil.performVDSPortVerifcation(connectAnchor, this.hostMor,
               vmMor, portConnection, switchUUID),
               " Failed to verify port connection  and/or PortPersistenceLocation for VM : "
                        + vmName);
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

      if (this.vmMor != null) {
         assertTrue((this.ivm.setVMState(vmMor, VirtualMachinePowerState.POWERED_OFF, false)),
                  VM_POWEROFF_PASS, VM_POWEROFF_FAIL);
         assertTrue(this.ivm.destroy(vmMor), VM_DEL_PASS, VM_DEL_FAIL);

      }
      if (this.orgHostNetworkConfig != null) {
         log.info("Restoring the network setting of the host");
         assertTrue(this.ins.updateNetworkConfig(this.networkMor,
                  this.orgHostNetworkConfig, TestConstants.CHANGEMODE_MODIFY),
                  " Failed to restore the network setting of the host");
      }
      if (this.dvsMor != null) {
         assertTrue(this.iDistributedVirtualSwitch.destroy(this.dvsMor),
                  " Failed to destroy vDs");
      }
      return true;
   }
}