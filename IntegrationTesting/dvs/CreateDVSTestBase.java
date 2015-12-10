/*
 * ************************************************************************
 *
 * Copyright 2004 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */

package dvs;

import static com.vmware.vc.VirtualMachinePowerState.POWERED_OFF;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;

import com.vmware.vc.ConfigSpecOperation;
import com.vmware.vc.DVPortConfigSpec;
import com.vmware.vc.DVPortSetting;
import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.HostDVSPortData;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.Permission;
import com.vmware.vc.UserSession;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.internal.vim.InternalServiceInstance;
import com.vmware.vcqa.internal.vim.dvs.InternalHostDistributedVirtualSwitchManager;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.AuthorizationManager;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.SessionManager;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.NetworkSystem;

/**
 * CreateDVSTestBase is a base class for all test cases under create DVS.Every
 * Test case should extend from this base class and implement two abstract
 * methods. They are: 1. setTestDescription() - Set one line precise Test
 * Description 2. test() - Logic for actual test and verification
 */

public abstract class CreateDVSTestBase extends TestBase
{
   private SessionManager sessionManager = null;
   /*
    * private data variables
    */
   protected UserSession loginSession = null;
   protected Folder iFolder = null;
   protected ManagedEntity iManagedEntity = null;
   protected HostSystem ihs = null;
   protected VirtualMachine ivm = null;
   protected NetworkSystem ins = null;
   protected ManagedObjectReference dcMor = null;
   protected ManagedObjectReference dvsMOR = null;
   protected DVSConfigSpec configSpec = null;
   protected ManagedObjectReference networkFolderMor = null;
   protected DistributedVirtualSwitch iDistributedVirtualSwitch = null;
   protected DistributedVirtualPortgroup idvpg = null;
   protected Map<String, ManagedObjectReference> permissionSpecMap = new HashMap<String, ManagedObjectReference>();
   protected List<String> roleIdList = null;
   protected boolean isVMCreated = false;
   private AuthorizationManager authentication;
   private ManagedObjectReference authManagerMor;

   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean cleanUpDone = true;

      if (this.dvsMOR != null) {
         cleanUpDone = this.iManagedEntity.destroy(this.dvsMOR);
         if (cleanUpDone) {
            log.info("dvsMOR destroyed successfully");
         } else {
            log.error("dvsMOR could not be removed");
         }
      }
      Assert.assertTrue(cleanUpDone, "Cleanup failed");
      return cleanUpDone;
   }

   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      this.iFolder = new Folder(connectAnchor);
      this.iManagedEntity = new ManagedEntity(connectAnchor);
      this.iDistributedVirtualSwitch =
               new DistributedVirtualSwitch(connectAnchor);
      this.ihs = new HostSystem(connectAnchor);
      this.ivm = new VirtualMachine(connectAnchor);
      this.ins = new NetworkSystem(connectAnchor);
      this.idvpg = new DistributedVirtualPortgroup(connectAnchor);
      this.dcMor = (ManagedObjectReference) this.iFolder.getDataCenter();
      return true;
   }

   /**
    * Add a role with given privileges and set necessary entity permissions.
    *
    * @param permissionSpecMap Map of privileges and entity
    * @return boolean true, if setentitypermissions is successful, false,
    *         otherwise.
    */
   public boolean addRolesAndSetPermissions(Map<String, ManagedObjectReference> permissionSpecMap)
   {
      boolean result = false;
      final String roleName = getTestId() + "Role";
      String[] privileges = null;
      int roleId = -1;
      authentication = new AuthorizationManager(connectAnchor);
      authManagerMor = this.authentication.getAuthorizationManager();

      try {
         if (permissionSpecMap != null && !permissionSpecMap.isEmpty()) {
            privileges = (String[]) permissionSpecMap.keySet().toArray(
                     new String[0]);
            if (privileges != null && privileges.length > 0) {
               roleIdList = new Vector<String>(privileges.length);
               roleId = authentication.addAuthorizationRole(authManagerMor,
                        roleName, privileges);
               roleIdList.add(roleId + "");
               if (this.authentication.roleExists(this.authManagerMor,
                        roleId)) {
                  log.info("Successfully added the Role : " + roleName
                           + "with privileges");
                  final Permission permissionSpec = new Permission();
                  permissionSpec.setGroup(false);
                  permissionSpec.setPrincipal(TestConstants.GENERIC_USER);
                  permissionSpec.setPropagate(true);
                  permissionSpec.setRoleId(roleId);
                  final Permission[] permissionsArr = { permissionSpec };
                  result = true;
                  for (int i = 0; i < privileges.length; i++) {
                     if (this.authentication.setEntityPermissions(
                              this.authManagerMor,
                              permissionSpecMap.get(privileges[i]),
                              permissionsArr)) {
                        log.info("Successfully set entity permissions " + privileges[i]);
                     } else {
                        log.error("Failed to set entity permissions " + privileges[i]);
                        result = false;
                        break;
                     }
                  }
               }

            } else {
               log.error("Unable to obtain privileges ");
            }
         } else {
            log.error("Unable to obtain permissionSpecMap ");
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
      }
      return result;
   }

   /**
    * This method performs following actions. 1.Logout of GENERIC_USER 2.Logged in
    * of administrator 3.Removes authorization role
    *
    * @param connectAnchor ConnectAnchor.
    * @param data.getString(TestConstants.TESTINPUT_USERNAME)
    * @param data.getString(TestConstants.TESTINPUT_PASSWORD).
    * @return boolean true, If successful. false, otherwise.
    * @throws MethodFault, Exception
    */
   public boolean performSecurityTestsCleanup(ConnectAnchor connectAnchor,
                                              String userName,
                                              String password)
      throws Exception
   {
      boolean result = false;
      int roleId = -1;
      if (SessionManager.logout(connectAnchor)) {
         this.loginSession = SessionManager.login(connectAnchor,
                  data.getString(TestConstants.TESTINPUT_USERNAME),
                  data.getString(TestConstants.TESTINPUT_PASSWORD));
         if (this.loginSession != null) {
            log.info("Successfully logged in user: "
                     + data.getString(TestConstants.TESTINPUT_USERNAME));
            result = true;
            if (roleIdList != null && roleIdList.size() > 0) {
               for (int i = 0; i < roleIdList.size(); i++) {
                  roleId = Integer.parseInt(roleIdList.get(i));
                  if (this.authentication.roleExists(this.authManagerMor,
                           roleId)) {
                     result &= this.authentication.removeAuthorizationRole(
                              this.authManagerMor, roleId, false);
                  }
               }
            }
         } else {
            log.error("Failed to login user:"
                     + data.getString(TestConstants.TESTINPUT_USERNAME));
         }
      } else {
         log.error("Failed to logout user: " + TestConstants.GENERIC_USER);
      }
      return result;
   }

   /**
    * This method performs following actions. 1.Logout of administrator 2.Logged
    * in of GENERIC_USER
    *
    * @param connectAnchor ConnectAnchor.
    * @return boolean true, If successful. false, otherwise.
    * @throws MethodFault, Exception
    */
   public boolean performSecurityTestsSetup(ConnectAnchor connectAnchor)
      throws Exception
   {
      boolean result = false;
      if (SessionManager.logout(connectAnchor)) {
         log.info("Successfully logged out "
                  + data.getString(TestConstants.TESTINPUT_USERNAME));
         this.loginSession = SessionManager.login(connectAnchor,
                  TestConstants.GENERIC_USER, TestConstants.PASSWORD);
         if (this.loginSession != null) {
            log.info("Successfully logged in " + "with user dvsUser");
            result = true;
         } else {
            log.error("Failed to login with test user.");
         }
      } else {
         log.error("Faied to logout.");
      }
      return result;
   }

   /**
    * Verifies that the port setting is transferred to the host properly when a
    * port is created on the host.
    *
    * @param connectAnchor ConnectAnchor object.
    * @param portSetting DVPortSetting object.
    * @return boolean true if the port setting is pushed onto to the host, false
    *         otherwise
    * @throws MethodFault, Exception
    */
   protected boolean verifyPortSettingOnHost(ConnectAnchor connectAnchor,
                                             DVPortSetting portSetting)
      throws Exception
   {
      boolean verified = false;
      DVSConfigSpec dvsConfigSpec = null;
      DVSConfigInfo dvsConfigInfo = null;
      ManagedObjectReference hostMor = null;
      DistributedVirtualSwitchHostMemberConfigSpec hostMemberConfigSpec = null;
      DistributedVirtualSwitchHostMemberPnicBacking backing = null;
      HostNetworkConfig[] hostNetworkConfig = null;
      VirtualMachineConfigSpec[] vmConfigSpecs = null;
      ManagedObjectReference vmMor = null;
      Vector<ManagedObjectReference> hostVMs = null;
      DistributedVirtualSwitchPortConnection portConnection = null;
      ConnectAnchor hostConnectAnchor = null;
      AuthorizationManager iAuthentication = null;
      ManagedObjectReference sessionMgrMor = null;
      UserSession hostLoginSession = null;
      InternalServiceInstance msi = null;
      ManagedObjectReference hostDVSManager = null;
      InternalHostDistributedVirtualSwitchManager iHostDVSManager = null;
      HostDVSPortData[] portData = null;
      Vector<ManagedObjectReference> allHosts = null;
      VirtualMachineConfigSpec tempVmConfigSpec = null;
      try {
         Assert.assertNotNull(portSetting, "The port setting passed is null");
         Assert.assertNotNull(this.dvsMOR, "The DVS mor is null");
         dvsConfigInfo = this.iDistributedVirtualSwitch.getConfig(this.dvsMOR);
         dvsConfigSpec = new DVSConfigSpec();
         allHosts = this.ihs.getAllHost();
         if (allHosts != null && allHosts.size() > 0) {
            hostMor = allHosts.get(0);
            Assert.assertNotNull(hostMor, "The host mor is null");
            dvsConfigSpec = new DVSConfigSpec();
            dvsConfigSpec.setConfigVersion(dvsConfigInfo.getConfigVersion());
            dvsConfigSpec.setNumStandalonePorts(1);
            hostMemberConfigSpec = new DistributedVirtualSwitchHostMemberConfigSpec();
            backing = new DistributedVirtualSwitchHostMemberPnicBacking();
            backing.getPnicSpec().clear();
            backing.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] {}));
            hostMemberConfigSpec.setHost(hostMor);
            hostMemberConfigSpec.setOperation(TestConstants.CONFIG_SPEC_ADD);
            hostMemberConfigSpec.setBacking(backing);
            dvsConfigSpec.getHost().clear();
            dvsConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostMemberConfigSpec }));
            Assert.assertTrue(this.iDistributedVirtualSwitch.reconfigure(
                     this.dvsMOR, dvsConfigSpec),
                     "Successfully added the host to connect to the DVS",
                     "Can not add the host to the DVS");
            hostNetworkConfig = this.iDistributedVirtualSwitch.getHostNetworkConfigMigrateToDVS(
                     this.dvsMOR, hostMor);
            if (hostNetworkConfig != null && hostNetworkConfig.length >= 2
                     && hostNetworkConfig[0] != null
                     && hostNetworkConfig[1] != null) {
               log.info("Successfully obtained the network configuration of the "
                        + "host to update to");
               Assert.assertTrue(
                        this.ins.updateNetworkConfig(
                                 this.ins.getNetworkSystem(hostMor),
                                 hostNetworkConfig[0],
                                 TestConstants.CHANGEMODE_MODIFY),
                        "Successfully updated the network configuration of the host",
                        "Can not update the network configuration of the host");
               portConnection = this.iDistributedVirtualSwitch.getPortConnection(
                        this.dvsMOR, null, false, null);
               Assert.assertNotNull(portConnection,
                        "Can not obtain a free port connection object");
               hostVMs = this.ihs.getVMs(hostMor, null);
               if (hostVMs == null || hostVMs.size() <= 0) {
                  tempVmConfigSpec = DVSUtil.buildDefaultSpec(connectAnchor,
                           hostMor,
                           TestConstants.VM_VIRTUALDEVICE_ETHERNET_PCNET32,
                           this.getTestId() + "-VM");
                  if (tempVmConfigSpec != null) {
                     vmMor = new Folder(super.getConnectAnchor()).createVM(
                              this.ivm.getVMFolder(), tempVmConfigSpec,
                              this.ihs.getResourcePool(hostMor).get(0), hostMor);
                     if (vmMor != null) {
                        this.isVMCreated = true;
                     }
                  }
               } else {
                  vmMor = hostVMs.get(0);
               }

               Assert.assertNotNull(vmMor, "The vm mor is null");
               vmConfigSpecs = DVSUtil.getVMConfigSpecForDVSPort(
                        vmMor,
                        connectAnchor,
                        new DistributedVirtualSwitchPortConnection[] { portConnection });
               if (vmConfigSpecs != null && vmConfigSpecs.length >= 2
                        && vmConfigSpecs[0] != null && vmConfigSpecs[1] != null) {
                  Assert.assertTrue(
                           this.ivm.reconfigVM(vmMor, vmConfigSpecs[0]),
                           "Successfully reconfigured the "
                                    + "VM to connect to the standalone dv port",
                           "Can not reconfigure the VM to connect to "
                                    + "the standalone dv port");
                  hostConnectAnchor = new ConnectAnchor(
                           this.ihs.getHostName(hostMor),
                           data.getInt(TestConstants.TESTINPUT_PORT));
                  Assert.assertNotNull(hostConnectAnchor,
                           "The host connect anchor is null");
                  iAuthentication = new AuthorizationManager(hostConnectAnchor);
                  sessionManager = new SessionManager(hostConnectAnchor);
                  sessionMgrMor = sessionManager.getSessionManager();
                  hostLoginSession = new SessionManager(hostConnectAnchor).login(
                           sessionMgrMor, TestConstants.ESX_USERNAME,
                           TestConstants.ESX_PASSWORD, null);
                  Assert.assertNotNull(hostLoginSession,
                           "Can not login into the host");
                  msi = new InternalServiceInstance(hostConnectAnchor);
                  Assert.assertNotNull(msi, "The service instance is null");
                  hostDVSManager = msi.getInternalServiceInstanceContent().getHostDistributedVirtualSwitchManager();
                  Assert.assertNotNull(hostDVSManager,
                           "The host DVS manager mor is null");
                  iHostDVSManager = new InternalHostDistributedVirtualSwitchManager(
                           hostConnectAnchor);
                  portData = iHostDVSManager.fetchPortState(hostDVSManager,
                           dvsConfigInfo.getUuid(),
                           new String[] { portConnection.getPortKey() }, null);
                  Assert.assertNotNull(portData, "The port data is null");
                  Assert.assertTrue((portData.length == 1),
                           "The size of the array is incorrect");
                  Assert.assertNotNull(portData[0], "The port data is null");
                  Assert.assertNotNull(portData[0].getSetting(),
                           "The port setting is null");
                  verified = TestUtil.compareObject(portData[0].getSetting(),
                           portSetting, TestUtil.getIgnorePropertyList(
                                    portSetting, false));
                  if (verified) {
                     log.info("Verified that the port setting is correctly "
                              + "set on the host");
                     /*
                      * Power-On the vm
                      */
                  } else {
                     log.error("The port setting on the host diverges from"
                              + " the port setting on the VC");
                  }
               } else {
                  log.error("Can not obtain the vm config spec");
               }
            } else {
               log.error("Can not obtain the network configuration");
            }
         } else {
            log.error("There are no hosts in the setup");
         }
      } finally {
         if (vmMor != null) {
            if (this.isVMCreated && ivm.setVMState(vmMor, POWERED_OFF, false)) {
               // destroy the VM
               verified &= this.ivm.destroy(vmMor);
            } else {
               if (vmConfigSpecs != null && vmConfigSpecs.length >= 2
                        && vmConfigSpecs[1] != null) {
                  verified &= this.ivm.reconfigVM(vmMor, vmConfigSpecs[1]);
               }
            }
         }
         if (hostMor != null && hostNetworkConfig != null
                  && hostNetworkConfig[1] != null) {
            verified &= this.ins.updateNetworkConfig(
                     this.ins.getNetworkSystem(hostMor), hostNetworkConfig[1],
                     TestConstants.CHANGEMODE_MODIFY);
         }
         if (hostLoginSession != null) {
            verified &= sessionManager.logout(sessionMgrMor);
         }
      }
      return verified;
   }

   /**
    * Verifies that the port setting is transferred to the host properly when a
    * port is created on the host.
    *
    * @param connectAnchor ConnectAnchor object.
    * @param portSetting DVPortSetting object.
    * @param powerOnVM boolean flag for powerOnVM
    * @return boolean true if the port setting is pushed onto to the host, false
    *         otherwise
    * @throws MethodFault, Exception
    */
   protected boolean verifyPortSettingOnHost(ConnectAnchor connectAnchor,
                                             DVPortSetting portSetting,
                                             boolean powerOnVM)
      throws Exception
   {
      boolean verified = false;
      DVSConfigSpec dvsConfigSpec = null;
      DVSConfigInfo dvsConfigInfo = null;
      ManagedObjectReference hostMor = null;
      DistributedVirtualSwitchHostMemberConfigSpec hostMemberConfigSpec = null;
      DistributedVirtualSwitchHostMemberPnicBacking backing = null;
      HostNetworkConfig[] hostNetworkConfig = null;
      VirtualMachineConfigSpec[] vmConfigSpecs = null;
      ManagedObjectReference vmMor = null;
      Vector<ManagedObjectReference> hostVMs = null;
      DistributedVirtualSwitchPortConnection portConnection = null;
      ConnectAnchor hostConnectAnchor = null;
      AuthorizationManager iAuthentication = null;
      ManagedObjectReference sessionMgrMor = null;
      UserSession hostLoginSession = null;
      InternalServiceInstance msi = null;
      ManagedObjectReference hostDVSManager = null;
      InternalHostDistributedVirtualSwitchManager iHostDVSManager = null;
      HostDVSPortData[] portData = null;
      Vector<ManagedObjectReference> allHosts = null;
      VirtualMachineConfigSpec tempVmConfigSpec = null;
      DVPortConfigSpec[] portConfigSpecs = null;
      int DVS_PORT_NUM = 1;
      VMwareDVSPortSetting dvPort = null;

      try {
         Assert.assertNotNull(portSetting, "The port setting passed is null");
         Assert.assertNotNull(this.dvsMOR, "The DVS mor is null");
         dvsConfigInfo = this.iDistributedVirtualSwitch.getConfig(this.dvsMOR);
         dvsConfigSpec = new DVSConfigSpec();
         allHosts = this.ihs.getAllHost();
         if (allHosts != null && allHosts.size() > 0) {
            hostMor = allHosts.get(0);
            Assert.assertNotNull(hostMor, "The host mor is null");
            dvsConfigSpec = new DVSConfigSpec();
            dvsConfigSpec.setConfigVersion(dvsConfigInfo.getConfigVersion());
            dvsConfigSpec.setNumStandalonePorts(1);
            hostMemberConfigSpec = new DistributedVirtualSwitchHostMemberConfigSpec();
            backing = new DistributedVirtualSwitchHostMemberPnicBacking();
            backing.getPnicSpec().clear();
            backing.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] {}));
            hostMemberConfigSpec.setHost(hostMor);
            hostMemberConfigSpec.setOperation(TestConstants.CONFIG_SPEC_ADD);
            hostMemberConfigSpec.setBacking(backing);
            dvsConfigSpec.getHost().clear();
            dvsConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostMemberConfigSpec }));
            Assert.assertTrue(this.iDistributedVirtualSwitch.reconfigure(
                     this.dvsMOR, dvsConfigSpec),
                     "Successfully added the host to connect to the DVS",
                     "Can not add the host to the DVS");
            hostNetworkConfig = this.iDistributedVirtualSwitch.getHostNetworkConfigMigrateToDVS(
                     this.dvsMOR, hostMor);
            if (hostNetworkConfig != null && hostNetworkConfig.length >= 2
                     && hostNetworkConfig[0] != null
                     && hostNetworkConfig[1] != null) {
               log.info("Successfully obtained the network configuration of the "
                        + "host to update to");
               Assert.assertTrue(
                        this.ins.updateNetworkConfig(
                                 this.ins.getNetworkSystem(hostMor),
                                 hostNetworkConfig[0],
                                 TestConstants.CHANGEMODE_MODIFY),
                        "Successfully updated the network configuration of the host",
                        "Can not update the network configuration of the host");
               portConnection = this.iDistributedVirtualSwitch.getPortConnection(
                        this.dvsMOR, null, false, null);

               Assert.assertNotNull(portConnection,
                        "Can not obtain a free port connection object");
               hostVMs = this.ihs.getVMs(hostMor, null);
               if (hostVMs == null || hostVMs.size() <= 0) {
                  tempVmConfigSpec = DVSUtil.buildDefaultSpec(connectAnchor,
                           hostMor,
                           TestConstants.VM_VIRTUALDEVICE_ETHERNET_PCNET32,
                           this.getTestId() + "-VM");
                  if (tempVmConfigSpec != null) {
                     vmMor = new Folder(super.getConnectAnchor()).createVM(
                              this.ivm.getVMFolder(), tempVmConfigSpec,
                              this.ihs.getResourcePool(hostMor).get(0), hostMor);
                     if (vmMor != null) {
                        this.isVMCreated = true;
                     }
                  }
               } else {
                  vmMor = hostVMs.get(0);
               }

               Assert.assertNotNull(vmMor, "The vm mor is null");
               vmConfigSpecs = DVSUtil.getVMConfigSpecForDVSPort(
                        vmMor,
                        connectAnchor,
                        new DistributedVirtualSwitchPortConnection[] { portConnection });
               if (vmConfigSpecs != null && vmConfigSpecs.length >= 2
                        && vmConfigSpecs[0] != null && vmConfigSpecs[1] != null) {
                  Assert.assertTrue(
                           this.ivm.reconfigVM(vmMor, vmConfigSpecs[0]),
                           "Successfully reconfigured the "
                                    + "VM to connect to the standalone dv port",
                           "Can not reconfigure the VM to connect to "
                                    + "the standalone dv port");
                  hostConnectAnchor = new ConnectAnchor(
                           this.ihs.getHostName(hostMor),
                           data.getInt(TestConstants.TESTINPUT_PORT));
                  Assert.assertNotNull(hostConnectAnchor,
                           "The host connect anchor is null");
                  iAuthentication = new AuthorizationManager(hostConnectAnchor);
                  sessionManager = new SessionManager(hostConnectAnchor);
                  sessionMgrMor = sessionManager.getSessionManager();
                  hostLoginSession = new SessionManager(hostConnectAnchor).login(
                           sessionMgrMor, TestConstants.ESX_USERNAME,
                           TestConstants.ESX_PASSWORD, null);

                  Assert.assertNotNull(hostLoginSession,
                           "Can not login into the host");
                  msi = new InternalServiceInstance(hostConnectAnchor);
                  Assert.assertNotNull(msi, "The service instance is null");
                  hostDVSManager = msi.getInternalServiceInstanceContent().getHostDistributedVirtualSwitchManager();
                  Assert.assertNotNull(hostDVSManager,
                           "The host DVS manager mor is null");
                  iHostDVSManager = new InternalHostDistributedVirtualSwitchManager(
                           hostConnectAnchor);
                  portData = iHostDVSManager.fetchPortState(hostDVSManager,
                           dvsConfigInfo.getUuid(),
                           new String[] { portConnection.getPortKey() }, null);
                  Assert.assertNotNull(portData, "The port data is null");
                  Assert.assertTrue((portData.length == 1),
                           "The size of the array is incorrect");
                  Assert.assertNotNull(portData[0], "The port data is null");
                  Assert.assertNotNull(portData[0].getSetting(),
                           "The port setting is null");
                  verified = TestUtil.compareObject(portData[0].getSetting(),
                           portSetting, TestUtil.getIgnorePropertyList(
                                    portSetting, false));
                  if (verified) {
                     log.info("Verified that the port setting is correctly "
                              + "set on the host");
                     /*
                      * Power-On the vm
                      */
                     if (powerOnVM
                              && this.ivm.setVMState(vmMor, VirtualMachinePowerState.POWERED_ON, false)) {
                        log.info("PowerOn successful for VM");

                        portConfigSpecs = new DVPortConfigSpec[DVS_PORT_NUM];
                        portConfigSpecs[0] = new DVPortConfigSpec();
                        portConfigSpecs[0].setKey(portConnection.getPortKey());
                        portConfigSpecs[0].setOperation(ConfigSpecOperation.EDIT.value());
                        dvPort = new VMwareDVSPortSetting();
                        dvPort.setBlocked(DVSUtil.getBoolPolicy(false, true));
                        portConfigSpecs[0].setSetting(dvPort);
                        if (this.iDistributedVirtualSwitch.reconfigurePort(
                                 this.dvsMOR, portConfigSpecs)) {
                           log.info("Successfully reconfigured DVS");
                        } else {
                           log.error("Failed to reconfigure dvs");
                           verified = false;
                        }
                     } else {
                        log.error("Unable to PowerOn the VM");
                        verified = false;
                     }

                  } else {
                     log.error("The port setting on the host diverges from"
                              + " the port setting on the VC");
                  }
               } else {
                  log.error("Can not obtain the vm config spec");
               }
            } else {
               log.error("Can not obtain the network configuration");
            }
         } else {
            log.error("There are no hosts in the setup");
         }
      } finally {
         if (vmMor != null && ivm.setVMState(vmMor, POWERED_OFF, false)) {
            if (this.isVMCreated) {
               verified &= this.ivm.destroy(vmMor);
            } else {
               if (vmConfigSpecs != null && vmConfigSpecs.length >= 2
                        && vmConfigSpecs[1] != null) {
                  verified &= this.ivm.reconfigVM(vmMor, vmConfigSpecs[1]);
               }
            }
         }
         if (hostMor != null && hostNetworkConfig != null
                  && hostNetworkConfig[1] != null) {
            verified &= this.ins.updateNetworkConfig(
                     this.ins.getNetworkSystem(hostMor), hostNetworkConfig[1],
                     TestConstants.CHANGEMODE_MODIFY);
         }
         if (hostLoginSession != null) {
            verified &= sessionManager.logout(sessionMgrMor);
         }
      }
      return verified;
   }

};