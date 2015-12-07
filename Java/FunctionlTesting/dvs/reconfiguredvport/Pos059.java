/*
 * ************************************************************************
 *
 * Copyright 2009 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvport;

import static com.vmware.vcqa.util.Assert.assertNotEmpty;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.ArrayList;
import java.util.List;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.DistributedVirtualSwitchPortCriteria;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.NetworkSystem;

import dvs.CreateDVSTestBase;

/**
 * Reconfigure a dvport to set the scope to a virtual machine mor. Reconfigure
 * the port to change the name.
 */
public class Pos059 extends CreateDVSTestBase
{
   private DVPortConfigSpec[] portConfigSpecs = null;
   private final int DVS_PORT_NUM = 1;
   private ManagedObjectReference vmMor = null;
   private ManagedObjectReference networkMor = null;
   private String portKey = null;
   private VirtualMachineConfigSpec orgVMConfigSpec = null;
   private VirtualMachine ivm = null;
   private HostSystem ihs = null;
   private ManagedObjectReference hostMor = null;
   private String vmName = null;
   private HostNetworkConfig orgHostNetworkConfig = null;
   private NetworkSystem ins = null;
   private VirtualMachineConfigSpec[] vmConfigSpec = null;
   private String ipAddress = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      setTestDescription("Reconfigure a dvport to set the scope to a "
               + "virtual machine mor. Reconfigure the port to change the name.");
   }

   /**
    * Method to setup the environment for the test.
    * 
    * @param connectAnchor ConnectAnchor object
    * @return boolean true if successful, false otherwise.
    */
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      DistributedVirtualSwitchPortCriteria portCriteria = null;
      List<ManagedObjectReference> hostList = new ArrayList<ManagedObjectReference>();
      DistributedVirtualSwitchPortConnection portConnection = null;
      DistributedVirtualSwitchHostMemberConfigSpec hostMemberConfigSpec = null;
      DistributedVirtualSwitchHostMemberPnicBacking pnicBaking = null;
      Vector allHosts = null;
      HostNetworkConfig[] hostNetworkConfig = null;
      List<ManagedObjectReference> hostMorList = null;
      assertTrue(super.testSetUp(), "Successfully logged in "
               + "to the session", "Failed to login");
      this.ihs = new HostSystem(connectAnchor);
      this.ins = new NetworkSystem(connectAnchor);
      this.networkFolderMor = this.iFolder.getNetworkFolder(this.dcMor);
      assertNotNull(this.networkFolderMor, "The network folder mor is null");
      this.hostMor = this.ihs.getConnectedHost(false);
      assertNotNull(this.hostMor, "The host mor is null");
      hostList.add(this.hostMor);
      this.networkMor = this.ins.getNetworkSystem(this.hostMor);
      this.configSpec = DVSUtil.createDefaultDVSConfigSpec(
               getTestId() + "-DVS", hostList);
      assertNotNull(this.configSpec, "The config spec returned is null");
      this.configSpec.setNumStandalonePorts(DVS_PORT_NUM);
      this.dvsMOR = this.iFolder.createDistributedVirtualSwitch(
               this.networkFolderMor, this.configSpec);
      assertNotNull(this.dvsMOR, "Could not create a vds in the network "
               + "folder");
      hostNetworkConfig = this.iDistributedVirtualSwitch.getHostNetworkConfigMigrateToDVS(
               this.dvsMOR, this.hostMor);
      assertTrue(
               hostNetworkConfig != null && hostNetworkConfig.length == 2
                        && hostNetworkConfig[0] != null
                        && hostNetworkConfig[1] != null,
               "Failed to obtain the new "
                        + "network configuration to migrate the host pnics to the vds");
      assertTrue(this.ins.updateNetworkConfig(this.networkMor,
               hostNetworkConfig[0], TestConstants.CHANGEMODE_MODIFY),
               "Successfully updated the network configuration to migrate "
                        + "the host pnics to the vds",
               "Failed to update the network "
                        + "configuration to migrate the host pnics to the vds");
      this.orgHostNetworkConfig = hostNetworkConfig[1];
      portCriteria = this.iDistributedVirtualSwitch.getPortCriteria(false,
               null, null, null, null, false);
      List<String> portKeyList = this.iDistributedVirtualSwitch.fetchPortKeys(
               this.dvsMOR, portCriteria);
      assertTrue(portKeyList != null && portKeyList.size() == DVS_PORT_NUM,
               "Successfully obtained a port in the vds", "Failed to obtain a "
                        + "port in the vds");
      this.portKey = portKeyList.get(0);
      this.ivm = new VirtualMachine(connectAnchor);
      List<ManagedObjectReference> vmList = this.ihs.getAllVirtualMachine(hostMor);
      assertNotEmpty(vmList, "Found atleast one vm in the inventory", "Failed "
               + "to find a vm in the inventory");
      this.vmMor = vmList.get(0);
      assertNotNull(this.vmMor, "The virtual machine MOR is null");
      this.vmName = this.ivm.getVMName(this.vmMor);
      portConfigSpecs = new DVPortConfigSpec[DVS_PORT_NUM];
      portConfigSpecs[0] = new DVPortConfigSpec();
      portConfigSpecs[0].setKey(portKeyList.get(0));
      portConfigSpecs[0].getScope().clear();
      portConfigSpecs[0].getScope().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new ManagedObjectReference[] { this.vmMor }));
      portConfigSpecs[0].setOperation(TestConstants.CONFIG_SPEC_EDIT);
      assertTrue(iDistributedVirtualSwitch.reconfigurePort(this.dvsMOR,
               this.portConfigSpecs), "Successfully reconfigured the port "
               + "to set the scope to the virtual machine mor", "Failed to "
               + "reconfigure the port to set the scope to the virtual "
               + "machine mor");
      portConnection = new DistributedVirtualSwitchPortConnection();
      portConnection.setSwitchUuid(this.iDistributedVirtualSwitch.getConfig(
               dvsMOR).getUuid());
      portConnection.setPortKey(this.portKey);
      vmConfigSpec = DVSUtil.getVMConfigSpecForDVSPort(this.vmMor,
               connectAnchor,
               new DistributedVirtualSwitchPortConnection[] { portConnection });
      assertTrue(vmConfigSpec != null && vmConfigSpec.length == 2
               && vmConfigSpec[0] != null && vmConfigSpec[1] != null,
               "The config "
                        + "spec for reconfiguring the virtual machines is null");
      this.orgVMConfigSpec = vmConfigSpec[1];
      assertTrue(this.ivm.reconfigVM(this.vmMor, vmConfigSpec[0]),
               "Successfully reconfigured the virtual machine to connect to "
                        + "the port",
               "Failed to reconfigure the virtual machine to "
                        + "connect to the port");
      /*
       * Verify that the vm is connected to the port
       */
      assertTrue(DVSUtil.verifyPortConnectionOnVM(connectAnchor, vmMor,
               portConnection),
               "Verified that the vm is connected to the port",
               "The vm is not connected to the dvport");
      portConfigSpecs[0] = new DVPortConfigSpec();
      portConfigSpecs[0].setName(getTestId() + "-port");
      portConfigSpecs[0].setKey(portKeyList.get(0));
      portConfigSpecs[0].setOperation(TestConstants.CONFIG_SPEC_EDIT);
      return true;
   }

   /**
    * Method that reconfigures the port's name
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Reconfigure a dvport to set the scope to a "
               + "virtual machine mor. Reconfigure the port to change the name.")
   public void test()
      throws Exception
   {
      DVPortConfigSpec[] dvPortConfigSpec = null;
      ManagedObjectReference[] actualScope = null;
      assertTrue(iDistributedVirtualSwitch.reconfigurePort(this.dvsMOR,
               this.portConfigSpecs), "Successfully reconfigured the port "
               + "to set the scope to the virtual machine mor", "Failed to "
               + "reconfigure the port to set the scope to the virtual "
               + "machine mor");
      dvPortConfigSpec = iDistributedVirtualSwitch.getPortConfigSpec(dvsMOR,
               new String[] { portConfigSpecs[0].getKey() });
      assertTrue(dvPortConfigSpec != null && dvPortConfigSpec.length == 1,
               "Found the port config spec",
               "Could not find the port config spec");
      actualScope = com.vmware.vcqa.util.TestUtil.vectorToArray(dvPortConfigSpec[0].getScope(), com.vmware.vc.ManagedObjectReference.class);
      assertTrue(actualScope != null && actualScope.length == 1, "Found "
               + "one mor in the port's scope", "Failed to find a mor in the "
               + "port's scope");
      assertTrue(actualScope[0].getValue().equals(vmMor.getValue())
               && actualScope[0].getServerGuid().equals(vmMor.getServerGuid())
               && actualScope[0].getType().equals(vmMor.getType()), "The "
               + "scope of the port was preserved", "The scope of the port "
               + "was not preserved");
   }

   /**
    * Method to restore the state as it was before the test is started.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      assertTrue(this.ivm.reconfigVM(vmMor, orgVMConfigSpec), "Successfully "
               + "reverted the virtual machine's settings",
               "Failed to revert the " + "virtual machine settings");
      assertTrue(this.ins.updateNetworkConfig(this.networkMor,
               this.orgHostNetworkConfig, TestConstants.CHANGEMODE_MODIFY),
               "Successfully reverted the network configuration on the host",
               "Failed to revert the network configuration on the host");
      assertTrue(this.iDistributedVirtualSwitch.destroy(this.dvsMOR),
               "Successfully destroyed the vds", "Failed to destroy the vds");
      return true;
   }
}