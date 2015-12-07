/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */

package dvs.vmops.createvm;

import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.MessageConstants.HOST_GET_MOR_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.HOST_GET_MOR_PASS;
import static com.vmware.vcqa.vim.MessageConstants.HOST_GET_RP_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.HOST_GET_RP_PASS;
import static com.vmware.vcqa.vim.MessageConstants.VM_CREATE_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.VM_CREATE_PASS;
import static com.vmware.vcqa.vim.MessageConstants.VM_DEL_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.VM_DEL_PASS;
import static com.vmware.vcqa.vim.MessageConstants.VM_POWEROFF_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.VM_POWEROFF_PASS;
import static com.vmware.vcqa.vim.MessageConstants.VM_POWERON_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.VM_POWERON_PASS;
import static com.vmware.vcqa.vim.MessageConstants.VM_SPC_CREATE_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.VM_SPC_CREATE_PASS;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualPortgroupPortgroupType;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualDeviceConfigSpec;
import com.vmware.vc.VirtualEthernetCard;
import com.vmware.vc.VirtualEthernetCardDistributedVirtualPortBackingInfo;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.NetworkSystem;

/**
 * Create a HW Version 8(or higher) VM with e1000e NIC with
 * DistributedVirtualPortBackingInfo
 */
public class Pos023 extends TestBase
{

   // Constant for this test
   public final String DV_PORTGROUP_TYPE = "earlyBinding";

   private VirtualMachine vm;
   private HostSystem hs;
   private ManagedObjectReference vmMor;
   private ManagedObjectReference poolMor;
   private ManagedObjectReference vmFolderMor;
   private VirtualMachineConfigSpec origVMConfigSpec;
   private String vmName;
   private ManagedObjectReference hostMor;
   private Folder folder;
   private ManagedObjectReference dvsMor;
   private String dvsName;
   private NetworkSystem networkSystem;
   private DistributedVirtualSwitch dvs;
   private DistributedVirtualSwitchPortConnection dvsPortConn;

   @Override
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      vm = new VirtualMachine(connectAnchor);
      hs = new HostSystem(connectAnchor);
      folder = new Folder(connectAnchor);
      networkSystem = new NetworkSystem(connectAnchor);
      dvs = new DistributedVirtualSwitch(connectAnchor);

      // Create VM ConfigSpec
      hostMor = hs.getConnectedHost(false);
      assertNotNull(hostMor, HOST_GET_MOR_PASS, HOST_GET_MOR_FAIL);
      vmFolderMor = vm.getVMFolder();
      Vector<ManagedObjectReference> poolList = hs.getResourcePool(hostMor);
      assertNotNull(poolList, HOST_GET_RP_PASS, HOST_GET_RP_FAIL);
      poolMor = (ManagedObjectReference) poolList.elementAt(0);
      vmName = getTestId();
      origVMConfigSpec = vm.createVMConfigSpec(poolMor, hostMor, vmName,
               TestConstants.VM_GUEST_WIN_7_32_BIT,
               TestUtil.arrayToVector(new String[] {
                        TestConstants.VM_CREATE_DEFAULT_DEVICE_TYPE,
                        TestConstants.VM_VIRTUALDEVICE_ETHERNET_E1000E }), null);
      assertNotNull(origVMConfigSpec, VM_SPC_CREATE_PASS, VM_SPC_CREATE_FAIL);

      // Get free PNICs
      String[] freePNicIds = networkSystem.getPNicIds(hostMor, false);
      assertNotNull(freePNicIds, "Unable to get free PNICs on host:"
               + hs.getHostName(hostMor));
      final Map<ManagedObjectReference, String> pNicMap = new HashMap<ManagedObjectReference, String>();
      pNicMap.put(hostMor, freePNicIds[0]);

      dvsName = getTestId() + "-DVS";
      ArrayList<ManagedObjectReference> hostMorList = new ArrayList<ManagedObjectReference>();
      hostMorList.add(hostMor);

      // Create default DVSConfigSpec
      DVSConfigSpec dvsConfigSpec = DVSUtil.createDefaultDVSConfigSpec(dvsName,
               hostMorList);

      // Add host with free pnic to dvs switch configspec
      dvsConfigSpec = DVSUtil.addHostsToDVSConfigSpecWithPnic(dvsConfigSpec,
               pNicMap, null);

      ManagedObjectReference networkFolderMor = folder.getNetworkFolder(folder.getDataCenter());

      // Create DVS Switch
      dvsMor = folder.createDistributedVirtualSwitch(networkFolderMor,
               dvsConfigSpec);
      assertNotNull(dvsMor, "Successfully created the DVSwitch: "
               + dvsConfigSpec.getName(), "Failed to create the DVS: "
               + dvsConfigSpec.getName());

      assertTrue(
               networkSystem.refresh(networkSystem.getNetworkSystem(hostMor)),
               "Refresh network failed for host: " + hs.getName(hostMor));

      DistributedVirtualPortgroupPortgroupType dvPgType = null;
      dvPgType = DistributedVirtualPortgroupPortgroupType.fromValue(DV_PORTGROUP_TYPE);

      String portGroupName = vmName + "-PG";
      String portGroupKey = dvs.addPortGroup(dvsMor, dvPgType.value(), 1,
               portGroupName);
      dvsPortConn = DVSUtil.buildDistributedVirtualSwitchPortConnection(
               dvs.getConfig(dvsMor).getUuid(), null, portGroupKey);

      return true;
   }

   @Override
   @Test(description = "Create a HW Version 8(or higher) VM with e1000e NIC with"
            + "DistributedVirtualPortBackingInfo")
   public void test()
      throws Exception
   {

      // Create VM with VirtualEthernetCardDistributedVirtualPortBackingInfo
      HashMap deviceSpecMap = this.vm.getVirtualDeviceSpec(
               this.origVMConfigSpec,
               TestConstants.VM_VIRTUALDEVICE_ETHERNET_E1000E);

      Iterator deviceSpecItr = deviceSpecMap.values().iterator();
      assertTrue(deviceSpecItr.hasNext(), "Unable to find device of type:"
               + TestConstants.VM_VIRTUALDEVICE_ETHERNET_E1000E);
      VirtualDeviceConfigSpec deviceSpec = (VirtualDeviceConfigSpec) deviceSpecItr.next();
      VirtualEthernetCard device = (VirtualEthernetCard) deviceSpec.getDevice();
      VirtualEthernetCardDistributedVirtualPortBackingInfo backingInfo = new VirtualEthernetCardDistributedVirtualPortBackingInfo();
      backingInfo.setPort(dvsPortConn);
      device.setBacking(backingInfo);

      vmMor = new Folder(super.getConnectAnchor()).createVM(vmFolderMor,
               origVMConfigSpec, poolMor, hostMor);
      assertNotNull(vmMor, VM_CREATE_PASS, VM_CREATE_FAIL);

      assertTrue(vm.powerOnVM(vmMor, null, false), VM_POWERON_PASS,
               VM_POWERON_FAIL);

      // Check whether NIC is connected
      int key = vm.getExistingDeviceKey(vmMor,
               TestConstants.VM_VIRTUALDEVICE_ETHERNET_E1000E);
      assertTrue(vm.isE1000EConnected(key, vmMor),
               TestConstants.VM_VIRTUALDEVICE_ETHERNET_E1000E
                        + " is connected to VM",
               TestConstants.VM_VIRTUALDEVICE_ETHERNET_E1000E
                        + " is not connected to VM");
   }

   @Override
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean cleanupDone = true;
      if (vmMor != null) {
         if (vm.setVMState(vmMor, VirtualMachinePowerState.POWERED_OFF, false)) {
            log.info(VM_POWEROFF_PASS);
            if (vm.destroy(vmMor)) {
               log.info(VM_DEL_PASS);
            } else {
               log.error(VM_DEL_FAIL);
               cleanupDone = false;
            }
         } else {
            log.error(VM_POWEROFF_FAIL);
            cleanupDone = false;
         }
      }

      if (dvsMor != null) {
         assertTrue(dvs.destroy(dvsMor), "Successfully destroyed dvs Switch:"
                  + dvsName, "Unable to destroy dvs Switch:" + dvsName);

      }
      return cleanupDone;
   }
}
