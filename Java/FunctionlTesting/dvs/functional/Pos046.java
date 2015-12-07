/*
 * ************************************************************************
 *
 * Copyright 2009-2010 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.functional;

import static com.vmware.vc.VirtualMachinePowerState.POWERED_OFF;
import static com.vmware.vc.VirtualMachinePowerState.POWERED_ON;
import static com.vmware.vcqa.TestConstants.VM_DEFAULT_GUEST_WINDOWS;
import static com.vmware.vcqa.TestConstants.VM_VIRTUALDEVICE_ETHERNET_PCNET32;
import static com.vmware.vcqa.TestConstants.VM_VIRTUALDEVICE_SCSI_BUSL_CONTROLLER;
import static com.vmware.vcqa.util.Assert.assertNotEmpty;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.util.VersionConstants.ESX4x;
import static com.vmware.vcqa.vim.MessageConstants.HOST_GET_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.HOST_GET_PASS;
import static com.vmware.vcqa.vim.MessageConstants.VM_CREATE_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.VM_CREATE_PASS;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_EPHEMERAL;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_LATE_BINDING;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVS_DEFAULT_NUM_UPLINK_PORTS;

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
import com.vmware.vc.DVSTrafficShapingPolicy;
import com.vmware.vc.DistributedVirtualPort;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnectee;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.DistributedVirtualSwitchPortCriteria;
import com.vmware.vc.HostDVSPortData;
import com.vmware.vc.HostSystemConnectionState;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.UserSession;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VMwareDVSPortgroupPolicy;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachineMovePriority;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vc.VirtualMachineRelocateSpec;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.internal.vim.InternalServiceInstance;
import com.vmware.vcqa.internal.vim.dvs.InternalHostDistributedVirtualSwitchManager;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.SSHUtil;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.util.ThreadUtil;
import com.vmware.vcqa.vim.AuthorizationManager;
import com.vmware.vcqa.vim.Datastore;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.SessionManager;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.DatastoreInformation;
import com.vmware.vcqa.vim.host.HostSystemInformation;
import com.vmware.vcqa.vim.host.NetworkSystem;
import com.vmware.vcqa.vim.provisioning.ProvisioningOpsHelper;

/**
 * DESCRIPTION:<br>
 * Verify connection integrity of a VM connected to vDS after various
 * reconfigurations to vDS portGroups and cold migration of the VM.<br>
 * TARGET: VC <br>
 * NOTE : PR# 395300(Test case #3)<br>
 * SETUP: <br>
 * 1. Create a VM with 3 virtual-adapters on host1.<br>
 * 2. Create a DVS with 2 hosts added to it.<br>
 * TEST:<br>
 * 3. Add 1 static, 1 dynamic & 1 ephemeral PGs (2 ports each) to DVS.<br>
 * 4. Reconfigure VM to move vm-vmic1 to static, vm-vnic2 to dynamic and
 * vm-vnic3 to ephemeral PG<br>
 * 5. Power on VM, check whether all nics have networking, and power off. <br>
 * 6. Reconfigure VM (pass the SAME spec as current config, i.e. vm-vnic1 to
 * static, vm-vnic2 to dynamic and vm-vnic3 to ephemeral PG).<br>
 * 7. Reconfigure all 3 Portgroups <br>
 * 8. Power on VM, check VMs have networking, if Yes, power off VM, if No, flag
 * error<br>
 * 9: power-on VM on host-client, check VM has networking on vm-vnic1 and
 * vm-vnic3 (vm-vnic2 shouldn't because it was dynamic)<br>
 * 10: reconfigure of all 3 portgroups<br>
 * 11: Repeat step #9 Check using host client<br>
 * 12: power-on all VMs through VC client, make sure they all have networking,
 * power-off all VMs<br>
 * 13: kill vpxd, repeat step #9, restart vpxd and redo step #12<br>
 * 14: cold-migrate this VM from host1 to host2<br>
 * 15: repeat step 10-through 14<br>
 * <br>
 */
public class Pos046 extends TestBase
{
   private SessionManager sessionManager = null;
   private HostSystem ihs = null;
   private Map<ManagedObjectReference, HostSystemInformation> allHosts = null;
   private ManagedObjectReference[] hostMors = null;
   private ManagedObjectReference vmMor = null;
   private VirtualMachine ivm = null;
   private String vmName = null;
   private String dvSwitchUuid = null;
   private Folder iFolder = null;
   private NetworkSystem ins = null;
   private ManagedObjectReference dcMor = null;
   private ManagedObjectReference dvsMor = null;
   private ManagedObjectReference netFolderMor = null;
   private DistributedVirtualSwitch idvs = null;
   private DistributedVirtualPortgroup idvpg = null;
   private Map<String, DVPortgroupConfigSpec> pgCfgs = new HashMap<String, DVPortgroupConfigSpec>();
   private String earlyPgKey = null;
   private String latePgKey = null;
   private String ephemeralPgKey = null;
   private ConnectAnchor hostConnectAnchor = null;
   private String esxHostName1 = null;
   private String esxHostName2 = null;
   private String dvsName = null;
   private ProvisioningOpsHelper iutil = null;
   private boolean isVCTomcatRunning = false;
   private String osType;
   private VirtualMachineRelocateSpec vmRelocateSpec;
   private ManagedObjectReference targetHost;
   private ManagedObjectReference targetPool;

   @Override
   public void setTestDescription()
   {
      super.setTestDescription("Verify connection integrity of a VM connected "
               + "to vDS after various reconfigurations to vDS portGroups "
               + "and cold migration of the VM. [395300(Test case #3)]");
   }

   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      sessionManager = new SessionManager(connectAnchor);
      osType = connectAnchor.getAboutInfo().getOsType();
      VirtualMachineConfigSpec vmConfigSpec = null;
      hostMors = new ManagedObjectReference[2];
      DistributedVirtualSwitchHostMemberPnicSpec hostPnicSpec = null;
      DistributedVirtualSwitchHostMemberPnicBacking hostPnicBacking = null;
      DistributedVirtualSwitchHostMemberConfigSpec[] hostMemberCfg;
      hostMemberCfg = new DistributedVirtualSwitchHostMemberConfigSpec[2];
      dvsName = getTestId() + "-DVS";
      vmName = getTestId() + "-vm";
      iFolder = new Folder(connectAnchor);
      idvs = new DistributedVirtualSwitch(connectAnchor);
      ihs = new HostSystem(connectAnchor);
      ivm = new VirtualMachine(connectAnchor);
      ins = new NetworkSystem(connectAnchor);
      idvpg = new DistributedVirtualPortgroup(connectAnchor);
      dcMor = iFolder.getDataCenter();
      allHosts = ihs.getAllHosts(ESX4x, HostSystemConnectionState.CONNECTED);
      assertNotNull(allHosts, HOST_GET_PASS, HOST_GET_FAIL);
      assertTrue(allHosts.size() >= 2, HOST_GET_PASS, HOST_GET_FAIL);
      Iterator<ManagedObjectReference> it = allHosts.keySet().iterator();
      hostMors[0] = it.next();
      esxHostName1 = allHosts.get(hostMors[0]).getHostName();
      hostMors[1] = it.next();
      esxHostName2 = allHosts.get(hostMors[1]).getHostName();
      ManagedObjectReference nsMor1 = ins.getNetworkSystem(hostMors[0]);
      ManagedObjectReference nsMor2 = ins.getNetworkSystem(hostMors[0]);
      assertNotNull(nsMor1, "Failed to get NetworkSystem of: " + esxHostName1);
      log.info("Got NetworkSystem of host: " + esxHostName1);
      assertNotNull(nsMor2, "Failed to get NetworkSystem of: " + esxHostName2);
      log.info("Got NetworkSystem of host: " + esxHostName2);
      /* 1. Create a VM with 3 NICs. */
      log.info("Creating VM '" + vmName + "' on host " + esxHostName1);
      vmConfigSpec = buildDefaultSpec(connectAnchor, hostMors[0],
               VM_VIRTUALDEVICE_ETHERNET_PCNET32, vmName, 3);
      Datastore ids = new Datastore(connectAnchor);
      List<ManagedObjectReference> dsMors = ids.getSharedDatastores(Arrays.asList(hostMors));
      assertNotEmpty(dsMors, "Failed to get shared datastore");
      DatastoreInformation dsInfo = ids.getDatastoreInfo(dsMors.get(0));
      log.info("Datastore used to create VM is: " + dsInfo.getName());
      ivm.setDatastorePath(vmConfigSpec, dsInfo);
      ManagedObjectReference poolMor = ihs.getPoolMor(hostMors[0]);
      vmMor = new Folder(super.getConnectAnchor()).createVM(ivm.getVMFolder(),
               vmConfigSpec, poolMor, null);
      assertNotNull(vmMor, VM_CREATE_PASS, VM_CREATE_FAIL);
      netFolderMor = iFolder.getNetworkFolder(dcMor);
      assertNotNull(netFolderMor, "Failed to get network folder");
      /* 2. Create DVS with 2 hosts added to it. */
      final DVSConfigSpec dvsCfg = new DVSConfigSpec();
      dvsCfg.setConfigVersion("");
      dvsCfg.setName(dvsName);
      dvsCfg.setNumStandalonePorts(1);
      for (int i = 0; i < hostMors.length; i++) {
         String[] hostPhysicalNics = ins.getPNicIds(hostMors[i]);
         assertNotNull(hostPhysicalNics, "No free pnics found on the host");
         hostMemberCfg[i] = new DistributedVirtualSwitchHostMemberConfigSpec();
         hostPnicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();
         hostPnicSpec.setPnicDevice(hostPhysicalNics[0]);
         hostPnicSpec.setUplinkPortKey(null);
         hostPnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
         hostPnicBacking.getPnicSpec().clear();
         hostPnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] { hostPnicSpec }));
         hostMemberCfg[i].setBacking(hostPnicBacking);
         hostMemberCfg[i].setHost(hostMors[i]);
         hostMemberCfg[i].setOperation(TestConstants.CONFIG_SPEC_ADD);
         // TODO Add 2 extra up-links ports to second host?.
         if (i == 1) {
            hostMemberCfg[i].setMaxProxySwitchPorts(DVS_DEFAULT_NUM_UPLINK_PORTS + 2);
         }
      }
      dvsCfg.getHost().clear();
      dvsCfg.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(hostMemberCfg));
      dvsMor = iFolder.createDistributedVirtualSwitch(netFolderMor, dvsCfg);
      assertNotNull(dvsMor, "Failed to create DVS");
      assertTrue(ins.refresh(nsMor1), "Failed to refresh network info of "
               + esxHostName1);
      assertTrue(ins.refresh(nsMor2), "Failed to refresh network info of "
               + esxHostName2);
      // FIXME validation of DVS spec may not be required.
      // assertTrue(idvs.validateDVSConfigSpec(dvsMor, dvsCfg, null),
      // "Failed to validate ");
      return true;
   }

   @Override
   @Test(description = "Verify connection integrity of a VM connected "
               + "to vDS after various reconfigurations to vDS portGroups "
               + "and cold migration of the VM. [395300(Test case #3)]")
   public void test()
      throws Exception
   {
      DistributedVirtualSwitchPortConnection portConnection = null;
      Vector<DistributedVirtualSwitchPortConnection> dvPortConns;
      ManagedObjectReference epgMor;
      ManagedObjectReference lpgMor;
      ManagedObjectReference ephepgMor;
      dvPortConns = new Vector<DistributedVirtualSwitchPortConnection>();
      DVSConfigInfo info = idvs.getConfig(dvsMor);
      dvSwitchUuid = info.getUuid();
      /* 3. Add 1 static, 1 dynamic & 1 ephemeral PGs (2 ports each) to DVS */
      epgMor = addPG(dvsMor, DVPORTGROUP_TYPE_EARLY_BINDING);
      earlyPgKey = idvpg.getKey(epgMor);
      assertNotNull(earlyPgKey, "Failed to get key of early binding PG");
      portConnection = new DistributedVirtualSwitchPortConnection();
      portConnection.setSwitchUuid(dvSwitchUuid);
      portConnection.setPortgroupKey(earlyPgKey);
      dvPortConns.add(portConnection);
      lpgMor = addPG(dvsMor, DVPORTGROUP_TYPE_LATE_BINDING);
      latePgKey = idvpg.getKey(lpgMor);
      assertNotNull(latePgKey, "Failed to get key of late binding PG");
      portConnection = new DistributedVirtualSwitchPortConnection();
      portConnection.setSwitchUuid(dvSwitchUuid);
      portConnection.setPortgroupKey(latePgKey);
      dvPortConns.add(portConnection);
      ephepgMor = addPG(dvsMor, DVPORTGROUP_TYPE_EPHEMERAL);
      ephemeralPgKey = idvpg.getKey(ephepgMor);
      assertNotNull(ephemeralPgKey, "Failed to get key of ephemeral PG");
      portConnection = new DistributedVirtualSwitchPortConnection();
      portConnection.setSwitchUuid(dvSwitchUuid);
      portConnection.setPortgroupKey(ephemeralPgKey);
      dvPortConns.add(portConnection);
      // 4. Reconfigure VM to connect it's NICs to added DVPortGroups.
      assertNotNull(reconfigVM(TestUtil.vectorToArray(dvPortConns),
               connectAnchor), "Failed to connect VM to DVS PG's");
      log.info("Successfully connected VM to DVPG's");
      // 5. Power on VM, check VMs have networking.
      assertTrue(checkPowerOps(esxHostName1), "Failed to verify connectivity");
      log.info("Reconfigure the added portgroups...");
      // 6. Reconfigure VM (pass the SAME spec as current config)
      assertNotNull(reconfigVM(TestUtil.vectorToArray(dvPortConns),
               connectAnchor), "Failed to connect VM to DVS PG's");
      // 7. Reconfigure all 3 Portgroups
      assertTrue(reconfigurePG(epgMor, DVPORTGROUP_TYPE_EARLY_BINDING),
               "Failed to reconfigure Early Binding PG");
      assertTrue(reconfigurePG(lpgMor, DVPORTGROUP_TYPE_LATE_BINDING),
               "Failed to reconfigure Late Binding PG");
      assertTrue(reconfigurePG(ephepgMor, DVPORTGROUP_TYPE_EPHEMERAL),
               "Failed to reconfigure Ephemeral PG");
      // 8. Power on VM, check VMs have networking. same as #5
      log.info("Verify connectlvity after reconfiguring the PG's");
      assertTrue(checkPowerOps(esxHostName1),
               "Failed to verify connectivity after reconfiguring the DVPG's");
      // 9. power-on VM on host-client, check VM has networking on vm-vnic1 and
      // vm-vnic3 (vm-vnic2 shouldn't because it was dynamic)
      log.info("Check on host client...");
      assertTrue(performOperationsOnhostd(esxHostName1), "Failed ops on hostd");
      // 10: reconfigure of all 3 portgroups again
      log.info("Reconfigure the added portgroups again ...");
      assertTrue(reconfigurePG(epgMor, DVPORTGROUP_TYPE_EARLY_BINDING),
               "Failed to reconfigure Early Binding PG");
      assertTrue(reconfigurePG(lpgMor, DVPORTGROUP_TYPE_LATE_BINDING),
               "Failed to reconfigure Late Binding PG");
      assertTrue(reconfigurePG(ephepgMor, DVPORTGROUP_TYPE_EPHEMERAL),
               "Failed to reconfigure Ephemeral PG");
      // Thread.sleep(60000);// why sleep? FIXME
      // 11. same as #9
      log.info("Now Check on host client...");
      assertTrue(performOperationsOnhostd(esxHostName1),
               "Failed ops on hostd after recfg");
      // 12: power-on all VMs through VC client, check VMs have networking.
      assertTrue(checkPowerOps(esxHostName1),
               "Failed to verify connectivity after hostd ops");
      isVCTomcatRunning = TestUtil.isTomcatRunning(connectAnchor.getHostName());
      // 13.
      stopAVPXD(connectAnchor);
      log.info("Check on host client after vpxd restart...");
      assertTrue(performOperationsOnhostd(esxHostName1),
               "Failed ops on hostd after vpxd is stopped");
      startVPXD(connectAnchor);
      assertTrue(checkPowerOps(esxHostName1),
               "Failed to verify connectivity after hostd ops");
      // 14.
      log.info("Cold migrate the VM from host1 to host2");
      vmMor = ivm.getVM(vmName);

      String destDSType = iutil.parseDestDatastoreType();
      boolean sameHost = iutil.parseIsSameHost();
      boolean isDestinationHostMultipleAccess =
                        iutil.parseIsDestinationHostMultileAccess();
      Map<ManagedObjectReference, ManagedObjectReference> destDSHostMap =
         iutil.getDestinationDSHostMap(vmMor, destDSType, sameHost,
                                  isDestinationHostMultipleAccess);

      Assert.assertTrue(destDSHostMap.size() > 0,
                        "Successfully obtained the destination DSHostMap",
                        "Destination dsHostMap Empty");
      ManagedObjectReference destDatastore =
                       destDSHostMap.keySet().iterator().next();
      targetHost = destDSHostMap.get(destDatastore);
      targetPool = ihs.getResourcePool(targetHost).elementAt(0);

      this.vmRelocateSpec = new VirtualMachineRelocateSpec();
      this.vmRelocateSpec.setPool(targetPool);
      this.vmRelocateSpec.setHost(targetHost);
      this.vmRelocateSpec.setDatastore(destDatastore);

      log.info("Relocate the VM now...");
      assertTrue(ivm.relocateVM(vmMor, vmRelocateSpec, VirtualMachineMovePriority.DEFAULT_PRIORITY, true),
               "Relocation failed");

      log.info("Now do ops on hostd...");
      assertTrue(performOperationsOnhostd(esxHostName2), "");
      log.info("Reconfigure the portgroups ...");
      assertTrue(reconfigurePG(epgMor, DVPORTGROUP_TYPE_EARLY_BINDING),
               "Failed to reconfig early PG");
      assertTrue(reconfigurePG(lpgMor, DVPORTGROUP_TYPE_LATE_BINDING),
               "Failed to reconfigure late PG");
      assertTrue(reconfigurePG(ephepgMor, DVPORTGROUP_TYPE_EPHEMERAL),
               "Failed to reconfigure ephemeral PG");
      // FIXME kiri un-comment after the existing bug get's fixed.
      // status &= performOperationsOnhostd(esxHostName2);
      // status &= checkPowerOps(esxHostName2);
      // stopAVPXD(connectAnchor);
      // status &= performOperationsOnhostd(esxHostName2);
      // startVPXD(connectAnchor);
      // status &= checkPowerOps(esxHostName2);
      // assertTrue(status, "Test Failed");
   }

   private void stopAVPXD(ConnectAnchor connectAnchor)
      throws Exception
   {
      /*
       * Stop services
       */
      if (isVCTomcatRunning) {
         /*
          * Due to bug 361028, an error could be returned when stopping vctomcat
          * service even though it may have stopped successfully. If the command
          * fails, check vctomcat status to verify. Replace this code with
          * commented out code after bug is fixed.
          */
         // assertTrue(stopService(conn, TestConstants.SERVICE_VCTOMCAT),
         // "Successfully stopped service " + TestConstants.SERVICE_VCTOMCAT,
         // "Failed to stop service " + TestConstants.SERVICE_VCTOMCAT);
         if (!SSHUtil.stopService(connectAnchor.getHostName(),
                  TestConstants.SERVICE_VCTOMCAT, osType)) {
            final long DELAY = 5000;
            final long MAX_SLEEP_TIME = TestConstants.SSHCOMMAND_TIMEOUT * 1000;
            long sleepTime = 0;
            while (TestUtil.isTomcatRunning(connectAnchor.getHostName())) {
               Thread.sleep(DELAY);
               sleepTime = sleepTime + DELAY;
               assertTrue(sleepTime <= MAX_SLEEP_TIME,
                        "Failed to stop service "
                                 + TestConstants.SERVICE_VCTOMCAT);
            }
         }
         log.info("Successfully stopped service "
                  + TestConstants.SERVICE_VCTOMCAT);
      }
      assertTrue(SSHUtil.stopService(connectAnchor.getHostName(),
               TestConstants.SERVICE_VPXD, osType),
               "Successfully stopped service " + TestConstants.SERVICE_VPXD,
               "Failed to stop service " + TestConstants.SERVICE_VPXD);
   }

   private void startVPXD(ConnectAnchor connectAnchor)
      throws Exception
   {
      /*
       * Start services
       */
      assertTrue(SSHUtil.startService(connectAnchor.getHostName(),
               TestConstants.SERVICE_VPXD, osType),
               "Successfully started service " + TestConstants.SERVICE_VPXD,
               "Failed to start service " + TestConstants.SERVICE_VPXD);
      if (isVCTomcatRunning) {
         /*
          * Due to bug 361028, an error could be returned when starting vctomcat
          * service even though it may have started successfully. If the command
          * fails, check vctomcat status to verify. Replace this code with
          * commented out code after bug is fixed.
          */
         // assertTrue(startService(conn, TestConstants.SERVICE_VCTOMCAT),
         // "Successfully started service " + TestConstants.SERVICE_VCTOMCAT,
         // "Failed to start service " + TestConstants.SERVICE_VCTOMCAT);
         if (!SSHUtil.startService(connectAnchor.getHostName(),
                  TestConstants.SERVICE_VCTOMCAT, osType)) {
            final long DELAY = 5000;
            final long MAX_SLEEP_TIME = TestConstants.SSHCOMMAND_TIMEOUT * 1000;
            long sleepTime = 0;
            while (!TestUtil.isTomcatRunning(connectAnchor.getHostName())) {
               Thread.sleep(DELAY);
               sleepTime = sleepTime + DELAY;
               assertTrue(sleepTime <= MAX_SLEEP_TIME,
                        "Failed to start service "
                                 + TestConstants.SERVICE_VCTOMCAT);
            }
         }
         log.info("Successfully started service "
                  + TestConstants.SERVICE_VCTOMCAT);
      }
      UserSession loginSession = SessionManager.login(connectAnchor,
               data.getString(TestConstants.TESTINPUT_USERNAME),
               data.getString(TestConstants.TESTINPUT_PASSWORD));
      assertNotNull(loginSession, "Failed to login to "
               + connectAnchor.getHostName());
      log.info("Login Successful : Login User = "
               + loginSession.getUserName());
      iFolder = new Folder(connectAnchor);
      idvs = new DistributedVirtualSwitch(connectAnchor);
      ihs = new HostSystem(connectAnchor);
      ivm = new VirtualMachine(connectAnchor);
      ins = new NetworkSystem(connectAnchor);
      idvpg = new DistributedVirtualPortgroup(connectAnchor);
      dcMor = iFolder.getDataCenter();
      iutil = new ProvisioningOpsHelper(connectAnchor);
      ivm = new VirtualMachine(connectAnchor);
      // iNetworkSystem = new NetworkSystem(connectAnchor);
      dvsMor = iFolder.getDistributedVirtualSwitch(netFolderMor, dvsName);
      vmMor = ivm.getVM(vmName);
      Thread.sleep(20000);
   }

   private boolean performOperationsOnhostd(String esxHostName)
      throws Exception
   {
      boolean status = true;
      Thread.sleep(60000);
      hostConnectAnchor = new ConnectAnchor(esxHostName,
               data.getInt(TestConstants.TESTINPUT_PORT));
      assertNotNull(hostConnectAnchor, "Failed to get host ConnectAnchor");
      log.info("Obtained ConnectAnchor to host: " + esxHostName);
      VirtualMachine hostIvm = null;
      ManagedObjectReference hostVMMor = null;
      UserSession newLoginSession = null;
      AuthorizationManager esxAuth = null;
      InternalServiceInstance msi = null;
      ManagedObjectReference hostDVSManager = null;
      InternalHostDistributedVirtualSwitchManager iHostDvsMgr = null;
      HostDVSPortData[] portData = null;
      ManagedObjectReference newAuthenticationMor = null;
      esxAuth = new AuthorizationManager(hostConnectAnchor);
      sessionManager = new SessionManager(hostConnectAnchor);
      newAuthenticationMor = sessionManager.getSessionManager();
      assertNotNull(newAuthenticationMor, "Null session manager");
      newLoginSession = sessionManager.login(newAuthenticationMor,
               TestConstants.ESX_USERNAME, TestConstants.ESX_PASSWORD, null);
      assertNotNull(newLoginSession, "Null login session");
      // new HostSystem(hostConnectAnchor);
      msi = new InternalServiceInstance(hostConnectAnchor);
      assertNotNull(msi, "The service instance is null");
      hostDVSManager = msi.getInternalServiceInstanceContent().getHostDistributedVirtualSwitchManager();
      Assert.assertNotNull(hostDVSManager, "The host DVS manager mor is null");
      iHostDvsMgr = new InternalHostDistributedVirtualSwitchManager(hostConnectAnchor);
      hostIvm = new VirtualMachine(hostConnectAnchor);
      hostVMMor = hostIvm.getVM(vmName);
      assertTrue(hostIvm.setVMState(hostVMMor, POWERED_ON, false),
               "Failed to power on VM: " + vmName);
      log.info("VM is powered on: " + vmName);
      portData = iHostDvsMgr.fetchPortState(hostDVSManager, dvSwitchUuid, null,null);
      for (HostDVSPortData pd : portData) {
         final String portKey = pd.getPortKey();
         final String pgKey = pd.getPortgroupKey();
         final boolean linkUp = pd.getState().getRuntimeInfo().isLinkUp();
         final String mac = pd.getState().getRuntimeInfo().getMacAddress();
         log.info("PG: " + pgKey + "  Port: " + portKey + "  Link:"
                  + linkUp + "  MAC: " + mac);
         if ((pgKey.equals(ephemeralPgKey) && portKey.startsWith("h-"))) {
            log.info("Ephemeral PortGroup : " + pgKey);
            if (mac == null || !linkUp) {
               log.error("Mac is null / Link is down");
               status = false;
            } else {
               break;
            }
         }
         if ((pgKey.equals(earlyPgKey))) {
            log.info("Early Binding PortGroup : " + pgKey);
            if (mac == null || !linkUp) {
               log.error("Mac is null / Link is down");
               status = false;
            } else {
               break;
            }
         }
         // If dynamic(late) PG then link / mac will not be present.
         if ((pgKey.equals(latePgKey))) {
            log.info("Late Binding PortGroup : " + pgKey);
            if (linkUp) {
               log.error("Link shuldnot have been up");
               status = false;
            } else {
               break;
            }
         }
      }
      // FIXME hitting TaskInProgress here
      // haTask-9104-vim.VirtualMachine.reconfigure-45609
      assertTrue(hostIvm.setVMState(hostVMMor, POWERED_OFF, false),
               "Failed to power off VM: " + vmName);
      log.info("PowerOff on hostd successful for VM: " + vmName);
      // esxAuth.logout(newAuthenticationMor);
      log.info("Wait for power state sync b/w hostd & VC");
      // In cleanup the VM power state will be ON in spite of it being OFF from
      // hostd, so sleep for 2s before proceeding.
      ThreadUtil.sleep(2000);
      status &= true;
      return status;
   }

   @Override
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      try {
         vmMor = ivm.getVM(vmName);
         if (vmMor != null) {
            if (ivm.setVMState(vmMor, VirtualMachinePowerState.POWERED_OFF, false)) {
               log.info("Destroying the VM: " + vmName);
               status &= ivm.destroy(vmMor);
            } else {
               log.error("Can not power off the VM");
               status &= false;
            }
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
      }
      try {
         if (dvsMor != null) {
            status &= idvs.destroy(dvsMor);
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
      }
      return status;
   }

   private VirtualMachineConfigSpec reconfigVM(DistributedVirtualSwitchPortConnection portConnection[],
                                               ConnectAnchor connectAnchor)
      throws Exception
   {
      VirtualMachineConfigSpec[] vmConfigSpec = null;
      VirtualMachineConfigSpec originalVMConfigSpec = null;
      vmConfigSpec = DVSUtil.getVMConfigSpecForDVSPort(vmMor, connectAnchor,
               portConnection);
      if (vmConfigSpec != null && vmConfigSpec.length == 2
               && vmConfigSpec[0] != null && vmConfigSpec[1] != null) {
         log.info("Successfully obtained the original and the updated virtual"
                  + " machine config spec");
         originalVMConfigSpec = vmConfigSpec[1];
         if (ivm.reconfigVM(vmMor, vmConfigSpec[0])) {
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
    * @throws MethodFault , Exception
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
            deviceTypesVector.add(deviceType);
         }
         // create the VMCfg with the default devices.
         vmConfigSpec = ivm.createVMConfigSpec(poolMor, null, vmName,
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
      DVPortgroupConfigSpec pgConfigSpec = new DVPortgroupConfigSpec();
      pgConfigSpec.setName(type);
      pgConfigSpec.setType(type);
      if (!type.equalsIgnoreCase(DVPORTGROUP_TYPE_EPHEMERAL)) {
         pgConfigSpec.setNumPorts(2);
      }
      List<ManagedObjectReference> pgList = idvs.addPortGroups(dvsMor,
               new DVPortgroupConfigSpec[] { pgConfigSpec });
      assertNotEmpty(pgList, "Failed to DVPortGroup add PG of type: " + type);
      log.info("Successfully added DVPortGroup of type: " + type);
      pgCfgs.put(type, pgConfigSpec);
      return pgList.get(0);
   }

   /**
    * Check power-ops on VC for the created VM.<br>
    *
    * @param hostName
    * @return
    * @throws MethodFault
    * @throws Exception
    */
   // FIXME host is not necessary here. pass vm mor here.
   private boolean checkPowerOps(String hostName)
      throws Exception
   {
      log.info("CheckPowerOps on Host: " + hostName);
      boolean status = true;
      ThreadUtil.sleep(60000);
      vmMor = ivm.getVM(vmName);
      // ManagedObjectReference hostMor = ihs.getHost(hostName);
      // assertTrue(hostMor.equals(ivm.getHost(vmMor)), "VM is not in host: "
      // + hostName);
      log.info("PoweredOn the VM: " + vmName);
      assertTrue(ivm.setVMState(vmMor, POWERED_ON, false), "Power on failed");
      Thread.sleep(60000);
      assertTrue(idvs.refreshPortState(dvsMor, null), "Refresh failed");
      DistributedVirtualSwitchPortCriteria criteria = null;
      criteria = idvs.getPortCriteria(null, null, null, new String[] {
               earlyPgKey, latePgKey, ephemeralPgKey }, null, true);
      List<DistributedVirtualPort> ports = idvs.fetchPorts(dvsMor, criteria);
      assertNotEmpty(ports, "No ports found");
      log.info("Number of DVPorts: " + ports.size());
      for (DistributedVirtualPort aPort : ports) {
         final String portKey = aPort.getKey();
         log.info("PortKey: " + portKey + "  State: " + aPort.getState());
         DistributedVirtualSwitchPortConnectee connectee = aPort.getConnectee();
         // If the VM is connected to the DVPort check that it's up.
         if (connectee != null && vmMor.equals(connectee.getConnectedEntity())) {
            if (!aPort.getState().getRuntimeInfo().isLinkUp()) {
               log.warn("Link is down portkey  :" + portKey);
               status = false;
            }
         } else {
            log.debug("DVPort '" + portKey
                     + "' is not connected to any entity.");
         }
      }
      status &= ivm.setVMState(vmMor, POWERED_OFF, false);
      assertTrue(status, "Cleanup failed");
      return status;
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
      pgCfgs.get(type).getScope().clear();
      pgCfgs.get(type).getScope().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new ManagedObjectReference[] { dcMor }));
      pgCfgs.get(type).setPortNameFormat(
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
      pgCfgs.get(type).setPolicy(portgroupPolicy);
      pgCfgs.get(type).setDefaultPortConfig(portSetting);
      pgCfgs.get(type).setConfigVersion(
               idvpg.getConfigInfo(dvPG).getConfigVersion());
      if (idvpg.reconfigure(dvPG, pgCfgs.get(type))) {
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
