/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.functional;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Set;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.DistributedVirtualSwitchProductSpec;
import com.vmware.vc.HostDVSPortData;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.HostSystemConnectionState;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.UserSession;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.internal.vim.InternalServiceInstance;
import com.vmware.vcqa.internal.vim.dvs.InternalHostDistributedVirtualSwitchManager;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.util.ThreadUtil;
import com.vmware.vcqa.util.VersionConstants;
import com.vmware.vcqa.vim.AuthorizationManager;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.SessionManager;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchHelper;
import com.vmware.vcqa.vim.host.HostSystemInformation;
import com.vmware.vcqa.vim.host.NetworkSystem;

/**
 *   PR#482571..Verify that VC is able to reclaim ports on the host
 *    which were connected to a VM but are not 
 *    connected anymore after the VM has been 
 *    moved to a new portgroup
 */

/**
 * Class for the precheck in ops
 */
public class Pos051 extends TestBase
{
   private SessionManager sessionManager = null;
   private HostSystem ihs = null;
   private VirtualMachine ivm = null;
   private DistributedVirtualSwitchHelper iDVS = null;
   private DistributedVirtualPortgroup iDVPG = null;
   private ManagedObjectReference hostMor = null;
   private ManagedObjectReference vmMor = null;
   private ManagedObjectReference dvsMor = null;
   private NetworkSystem ins = null;
   private HostNetworkConfig originalNetworkConfig = null;
   private ManagedObjectReference nsMor = null;
   private VirtualMachineConfigSpec originalVMConfigSpec = null;
   private boolean isVMCreated = false;
   private String hostVersion = null;
   private String early = DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING;
   private String portgroupKey = null;
   private String portKey = null;
   private ConnectAnchor hostConnectAnchor = null;
   private String dvSwitchUuid = null;
   private String esxhostName = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   @Override
   public void setTestDescription()
   {
      super.setTestDescription(" PR#482571..Verify that VC is able to reclaim "
               + "ports on the host"
               + " which were connected to a VM but are not "
               + "connected anymore after the VM has been "
               + "moved to a new portgroup");
   }

   /**
    * Method to setup the environment for the test.
    * 
    * @param connectAnchor ConnectAnchor object
    * @return boolean true if successful, false otherwise.
    */
   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      sessionManager = new SessionManager(connectAnchor);
      boolean status = false;
      log.info("Test setup Begin:");
      HashMap<ManagedObjectReference, HostSystemInformation> hostsMap = null;
      Set<ManagedObjectReference> allHosts = null;
      Vector<ManagedObjectReference> hostVMs = null;
      Iterator<ManagedObjectReference> it = null;
      VirtualMachineConfigSpec vmConfigSpec = null;
      String vmName = null;
      String[] pnicIds = null;
     
         this.ivm = new VirtualMachine(connectAnchor);
         this.iDVS = new DistributedVirtualSwitchHelper(connectAnchor);
         this.iDVPG = new DistributedVirtualPortgroup(connectAnchor);
         this.ihs = new HostSystem(connectAnchor);
         this.ins = new NetworkSystem(connectAnchor);
         hostsMap = this.ihs.getAllHosts(VersionConstants.ESX4x, HostSystemConnectionState.CONNECTED);
         if (hostsMap != null) {
            allHosts = hostsMap.keySet();
            if (allHosts != null && allHosts.size() > 0) {
               it = allHosts.iterator();
               while (it.hasNext()) {
                  ManagedObjectReference tempMor = it.next();
                  if (tempMor != null) {
                     if (this.ins.getPNicIds(tempMor) != null) {
                        this.hostMor = tempMor;
                        break;
                     }
                  }
               }
               if (this.hostMor != null) {
                  esxhostName = this.ihs.getHostName(hostMor);
                  log.info(" host name is :" + esxhostName);
                  this.hostVersion = this.ihs.getHostProductIdVersion(this.hostMor);
                  log.info("Found a host with free pnics in the inventory");
                  this.nsMor = this.ins.getNetworkSystem(this.hostMor);
                  if (this.nsMor != null) {
                     pnicIds = this.ins.getPNicIds(this.hostMor);
                     if (pnicIds != null) {
                        vmName = this.getTestId() + "-vm";
                        vmConfigSpec = DVSUtil.buildDefaultSpec(
                                 connectAnchor,
                                 this.hostMor,
                                 TestConstants.VM_VIRTUALDEVICE_ETHERNET_PCNET32,
                                 vmName);
                        this.vmMor = new Folder(super.getConnectAnchor()).createVM(
                                 this.ivm.getVMFolder(), vmConfigSpec,
                                 this.ihs.getPoolMor(this.hostMor),
                                 this.hostMor);
                        if (this.vmMor != null) {
                           this.isVMCreated = true;
                           log.info("Successfully created the VM "
                                    + vmName);
                           status = true;
                        } else {
                           log.error("Can not create the VM " + vmName);
                        }
                     } else {
                        log.error("There are no free pnics on the host");
                     }
                  } else {
                     log.error("The network system MOR is null");
                  }
               } else {
                  log.error("There are no free pnics on any of the host in "
                           + "the inventory");
               }
            } else {
               log.error("There are no hosts in the VC inventory");
            }
         } else {
            log.error("The host map is null");
         }
     
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that creates the DVS.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @Test(description = " PR#482571..Verify that VC is able to reclaim "
               + "ports on the host"
               + " which were connected to a VM but are not "
               + "connected anymore after the VM has been "
               + "moved to a new portgroup")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      DVSConfigSpec configSpec = null;
      ManagedObjectReference pgMor = null;
      HostNetworkConfig[] hostNetworkConfig = null;
      DistributedVirtualSwitchHostMemberConfigSpec hostMember = null;
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      DistributedVirtualSwitchProductSpec productSpec = null;
     
         configSpec = new DVSConfigSpec();
         configSpec.setConfigVersion("");
         configSpec.setName(this.getTestId());
         configSpec.setNumStandalonePorts(5);
         hostMember = new DistributedVirtualSwitchHostMemberConfigSpec();
         pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
         pnicBacking.getPnicSpec().clear();
         pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] {}));
         hostMember.setBacking(pnicBacking);
         hostMember.setOperation(TestConstants.CONFIG_SPEC_ADD);
         hostMember.setHost(this.hostMor);
         configSpec.getHost().clear();
         configSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostMember }));
         if (this.hostMor != null
                  && (this.hostVersion.equalsIgnoreCase(VersionConstants.ESX400) || this.hostVersion.equalsIgnoreCase(VersionConstants.EESX400))) {
            log.info("Got " + this.hostVersion + " host");
            log.info("Creating product spec for " + this.hostVersion
                     + " host");
            productSpec = DVSUtil.getProductSpec(connectAnchor,
                     DVSTestConstants.VDS_VERSION_40);
            Assert.assertNotNull(productSpec,
                     "Successfully obtained the productSpec for  "
                              + DVSTestConstants.VDS_VERSION_40 + " version",
                     "Failed to get productSpec for "
                              + DVSTestConstants.VDS_VERSION_40 + " version");
         }
         this.dvsMor = DVSUtil.createDVSFromCreateSpec(connectAnchor,
                  DVSUtil.createDVSCreateSpec(configSpec, productSpec, null));
         if (this.dvsMor != null) {
            log.info("Successfully created the DVS " + this.getTestId());
            if (this.ins.refresh(this.nsMor)) {
               log.info("Refreshed the network system of the host");
               if (this.iDVS.validateDVSConfigSpec(this.dvsMor, configSpec,
                        null)) {
                  log.info("Successfully validated the DVS config spec");
                  dvSwitchUuid = this.iDVS.getConfig(dvsMor).getUuid();
                  hostNetworkConfig = this.iDVS.getHostNetworkConfigMigrateToDVS(
                           this.dvsMor, this.hostMor);
                  if (hostNetworkConfig != null
                           && hostNetworkConfig.length == 2
                           && hostNetworkConfig[0] != null
                           && hostNetworkConfig[1] != null) {
                     log.info("Successfully retrieved the original and the "
                              + "updated network config of the host");
                     this.originalNetworkConfig = hostNetworkConfig[1];
                     status = this.ins.updateNetworkConfig(this.nsMor,
                              hostNetworkConfig[0],
                              TestConstants.CHANGEMODE_MODIFY);
                     if (status) {
                        log.info("Successfully updated the host network config");
                        pgMor = addPg("static-pg-1");
                        this.portgroupKey = this.iDVPG.getKey(pgMor);
                        portKey = this.iDVPG.getPortKeys(pgMor).get(0);
                        assertTrue(performVMOps(connectAnchor, pgMor),
                                 " Failed performVMOps for PG " + "static-pg-1");

                        pgMor = addPg("static-pg-2");
                        assertTrue(performVMOps(connectAnchor, pgMor),
                                 " Failed performVMOps for PG type"
                                          + "static-pg-2");
                        assertTrue(
                                 performOperationsOnhostd(esxhostName),
                                 "PR#482571..Verified VC is able to reclaim ports on the host"
                                          + " which were connected to a VM but are not "
                                          + "connected anymore after the VM has been "
                                          + "moved to a new portgroup",
                                 "VC is unable to reclaim ports on the host "
                                          + "which were connected to a VM but are not "
                                          + "connected anymore after the VM has been "
                                          + "moved to a new portgroup.");
                        status = true;

                     } else {
                        log.error("Can not update the host network config");
                     }
                  } else {
                     log.error("Can not retrieve the original and the updated "
                              + "network config");
                  }
               } else {
                  log.error("The config spec does not match");
               }
            } else {
               log.error("Can not refresh the network system of the host");
            }

         } else {
            log.error("Can not create the DVS " + this.getTestId());
         }
     

      assertTrue(status, "Test Failed");
   }

   private boolean performOperationsOnhostd(String esxHostName)
      throws Exception
   {
      boolean status = false;
      this.hostConnectAnchor = new ConnectAnchor(esxHostName,
               data.getInt(TestConstants.TESTINPUT_PORT));
      if (this.hostConnectAnchor != null) {
         log.info("Successfully obtained the connect"
                  + " anchor to the host");
         UserSession newLoginSession = null;
         AuthorizationManager newAuthentication = null;
         InternalServiceInstance msi = null;
         ManagedObjectReference hostDVSManager = null;
         InternalHostDistributedVirtualSwitchManager iHostDVSManager = null;
         HostDVSPortData[] portData = null;

         ManagedObjectReference newAuthenticationMor = null;
         newAuthentication = new AuthorizationManager(hostConnectAnchor);
         sessionManager = new SessionManager(hostConnectAnchor);
         newAuthenticationMor = sessionManager.getSessionManager();
         if (newAuthenticationMor != null) {
            newLoginSession = sessionManager.login(newAuthenticationMor,
                     TestConstants.ESX_USERNAME, TestConstants.ESX_PASSWORD,
                     null);
            if (newLoginSession != null) {
               msi = new InternalServiceInstance(hostConnectAnchor);
               Assert.assertNotNull(msi, "The service instance is null");
               hostDVSManager = msi.getInternalServiceInstanceContent().getHostDistributedVirtualSwitchManager();
               Assert.assertNotNull(hostDVSManager,
                        "The host DVS manager mor is null");
               iHostDVSManager = new InternalHostDistributedVirtualSwitchManager(
                        hostConnectAnchor);
               portData = iHostDVSManager.fetchPortState(hostDVSManager,
                        this.dvSwitchUuid, new String[] { this.portKey }, null);

               if (portData != null && portData.length > 0) {
                  log.warn("PR#482571..VC is unable to reclaim ports on the host"
                           + "...checking again");
                  status = false;
                  int timeOut = 0;
                  int total_times = 18;
                  while (timeOut <= total_times) {
                      log.info("Wait for a while to see if the port gets reclaimed: " +
                            timeOut + " of " + total_times);
                      ThreadUtil.sleep(180000);
                      portData = iHostDVSManager.fetchPortState(hostDVSManager,
                               this.dvSwitchUuid, new String[] { this.portKey },null);
                      if (portData == null || portData.length == 0) {
                         status = true;
                         break;
                      }
                      timeOut++;
                  }
               } else {
                  status = true;
               }
            } else {
               log.error("Can not login into the host " + esxHostName);
            }
         } else {
            log.error("The session manager object is null");
         }
      } else {
         status = false;
         log.error("Can not obtain the connect " + "anchor to the host");
      }

      return status;
   }

   /**
    * Method to add portgroup
    * 
    * @param type portgroup type
    * @return ManagedObjectReference portgroup mor
    */
   private ManagedObjectReference addPg(String name)
      throws Exception
   {
      DVPortgroupConfigSpec pgConfigSpec = new DVPortgroupConfigSpec();
      List<ManagedObjectReference> pgList = null;
      pgConfigSpec.setName(name);
      pgConfigSpec.setType(early);
      pgConfigSpec.setNumPorts(1);
      pgList = this.iDVS.addPortGroups(this.dvsMor,
               new DVPortgroupConfigSpec[] { pgConfigSpec });
      assertTrue((pgList != null && pgList.size() == 1),
               "Successfully added the " + name + " portgroup to the DVS ",
               " Failed to add " + name + "portgroup");
      return pgList.get(0);
   }

   /**
    * This method is used to reconfigVM and verifyPowerOps.
    * 
    * @param connectAnchor ConnectAnchor object
    * @param pgMor
    * @return boolean
    */
   private boolean performVMOps(ConnectAnchor connectAnchor,
                                ManagedObjectReference pgMor)
      throws Exception
   {
      DistributedVirtualSwitchPortConnection portConnection = null;
      Assert.assertNotNull(portgroupKey, "The port group key is null");
      portConnection = new DistributedVirtualSwitchPortConnection();
      portConnection.setSwitchUuid(this.iDVS.getConfig(this.dvsMor).getUuid());
      portConnection.setPortgroupKey(this.iDVPG.getKey(pgMor));
      Assert.assertNotNull(portConnection,
               "Can not get a valid port connection object");
      if (this.originalVMConfigSpec == null) {
         this.originalVMConfigSpec = reconfigVM(portConnection, connectAnchor);
         Assert.assertNotNull(this.originalVMConfigSpec,
                  "Can not reconfigure the VM to "
                           + "connect to the late binding porgroup");
      } else {
         Assert.assertNotNull(reconfigVM(portConnection, connectAnchor),
                  "Can not reconfigure the VM to "
                           + "connect to the late binding porgroup");
      }

      assertTrue((this.ivm.verifyPowerOps(this.vmMor, false)),
               "Successfully verified the power " + "ops of the VM",
               "Can not verify the power ops for " + "the VM");
      return true;
   }

   /**
    * Method to restore the state as it was before the test is started.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Override
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
               }
            } else {
               log.error("Can not power off the VM");
               status &= false;
            }
         }
         if (this.originalNetworkConfig != null) {
            log.info("Restoring the network setting of the host");
            status &= this.ins.updateNetworkConfig(this.nsMor,
                     this.originalNetworkConfig,
                     TestConstants.CHANGEMODE_MODIFY);
         }
         if (this.dvsMor != null) {
            status &= this.iDVS.destroy(this.dvsMor);
         }
     
      assertTrue(status, "Cleanup failed");
      return status;
   }

   /**
    * This method is used to reconfigVM .
    * 
    * @param portConnection
    * @param connectAnchor ConnectAnchor object
    * @return VirtualMachineConfigSpec
    */
   private VirtualMachineConfigSpec reconfigVM(DistributedVirtualSwitchPortConnection portConnection,
                                               ConnectAnchor connectAnchor)
      throws Exception
   {
      VirtualMachineConfigSpec[] vmConfigSpec = null;
      VirtualMachineConfigSpec originalVMConfigSpec = null;
      vmConfigSpec = DVSUtil.getVMConfigSpecForDVSPort(this.vmMor,
               connectAnchor,
               new DistributedVirtualSwitchPortConnection[] { portConnection });
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
}
