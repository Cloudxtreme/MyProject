/*
 * ************************************************************************
 *
 * Copyright 2008-2010 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfigureportgroups;

import static com.vmware.vc.VirtualMachinePowerState.POWERED_OFF;
import static com.vmware.vc.VirtualMachinePowerState.POWERED_ON;
import static com.vmware.vcqa.util.Assert.assertNotEmpty;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.NetworkSystem;

/**
 * DESCRIPTION:<br>
 * Reconfigure an early binding DVPortGroup by setting numPorts=1 and with valid
 * version, name and description; Reconfigure a VM to connect to this
 * DVPortGroup<br>
 * <br>
 * TARGET: VC <br>
 * <br>
 * SETUP:<br>
 * 1. Make sure that we have DC, host and a VM in powered off state.<br>
 * 2. Create a DVS by adding one host to it.<br>
 * 3. Add a early binding port group to the DVS<br>
 * TEST:<br>
 * 4. Reconfigure the PG to set numPorts=1 with valid name,desc & version<br>
 * 5. Reconfigure the VM to connect to this PG.<br>
 * 6. <br>
 * CLEANUP:<br>
 * 7. <br>
 * 8. <br>
 * 9. <br>
 */
public class Pos008 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference dvsMor = null;
   private DistributedVirtualSwitch iDVSwitch = null;
   private VirtualMachine ivm = null;
   private HostSystem ihs = null;
   private NetworkSystem ins = null;
   private ManagedObjectReference hostMor = null;
   private ManagedObjectReference vmMor = null;
   private ManagedObjectReference nsMor = null;
   private DVPortgroupConfigSpec dvPgCfg = null;
   private HostNetworkConfig[] hostNetworkCfg = null;
   private HostNetworkConfig originalNetworkConfig = null;
   private DistributedVirtualSwitchHostMemberConfigSpec hostConfigSpecElement = null;
   private List<ManagedObjectReference> dvPgMors = null;
   private DistributedVirtualSwitchPortConnection portConnection = null;
   private DistributedVirtualPortgroup iDVPortgroup = null;
   private String portgroupKey = null;
   private Map<String, List<String>> usedPorts = null;
   private VirtualMachineConfigSpec[] vmDeltaConfigSpec = null;
   private ManagedObjectReference dcMor = null;

   @Override
   public void setTestDescription()
   {
      setTestDescription("Reconfigure an early binding portgroup on an "
               + "existing distributed virtual switch and reconfigure"
               + " a VMvnic to connect to this portgroup");
   }

   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      final String dvsName = getTestId() + "-dvs";
      iFolder = new Folder(connectAnchor);
      iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
      iDVPortgroup = new DistributedVirtualPortgroup(connectAnchor);
      ivm = new VirtualMachine(connectAnchor);
      ihs = new HostSystem(connectAnchor);
      iManagedEntity = new ManagedEntity(connectAnchor);
      ins = new NetworkSystem(connectAnchor);
      dcMor = iFolder.getDataCenter();
      assertNotNull(dcMor, "Failed to get Datacenter");
      hostMor = ihs.getAllHost().get(0);
      assertNotNull(hostMor, "Failed to get a host");
      nsMor = ins.getNetworkSystem(hostMor);
      assertNotNull(nsMor, "Failed to get Host network system");
      List<ManagedObjectReference> allVMs = ihs.getVMs(hostMor, null);
      assertNotEmpty(allVMs, "Failed to VMs from the host");
      vmMor = allVMs.get(0);
      assertTrue(ivm.setVMState(vmMor, POWERED_OFF, false), "Faied VM POWEROFF");
      log.info("VM is in poweroff state");
      log.info("Creating DVS: " + dvsName);
      final Map<ManagedObjectReference, String> pNicMap;
      final String[] freePnics = ins.getPNicIds(hostMor, false);
      assertNotEmpty(freePnics, "No free pnics found on host");
      pNicMap = new HashMap<ManagedObjectReference, String>();
      pNicMap.put(hostMor, freePnics[0]);
      DVSConfigSpec dvsCfg = new DVSConfigSpec();
      dvsCfg.setConfigVersion("");
      dvsCfg.setName(dvsName);
      dvsCfg = DVSUtil.addHostsToDVSConfigSpecWithPnic(dvsCfg, pNicMap, null);
      dvsMor = iFolder.createDistributedVirtualSwitch(
               iFolder.getNetworkFolder(dcMor), dvsCfg);
      assertNotNull(dvsMor, "Failed to create DVS: " + dvsName);
      log.info("Successfully created the DVS: " + dvsName);
      dvPgCfg = new DVPortgroupConfigSpec();
      dvPgCfg.setConfigVersion("");
      dvPgCfg.setName(getTestId());
      dvPgCfg.setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
      dvPgMors = iDVSwitch.addPortGroups(dvsMor,
               new DVPortgroupConfigSpec[] { dvPgCfg });
      assertNotNull(dvPgMors, "Failed to add DVPortGroup.");
      log.info("Successfully added the " + "portgroup");
      return true;
   }

   @Override
   @Test(description = "Reconfigure an early binding portgroup on an "
               + "existing distributed virtual switch and reconfigure"
               + " a VMvnic to connect to this portgroup")
   public void test()
      throws Exception
   {
      String ipAddress = null;
      boolean checkGuest = DVSTestConstants.CHECK_GUEST;
      dvPgCfg = new DVPortgroupConfigSpec();
      dvPgCfg.setConfigVersion(iDVPortgroup.getConfigInfo(dvPgMors.get(0)).getConfigVersion());
      dvPgCfg.setName(getTestId() + "-earlypg");
      dvPgCfg.setDescription(DVSTestConstants.DVPORTGROUP_VALID_DESCRIPTION);
      dvPgCfg.setNumPorts(1);
      dvPgCfg.setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
      assertTrue(iDVPortgroup.reconfigure(dvPgMors.get(0), dvPgCfg),
               "Failed to reconfigure the PG");
      log.info("Successfully reconfigured the portgroup");
      portgroupKey = iDVPortgroup.getKey(dvPgMors.get(0));
      assertNotNull(portgroupKey, "Failed to get the DVPortGroup key");
      usedPorts = new HashMap<String, List<String>>();
      usedPorts.put(portgroupKey, null);
      portConnection = iDVSwitch.getPortConnection(dvsMor, null, false,
               usedPorts, new String[] { portgroupKey });
      vmDeltaConfigSpec = DVSUtil.getVMConfigSpecForDVSPort(vmMor,
               connectAnchor,
               new DistributedVirtualSwitchPortConnection[] { portConnection });
      assertNotNull(vmDeltaConfigSpec, "Failed to VM reconfig spec");
      assertTrue(ivm.reconfigVM(vmMor, vmDeltaConfigSpec[0]),
               "Failed to reconfigure the VM to connect to DVPG");
      log.info("Reconfigured VM to connect to a free port of portgroup");
      assertTrue(ivm.setVMState(vmMor, POWERED_ON, checkGuest),
               "Failed to poewer on the VM");
      if (checkGuest) {
         ipAddress = ivm.getIPAddress(vmMor);
         assertNotNull(ipAddress, "Failed to get IP of the VM");
         assertTrue(DVSUtil.checkNetworkConnectivity(ihs.getIPAddress(hostMor),
                  ipAddress), "Connectivity check failed");
      }
   }

   @Override
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      if (vmMor != null) {
         log.info("Power off the VM");
         status &= ivm.setVMState(vmMor, POWERED_OFF, false);
         log.info("Restore VM to it's original config");
         status &= ivm.reconfigVM(vmMor, vmDeltaConfigSpec[1]);
      }
      log.info("Restore the original network config on host");
      if (originalNetworkConfig != null) {
         status &= ins.updateNetworkConfig(nsMor, originalNetworkConfig,
                  TestConstants.CHANGEMODE_MODIFY);
      }
      if (dvsMor != null) {
         log.info("Destroy the DVS");
         status &= iManagedEntity.destroy(dvsMor);
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }
}