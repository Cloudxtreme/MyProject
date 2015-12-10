/*
 * ************************************************************************
 *
 * Copyright 2009-2010 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.functional;

import static com.vmware.vcqa.TestConstants.*;
import static com.vmware.vcqa.util.Assert.*;
import static com.vmware.vcqa.util.VersionConstants.*;
import static com.vmware.vcqa.vim.MessageConstants.*;

import java.util.ArrayList;
import java.util.Arrays;
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
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.HostPortGroupSpec;
import com.vmware.vc.HostSystemConnectionState;
import com.vmware.vc.HostVirtualNicConfig;
import com.vmware.vc.HostVirtualNicSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.UserSession;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.SessionManager;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.host.HostSystemInformation;
import com.vmware.vcqa.vim.host.NetworkSystem;

/**
 * PR# 395300 : test case 5<br>
 * 1. Create a DVS with 1 static, 1 dynamic, 1 ephemeral PGs (say 2 ports each)<br>
 * 2. Add 2 hosts to it<br>
 * 3. Create 3 console vnics and move one each to static, dynamic and ephemeral
 * PG<br>
 * 4. Reconfigure host-vmknic and host-vswifnic to same PG again<br>
 * 5. Create one console vnic via hostd and connect it to ephemeral PG<br>
 */
public class Pos044 extends TestBase
{
   private SessionManager sessionManager = null;
   private HostSystem ihs = null;
   private ManagedObjectReference hostMor = null;
   private String dvSwitchUuid = null;
   private Folder iFolder = null;
   private NetworkSystem ins = null;
   private ManagedObjectReference dcMor = null;
   private ManagedObjectReference dvsMor = null;
   private DVSConfigSpec dvsCfg = null;
   private ManagedObjectReference networkFolderMor = null;
   private DistributedVirtualSwitch idvs = null;
   private DistributedVirtualPortgroup idvpg = null;
   private ManagedObjectReference nsMor = null;
   private final Map<String, DVPortgroupConfigSpec> pgCfgs = new HashMap<String, DVPortgroupConfigSpec>();
   private HostPortGroupSpec hostPgSpec = null;
   private String vswitchId = null;
   private String pgName = null;
   private HostVirtualNicSpec hostVNicSpec = null;
   private final String[] ips = { "100.100.100.105", "100.100.100.101",
            "100.100.100.102", "100.100.100.103", "100.100.100.104" };
   private final Map<String, HostVirtualNicSpec> hmHostVirtualNicSpecs = new HashMap<String, HostVirtualNicSpec>();
   private final Map<String, HostVirtualNicSpec> hmHostvNicSpecs = new HashMap<String, HostVirtualNicSpec>();
   private HostVirtualNicSpec vnicSpec = null;
   private HostVirtualNicSpec origVnicSpec = null;
   private String vNicdevice = null;
   private HostVirtualNicSpec origconsoleVnicSpec = null;
   private HostVirtualNicSpec consoleVnicSpec = null;
   private String consoleVnicdevice = null;
   // private Map<String, DistributedVirtualSwitchPortConnection> portConns =
   // new HashMap<String, DistributedVirtualSwitchPortConnection>();
   private String elPortgroupKey = null;
   private String lbPortgroupKey = null;
   private String ephPortgroupKey = null;
   private ManagedObjectReference lpg = null;
   private ManagedObjectReference epg = null;
   private ManagedObjectReference ephepg = null;
   private final List<DistributedVirtualSwitchPortConnection> alPortConn = new ArrayList<DistributedVirtualSwitchPortConnection>();
   private ConnectAnchor hostConnectAnchor = null;
   private String esxHostName = null;
   private final List<String> vnicList = new ArrayList<String>();
   private final Map<String, String> hmNicType = new HashMap<String, String>();

   @Override
   public void setTestDescription()
   {
      super.setTestDescription("PR# 395300  : test case 5 \n"
               + "1. Create a DVS with 1 static, 1 dynamic, 1 ephemeral PGs (say 2 ports each) \n"
               + " 2. Add 2 hosts to it \n"
               + " 4. create three consolevnics and move 1 each to static, dynamic and ephemeral PG\n"
               + " 5. update console virtual nic  move each console vnic to  static, dynamic and to ephemeral PG \n"
               + " 6. Reconfigure host-vmknic and host-vswifnic to same PG again\n"
               + " 7. Create one consolevnic on host-client and connect it to ephemeral PG \n");
   }

   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      sessionManager = new SessionManager(connectAnchor);
      final Map<ManagedObjectReference, HostSystemInformation> allHosts;
      final String dvsName = getTestId();
      iFolder = new Folder(connectAnchor);
      idvs = new DistributedVirtualSwitch(connectAnchor);
      ins = new NetworkSystem(connectAnchor);
      idvpg = new DistributedVirtualPortgroup(connectAnchor);
      dcMor = iFolder.getDataCenter();
      assertNotNull(dcMor, "Failed to get a Datacenter");
      ihs = new HostSystem(connectAnchor);
      allHosts = ihs.getAllHosts(ESX4x, HostSystemConnectionState.CONNECTED);
      assertNotNull(allHosts, "Failed to get hosts");
      assertTrue(allHosts.size() >= 2, "Failed to get required number hosts");
      final Iterator<ManagedObjectReference> iter = allHosts.keySet().iterator();
      while(iter.hasNext()) {
         final ManagedObjectReference aHostMor = iter.next();
         if(!ihs.isEesxHost(aHostMor)) { 
            hostMor  = aHostMor;
            break;
         }
      }
      assertNotNull(hostMor,HOST_GET_PASS,HOST_GET_FAIL);
      esxHostName = ihs.getHostName(hostMor);
      nsMor = ins.getNetworkSystem(hostMor);
      networkFolderMor = iFolder.getNetworkFolder(dcMor);
      dvsCfg = new DVSConfigSpec();
      dvsCfg.setConfigVersion("");
      dvsCfg.setName(dvsName);
      dvsCfg.setNumStandalonePorts(1);
      final DistributedVirtualSwitchHostMemberConfigSpec[] hostCfgs;
      DistributedVirtualSwitchHostMemberPnicSpec hostPnicSpec;
      DistributedVirtualSwitchHostMemberPnicBacking hostPnicBacking;
      hostCfgs = new DistributedVirtualSwitchHostMemberConfigSpec[1];
         final String[] hostPnics = ins.getPNicIds(hostMor);
         assertNotEmpty(hostPnics, "There are no free pnics on host:" + esxHostName);
         log.info(" Free pnics: " + Arrays.toString(hostPnics));
         hostCfgs[0] = new DistributedVirtualSwitchHostMemberConfigSpec();
         hostPnicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();
         hostPnicSpec.setPnicDevice(hostPnics[0]);
         hostPnicSpec.setUplinkPortKey(null);
         hostPnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
         hostPnicBacking.getPnicSpec().clear();
         hostPnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] { hostPnicSpec }));
         hostCfgs[0].setBacking(hostPnicBacking);
         hostCfgs[0].setHost(hostMor);
         hostCfgs[0].setOperation(TestConstants.CONFIG_SPEC_ADD);
      dvsCfg.getHost().clear();
      dvsCfg.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(hostCfgs));
      return true;
   }

   @Override
   @Test(description = "PR# 395300  : test case 5 \n"
               + "1. Create a DVS with 1 static, 1 dynamic, 1 ephemeral PGs (say 2 ports each) \n"
               + " 2. Add 2 hosts to it \n"
               + " 4. create three consolevnics and move 1 each to static, dynamic and ephemeral PG\n"
               + " 5. update console virtual nic  move each console vnic to  static, dynamic and to ephemeral PG \n"
               + " 6. Reconfigure host-vmknic and host-vswifnic to same PG again\n"
               + " 7. Create one consolevnic on host-client and connect it to ephemeral PG \n")
   public void test()
      throws Exception
   {
      DistributedVirtualSwitchPortConnection portConnection = null;
      final Vector<DistributedVirtualSwitchPortConnection> pcs = new Vector<DistributedVirtualSwitchPortConnection>();
      final List<String> alvnics = new ArrayList<String>();
      log.info("Getting the host-vmknic and host-vswifnic...");
      final HostNetworkConfig nwCfg = ins.getNetworkConfig(nsMor);
      assertNotNull(nwCfg, "Unable to find Network Config of host: "
               + esxHostName);
      assertNotEmpty(com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getVnic(), com.vmware.vc.HostVirtualNicConfig.class), "Unable to find valid Vnic(s)");
      final HostVirtualNicConfig hostVnicCfg = com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getVnic(), com.vmware.vc.HostVirtualNicConfig.class)[0];
      origVnicSpec = hostVnicCfg.getSpec();
      vnicSpec = (HostVirtualNicSpec) TestUtil.deepCopyObject(origVnicSpec);
      vNicdevice = hostVnicCfg.getDevice();
      log.info("VnicDevice : " + vNicdevice);
      alvnics.add(vNicdevice);
      hmHostvNicSpecs.put(vNicdevice, vnicSpec);
      hmNicType.put(vNicdevice, "vnic");
      // got the VNIC now get SCOS
      assertNotEmpty(com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getConsoleVnic(), com.vmware.vc.HostVirtualNicConfig.class), "Unable to find Console VNIC");
      final HostVirtualNicConfig consoleVnicConfig = com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getConsoleVnic(), com.vmware.vc.HostVirtualNicConfig.class)[0];
      origconsoleVnicSpec = consoleVnicConfig.getSpec();
      consoleVnicSpec = (HostVirtualNicSpec) TestUtil.deepCopyObject(origconsoleVnicSpec);
      consoleVnicdevice = consoleVnicConfig.getDevice();
      hmNicType.put(consoleVnicdevice, "consoleVnicdevice");
      alvnics.add(consoleVnicdevice);
      log.info("consoleVnicDevice: " + consoleVnicdevice);
      hmHostvNicSpecs.put(consoleVnicdevice, consoleVnicSpec);
      // Add VSwitch
      vswitchId = getTestId() + "-vswitch";
      pgName = getTestId() + "-PG";
      log.info("Adding VSwitch: " + vswitchId);
      assertTrue(ins.addVirtualSwitch(nsMor, vswitchId, null),
               "Failed to add VSwitch : " + vswitchId);
      log.info("Successfully added VSwitch: " + vswitchId);
      hostVNicSpec = ins.createVNicSpecification();
      addVNIC(ips[0]);
      addVNIC(ips[1]);
      addVNIC(ips[2]);
      dvsMor = iFolder.createDistributedVirtualSwitch(networkFolderMor, dvsCfg);
      assertNotNull(dvsMor, "Failed to add DVS: " + dvsCfg.getName());
      log.info("Successfully created the DVSwitch: " + dvsCfg.getName());
      assertTrue(ins.refresh(nsMor), "Failed to refresh network of "
               + esxHostName);
      assertTrue(ins.refresh(ins.getNetworkSystem(hostMor)),
               "Failed to refresh network system");
      assertTrue(idvs.validateDVSConfigSpec(dvsMor, dvsCfg, null),
               "Failed to validate DVSCfg");
      /* add pgs here */
      epg = addPG(dvsMor, DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
      if (epg != null) {
         elPortgroupKey = idvpg.getKey(epg);
         if (elPortgroupKey != null) {
            portConnection = idvs.getPortConnection(dvsMor, null, false, null,
                     elPortgroupKey);
            pcs.add(portConnection);
            // portConns.put(
            // DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING,
            // portConnection);
         }
      }
      lpg = addPG(dvsMor, DVSTestConstants.DVPORTGROUP_TYPE_LATE_BINDING);
      if (lpg != null) {
         lbPortgroupKey = idvpg.getKey(lpg);
         if (lbPortgroupKey != null) {
            /*
             * portConnection = this.iDistributedVirtualSwitch.
             * getPortConnection(this.dvsMOR, null, false, null,
             * lbPortgroupKey);
             */
            final DVSConfigInfo info = idvs.getConfig(dvsMor);
            dvSwitchUuid = info.getUuid();
            portConnection = new DistributedVirtualSwitchPortConnection();
            portConnection.setSwitchUuid(dvSwitchUuid);
            portConnection.setPortgroupKey(lbPortgroupKey);
            pcs.add(portConnection);
            // portConns.put(
            // DVSTestConstants.DVPORTGROUP_TYPE_LATE_BINDING,
            // portConnection);
         }
      }
      ephepg = addPG(dvsMor, DVSTestConstants.DVPORTGROUP_TYPE_EPHEMERAL);
      if (ephepg != null) {
         ephPortgroupKey = idvpg.getKey(ephepg);
         if (ephPortgroupKey != null) {
            final DVSConfigInfo info = idvs.getConfig(dvsMor);
            dvSwitchUuid = info.getUuid();
            portConnection = new DistributedVirtualSwitchPortConnection();
            portConnection.setSwitchUuid(dvSwitchUuid);
            portConnection.setPortgroupKey(ephPortgroupKey);
            pcs.add(portConnection);
            // hmDistributedVirtualSwitchPortConnection.put(DVSTestConstants.DVPORTGROUP_TYPE_EPHEMERAL,portConnection);
         }
      }
      /*
       * Move each vmknic to static, dynamic and ephemeral PG.
       */
      final Iterator<String> itVnic = hmHostVirtualNicSpecs.keySet().iterator();
      int i = 0;
      while (itVnic.hasNext()) {
         final String vmknic = itVnic.next();
         if (moveVmkNicToPG(pcs.get(i), vmknic)) {
            log.info("Successfully moved vmknic : " + vmknic);
            i++;
         }
      }
      /*
       * Reconfigure host-vmknic and host-vswifnic to same PG again
       */
      String port = idvs.getFreePortInPortgroup(dvsMor, elPortgroupKey, null);
      portConnection = new DistributedVirtualSwitchPortConnection();
      portConnection.setSwitchUuid(dvSwitchUuid);
      portConnection.setPortgroupKey(elPortgroupKey);
      portConnection.setPortKey(port);
      alPortConn.add(portConnection);
      port = idvs.getFreePortInPortgroup(dvsMor, lbPortgroupKey, null);
      portConnection = new DistributedVirtualSwitchPortConnection();
      portConnection.setSwitchUuid(dvSwitchUuid);
      portConnection.setPortgroupKey(lbPortgroupKey);
      // portConnection.setPortKey(port);
      alPortConn.add(portConnection);
      i = 0;
      for (final String vnics : alvnics) {
         if (moveHostVmkNicToPG(alPortConn.get(i), vnics)) {
            log.info("Successfully moved vmknic : " + vnics);
            i++;
         }
      }
      /*
       * Create one vmknic on host-client and connect it to ephemeral PG
       */
      hostConnectAnchor = new ConnectAnchor(esxHostName,
               data.getInt(TestConstants.TESTINPUT_PORT));
      assertNotNull(hostConnectAnchor, "Cannot connect to host: " + esxHostName);
      log.info("Successfully Connected to the host " + esxHostName);
      HostSystem hostIhs = null;
      NetworkSystem hostINetworkSystem = null;
      ManagedObjectReference hostHostMor = null;
      ManagedObjectReference hostNsMor = null;
      UserSession newLoginSession = null;
      ManagedObjectReference hostSessionMor = null;
      sessionManager = new SessionManager(hostConnectAnchor);
      hostSessionMor = sessionManager.getSessionManager();
      assertNotNull(hostSessionMor, "");
      newLoginSession = sessionManager.login(hostSessionMor,
               TestConstants.ESX_USERNAME, TestConstants.ESX_PASSWORD, null);
      assertNotNull(newLoginSession, "");
      hostIhs = new HostSystem(connectAnchor);
      hostINetworkSystem = new NetworkSystem(connectAnchor);
      hostHostMor = hostIhs.getHost(esxHostName);
      hostNsMor = hostINetworkSystem.getNetworkSystem(hostHostMor);
      hostVNicSpec = hostINetworkSystem.createVNicSpecification();
      final String vnic1 = addVNICFromHost(ips[3], hostINetworkSystem, hostNsMor);
      portConnection = new DistributedVirtualSwitchPortConnection();
      portConnection.setSwitchUuid(dvSwitchUuid);
      portConnection.setPortgroupKey(ephPortgroupKey);
      assertTrue((moveVmkNicToPG(portConnection, vnic1, ips[3], dvSwitchUuid,
               hostINetworkSystem, hostNsMor)), "");
      log.info("Successfully moved vmknic : " + vnic1);
   }

   @Override
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      if (origconsoleVnicSpec != null) {
         if (ins.updateServiceConsoleVirtualNic(nsMor, consoleVnicdevice,
                  origconsoleVnicSpec)) {
            log.info("Successfully restored original console  VirtualNic "
                     + "config: " + consoleVnicdevice);
         } else {
            log.info("Unable to restore console VirtualNic "
                     + consoleVnicdevice);
            status &= false;
         }
      }
      if (origVnicSpec != null) {
         if (ins.updateVirtualNic(nsMor, vNicdevice, origVnicSpec)) {
            log.info("Successfully restored original VirtualNic "
                     + "config: " + vNicdevice);
            status &= true;
         } else {
            log.info("Unable to update VirtualNic " + vNicdevice);
            status &= false;
         }
      }
      /*
       * remove all newly created vnics here
       */
      if (vnicList != null && vnicList.size() > 0) {
         for (final String vnic : vnicList) {
            if (ins.removeServiceConsoleVirtualNic(nsMor, vnic)) {
               log.info("Successfully removed  VirtualNic : " + vnic);
            }
         }
         ins.removeVirtualSwitch(nsMor, vswitchId, true);
      }
      if (dvsMor != null) {
         status &= idvs.destroy(dvsMor);
      }
      return status;
   }

   private boolean moveHostVmkNicToPG(final DistributedVirtualSwitchPortConnection portConnection,
                                      final String vmkNic)
      throws Exception
   {
      boolean status = false;
      final DVSConfigInfo info = idvs.getConfig(dvsMor);
      dvSwitchUuid = info.getUuid();
      hmHostvNicSpecs.get(vmkNic).setDistributedVirtualPort(portConnection);
      hmHostvNicSpecs.get(vmkNic).setPortgroup(null);
      if (hmNicType.get(vmkNic).equalsIgnoreCase("vnic")) {
         if (ins.updateVirtualNic(nsMor, vmkNic, hmHostvNicSpecs.get(vmkNic))) {
            log.info("Successfully updated VirtualNic " + vmkNic);
            status = true;
         } else {
            log.error("Unable to update VirtualNic " + vmkNic);
            status = false;
         }
      } else {
         if (ins.updateServiceConsoleVirtualNic(nsMor, vmkNic,
                  hmHostvNicSpecs.get(vmkNic))) {
            log.info("Successfully updated VirtualNic " + vmkNic);
            status = true;
         } else {
            log.error("Unable to update VirtualNic " + vmkNic);
            status = false;
         }
      }
      return status;
   }

   private boolean moveVmkNicToPG(final DistributedVirtualSwitchPortConnection portConnection,
                                  final String vmkNic)
      throws Exception
   {
      boolean status = false;
      final DVSConfigInfo info = idvs.getConfig(dvsMor);
      dvSwitchUuid = info.getUuid();
      hmHostVirtualNicSpecs.get(vmkNic).setDistributedVirtualPort(
               portConnection);
      hmHostVirtualNicSpecs.get(vmkNic).setPortgroup(null);
      if (ins.updateServiceConsoleVirtualNic(nsMor, vmkNic,
               hmHostVirtualNicSpecs.get(vmkNic))) {
         log.info("Successfully updated VirtualNic " + vmkNic);
         status = true;
      } else {
         log.error("Unable to update VirtualNic " + vmkNic);
         status = false;
      }
      return status;
   }

   private boolean moveVmkNicToPG(final DistributedVirtualSwitchPortConnection portConnection,
                                  final String vmkNic,
                                  final String ipAddress,
                                  final String dvSwitchUuid,
                                  final NetworkSystem ins,
                                  final ManagedObjectReference nsMor)
      throws Exception
   {
      boolean status = false;
      hmHostVirtualNicSpecs.get(ipAddress).setDistributedVirtualPort(
               portConnection);
      hmHostVirtualNicSpecs.get(ipAddress).setPortgroup(null);
      if (ins.updateServiceConsoleVirtualNic(nsMor, vmkNic,
               hmHostVirtualNicSpecs.get(ipAddress))) {
         log.info("Successfully updated VirtualNic " + vmkNic);
         status = true;
      } else {
         log.error("Unable to update VirtualNic " + vmkNic);
         status = false;
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }

   private String addVNIC(final String ipaddress)
      throws Exception
   {
      String vNicId = null;
      HostVirtualNicSpec vnicSpec = null;
      final String pgName = getTestId() + "_" + ipaddress.replace(".", "-");
      hostPgSpec = ins.createPortGroupSpec(pgName);
      hostPgSpec.setVswitchName(vswitchId);
      if (ins.addPortGroup(nsMor, hostPgSpec)) {
         log.info("Successfully added the " + "VirtualSwitchPortGroup: "
                  + pgName);
         vnicSpec = (HostVirtualNicSpec) TestUtil.deepCopyObject(hostVNicSpec);
         vnicSpec.getIp().setIpAddress(ipaddress);
         vNicId = ins.addServiceConsoleVirtualNic(nsMor, pgName, vnicSpec);
         if (vNicId != null) {
            hmHostVirtualNicSpecs.put(vNicId, vnicSpec);
            log.info("Successfully added the Virtual NIC " + vNicId);
            vnicList.add(vNicId);
         } else {
            log.error("Unable to add the Virtual NIC");
         }
      } else {
         log.error("Unable to add the " + "VirtualSwitchPortGroup"
                  + this.pgName);
      }
      return vNicId;
   }

   private String addVNICFromHost(final String ipaddress,
                                  final NetworkSystem ins,
                                  final ManagedObjectReference nsMor)
      throws Exception
   {
      String vNicId = null;
      HostVirtualNicSpec vnicSpec = null;
      final String pgName = getTestId() + "-pg2";
      HostPortGroupSpec hostPgSpec = null;
      hostPgSpec = ins.createPortGroupSpec(pgName);
      hostPgSpec.setVswitchName(vswitchId);
      if (ins.addPortGroup(nsMor, hostPgSpec)) {
         log.info("Successfully added the " + "VirtualSwitchPortGroup"
                  + pgName);
         vnicSpec = (HostVirtualNicSpec) TestUtil.deepCopyObject(hostVNicSpec);
         vnicSpec.getIp().setIpAddress(ipaddress);
         vNicId = ins.addServiceConsoleVirtualNic(nsMor, pgName, vnicSpec);
         if (vNicId != null) {
            hmHostVirtualNicSpecs.put(ipaddress, vnicSpec);
            log.info("Successfully added the Virtual NIC " + vNicId);
            vnicList.add(vNicId);
         } else {
            log.error("Unable to add the Virtual NIC");
         }
      } else {
         log.error("Unable to add the " + "VirtualSwitchPortGroup"
                  + this.pgName);
      }
      return vNicId;
   }

   //
   // private VirtualMachineConfigSpec
   // reconfigVM(DistributedVirtualSwitchPortConnection portConnection[],
   // ConnectAnchor connectAnchor)
   // throws MethodFault, Exception
   // {
   // VirtualMachineConfigSpec[] vmConfigSpec = null;
   // VirtualMachineConfigSpec originalVMConfigSpec = null;
   // vmConfigSpec = DVSUtil.getVMConfigSpecForDVSPort(vmMor, connectAnchor,
   // portConnection);
   // if (vmConfigSpec != null && vmConfigSpec.length == 2
   // && vmConfigSpec[0] != null && vmConfigSpec[1] != null) {
   // log.info("Successfully obtained the original and the updated virtual"
   // + " machine config spec");
   // originalVMConfigSpec = vmConfigSpec[1];
   // if (ivm.reconfigVM(vmMor, vmConfigSpec[0])) {
   // log.info("Successfully reconfigured the virtual machine to use "
   // + "the DV port");
   // originalVMConfigSpec = vmConfigSpec[1];
   // } else {
   // log.error("Can not reconfigure the virtual machine to use the "
   // + "DV port");
   // }
   // }
   // return originalVMConfigSpec;
   // }
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
   public static VirtualMachineConfigSpec buildDefaultSpec(final ConnectAnchor connectAnchor,
                                                           final ManagedObjectReference hostMor,
                                                           final String deviceType,
                                                           final String vmName,
                                                           final int noOfCards)
      throws Exception
   {
      ManagedObjectReference poolMor = null;
      VirtualMachineConfigSpec vmConfigSpec = null;
      final HostSystem ihs = new HostSystem(connectAnchor);
      final VirtualMachine ivm = new VirtualMachine(connectAnchor);
      final Vector<String> deviceTypesVector = new Vector<String>();
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
   private ManagedObjectReference addPG(final ManagedObjectReference dvsMor,
                                        final String type)
      throws Exception
   {
      ManagedObjectReference pgMor = null;
      final DVPortgroupConfigSpec pgConfigSpec = new DVPortgroupConfigSpec();
      pgConfigSpec.setName(type);
      pgConfigSpec.setType(type);
      if (!type.equalsIgnoreCase(DVSTestConstants.DVPORTGROUP_TYPE_EPHEMERAL)) {
         pgConfigSpec.setNumPorts(2);
      }
      final List<ManagedObjectReference> pgList = idvs.addPortGroups(dvsMor,
               new DVPortgroupConfigSpec[] { pgConfigSpec });
      if (pgList != null && pgList.size() == 1) {
         log.info("Successfully added the  " + "portgroup to the DVS ");
         pgMor = pgList.get(0);
         pgCfgs.put(type, pgConfigSpec);
      }
      return pgMor;
   }

}
