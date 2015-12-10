/*
 * ************************************************************************
 *
 * Copyright 2009 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.functional;

import static com.vmware.vcqa.TestConstants.VM_DEFAULT_GUEST_WINDOWS;
import static com.vmware.vcqa.TestConstants.VM_VIRTUALDEVICE_SCSI_BUSL_CONTROLLER;
import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DVSTrafficShapingPolicy;
import com.vmware.vc.DistributedVirtualPort;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.DistributedVirtualSwitchPortCriteria;
import com.vmware.vc.HostSystemConnectionState;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VMwareDVSPortgroupPolicy;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.util.VersionConstants;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.NetworkSystem;

/**
 * 1. Create a DVS with 1 static, 1 dynamic, 1 ephemeral PGs with one port 2.
 * Add 2 hosts to it 3. Create a VM on host1 4. Create 3 virtual-adapters on VM
 * 5. Reconfigure VM to move vm-vmic1 to static, vm-vnic2 to dynamic and
 * vm-vnic3 to ephemeral PG 6. Power on VM, check VMs have networking, if Yes,
 * power off VM, if No, flag error 7. Reconfigure VM (pass the SAME spec as
 * current config, i.e. vm-vnic1 to static, vm-vnic2 to dynamic and vm-vnic3 to
 * ephemeral PG). 8. Reconfigure all 3 Portgroups 9. Power on VM, check VMs have
 * networking, if Yes, power off VM, if No, flag error
 */
public class Pos042 extends TestBase
{
   /*
    * private data variables
    */
   private HostSystem ihs = null;
   private Map allHosts = null;
   private ManagedObjectReference[] hostMors = null;
   private NetworkSystem iNetworkSystem = null;
   private ManagedObjectReference vmMor = null;
   private VirtualMachine ivm = null;
   private String vmName = null;
   private VirtualMachinePowerState originalVMState = null;
   private String dvSwitchUuid = null;
   private Folder iFolder = null;
   private NetworkSystem ins = null;
   private ManagedObjectReference dcMor = null;
   private ManagedObjectReference dvsMOR = null;
   private DVSConfigSpec configSpec = null;
   private ManagedObjectReference networkFolderMor = null;
   private DistributedVirtualSwitch iDistributedVirtualSwitch = null;
   private DistributedVirtualPortgroup idvpg = null;
   private boolean isVMCreated = false;
   private ManagedObjectReference nsMor = null;
   private Map<String, DVPortgroupConfigSpec> hmPgConfig = new HashMap<String, DVPortgroupConfigSpec>();
   private String early = null;
   private String late = null;
   private String ephemeral = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      super.setTestDescription("1. Create a DVS with 1 static, 1 dynamic, 1 ephemeral PGs with one port \n"
               + " 2. Add 2 hosts to it \n"
               + " 3. Create a VM on host1 \n"
               + " 4. Create 3 virtual-adapters on VM \n"
               + " 5. Reconfigure VM to move vm-vmic1 to static, vm-vnic2 to dynamic and vm-vnic3 to ephemeral PG \n"
               + " 6. Power on VMs\n"
               + " 7. Reconfigure VM (pass the SAME spec as current config, i.e. vm-vnic1 to static, vm-vnic2 to dynamiv and vm-vnic3 to ephemeral PG). \n"
               + " 8. Reconfigure all 3 Portgroups  \n" + " 9. Power on VM, \n");
   }

   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      Iterator it = null;
      VirtualMachineConfigSpec vmConfigSpec = null;
      String[] pnicIds = null;
      this.hostMors = new ManagedObjectReference[2];
      DistributedVirtualSwitchHostMemberPnicSpec hostPnicSpec = null;
      DistributedVirtualSwitchHostMemberPnicBacking hostPnicBacking = null;
      DistributedVirtualSwitchHostMemberConfigSpec[] hostConfigSpecElement = new DistributedVirtualSwitchHostMemberConfigSpec[2];
      String dvsName = this.getTestId();
      log.info("Test setup Begin:");
     
         this.iFolder = new Folder(connectAnchor);
         this.iDistributedVirtualSwitch = new DistributedVirtualSwitch(
                  connectAnchor);
         this.ihs = new HostSystem(connectAnchor);
         this.ivm = new VirtualMachine(connectAnchor);
         this.ins = new NetworkSystem(connectAnchor);
         this.idvpg = new DistributedVirtualPortgroup(connectAnchor);
         this.dcMor = (ManagedObjectReference) this.iFolder.getDataCenter();

         this.ihs = new HostSystem(connectAnchor);
         this.ivm = new VirtualMachine(connectAnchor);
         this.iNetworkSystem = new NetworkSystem(connectAnchor);
         allHosts = this.ihs.getAllHosts(VersionConstants.ESX4x, HostSystemConnectionState.CONNECTED);
         if ((allHosts != null) && (allHosts.size() >= 2)) {
            it = allHosts.keySet().iterator();
            this.hostMors[0] = (ManagedObjectReference) it.next();
            this.hostMors[1] = (ManagedObjectReference) it.next();
            /*
             * create vm here
             */
            log.info("Found a host with free pnics in the inventory");
            this.nsMor = this.ins.getNetworkSystem(this.hostMors[0]);
            if (this.nsMor != null) {
               pnicIds = this.ins.getPNicIds(this.hostMors[0]);
               if (pnicIds != null) {
                  vmName = this.getTestId() + "-vm";
                  vmConfigSpec = buildDefaultSpec(connectAnchor,
                           this.hostMors[0],
                           TestConstants.VM_VIRTUALDEVICE_ETHERNET_PCNET32,
                           vmName, 2);
                  this.vmMor = new Folder(super.getConnectAnchor()).createVM(
                           this.ivm.getVMFolder(), vmConfigSpec,
                           this.ihs.getPoolMor(this.hostMors[0]),
                           this.hostMors[0]);
                  if (this.vmMor != null) {
                     this.isVMCreated = true;
                     log.info("Successfully created the VM " + vmName);
                  } else {
                     log.error("Can not create the VM " + vmName);
                  }
                  if (this.vmMor != null) {
                     this.originalVMState = this.ivm.getVMState(this.vmMor);
                     status = this.ivm.setVMState(this.vmMor, VirtualMachinePowerState.POWERED_OFF, false);
                  }
               } else {
                  log.error("There are no free pnics on the host");
               }
            } else {
               log.error("The network system MOR is null");
            }

         } else {
            log.error("Valid Host MOR not found");
            status = false;
         }
         if (status) {
            this.networkFolderMor = this.iFolder.getNetworkFolder(this.dcMor);
            if (this.networkFolderMor != null) {
               this.configSpec = new DVSConfigSpec();
               this.configSpec.setConfigVersion("");
               this.configSpec.setName(dvsName);
               this.configSpec.setNumStandalonePorts(1);
               String[] hostPhysicalNics = null;
               for (int i = 0; i < 2; i++) {
                  hostPhysicalNics = this.iNetworkSystem.getPNicIds(this.hostMors[i]);
                  if (hostPhysicalNics != null) {
                     hostConfigSpecElement[i] = new DistributedVirtualSwitchHostMemberConfigSpec();
                     hostPnicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();
                     hostPnicSpec.setPnicDevice(hostPhysicalNics[0]);
                     hostPnicSpec.setUplinkPortKey(null);
                     hostPnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
                     hostPnicBacking.getPnicSpec().clear();
                     hostPnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] { hostPnicSpec }));
                     hostConfigSpecElement[i].setBacking(hostPnicBacking);
                     hostConfigSpecElement[i].setHost(this.hostMors[i]);
                     hostConfigSpecElement[i].setOperation(TestConstants.CONFIG_SPEC_ADD);
                     if (i == 1) {
                        hostConfigSpecElement[i].setMaxProxySwitchPorts(DVSTestConstants.DVS_DEFAULT_NUM_UPLINK_PORTS + 2);
                     }
                  } else {
                     status = false;
                     log.error("No free pnics found on the host.");
                  }
               }
               this.configSpec.getHost().clear();
               this.configSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(hostConfigSpecElement));
            } else {
               status = false;
               log.error("Failed to create the network folder");
            }
         }

     

      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that creates the DVS.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "1. Create a DVS with 1 static, 1 dynamic, 1 ephemeral PGs with one port \n"
               + " 2. Add 2 hosts to it \n"
               + " 3. Create a VM on host1 \n"
               + " 4. Create 3 virtual-adapters on VM \n"
               + " 5. Reconfigure VM to move vm-vmic1 to static, vm-vnic2 to dynamic and vm-vnic3 to ephemeral PG \n"
               + " 6. Power on VMs\n"
               + " 7. Reconfigure VM (pass the SAME spec as current config, i.e. vm-vnic1 to static, vm-vnic2 to dynamiv and vm-vnic3 to ephemeral PG). \n"
               + " 8. Reconfigure all 3 Portgroups  \n" + " 9. Power on VM, \n")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      DistributedVirtualSwitchPortConnection portConnection = null;
      Vector<DistributedVirtualSwitchPortConnection> pcs = new Vector<DistributedVirtualSwitchPortConnection>();
     
         if (this.configSpec != null) {
            this.dvsMOR = this.iFolder.createDistributedVirtualSwitch(
                     this.networkFolderMor, this.configSpec);
            if (this.dvsMOR != null) {
               log.info("Successfully created the DVSwitch");
               if (this.iNetworkSystem.refresh(this.iNetworkSystem.getNetworkSystem(this.hostMors[0]))
                        && this.iNetworkSystem.refresh(this.iNetworkSystem.getNetworkSystem(this.hostMors[1]))) {
                  if (this.iDistributedVirtualSwitch.validateDVSConfigSpec(
                           this.dvsMOR, this.configSpec, null)) {
                     /*
                      * add pgs here
                      */
                     ManagedObjectReference epg = addPG(this.dvsMOR,
                              DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);

                     if (epg != null) {
                        early = this.idvpg.getKey(epg);
                        if (early != null) {
                           portConnection = this.iDistributedVirtualSwitch.getPortConnection(
                                    this.dvsMOR, null, false, null, early);
                           pcs.add(portConnection);
                        }
                     }

                     ManagedObjectReference lpg = addPG(this.dvsMOR,
                              DVSTestConstants.DVPORTGROUP_TYPE_LATE_BINDING);
                     if (lpg != null) {
                        late = this.idvpg.getKey(lpg);
                        if (late != null) {
                           portConnection = this.iDistributedVirtualSwitch.getPortConnection(
                                    this.dvsMOR, null, false, null, late);
                           pcs.add(portConnection);
                        }
                     }
                     ManagedObjectReference ephepg = addPG(this.dvsMOR,
                              DVSTestConstants.DVPORTGROUP_TYPE_EPHEMERAL);
                     if (ephepg != null) {
                        ephemeral = this.idvpg.getKey(ephepg);
                        if (ephemeral != null) {
                           DVSConfigInfo info = iDistributedVirtualSwitch.getConfig(dvsMOR);
                           dvSwitchUuid = info.getUuid();

                           portConnection = new DistributedVirtualSwitchPortConnection();
                           portConnection.setSwitchUuid(dvSwitchUuid);
                           portConnection.setPortgroupKey(ephemeral);

                           pcs.add(portConnection);
                        }
                     }

                     if (reconfigVM(TestUtil.vectorToArray(pcs), connectAnchor) != null) {
                        if (this.ivm.verifyPowerOps(this.vmMor, false)) {
                           log.info("Successfully verified the power "
                                    + "ops of the VM");
                           if (reconfigurePG(
                                    epg,
                                    DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING)
                                    && reconfigurePG(
                                             lpg,
                                             DVSTestConstants.DVPORTGROUP_TYPE_LATE_BINDING)
                                    && reconfigurePG(
                                             ephepg,
                                             DVSTestConstants.DVPORTGROUP_TYPE_EPHEMERAL)) {
                              status = checkPowerOps();
                           }

                        } else {
                           status = false;
                           log.error("Can not verify the power ops for "
                                    + "the VM");
                        }
                     } else {
                        log.error("Can not reconfigure the VM to "
                                 + "connect to the late binding porgroup");
                        status = false;
                     }
                  } else {
                     log.info("The config spec of the Distributed Virtual "
                              + "Switch is not created as per specifications");
                  }
               }
            } else {
               log.error("Cannot create the distributed "
                        + "virtual switch with the config spec passed");
            }
         }
     
      assertTrue(status, "Test Failed");
   }

   private boolean checkPowerOps()
      throws Exception
   {

      boolean status = false;
      boolean poweredOn = this.ivm.powerOnVM(vmMor, null, false);
      if (poweredOn) {
         status = true;
         DistributedVirtualSwitchPortCriteria portCriteria = null;
         portCriteria = this.iDistributedVirtualSwitch.getPortCriteria(true,
                  null, null, new String[] { early, late, ephemeral }, null,
                  true);

         List<DistributedVirtualPort> ports = null;
         assertTrue(iDistributedVirtualSwitch.refreshPortState(this.dvsMOR,
                  null), "Filed to refreshPortState");
         ports = iDistributedVirtualSwitch.fetchPorts(this.dvsMOR, portCriteria);

         for (DistributedVirtualPort mor : ports) {
            String key = mor.getKey();
            assertTrue(mor.getConnectee() != null
                     && mor.getConnectee().getConnectedEntity() != null
                     && mor.getConnectee().getConnectedEntity().equals(vmMor)
                     && mor.getState() != null
                     && mor.getState().getRuntimeInfo() != null
                     && mor.getState().getRuntimeInfo().isLinkUp(),
                     "link is up for portkey  :" + key,
                     "link is down portkey  :" + key);

         }

         boolean powerOff = this.ivm.powerOffVM(vmMor);

         if (powerOff) {
            log.info("PowerOff successful for VM");
            status &= true;
         } else {
            log.error("Unable to power off vm");
         }

      }
      return status;
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
      boolean status = true;
     
         if (this.vmMor != null) {
            if (this.ivm.setVMState(this.vmMor, VirtualMachinePowerState.POWERED_OFF, false)) {
               if (this.isVMCreated) {
                  log.info("Destroying the created VM");
                  status &= this.ivm.destroy(this.vmMor);
               } else if (this.originalVMState != null) {
                  log.info("Restoring the VM to its original power state.");
                  status &= this.ivm.setVMState(this.vmMor,
                           this.originalVMState, false);
               }
            } else {
               log.error("Can not power off the VM");
               status &= false;
            }
         }

         if (this.dvsMOR != null) {
            status &= this.iDistributedVirtualSwitch.destroy(this.dvsMOR);
         }

     
      assertTrue(status, "Cleanup failed");
      return status;
   }

   private VirtualMachineConfigSpec reconfigVM(DistributedVirtualSwitchPortConnection portConnection[],
                                               ConnectAnchor connectAnchor)
      throws Exception
   {
      VirtualMachineConfigSpec[] vmConfigSpec = null;
      VirtualMachineConfigSpec originalVMConfigSpec = null;
      vmConfigSpec = DVSUtil.getVMConfigSpecForDVSPort(this.vmMor,
               connectAnchor, portConnection);
      if (vmConfigSpec != null && vmConfigSpec.length == 2
               && vmConfigSpec[0] != null && vmConfigSpec[1] != null) {
         log.info("Successfully obtained the original and the updated virtual"
                  + " machine config spec");
         originalVMConfigSpec = vmConfigSpec[1];
         if (this.ivm.reconfigVM(this.vmMor, vmConfigSpec[0])) {
            log.info("Successfully reconfigured the virtual machine to use "
                     + "the DV port");
            originalVMConfigSpec = vmConfigSpec[1];
         } else {
            log.error("Can not reconfigure the virtual machine to use the "
                     + "DV port");
         }
      }
      return originalVMConfigSpec;
   }

   /**
    * Create a default VMConfigSpec.
    * 
    * @param connectAnchor ConnectAnchor
    * @param hostMor The MOR of the host where the defaultVMSpec has to be
    *           created.
    * @param deviceType type of the device.
    * @param vmName String
    * @return vmConfigSpec VirtualMachineConfigSpec.
    * @throws MethodFault, Exception
    */
   public static VirtualMachineConfigSpec buildDefaultSpec(ConnectAnchor connectAnchor,
                                                           ManagedObjectReference hostMor,
                                                           String deviceType,
                                                           String vmName,
                                                           int noOfCards)
      throws Exception
   {
      ManagedObjectReference poolMor = null;
      VirtualMachineConfigSpec vmConfigSpec = null;
      HostSystem ihs = new HostSystem(connectAnchor);
      VirtualMachine ivm = new VirtualMachine(connectAnchor);
      Vector<String> deviceTypesVector = new Vector<String>();
      poolMor = ihs.getPoolMor(hostMor);
      if (poolMor != null) {

         deviceTypesVector.add(TestConstants.VM_VIRTUALDEVICE_DISK);
         deviceTypesVector.add(VM_VIRTUALDEVICE_SCSI_BUSL_CONTROLLER);
         for (int i = 0; i < noOfCards; i++) {
            deviceTypesVector.add(TestConstants.VM_VIRTUALDEVICE_ETHERNET_PCNET32);
         }
         deviceTypesVector.add(deviceType);
         // create the VMCfg with the default devices.
         vmConfigSpec = ivm.createVMConfigSpec(poolMor, vmName,
                  VM_DEFAULT_GUEST_WINDOWS, deviceTypesVector, null);
      } else {
         log.error("Unable to get the resource pool from the host.");
      }
      return vmConfigSpec;
   }

   /*
    * add pg here 
    */
   private ManagedObjectReference addPG(ManagedObjectReference dvsMor,
                                        String type)
      throws Exception
   {
      ManagedObjectReference pgMor = null;
      DVPortgroupConfigSpec pgConfigSpec = new DVPortgroupConfigSpec();
      pgConfigSpec.setName(type);
      pgConfigSpec.setType(type);
      if (!type.equalsIgnoreCase(DVSTestConstants.DVPORTGROUP_TYPE_EPHEMERAL))
         pgConfigSpec.setNumPorts(1);
      List<ManagedObjectReference> pgList = this.iDistributedVirtualSwitch.addPortGroups(
               dvsMor, new DVPortgroupConfigSpec[] { pgConfigSpec });
      if (pgList != null && pgList.size() == 1) {

         log.info("Successfully added the  " + "portgroup to the DVS "
                  + type);
         pgMor = pgList.get(0);
         hmPgConfig.put(type, pgConfigSpec);
      }
      return pgMor;
   }

   private boolean reconfigurePG(ManagedObjectReference dvPG,
                                 String type)
      throws Exception
   {
      boolean result = false;
      DVSTrafficShapingPolicy outShapingPolicy = null;
      VMwareDVSPortgroupPolicy portgroupPolicy = null;
      Map<String, Object> settingsMap = null;
      DVSTrafficShapingPolicy inShapingPolicy = null;
      VMwareDVSPortSetting portSetting = null;

      settingsMap = new HashMap<String, Object>();

      this.hmPgConfig.get(type).getScope().clear();
      this.hmPgConfig.get(type).getScope().addAll(
               com.vmware.vcqa.util.TestUtil.arrayToVector(new ManagedObjectReference[] { this.dcMor }));

      this.hmPgConfig.get(type).setPortNameFormat(
               DVSTestConstants.DVPORTGROUP_PORTNAMEFORMAT_PORTINDEX);

      inShapingPolicy = new DVSTrafficShapingPolicy();
      inShapingPolicy.setInherited(false);
      inShapingPolicy.setEnabled(DVSUtil.getBoolPolicy(false, true));
      inShapingPolicy.setAverageBandwidth(DVSUtil.getLongPolicy(false,
               new Long(10)));
      inShapingPolicy.setBurstSize(DVSUtil.getLongPolicy(false, new Long(50)));
      inShapingPolicy.setPeakBandwidth(DVSUtil.getLongPolicy(false, new Long(
               100)));
      settingsMap.put(DVSTestConstants.INSHAPING_POLICY_KEY, inShapingPolicy);

      outShapingPolicy = new DVSTrafficShapingPolicy();
      outShapingPolicy.setInherited(false);
      outShapingPolicy.setEnabled(DVSUtil.getBoolPolicy(false, true));
      outShapingPolicy.setAverageBandwidth(DVSUtil.getLongPolicy(false,
               new Long(10)));
      outShapingPolicy.setBurstSize(DVSUtil.getLongPolicy(false, new Long(50)));
      outShapingPolicy.setPeakBandwidth(DVSUtil.getLongPolicy(false, new Long(
               100)));
      settingsMap.put(DVSTestConstants.OUT_SHAPING_POLICY_KEY, outShapingPolicy);

      portSetting = DVSUtil.getDefaultVMwareDVSPortSetting(settingsMap);

      portgroupPolicy = new VMwareDVSPortgroupPolicy();
      portgroupPolicy.setBlockOverrideAllowed(false);
      portgroupPolicy.setShapingOverrideAllowed(false);
      portgroupPolicy.setVendorConfigOverrideAllowed(true);
      portgroupPolicy.setLivePortMovingAllowed(true);
      portgroupPolicy.setPortConfigResetAtDisconnect(true);
      portgroupPolicy.setVlanOverrideAllowed(true);
      portgroupPolicy.setUplinkTeamingOverrideAllowed(true);
      portgroupPolicy.setSecurityPolicyOverrideAllowed(false);

      this.hmPgConfig.get(type).setPolicy(portgroupPolicy);

      this.hmPgConfig.get(type).setDefaultPortConfig(portSetting);

      this.hmPgConfig.get(type).setConfigVersion(
               this.idvpg.getConfigInfo(dvPG).getConfigVersion());

      if (this.idvpg.reconfigure(dvPG, this.hmPgConfig.get(type))) {
         log.info("Successfully reconfigured the portgroup for " + type);
         result = true;
      } else {
         if (type.equalsIgnoreCase(DVSTestConstants.DVPORTGROUP_TYPE_EPHEMERAL)) {
            log.info("Successfully reconfigured the portgroup for "
                     + type);
            result = true;
         } else {
            result = false;
            log.error("Failed to reconfigure the portgroup for " + type);
         }

      }
      return result;
   }

}
