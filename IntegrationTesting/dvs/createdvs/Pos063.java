/*
 * ************************************************************************
 *
 * Copyright 2008-2010 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.createdvs;

import static com.vmware.vc.HostSystemConnectionState.CONNECTED;
import static com.vmware.vc.VirtualMachineMovePriority.DEFAULT_PRIORITY;
import static com.vmware.vc.VirtualMachinePowerState.POWERED_OFF;
import static com.vmware.vc.VirtualMachinePowerState.POWERED_ON;
import static com.vmware.vcqa.util.Assert.assertNotEmpty;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.util.VersionConstants.ESX4x;
import static com.vmware.vcqa.vim.MessageConstants.TB_SETUP_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.TB_SETUP_PASS;

import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualDeviceConfigSpec;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.HostSystemInformation;
import com.vmware.vcqa.vim.host.VmotionSystem;

import dvs.CreateDVSTestBase;

/**
 * DESCRIPTION:<br>
 * VMotion a VM connected to the DVS from on host to another host.<br>
 * <br>
 * TARGET: VC, > ESX40<br>
 * <br>
 * SETUP:<br>
 * 1. Make sure that the VMotion is enabled on both the hosts.<br>
 * 2. Get a VM from source host and make sure that it has a NIC vard.<br>
 * 3. Create a DVS with 2 hosts in it.<br>
 * TEST:<br>
 * 4. Reconfigure the VM to connect to DVS<br>
 * 5. Power on the VM<br>
 * 6. VMotion the VM to destination host.<br>
 * CLEANUP:<br>
 * 7. VMotion the VM back to it original host<br>
 * 8. Power off the VM<br>
 * 9. Reconfigure the VM back to use its original network<br>
 * 10. Delete the DVS by calling the super class cleanup.<br>
 */
public class Pos063 extends CreateDVSTestBase
{
   private ManagedObjectReference srcHostMor;
   private ManagedObjectReference dstHostMor;
   private String srcHostName;
   private String dstHostName;
   private ManagedObjectReference vmMor;
   private VirtualMachineConfigSpec vmOriginalCfg;
   private final String dvsName = getTestId() + "-dvs";
   private String vmName;

   @Override
   public void setTestDescription()
   {
      super.setTestDescription("Create DVSwitch with the following parameters"
               + " while simulaneoulsy adding two hosts H1, "
               + "and H2. VMotion a VM on host H2 connected to"
               + " the DVS to H1");
   }

   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      Vector<ManagedObjectReference> vmMors = null;
      List<VirtualDeviceConfigSpec> ethCards = null;
      assertTrue(super.testSetUp(), TB_SETUP_PASS, TB_SETUP_FAIL);
      Map<ManagedObjectReference, HostSystemInformation> allHosts;
      allHosts = ihs.getAllHosts(ESX4x, CONNECTED);
      assertTrue(allHosts.size() >= 2, "Failed to get 2 or more hosts");
      Iterator<ManagedObjectReference> it = allHosts.keySet().iterator();
      srcHostMor = it.next();
      dstHostMor = it.next();
      srcHostName = ihs.getName(srcHostMor);
      dstHostName = ihs.getName(dstHostMor);
      final VmotionSystem ivms = new VmotionSystem(connectAnchor);
      final ManagedObjectReference srcVmotionSys = ivms.getVMotionSystem(srcHostMor);
      final ManagedObjectReference dstVmotionSys = ivms.getVMotionSystem(dstHostMor);
      log.info("Check whether VMotion is enabled on both the hosts.");
      assertTrue(ivms.checkVMotionNicSelected(srcVmotionSys),
               "Vmotion not enabled on src host: " + srcHostName);
      assertTrue(ivms.checkVMotionNicSelected(dstVmotionSys),
               "Vmotion not enabled on dst host: " + dstHostName);
      vmMors = ihs.getAllVirtualMachine(srcHostMor);
      assertNotEmpty(vmMors, "Failed to get a VM");
      vmMor = vmMors.get(0);
      vmName = ivm.getName(vmMor);
      log.info("Found the VM mor on the host");
      ethCards = DVSUtil.getAllVirtualEthernetCardDevices(vmMor, connectAnchor);
      assertNotEmpty(ethCards, "No NIC's found in the VM: " + vmName);
      log.info("Found valid ethernet adapter on the VM: " + vmName);
      assertTrue(ivm.setVMState(vmMor, POWERED_OFF, false), "VM not OFF.");
      networkFolderMor = iFolder.getNetworkFolder(dcMor);
      final Map<ManagedObjectReference, String> pNicMap = new HashMap<ManagedObjectReference, String>();
      pNicMap.put(srcHostMor, ins.getPNicIds(srcHostMor, false)[0]);
      pNicMap.put(dstHostMor, ins.getPNicIds(dstHostMor, false)[0]);
      configSpec = new DVSConfigSpec();
      configSpec.setConfigVersion("");
      configSpec.setName(dvsName);
      configSpec.setNumStandalonePorts(1);
      configSpec = DVSUtil.addHostsToDVSConfigSpecWithPnic(configSpec, pNicMap,
               null);
      dvsMOR = iFolder.createDistributedVirtualSwitch(networkFolderMor,
               configSpec);
      assertNotNull(dvsMOR, "Failed to create the DVS: " + configSpec.getName());
      log.info("Successfully created the DVSwitch: "
               + configSpec.getName());
      assertTrue(ins.refresh(ins.getNetworkSystem(srcHostMor)),
               "Refresh network failed for host: " + srcHostName);
      assertTrue(ins.refresh(ins.getNetworkSystem(dstHostMor)),
               "Refresh network failed for host: " + dstHostName);
      assertTrue(iDistributedVirtualSwitch.validateDVSConfigSpec(dvsMOR,
               configSpec, null), "Config spec mismatch");
      return true;
   }

   @Override
   @Test(description = "Create DVSwitch with the following parameters"
               + " while simulaneoulsy adding two hosts H1, "
               + "and H2. VMotion a VM on host H2 connected to"
               + " the DVS to H1")
   public void test()
      throws Exception
   {
      DistributedVirtualSwitchPortConnection portConnection = null;
      VirtualMachineConfigSpec[] vmCfg = null;
      portConnection = iDistributedVirtualSwitch.getPortConnection(dvsMOR,
               null, false, null);
      assertNotNull(portConnection, "Failed to get port connection");
      vmCfg = DVSUtil.getVMConfigSpecForDVSPort(vmMor, connectAnchor,
               new DistributedVirtualSwitchPortConnection[] { portConnection });
      assertNotEmpty(vmCfg, "VMCfg is null");
      assertTrue(vmCfg[0] != null && vmCfg[1] != null,
               "Original / Update Configs are null");
      vmOriginalCfg = vmCfg[1];
      assertTrue(ivm.reconfigVM(vmMor, vmCfg[0]), "Failed to connect VM to DVS");
      log.info("Successfully configured VM to connect to the DVS");
      assertTrue(ivm.setVMState(vmMor, POWERED_ON, false),
               "Failed to power on the VM: " + vmName);
      log.info("Successfully powered on the VM: " + vmName);
      assertTrue(ivm.migrateVM(vmMor, ihs.getResourcePool(dstHostMor).get(0), dstHostMor, DEFAULT_PRIORITY, POWERED_ON),
               "Failed to VMotion the VM to host: " + dstHostName);
      log.info("Migrated the VM " + vmName + " to host " + dstHostName);
   }

   @Override
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      if (srcHostMor != null && dstHostMor != null && vmMor != null) {
         try {
            if (ivm.getHostName(vmMor).equals(dstHostName)) {
               if (ivm.migrateVM(vmMor, ihs.getResourcePool(srcHostMor).get(0), srcHostMor, DEFAULT_PRIORITY, null)) {
                  log.info("Successfully migrated the VM back to its "
                           + "original host: " + srcHostName);
               } else {
                  status = false;
                  log.error("Can not migrate the VM back to its original "
                           + "host: " + vmName);
               }
            } else {
               log.info("VM was not migrated!");
            }
         } catch (Exception e) {
            TestUtil.handleException(e);
         }
         try {
            if (vmOriginalCfg != null
                     && ivm.setVMState(vmMor, POWERED_OFF, false)) {
               status &= ivm.reconfigVM(vmMor, vmOriginalCfg);
            }
         } catch (Exception e) {
            TestUtil.handleException(e);
         }
      }
      status &= super.testCleanUp();
      assertTrue(status, "Cleanup failed");
      return status;
   }
}