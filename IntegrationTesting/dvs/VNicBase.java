/*
 * ************************************************************************
 *
 * Copyright 2008-2009 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;

import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.DistributedVirtualSwitchPortCriteria;
import com.vmware.vc.HostIpConfig;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.HostNetworkInfo;
import com.vmware.vc.HostVirtualNic;
import com.vmware.vc.HostVirtualNicSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.Permission;
import com.vmware.vc.UserSession;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
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
import com.vmware.vcqa.vim.host.VmotionSystem;

/**
 * This class is the base class for all the virtualNic test cases.
 */
public abstract class VNicBase extends TestBase
{
   private final SessionManager sessionManager = null;
   protected DistributedVirtualSwitch iDVSwitch;
   protected DistributedVirtualPortgroup iDVPortGroup;
   protected Folder iFolder;
   protected HostSystem ihs;
   protected NetworkSystem ins;
   protected VirtualMachine ivm;
   protected ManagedEntity iManagedEntity;
   protected VmotionSystem ivmotionSystem = null;
   protected UserSession loginSession;
   /* DVS MOR used in tests. */
   protected ManagedObjectReference dvsMor;
   /* Host MOR used for creating the DVS and VM. */
   protected ManagedObjectReference hostMor;
   protected ManagedObjectReference desthostMor;
   protected String dvsName;
   protected HostNetworkConfig[] hostNetworkConfig;
   protected boolean networkUpdated;
   protected ManagedObjectReference nwSystemMor;
   protected Map<String, ManagedObjectReference> permissionSpecMap = new HashMap<String, ManagedObjectReference>();
   protected List<String> roleIdList = null;
   private AuthorizationManager authentication;
   private ManagedObjectReference authManagerMor;

   /**
    * Get the port keys based on the port criteria passed.
    *
    * @param dvsMor DVS Mor.
    * @param portgroupKey Given portgroup key.
    * @return List<String> List containing portkeys of the DVSwitch.
    * @throws MethodFault, Exception
    */
   public List<String> fetchPortKeys(final ManagedObjectReference dvsMor,
                                     final String portgroupKey)
      throws Exception
   {
      final DistributedVirtualSwitchPortCriteria portCriteria = iDVSwitch.getPortCriteria(
               null, null, null, new String[] { portgroupKey }, null, true);
      return iDVSwitch.fetchPortKeys(dvsMor, portCriteria);
   }

   /**
    * Create HostVirtualNicSpec Object and set the values.
    *
    * @param portConnection DistributedVirtualSwitchPortConnection
    * @param ipAddress IPAddress
    * @param subnetMask subnetMask
    * @param dhcp boolean
    * @return HostVirtualNicSpec
    * @throws MethodFault, Exception
    */
   public HostVirtualNicSpec buildVnicSpec(final DistributedVirtualSwitchPortConnection portConnection,
                                           final String ipAddress,
                                           final String subnetMask,
                                           final boolean dhcp)
      throws Exception
   {
      final HostVirtualNicSpec spec = new HostVirtualNicSpec();
      spec.setDistributedVirtualPort(portConnection);
      final HostIpConfig ip = new HostIpConfig();
      ip.setDhcp(dhcp);
      ip.setIpAddress(ipAddress);
      ip.setSubnetMask(subnetMask);
      spec.setIp(ip);
      return spec;
   }

   /**
    * Method that returns the vnic spec based on if the host in question is a
    * ESX host or a visor host. If the host is Visor it will set the ip address
    * to take the dhcp value, otherwise it will retrieve the ip address from the
    * list of alternate ip's of the vmkernel nic or the service console nic.
    *
    * @param portConnection DistributedVirtualSwitchPortConnection object
    * @param hostMor ManagedObjectReference object.
    * @return HostVirtualNicSpec
    * @throws MethodFault, Exception
    */
   public HostVirtualNicSpec buildVnicSpec(final DistributedVirtualSwitchPortConnection portConnection,
                                           final ManagedObjectReference hostMor)
      throws Exception
   {
      HostVirtualNicSpec hostVNicSpec = null;
      HostVirtualNicSpec vnicSpec = null;
      HostNetworkInfo hostNetworkInfo = null;
      if (ihs.isEesxHost(hostMor)) {
         hostVNicSpec = buildVnicSpec(portConnection, null, null, true);
      } else {
         ManagedObjectReference nsMor = ins.getNetworkSystem(hostMor);
         log.info("The nsMor for hostMor " + hostMor + "is " + nsMor);
         hostNetworkInfo = ins.getNetworkInfo(nsMor);
         if (hostNetworkInfo != null) {
            if ((com.vmware.vcqa.util.TestUtil.vectorToArray(hostNetworkInfo.getConsoleVnic(), com.vmware.vc.HostVirtualNic.class) != null)
                     && (com.vmware.vcqa.util.TestUtil.vectorToArray(hostNetworkInfo.getConsoleVnic(), com.vmware.vc.HostVirtualNic.class).length > 0)
                     && (com.vmware.vcqa.util.TestUtil.vectorToArray(hostNetworkInfo.getConsoleVnic(), com.vmware.vc.HostVirtualNic.class)[0] != null)
                     && (com.vmware.vcqa.util.TestUtil.vectorToArray(hostNetworkInfo.getConsoleVnic(), com.vmware.vc.HostVirtualNic.class)[0].getSpec() != null)) {
               vnicSpec = com.vmware.vcqa.util.TestUtil.vectorToArray(hostNetworkInfo.getConsoleVnic(), com.vmware.vc.HostVirtualNic.class)[0].getSpec();
            } else if ((com.vmware.vcqa.util.TestUtil.vectorToArray(hostNetworkInfo.getVnic(), com.vmware.vc.HostVirtualNic.class) != null)
                     && (com.vmware.vcqa.util.TestUtil.vectorToArray(hostNetworkInfo.getVnic(), com.vmware.vc.HostVirtualNic.class).length > 0)
                     && (com.vmware.vcqa.util.TestUtil.vectorToArray(hostNetworkInfo.getVnic(), com.vmware.vc.HostVirtualNic.class)[0] != null)
                     && (com.vmware.vcqa.util.TestUtil.vectorToArray(hostNetworkInfo.getVnic(), com.vmware.vc.HostVirtualNic.class)[0].getSpec() != null)) {
               vnicSpec = com.vmware.vcqa.util.TestUtil.vectorToArray(hostNetworkInfo.getVnic(), com.vmware.vc.HostVirtualNic.class)[0].getSpec();
            } else {
               log.error("There are no vnic or service console "
                        + "vnics on the host");
            }
            if (vnicSpec != null) {
               String ipAddress = TestUtil.getAlternateServiceConsoleIP(
                        vnicSpec.getIp().getIpAddress());
               if(ipAddress != null){
                  hostVNicSpec = buildVnicSpec(portConnection,ipAddress,
                           vnicSpec.getIp().getSubnetMask(), false);
               }else{
                  hostVNicSpec = buildVnicSpec(portConnection,null,null,true);
               }
            } else {
               log.error("The vnic spec is null");
            }
         } else {
            log.error("Can not retrieve the host network info");
         }
      }
      return hostVNicSpec;
   }

   /**
    * This method create the HostvirtualNic and add virtualNic.
    *
    * @param aHostMor Given source/destination hostMor.
    * @param portConnection Given DVPortconnection.
    * @return String HostVirtualNic Device.
    */
   public String addVnic(final ManagedObjectReference aHostMor,
                         final DistributedVirtualSwitchPortConnection portConnection)
   {
      String device = null;
      HostVirtualNicSpec hostVnicSpec = null; // use to create VNIC.
      String vnicId = null;
      ManagedObjectReference nsMor = null;// Network System of give host.
      HostNetworkInfo networkInfo = null;
      DistributedVirtualSwitchPortConnection newConn = null;
      try {
         hostVnicSpec = buildVnicSpec(portConnection, aHostMor);
         nsMor = ins.getNetworkSystem(aHostMor);
         log.info("The nsMor returned for  host " + aHostMor + " is " + nsMor);
         vnicId = ins.addVirtualNic(nsMor, "", hostVnicSpec);
         if (vnicId != null) {
            log.info("Successfully added the virtual Nic.");
            networkInfo = ins.getNetworkInfo(nsMor);
            if ((networkInfo != null) && (com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getVnic(), com.vmware.vc.HostVirtualNic.class) != null)) {
               final HostVirtualNic[] vNics = com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getVnic(), com.vmware.vc.HostVirtualNic.class);
               for (final HostVirtualNic vnic : vNics) {
                  log.info("Vnic Key: " + vnic.getKey());
                  log.info("Vnic Device: " + vnic.getDevice());
                  if (vnic.getSpec() != null) {
                     newConn = vnic.getSpec().getDistributedVirtualPort();
                     if ((newConn != null)
                              && TestUtil.compareObject(portConnection,
                                       newConn, TestUtil.getIgnorePropertyList(
                                                portConnection, false))) {
                        device = vnic.getDevice();
                        log.info("Got the added vNIC: " + device);
                        break;
                     } else {
                        log.info("Not the added vNIC: " + vnic.getDevice());
                     }
                  } else {
                     log.error("Failed to get the HostVirtualNicSpec.");
                  }
               }
            } else {
               log.error("There are no vnics on the host");
            }
         } else {
            log.error("Failed to  add the virtula Nic.");
         }
      } catch (final Exception e) {
         TestUtil.handleException(e);
      }
      return device;
   }

   /**
    * Create the DVPortconnection object and set the values.
    *
    * @param switchUuid DVS switch uuid.
    * @param portKey Key of the given port.
    * @param portgroupKey Key of the portgroup.
    * @return connection DistributedVirtualSwitchPortConnection.
    */
   public DistributedVirtualSwitchPortConnection buildDistributedVirtualSwitchPortConnection(final String switchUuid,
                                                                                             final String portKey,
                                                                                             final String portgroupKey)
   {
      final DistributedVirtualSwitchPortConnection connection = new DistributedVirtualSwitchPortConnection();
      connection.setSwitchUuid(switchUuid);
      connection.setPortKey(portKey);
      connection.setPortgroupKey(portgroupKey);
      return connection;
   }

   /**
    * This method get the subnetMask.
    *
    * @param hostMor Given hostMor.
    * @return String subnetMask.
    * @throws MethodFault, Exception
    */
   public String getSubnetMask(final ManagedObjectReference hostMor)
      throws Exception
   {
      HostNetworkInfo networkInfo = null;
      String subnetMask = null;
      nwSystemMor = ins.getNetworkSystem(hostMor);
      networkInfo = ins.getNetworkInfo(nwSystemMor);
      //
      if (ihs.isEesxHost(hostMor)) {
         if (com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getVnic(), com.vmware.vc.HostVirtualNic.class) != null) {
            final HostVirtualNic vNic = com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getVnic(), com.vmware.vc.HostVirtualNic.class)[0];
            subnetMask = vNic.getSpec().getIp().getSubnetMask();
         }
      } else {
         final HostVirtualNic hostVirtualNic = com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getConsoleVnic(), com.vmware.vc.HostVirtualNic.class)[0];
         if (hostVirtualNic != null) {
            log.info("Successfully get the hostvirtualNic.");
            final HostVirtualNicSpec hostVNicSpec = hostVirtualNic.getSpec();
            if (hostVNicSpec != null) {
               log.info("Successfully get the hostVirtualNicSpec.");
               final HostIpConfig hostIpConfig = hostVNicSpec.getIp();
               if (hostIpConfig != null) {
                  log.info("Successfully get the hostIPconfig.");
                  subnetMask = hostIpConfig.getSubnetMask();
               } else {
                  log.error("Failed to get the hostIPConfig.");
               }
            } else {
               log.error("Failed to get the hostVirtualNicSpec.");
            }
         } else {
            log.error("Failed to get the hostVirtualNic.");
         }
      }
      log.info("SubnetMask: {}",subnetMask);
      return subnetMask;
   }

   /**
    * Destroy any managed entity.
    *
    * @param mor ManagedObjectReference
    * @return boolean true, if destroyed.
    * @throws MethodFault, Exception
    */
   public boolean destroy(final ManagedObjectReference mor)
      throws Exception
   {
      boolean status = false;
      if (mor != null) {
         log.info("Destroying: " + iManagedEntity.getName(mor));
         status = iManagedEntity.destroy(mor);
      } else {
         log.info("Given MOR is null");
         status = true;
      }
      return status;
   }

   /**
    * This method reboots and checks the network connectivity of the host
    *
    * @param hostMor HostMor object
    * @return boolean, true if network connectivity is available, false
    *         otherwise
    * @throws MethodFault, Exception
    */
   public boolean rebootAndVerifyNetworkConnectivity(final ManagedObjectReference hostMor)
      throws Exception
   {
      if (DVSUtil.disableHostReboot()) {
         log.warn("Not invoking rebootHost api as DISABLE_HOST_REBOOT flag in the dvs property file is set to true");
      } else {
         Assert.assertNotNull(hostMor, "hostMor is null");
         ihs.rebootHost(hostMor, data.getInt(TestConstants.TESTINPUT_PORT),
                  true, data.getString(TestConstants.TESTINPUT_USERNAME),
                  data.getString(TestConstants.TESTINPUT_PASSWORD));
         log.info("Rebooted the host:" + ihs.getHostName(hostMor));
         Assert.assertTrue(
                  (DVSUtil.checkNetworkConnectivity(ihs.getIPAddress(hostMor),
                           null, null)),
                  "Unable to obtain NetworkConnectivity of the host :"
                           + ihs.getHostName(hostMor));
      }
      return true;
   }

   /**
    * Default setup used in all the vmops tests. 1. Login.
    *
    * @param connectAnchor
    * @return boolean true, If successful. false, otherwise.
    */
   @Override
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      dvsName = getTestId() + "-DVS";
      iFolder = new Folder(connectAnchor);
      iManagedEntity = new ManagedEntity(connectAnchor);
      iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
      iDVPortGroup = new DistributedVirtualPortgroup(connectAnchor);
      ihs = new HostSystem(connectAnchor);
      ins = new NetworkSystem(connectAnchor);
      ivmotionSystem = new VmotionSystem(connectAnchor);
      ivm = new VirtualMachine(connectAnchor);
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
                  permissionSpec.setPropagate(false);
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
    * This method performs following actions. 1.Logout of GENERIC_USER 2.Logged
    * in of administrator 3.Removes authorization role
    *
    * @param connectAnchor ConnectAnchor.
    * @param data.getString(TestConstants.TESTINPUT_USERNAME)
    * @param data.getString(TestConstants.TESTINPUT_PASSWORD).
    * @return boolean true, If successful. false, otherwise.
    * @throws MethodFault, Exception
    */
   public boolean performSecurityTestsCleanup(final ConnectAnchor connectAnchor,
                                              final String userName,
                                              final String password)
      throws Exception
   {
      boolean result = false;
      int roleId = -1;
      if (SessionManager.logout(connectAnchor)) {
         loginSession = SessionManager.login(connectAnchor,
                  data.getString(TestConstants.TESTINPUT_USERNAME),
                  data.getString(TestConstants.TESTINPUT_PASSWORD));
         if (loginSession != null) {
            log.info("Successfully logged in user: "
                     + data.getString(TestConstants.TESTINPUT_USERNAME));
            result = true;
            if ((roleIdList != null) && (roleIdList.size() > 0)) {
               for (int i = 0; i < roleIdList.size(); i++) {
                  roleId = Integer.parseInt(roleIdList.get(i));
                  if (authentication.roleExists(authManagerMor,
                           roleId)) {
                     result &= authentication.removeAuthorizationRole(
                              authManagerMor, roleId, false);
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
   public boolean performSecurityTestsSetup(final ConnectAnchor connectAnchor)
      throws Exception
   {
      boolean result = false;
      if (SessionManager.logout(connectAnchor)) {
         log.info("Successfully logged out "
                  + data.getString(TestConstants.TESTINPUT_USERNAME));
         loginSession = SessionManager.login(connectAnchor,
                  TestConstants.GENERIC_USER, TestConstants.PASSWORD);
         if (loginSession != null) {
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
    * Test cleanup. 1.Try to restore the network to use the DVS. 2.Try to
    * destroy the DVS if it was create in test setup.
    *
    * @param connectAnchor ConnectAnchor.
    * @return true, if test cleanup was successful. false, otherwise.
    */
   @Override
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = false;
      try {
         status = destroy(dvsMor);
      } catch (final Exception e) {
         TestUtil.handleException(e);
      }
      Assert.assertTrue(status, "Cleanup failed");
      return status;
   }
}
