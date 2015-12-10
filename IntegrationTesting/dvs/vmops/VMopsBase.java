/*
 * ************************************************************************
 *
 * Copyright 2008-2009 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.vmops;

import static com.vmware.vcqa.TestConstants.VM_DEFAULT_GUEST_WINDOWS;
import static com.vmware.vcqa.TestConstants.VM_VIRTUALDEVICE_SCSI_BUSL_CONTROLLER;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVPortgroupPolicy;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.DistributedVirtualSwitchPortCriteria;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.Permission;
import com.vmware.vc.UserSession;
import com.vmware.vc.VirtualDeviceConfigSpec;
import com.vmware.vc.VirtualDeviceConfigSpecOperation;
import com.vmware.vc.VirtualDeviceConnectInfo;
import com.vmware.vc.VirtualEthernetCard;
import com.vmware.vc.VirtualEthernetCardDistributedVirtualPortBackingInfo;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
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
 * This class is the base class for all the vmops test cases.
 */
public abstract class VMopsBase extends TestBase
{
   protected DistributedVirtualSwitch iDVSwitch = null;
   protected DistributedVirtualPortgroup iDVPortGroup = null;
   protected Folder iFolder = null;
   protected HostSystem ihs = null;
   protected NetworkSystem ins = null;
   protected VirtualMachine ivm = null;
   protected ManagedEntity iManagedEntity = null;
   protected DVPortgroupConfigSpec dvPortgroupConfigSpec = null;
   // protected UserSession loginSession = null;
   /* DVS MOR used in tests. */
   protected ManagedObjectReference dvsMor = null;
   /* Host MOR used for creting the DVS nnd VM. */
   protected ManagedObjectReference hostMor = null;
   protected String dvsName = null;
   protected HostNetworkConfig[] hostNetworkConfig = null;
   protected boolean networkUpdated = false;
   protected ManagedObjectReference nwSystemMor = null;
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
   public List<String> fetchPortKeys(ManagedObjectReference dvsMor,
                                     String portgroupKey)
      throws Exception
   {
      DistributedVirtualSwitchPortCriteria portCriteria = iDVSwitch.getPortCriteria(
               null, null, null, new String[] { portgroupKey }, null, true);
      return iDVSwitch.fetchPortKeys(dvsMor, portCriteria);
   }

   /**
    * Create a DVPortgroupConfigSpec object using the given values.
    *
    * @param type Type of the port group.
    * @param numPort number of ports to create.
    * @param policy the policy to be used.
    * @return DVPortgroupConfigSpec with given values set.
    */
   public DVPortgroupConfigSpec buildDVPortgroupConfigSpec(String type,
                                                           int numPort,
                                                           DVPortgroupPolicy policy)
   {
      DVPortgroupConfigSpec cfg = new DVPortgroupConfigSpec();
      cfg.setType(type);
      cfg.setNumPorts(numPort);
      cfg.setPolicy(policy);
      return cfg;
   }

   /**
    * Create a VM config spec for adding a new VM.
    *
    * @param connection DistributedVirtualSwitchPortConnection
    * @param deviceType type of the VirtualEthernetCard to use.
    * @param hostMor The MOR of the host where the VM has to be created.
    * @return VirtualMachineConfigSpec.
    * @throws MethodFault, Exception
    */
   public VirtualMachineConfigSpec buildCreateVMCfg(DistributedVirtualSwitchPortConnection connection,
                                                    String deviceType,
                                                    ManagedObjectReference hostMor)
      throws Exception
   {
      log.info("Given device type: " + deviceType);
      VirtualMachineConfigSpec vmConfigSpec = null;
      HashMap deviceSpecMap = null;
      Iterator deviceSpecItr = null;
      VirtualDeviceConfigSpec deviceSpec = null;
      VirtualEthernetCard ethernetCard = null;
      VirtualEthernetCardDistributedVirtualPortBackingInfo dvPortBacking;
      VirtualDeviceConnectInfo connectInfo = null;
      // create the VMCfg with the default devices.
      vmConfigSpec = buildDefaultSpec(hostMor, deviceType);
      // now chagnge the backing for the ethernet card.
      deviceSpecMap = ivm.getVirtualDeviceSpec(vmConfigSpec, deviceType);
      deviceSpecItr = deviceSpecMap.values().iterator();
      if (deviceSpecItr.hasNext()) {
         deviceSpec = (VirtualDeviceConfigSpec) deviceSpecItr.next();
         ethernetCard = VirtualEthernetCard.class.cast(deviceSpec.getDevice());
         connectInfo = new VirtualDeviceConnectInfo();
         connectInfo.setConnected(false);
         connectInfo.setAllowGuestControl(true);
         connectInfo.setStartConnected(true);
         ethernetCard.setConnectable(connectInfo);
         log.info("Got the ethernet card: " + ethernetCard);
         // create a DVS backing to set the backing for given device.
         dvPortBacking = new VirtualEthernetCardDistributedVirtualPortBackingInfo();
         dvPortBacking.setPort(connection);
         ethernetCard.setBacking(dvPortBacking);
      } else {
         log.error("Unable to find the given device type:" + deviceType);
      }
      return vmConfigSpec;
   }

   /**
    * Create a default VMConfigSpec.
    *
    * @param hostMor The MOR of the host where the defaultVMSpec has to be
    *           created.
    * @param deviceType type of the device.
    * @return vmConfigSpec VirtualMachineConfigSpec.
    * @throws MethodFault, Exception
    */
   public VirtualMachineConfigSpec buildDefaultSpec(ManagedObjectReference hostMor,
                                                    String deviceType)
      throws Exception
   {
      ManagedObjectReference poolMor = null;
      VirtualMachineConfigSpec vmConfigSpec = null;
      Vector<String> deviceTypesVector = new Vector<String>();
      poolMor = ihs.getPoolMor(hostMor);
      if (poolMor != null) {
         deviceTypesVector.add(TestConstants.VM_VIRTUALDEVICE_DISK);
         deviceTypesVector.add(VM_VIRTUALDEVICE_SCSI_BUSL_CONTROLLER);
         deviceTypesVector.add(deviceType);
         // create the VMCfg with the default devices.
         vmConfigSpec = ivm.createVMConfigSpec(poolMor, getTestId(),
                  VM_DEFAULT_GUEST_WINDOWS, deviceTypesVector, null);
         ivm.setDiskCapacityInKB(vmConfigSpec, TestConstants.CLONEVM_DISK);
      } else {
         log.error("Unable to get the resource pool from the host.");
      }
      return vmConfigSpec;
   }

   /**
    * Method to verify the given VM. 1. Verify the config specs. 2. Verify by
    * power-ops.
    *
    * @param vmMor the mor of the VM to be verified.
    * @param deltaCfg the delta spec used while reconfiguring the VM.
    * @param originalCfg the orifinal spec used for cerating the VM.
    * @return true if both the checks are successful. false otherwise.
    * @throws MethodFault, Exception
    */
   public boolean verify(ManagedObjectReference vmMor,
                         VirtualMachineConfigSpec deltaCfg,
                         VirtualMachineConfigSpec originalCfg)
      throws Exception
   {
      boolean result = false;
      VirtualMachineConfigSpec newCfg = ivm.getVMConfigSpec(vmMor);
      if (ivm.compareVMConfigSpec(originalCfg, deltaCfg, newCfg)) {
         log.info("Configspecs matches. verifying power-ops...");
         if (ivm.verifyPowerOps(vmMor, false)) {
            log.info("Powerops successful.");
            result = true;
         } else {
            log.error("Powerops failed.");
         }
      } else {
         log.error("Configspecs doesnot match.");
      }
      return result;
   }

   /**
    * Create the DVPortconnection object and set the values.
    *
    * @param switchUuid DVS switch uuid.
    * @param portKey Key of the given port.
    * @param portgroupKey Key of the portgroup.
    * @return connection DistributedVirtualSwitchPortConnection.
    */
   public DistributedVirtualSwitchPortConnection buildDistributedVirtualSwitchPortConnection(String switchUuid,
                                                                                             String portKey,
                                                                                             String portgroupKey)
   {
      DistributedVirtualSwitchPortConnection connection = new DistributedVirtualSwitchPortConnection();
      connection.setSwitchUuid(switchUuid);
      connection.setPortKey(portKey);
      connection.setPortgroupKey(portgroupKey);
      return connection;
   }

   /**
    * Destroy any managed entity.
    *
    * @param mor ManagedObjectReference
    * @return boolean true, if destroyed.
    * @throws MethodFault, Exception
    */
   public boolean destroy(ManagedObjectReference mor)
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
    * Returns the VM configuration spec to have only the required ethernet
    * adapter type, all the other ethernet adapters that do not match the
    * adapter type are removed if the updated virtual machine spec is applied in
    * the reconfigure VM operation.
    *
    * @param vmMor ManagedObjectReference
    * @param connectAnchor ConnectAnchor
    * @param deviceType String type of the ethernet adapter
    * @return VirtualMachineConfigSpec[]
    * @throws MethodFault, Exception
    */
   public VirtualMachineConfigSpec[] getVMReconfigSpec(ManagedObjectReference vmMor,
                                                       ConnectAnchor connectAnchor,
                                                       String deviceType)
      throws Exception
   {
      VirtualMachineConfigSpec[] configSpec = new VirtualMachineConfigSpec[2];
      VirtualMachineConfigSpec originalConfigSpec = null;
      VirtualMachineConfigSpec updatedConfigSpec = null;
      List<VirtualDeviceConfigSpec> existingVDConfigSpecList = null;
      List<VirtualDeviceConfigSpec> originalVDConfigSpecList = new ArrayList<VirtualDeviceConfigSpec>();
      List<VirtualDeviceConfigSpec> updatedVDConfigSpecList = new ArrayList<VirtualDeviceConfigSpec>();
      VirtualDeviceConfigSpec updatedVDConfigSpec = null;
      boolean deviceFound = false;
      List<String> deviceTypes = null;
      List<VirtualDeviceConfigSpecOperation> operations = null;
      if (vmMor != null) {
         existingVDConfigSpecList = DVSUtil.getAllVirtualEthernetCardDevices(
                  vmMor, connectAnchor);
         if (existingVDConfigSpecList != null
                  && existingVDConfigSpecList.size() > 0) {
            updatedConfigSpec = new VirtualMachineConfigSpec();
            deviceTypes = new ArrayList<String>();
            operations = new ArrayList<VirtualDeviceConfigSpecOperation>();
            for (VirtualDeviceConfigSpec vdConfigSpec : existingVDConfigSpecList) {
               deviceTypes.add("" + vdConfigSpec.getDevice().getKey());
               if (vdConfigSpec.getDevice().getClass().getName().equals(
                        deviceType)) {
                  if (deviceFound) {
                     operations.add(VirtualDeviceConfigSpecOperation.REMOVE);
                  } else {
                     operations.add(VirtualDeviceConfigSpecOperation.EDIT);
                     deviceFound = true;
                  }
               } else {
                  operations.add(VirtualDeviceConfigSpecOperation.REMOVE);
               }
            }
            if (!deviceFound) {
               deviceTypes.add(deviceType);
               operations.add(VirtualDeviceConfigSpecOperation.ADD);
            }
            ivm.reconfigVMSpec(ivm.getVMConfigSpec(vmMor), updatedConfigSpec,
                     deviceTypes, operations, ivm.getResourcePool(vmMor));
            if (updatedConfigSpec != null
                     && com.vmware.vcqa.util.TestUtil.vectorToArray(updatedConfigSpec.getDeviceChange(), com.vmware.vc.VirtualDeviceConfigSpec.class) != null
                     && com.vmware.vcqa.util.TestUtil.vectorToArray(updatedConfigSpec.getDeviceChange(), com.vmware.vc.VirtualDeviceConfigSpec.class).length > 0) {
               for (VirtualDeviceConfigSpec vdConfigSpec : com.vmware.vcqa.util.TestUtil.vectorToArray(updatedConfigSpec.getDeviceChange(), com.vmware.vc.VirtualDeviceConfigSpec.class)) {
                  if (vdConfigSpec.getOperation().equals(
                           VirtualDeviceConfigSpecOperation.EDIT)) {
                     originalVDConfigSpecList.add(vdConfigSpec);
                  } else if (vdConfigSpec.getOperation().equals(
                           VirtualDeviceConfigSpecOperation.REMOVE)) {
                     updatedVDConfigSpec = (VirtualDeviceConfigSpec) TestUtil.deepCopyObject(vdConfigSpec);
                     updatedVDConfigSpecList.add(updatedVDConfigSpec);
                     vdConfigSpec.setOperation(VirtualDeviceConfigSpecOperation.ADD);
                     originalVDConfigSpecList.add(vdConfigSpec);
                  } else if (vdConfigSpec.getOperation().equals(
                           VirtualDeviceConfigSpecOperation.ADD)) {
                     updatedVDConfigSpec = (VirtualDeviceConfigSpec) TestUtil.deepCopyObject(vdConfigSpec);
                     updatedVDConfigSpecList.add(updatedVDConfigSpec);
                     vdConfigSpec.setOperation(VirtualDeviceConfigSpecOperation.REMOVE);
                     originalVDConfigSpecList.add(vdConfigSpec);
                  }
               }
            }
         }
      }
      if (updatedVDConfigSpecList.size() > 0) {
         updatedConfigSpec = new VirtualMachineConfigSpec();
         updatedConfigSpec.getDeviceChange().clear();
         updatedConfigSpec.getDeviceChange().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(updatedVDConfigSpecList.toArray(new VirtualDeviceConfigSpec[updatedVDConfigSpecList.size()])));
         configSpec[0] = updatedConfigSpec;
      } else {
         configSpec[0] = null;
      }
      if (originalVDConfigSpecList.size() > 0) {
         originalConfigSpec = new VirtualMachineConfigSpec();
         originalConfigSpec.getDeviceChange().clear();
         originalConfigSpec.getDeviceChange().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(originalVDConfigSpecList.toArray(new VirtualDeviceConfigSpec[originalVDConfigSpecList.size()])));
      }
      configSpec[1] = originalConfigSpec;
      return configSpec;
   }

   /**
    * Default setup used in all the vmops tests. 1. Login.
    *
    * @param connectAnchor
    * @return boolean true, If successful. false, otherwise.
    */
   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      dvsName = getTestId() + "-DVS";
      iFolder = new Folder(connectAnchor);
      iManagedEntity = new ManagedEntity(connectAnchor);
      iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
      iDVPortGroup = new DistributedVirtualPortgroup(connectAnchor);
      ivm = new VirtualMachine(connectAnchor);
      ihs = new HostSystem(connectAnchor);
      ins = new NetworkSystem(connectAnchor);
      return true;
   }

   /**
    * Try to destroy the DVS if it was create in test setup.
    *
    * @param connectAnchor ConnectAnchor.
    * @return true, if test cleanup was successful. false, otherwise.
    */
   @Override
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      return destroy(dvsMor);
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
      try {
         authentication = new AuthorizationManager(connectAnchor);
         authManagerMor = authentication.getAuthorizationManager();
         if (permissionSpecMap != null && !permissionSpecMap.isEmpty()) {
            privileges = permissionSpecMap.keySet().toArray(new String[0]);
            if (privileges != null && privileges.length > 0) {
               roleIdList = new Vector<String>(privileges.length);
               for (int i = 0; i < privileges.length; i++) {
                  roleId = authentication.addAuthorizationRole(authManagerMor,
                           roleName, privileges);
                  roleIdList.add(roleId + "");
                  if (authentication.roleExists(authManagerMor, roleId)) {
                     log.info("Successfully added the Role: " + roleName
                              + " with privileges: " + privileges[i]);
                     final Permission permissionSpec = new Permission();
                     permissionSpec.setGroup(false);
                     permissionSpec.setPrincipal(TestConstants.GENERIC_USER);
                     permissionSpec.setPropagate(true);
                     permissionSpec.setRoleId(roleId);
                     final Permission[] permissionsArr = { permissionSpec };
                     result = true;
                     if (authentication.setEntityPermissions(authManagerMor,
                              permissionSpecMap.get(privileges[i]),
                              permissionsArr)) {
                        log.info("Successfully set entity permissions.");
                     } else {
                        log.error("Failed to set entity permissions.");
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
         UserSession loginSession = SessionManager.login(connectAnchor,
                  data.getString(TestConstants.TESTINPUT_USERNAME),
                  data.getString(TestConstants.TESTINPUT_PASSWORD));
         if (loginSession != null) {
            log.info("Successfully logged in user: "
                     + data.getString(TestConstants.TESTINPUT_USERNAME));
            result = true;
            if (roleIdList != null && roleIdList.size() > 0) {
               for (int i = 0; i < roleIdList.size(); i++) {
                  roleId = Integer.parseInt(roleIdList.get(i));
                  if (authentication.roleExists(authManagerMor, roleId)) {
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
   public boolean performSecurityTestsSetup(ConnectAnchor connectAnchor)
      throws Exception
   {
      boolean result = false;
      if (SessionManager.logout(connectAnchor)) {
         log.info("Successfully logged out "
                  + data.getString(TestConstants.TESTINPUT_USERNAME));
         UserSession loginSession = SessionManager.login(connectAnchor,
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
}