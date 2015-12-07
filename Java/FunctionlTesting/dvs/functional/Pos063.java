/*
 * *****************************************************************************
 *
 * Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * *****************************************************************************
 */
package dvs.functional;

import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_LATE_BINDING;

import java.util.Arrays;
import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DVSNameArrayUplinkPortPolicy;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.HostProxySwitch;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.vim.Datastore;
import com.vmware.vcqa.vim.DatastoreProperties;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.DatastoreInformation;
import com.vmware.vcqa.vim.host.NetworkSystem;
import com.vmware.vcqa.vim.host.StorageSystem;

public class Pos063 extends TestBase
{
   private HostSystem hostSystem = null;
   private ManagedObjectReference hostMor = null;
   private NetworkSystem networkSystem = null;
   private ManagedObjectReference dvsMor = null;
   private Folder folder = null;
   private String switchUuid = null;
   private DistributedVirtualSwitch vds = null;
   private DistributedVirtualPortgroup vdsPortgroup = null;
   private String portgroupKey = null;
   private Datastore ds = null;
   private ManagedObjectReference dsMor = null;
   private ManagedObjectReference vmMor = null;
   private StorageSystem iss = null;
   private VirtualMachine ivm = null;

   /**
    * This method creates a vds and adds a host with a free pnic to the same
    * with the proxy switch having a maximum of 4 ports.A vm is created on
    * the host and powered on.
    *
    * @return boolean, true if all the setup operations were successful
    *                  false otherwise
    *
    * @throws Exception
    */
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      /*
       * Pick up a host in the inventory
       */
      hostSystem = new HostSystem(connectAnchor);
      hostMor = hostSystem.getConnectedHost(null);
      networkSystem = new NetworkSystem(connectAnchor);
      folder = new Folder(connectAnchor);
      vds = new DistributedVirtualSwitch(connectAnchor);
      vdsPortgroup = new DistributedVirtualPortgroup(connectAnchor);
      ivm = new VirtualMachine(connectAnchor);
      ds = new Datastore(connectAnchor);
      iss = new StorageSystem(connectAnchor);
      assertNotNull(hostMor, "Found a host in the inventory","Failed to " +
      		"find a host in the inventory");
      /*
       * Create the host member spec
       */
      String[] freePnics = networkSystem.getPNicIds(hostMor);
      String hostName = hostSystem.getHostName(hostMor);
      assertTrue(freePnics != null && freePnics[0] != null,
               "There are no free pnics on " + hostName);
      DistributedVirtualSwitchHostMemberConfigSpec hostMember = new
               DistributedVirtualSwitchHostMemberConfigSpec();
      hostMember.setOperation(TestConstants.CONFIG_SPEC_ADD);
      hostMember.setHost(hostMor);
      /*
       * Set maximum proxy switch ports to four
       */
      hostMember.setMaxProxySwitchPorts(4);
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = new
      DistributedVirtualSwitchHostMemberPnicBacking();
      DistributedVirtualSwitchHostMemberPnicSpec pnicSpec = new
               DistributedVirtualSwitchHostMemberPnicSpec();
      pnicSpec.setPnicDevice(freePnics[0]);
      pnicBacking.getPnicSpec().clear();
      pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new
               DistributedVirtualSwitchHostMemberPnicSpec[] { pnicSpec }));
      hostMember.setBacking(pnicBacking);
      /*
       * Populate the dvsconfigspec
       */
      DVSConfigSpec dvsConfigSpec = new DVSConfigSpec();
      dvsConfigSpec.setName(getTestId()+"-dvs");
      dvsConfigSpec.getHost().clear();
      dvsConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new
               DistributedVirtualSwitchHostMemberConfigSpec[]{hostMember}));
      String[] uplinkPortNames = new String[]{"Uplink1"};
      DVSNameArrayUplinkPortPolicy uplinkPolicyInst = new
         DVSNameArrayUplinkPortPolicy();
      uplinkPolicyInst.getUplinkPortName().clear();
      uplinkPolicyInst.getUplinkPortName().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(uplinkPortNames));
      dvsConfigSpec.setUplinkPortPolicy(uplinkPolicyInst);
      dvsMor = this.folder.createDistributedVirtualSwitch(
               folder.getNetworkFolder(folder.getDataCenter()),dvsConfigSpec);
      assertNotNull(dvsMor,"Successfully created the vds","Failed " +
      		   "to create the vds");
      switchUuid = vds.getConfig(dvsMor).getUuid();
      /*
       * Add a late binding portgroup to the vds
       */
      DVPortgroupConfigSpec pgConfigSpec =  new DVPortgroupConfigSpec();
      pgConfigSpec.setNumPorts(1);
      pgConfigSpec.setType(DVPORTGROUP_TYPE_LATE_BINDING);
      pgConfigSpec.setName(this.getTestId()+"-lpg");
      List<ManagedObjectReference> pgMors = vds.addPortGroups(dvsMor,
               new DVPortgroupConfigSpec[]{pgConfigSpec});
      assertTrue(pgMors != null && pgMors.size() ==1, "Failed to add the " +
               "late binding portgroup");
      portgroupKey = vdsPortgroup.getKey(pgMors.get(0));
      assertNotNull(portgroupKey,"The portgroup key is null");
      /*
       * Create a vm and attach it to the late binding portgroup and power on
       * the vm
       */
      DatastoreProperties dsProperties = new DatastoreProperties();
      dsProperties.setIsAccessible(true);
      dsProperties.setIsShared(false);
      dsMor = ds.getDatastores(Arrays.asList(new
               ManagedObjectReference[]{hostMor}),dsProperties).get(0);
      DatastoreInformation datastoreInfo = ds.getDatastoreInfo(dsMor);
      vmMor = iss.createVirtualMachine(hostSystem,hostMor, ivm,
               hostName+"_vm1", datastoreInfo);
      assertNotNull(vmMor,"The virtual machine could not be created on " +
      		   "the datastore");
      /*
       * Attach the vm to the late binding portgroup
       */
      VirtualMachineConfigSpec origConfigSpec = DVSUtil.reconfigVM(vmMor,
               dvsMor, connectAnchor, null,portgroupKey);
      /*
       * Power on the vm
       */
      assertTrue(ivm.setVMState(vmMor, VirtualMachinePowerState.POWERED_ON, false),"Successfully " +
               		"powered on the vm","Failed to power on the vm");
      /*
       * Wait for the port to be pushed to the host
       */
      Thread.sleep(10000);
      return true;
   }

   /**
    * This method verifies the number of available ports in the proxy switch
    *
    * @throws Exception
    */
   @Test(description = "Create a vds and add a host with maximum 4 ports " +
   		"on the proxy switch. Create a late binding portgroup with 1 port " +
   		"and create a vm to connect to this portgroup and power it on. " +
   		"Verify that the number of available ports on the host is one.(1 " +
   		"port is reserved, 1 port is connected to a pnic, 1 port is " +
   		"connected to the vm's vnic)")
   public void test()
      throws Exception
   {
      HostProxySwitch hostProxySwitch = com.vmware.vcqa.util.TestUtil.vectorToArray(networkSystem.getNetworkInfo(
                        networkSystem.getNetworkSystem(hostMor)).getProxySwitch(), com.vmware.vc.HostProxySwitch.class)[0];
      int numAvailablePorts = hostProxySwitch.getNumPortsAvailable();
      assertTrue(numAvailablePorts ==1,"There is one available port on the " +
      		   "proxy switch on the host","The expected number of ports " +
      		   		"is not available on the host");

   }

   /**
    * This method destroys the virtual machine and the vds
    *
    * @return boolean, true if all cleanup operations were successful
    *                  false otherwise
    *
    * @throws Exception
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      /*
       * Power off the vm and destroy it
       */
      assertTrue(ivm.setVMState(vmMor, VirtualMachinePowerState.POWERED_OFF, false),"Successfully powered off the vm","Failed to power " +
               		"off the vm");
      assertTrue(ivm.destroy(vmMor),"Successfully destroyed the vm",
               "Failed to destroy the vm");
      /*
       * Destroy the vds
       */
      assertTrue(vds.destroy(dvsMor),"Successfully destroyed the vds",
               "Failed to destroy the vds");
      return true;
   }
}
