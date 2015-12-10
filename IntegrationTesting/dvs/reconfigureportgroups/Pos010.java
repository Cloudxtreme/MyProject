/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfigureportgroups;

import static com.vmware.vc.VirtualMachinePowerState.POWERED_OFF;
import static com.vmware.vcqa.TestConstants.CHANGEMODE_MODIFY;
import static com.vmware.vcqa.util.Assert.assertNotEmpty;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.MessageConstants.DC_MOR_GET_PASS;
import static com.vmware.vcqa.vim.MessageConstants.HOST_GET_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.HOST_GET_PASS;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_LATE_BINDING;

import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.DistributedVirtualSwitchPortCriteria;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.util.ThreadUtil;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.NetworkSystem;

/**
 * TODO update the description and proc. Reconfigure a late binding portgroup on
 * an existing distributed virtual switch with one port and reconfigure 2 VMs to
 * connect to the portgroup and power on both the VMs. Only one of the VMs
 * should have network connectivity
 */
public class Pos010 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference rootFolderMor = null;
   private ManagedObjectReference dvsMor = null;
   private DistributedVirtualSwitch iDVSwitch = null;
   private VirtualMachine ivm = null;
   private HostSystem iHostSystem = null;
   private NetworkSystem ins = null;
   private ManagedObjectReference hostMor = null;
   private ManagedObjectReference[] vmMors = null;
   private ManagedObjectReference nsMor = null;
   private DVPortgroupConfigSpec dvPGCfgSpec = null;
   private HostNetworkConfig[] hostNetCfg = null;
   private HostNetworkConfig originalNetworkConfig = null;
   private VirtualMachinePowerState[] vmPowerState = null;
   private List<ManagedObjectReference> dvPortGroupMors = null;
   private DistributedVirtualPortgroup iDVPortgroup = null;
   private String portGroupKey = null;
   private VirtualMachineConfigSpec[][] updatedDeltaCfgSpec = null;
   private int numEthernetCards = 0;
   private ManagedObjectReference dcMor = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Reconfigure a late binding portgroup to an existing"
               + " distributed virtual switch with one port and "
               + "reconfigure two VMs to connect to this portgroup "
               + "and power on both the VMs");
   }

   /**
    * Method to setup the environment for the test. This method creates a
    * distributed virtual switch.
    * 
    * @param connectAnchor ConnectAnchor object
    * @return boolean true if successful, false otherwise.
    */
   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      final String dvsName = getTestId() + "-vDS";
      iFolder = new Folder(connectAnchor);
      iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
      iDVPortgroup = new DistributedVirtualPortgroup(connectAnchor);
      ivm = new VirtualMachine(connectAnchor);
      iHostSystem = new HostSystem(connectAnchor);
      iManagedEntity = new ManagedEntity(connectAnchor);
      ins = new NetworkSystem(connectAnchor);
      dcMor = iFolder.getDataCenter();
      assertNotNull(dcMor, DC_MOR_GET_PASS, DC_MOR_GET_PASS);
      hostMor = iHostSystem.getConnectedHost(false);
      assertNotNull(hostMor, HOST_GET_PASS, HOST_GET_FAIL);
      rootFolderMor = iFolder.getRootFolder();
      log.info("Creating vDS... " + dvsName);
      dvsMor = iFolder.createDistributedVirtualSwitch(dvsName, hostMor);
      assertNotNull(dvsMor, "Failed to create vDS");
      log.info("Successfully created vDS: " + dvsName);
      hostNetCfg = iDVSwitch.getHostNetworkConfigMigrateToDVS(dvsMor, hostMor);
      originalNetworkConfig = hostNetCfg[1];
      nsMor = ins.getNetworkSystem(hostMor);
      assertNotNull(nsMor, "Failed to get NetworkSystem of host.");
      ins.refresh(nsMor);
      ThreadUtil.sleep(10000);
      assertTrue(ins.updateNetworkConfig(nsMor, hostNetCfg[0],
               CHANGEMODE_MODIFY), "Successfully updated host network config.");
      List<ManagedObjectReference> allVMs = iHostSystem.getVMs(hostMor, null);
      assertNotEmpty(allVMs, "Failed to get the VMs");
      assertTrue(allVMs.size() >= 2, "Failed to get required number of VMs");
      vmMors = new ManagedObjectReference[] { allVMs.get(0), allVMs.get(1) };
      numEthernetCards = DVSUtil.getAllVirtualEthernetCardDevices(vmMors[0],
               connectAnchor).size();
      vmPowerState = new VirtualMachinePowerState[vmMors.length];
      vmPowerState[0] = ivm.getVMState(vmMors[0]);
      assertTrue(ivm.setVMState(vmMors[0], POWERED_OFF, false),
               "Failed to power off the first VM");
      log.info("Successfully powered off the first VM");
      vmPowerState[1] = ivm.getVMState(vmMors[1]);
      assertTrue(ivm.setVMState(vmMors[1], POWERED_OFF, false),
               "Failed to power off the second VM");
      dvPGCfgSpec = new DVPortgroupConfigSpec();
      dvPGCfgSpec.setConfigVersion("");
      dvPGCfgSpec.setName(getTestId());
      dvPGCfgSpec.setType(DVPORTGROUP_TYPE_LATE_BINDING);
      DVPortgroupConfigSpec[] dvPGCfgSpecs = new DVPortgroupConfigSpec[] { dvPGCfgSpec };
      dvPortGroupMors = iDVSwitch.addPortGroups(dvsMor, dvPGCfgSpecs);
      assertNotEmpty(dvPortGroupMors, "Failed to add DVPortGroups.");
      log.info("Successfully added the DVPortGroups");
      return true;
   }

   /**
    * Method that reconfigures a late binding portgroup with one port to the
    * distributed virtual switch and 2 VMs are reconfigured to connect to the
    * created portgroup
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @Test(description = "Reconfigure a late binding portgroup to an existing"
               + " distributed virtual switch with one port and "
               + "reconfigure two VMs to connect to this portgroup "
               + "and power on both the VMs")
   public void test()
      throws Exception
   {
      int maxNumEthernetCards = 0;
      int numEthernetCardsOnSecondVM = 0;
      DistributedVirtualSwitchPortConnection[] dvsPortConn = null;
      DistributedVirtualSwitchPortCriteria portCriteria = null;
      List<String> portKeys = null;
      dvPGCfgSpec = new DVPortgroupConfigSpec();
      dvPGCfgSpec.setConfigVersion(iDVPortgroup.getConfigInfo(
               dvPortGroupMors.get(0)).getConfigVersion());
      dvPGCfgSpec.setType(DVPORTGROUP_TYPE_LATE_BINDING);
      dvPGCfgSpec.setName(getTestId());
      numEthernetCardsOnSecondVM = DVSUtil.getAllVirtualEthernetCardDevices(
               vmMors[1], connectAnchor).size();
      maxNumEthernetCards = numEthernetCards > numEthernetCardsOnSecondVM ? numEthernetCards
               : numEthernetCardsOnSecondVM;
      dvPGCfgSpec.setNumPorts(maxNumEthernetCards);
      assertTrue(iDVPortgroup.reconfigure(dvPortGroupMors.get(0), dvPGCfgSpec),
               "Failed to reconfigure the DVPortGroup");
      log.info("Successfully reconfigured the DVPortGroup");
      portGroupKey = iDVPortgroup.getKey(dvPortGroupMors.get(0));
      assertNotNull(portGroupKey, "Failed to get DVPortGroup key");
      portCriteria = new DistributedVirtualSwitchPortCriteria();
      portCriteria.setConnected(false);
      portCriteria.setInside(true);
      portCriteria.getPortgroupKey().clear();
      portCriteria.getPortgroupKey().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new String[] { portGroupKey }));
      portKeys = iDVSwitch.fetchPortKeys(dvsMor, portCriteria);
      assertNotEmpty(portKeys, "Failed to get DVPort keys.");
      dvsPortConn = new DistributedVirtualSwitchPortConnection[maxNumEthernetCards];
      for (int i = 0; i < portKeys.size(); i++) {
         dvsPortConn[i] = new DistributedVirtualSwitchPortConnection();
         dvsPortConn[i].setPortgroupKey(portGroupKey);
         dvsPortConn[i].setSwitchUuid(iDVSwitch.getConfig(dvsMor).getUuid());
      }
      updatedDeltaCfgSpec = new VirtualMachineConfigSpec[2][2];
      updatedDeltaCfgSpec[0] = DVSUtil.getVMConfigSpecForDVSPort(vmMors[0],
               connectAnchor, dvsPortConn);
      assertTrue(ivm.reconfigVM(vmMors[0], updatedDeltaCfgSpec[0][0]),
               "Failed to reconfigure the first VM to conect to DVPortGroup");
      log.info("Reconfigured the first VM to connect to DVPortGroup");
      // assertTrue(ivm.setVMState(vmMors[0], poweredOn, true),
      // "Failed to power on the first VM.");
      log.info("Successfully powered on first VM");
      updatedDeltaCfgSpec[1] = DVSUtil.getVMConfigSpecForDVSPort(vmMors[1],
               connectAnchor, dvsPortConn);
      assertTrue(ivm.reconfigVM(vmMors[1], updatedDeltaCfgSpec[1][0]),
               "Failed to reconfigure second VM to conect to DVPortGroup.");
      log.info("Reconfigured second VM to connect to DVPortGroup");
      //
      assertTrue(ivm.powerOnVMs(TestUtil.arrayToVector(vmMors), true),
               "Failed to power on the VM's");
      //
      // assertTrue(ivm.setVMState(vmMors[1], poweredOn, true),
      // "Failed to power on the second VM.");
      log.info("Both the VM's are successfully powered on.");
      final String vmOneIp = ivm.getIPAddress(vmMors[0]);
      final String vmTwoIp = ivm.getIPAddress(vmMors[1]);
      assertTrue((vmOneIp == null || vmTwoIp == null),
               "One of the IP's should have been null");
      final String validIp = (vmOneIp != null) ? vmOneIp : vmTwoIp;
      assertNotNull(validIp, "Failed to get IP for one of the VM's");
      log.info("Got the valid IP " + validIp);
      final String hostIp = iHostSystem.getIPAddress(hostMor);
      assertTrue(DVSUtil.checkNetworkConnectivity(hostIp, validIp),
               "Network not accessible for IP" + validIp);
      // vmOneStatus = DVSUtil.checkNetworkConnectivity(hostIp, validIp);
      // vmTwoStatus = DVSUtil.checkNetworkConnectivity(hostIp, vmTwoIp);
      // log.info("VM2 Connected to network: " + vmTwoStatus);
      // assertTrue(vmOneStatus ^ vmTwoStatus,
      // "Both the VM's should't have been connected to netowrk.");
   }

   /**
    * Method to restore the state as it was before the test was started. Restore
    * the original state of the VM.Destroy the portgroup, followed by the
    * distributed virtual switch
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      try {
         /*
          * Power off both the VMs
          */
         for (int i = 0; i < vmMors.length; i++) {
            status &= ivm.setVMState(vmMors[i], VirtualMachinePowerState.POWERED_OFF, false);
         }
         /*
          * Reconfigure both the VMs to their original configuration and restore
          * the original power states of the respective VMs
          */
         for (int i = 0; i < vmMors.length; i++) {
            status &= ivm.setVMState(vmMors[i], vmPowerState[i], false);
            status &= ivm.reconfigVM(vmMors[i], updatedDeltaCfgSpec[i][1]);
         }
         /*
          * Restore the original network config
          */
         if (originalNetworkConfig != null) {
            status &= ins.updateNetworkConfig(nsMor, originalNetworkConfig,
                     TestConstants.CHANGEMODE_MODIFY);
         }
         /*
          * if(this.dvPortgroupMorList != null){ for(ManagedObjectReference mor:
          * dvPortgroupMorList){ status &= this.iManagedEntity.destroy(mor); } }
          */
      } catch (Exception e) {
         TestUtil.handleException(e);
         status = false;
      } finally {
         try {
            if (dvsMor != null) {
               status &= iManagedEntity.destroy(dvsMor);
            }
         } catch (Exception ex) {
            TestUtil.handleException(ex);
            status = false;
         }
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
