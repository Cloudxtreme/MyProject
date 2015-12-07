/*
 * ************************************************************************
 *
 * Copyright 2009 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.functional;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import ch.ethz.ssh2.Connection;

import com.vmware.vc.DVPortSetting;
import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DVSVendorSpecificConfig;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.DistributedVirtualSwitchKeyedOpaqueBlob;
import com.vmware.vc.DistributedVirtualSwitchProductSpec;
import com.vmware.vc.HostConnectSpec;
import com.vmware.vc.HostDVPortgroupConfigSpec;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.HostProxySwitchConfig;
import com.vmware.vc.HostSystemConnectionState;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.UserSession;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.internal.vim.InternalServiceInstance;
import com.vmware.vcqa.internal.vim.dvs.InternalHostDistributedVirtualSwitchManager;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.SSHUtil;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.util.VersionConstants;
import com.vmware.vcqa.vim.AuthorizationManager;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.SessionManager;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchHelper;
import com.vmware.vcqa.vim.host.HostSystemInformation;
import com.vmware.vcqa.vim.host.NetworkSystem;

/**
 * PR#489924 : test case
 */
public class Pos053 extends TestBase
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
   private VirtualMachinePowerState originalVMState = null;
   private boolean isVMCreated = false;
   private String hostVersion = null;
   private String early = DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING;
   private String ephemeral = DVSTestConstants.DVPORTGROUP_TYPE_EPHEMERAL;
   private ConnectAnchor hostConnectAnchor = null;
   private String dvSwitchUuid = null;
   private ManagedObjectReference pgMor = null;
   private ManagedObjectReference pgMor1 = null;
   private String portgroupKey = null;
   private String portgroupKey1 = null;
   private Connection conn = null;
   private DVPortgroupConfigSpec origSpec1 = null;
   private DVPortgroupConfigSpec origSpec2 = null;
   private String hostName;
   private HostConnectSpec hostConnectSpec = null;

   /**
    * Method to add portgroup
    *
    * @param type portgroup type
    * @return ManagedObjectReference portgroup mor
    */
   private ManagedObjectReference addPg(String type,
                                        String name)
      throws Exception
   {
      DVPortgroupConfigSpec pgConfigSpec = new DVPortgroupConfigSpec();
      List<ManagedObjectReference> pgList = null;
      pgConfigSpec.setName(name);
      pgConfigSpec.setType(type);
      pgConfigSpec.setNumPorts(1);
      pgList = this.iDVS.addPortGroups(this.dvsMor,
               new DVPortgroupConfigSpec[] { pgConfigSpec });
      assertTrue((pgList != null && pgList.size() == 1),
               "Successfully added the " + type + " portgroup to the DVS "
                        + this.getTestId() + type, " Failed to add " + type
                        + "portgroup");
      return pgList.get(0);
   }

   private boolean performOperationsOnhostd(String esxHostName,
                                            String portgroupKey,
                                            String portgroupKey1,
                                            DVPortgroupConfigSpec origSpec1,
                                            DVPortgroupConfigSpec origSpec2)
      throws Exception
   {
      boolean status = true;
      DVPortSetting portSetting = null;
      String name = null;
      int timeout = TestConstants.MAX_WAIT_CONNECT_TIMEOUT;

      HostDVPortgroupConfigSpec deltaSpec = null;
      DVPortgroupConfigSpec dvPortgroupConfigSpec = null;
      int origPgs = -1;
      String configVersion = this.iDVPG.getConfigSpec(this.pgMor).getConfigVersion();
      hostConnectAnchor = new ConnectAnchor(esxHostName,
               data.getInt(TestConstants.TESTINPUT_PORT));
      if (this.hostConnectAnchor != null) {
         log.info("Successfully obtained the connect"
                  + " anchor to the host");
         UserSession newLoginSession = null;
         AuthorizationManager newAuthentication = null;
         InternalServiceInstance msi = null;
         ManagedObjectReference hostDVSManager = null;
         InternalHostDistributedVirtualSwitchManager iHostDVSManager = null;
         String[] hostDVSUpdateDVPortgroupKeys = null;
         Map<String, Object> settingsMap = null;

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
               HostDVPortgroupConfigSpec[] pgSpecs = iHostDVSManager.retrieveDVPortgroupConfigSpec(
                        hostDVSManager, this.dvSwitchUuid, null);
               HostDVPortgroupConfigSpec[] pgSpecs0 = iHostDVSManager.retrieveDVPortgroupConfigSpec(
                        hostDVSManager, this.dvSwitchUuid,
                        new String[] { this.portgroupKey });

               HostDVPortgroupConfigSpec[] pgSpecs1 = iHostDVSManager.retrieveDVPortgroupConfigSpec(
                        hostDVSManager, this.dvSwitchUuid,
                        new String[] { this.portgroupKey1 });
               origPgs = pgSpecs.length;
               hostDVSUpdateDVPortgroupKeys = iHostDVSManager.retrieveDVPortgroups(
                        hostDVSManager, this.dvSwitchUuid);
               for (String hostDVPGKey : hostDVSUpdateDVPortgroupKeys) {
                  if (this.portgroupKey.equals(hostDVPGKey)) {
                     HostDVPortgroupConfigSpec[] specs = iHostDVSManager.retrieveDVPortgroupConfigSpec(
                              hostDVSManager, this.dvSwitchUuid,
                              new String[] { hostDVPGKey });
                     if (specs != null && specs.length == 1) {

                        deltaSpec = new HostDVPortgroupConfigSpec();
                        dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
                        dvPortgroupConfigSpec.setConfigVersion(configVersion);
                        dvPortgroupConfigSpec.setDescription(DVSTestConstants.DVPORTGROUP_VALID_DESCRIPTION);
                        name = "this.getTestId()" + "ON HOSTD";
                        dvPortgroupConfigSpec.setName(name);
                        dvPortgroupConfigSpec.setNumPorts(200);
                        deltaSpec.setSpecification(dvPortgroupConfigSpec);
                        deltaSpec.setOperation(TestConstants.CONFIG_SPEC_EDIT);
                        deltaSpec.setKey(hostDVPGKey);
                        deltaSpec.setSpecification(dvPortgroupConfigSpec);

                        DVSVendorSpecificConfig vendorSpecificConfig = DVSUtil.getVendorSpecificConfig(null);
                        DistributedVirtualSwitchKeyedOpaqueBlob[] vendor = new DistributedVirtualSwitchKeyedOpaqueBlob[2];
                        vendor[0] = new DistributedVirtualSwitchKeyedOpaqueBlob();
                        vendor[0].setKey("1");
                        vendor[0].setOpaqueData("vendor1");
                        vendor[1] = new DistributedVirtualSwitchKeyedOpaqueBlob();
                        vendor[1].setKey("2");
                        vendor[1].setOpaqueData("vendor2");
                        vendorSpecificConfig.getKeyValue().clear();
                        vendorSpecificConfig.getKeyValue().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(vendor));
                        settingsMap = new HashMap<String, Object>();
                        portSetting = DVSUtil.getDefaultPortSetting(
                                 settingsMap, null);
                        portSetting.setVendorSpecificConfig(vendorSpecificConfig);
                        dvPortgroupConfigSpec.setDefaultPortConfig(portSetting);

                        if (iHostDVSManager.updateDVPortGroups(hostDVSManager,
                                 dvSwitchUuid,
                                 new HostDVPortgroupConfigSpec[] { deltaSpec })) {
                           log.info("Successfully reconfigured the portgroup");

                           boolean updated = true;
                           if (updated) {
                              pgSpecs = iHostDVSManager.retrieveDVPortgroupConfigSpec(
                                       hostDVSManager, this.dvSwitchUuid,
                                       new String[] { hostDVPGKey });
                              if (pgSpecs != null && pgSpecs.length == 1) {
                                 HostDVPortgroupConfigSpec pgSpec = pgSpecs[0];
                                 DVPortgroupConfigSpec updatedSpec = pgSpec.getSpecification();
                                 if (updatedSpec.getName().equals(name)) {
                                    updated = true;

                                 }
                              }

                           } else {
                              log.error("Failed to reconfigure the portgroup");
                           }

                        }

                     }

                  } else {
                     continue;
                  }

               }
               /*
                * Create one pg here
                */

               deltaSpec = new HostDVPortgroupConfigSpec();
               DVPortgroupConfigSpec pgConfigSpec = new DVPortgroupConfigSpec();
               pgConfigSpec.setName(name);
               pgConfigSpec.setType(ephemeral);
               pgConfigSpec.setNumPorts(1);
               pgConfigSpec.setPolicy(null);
               pgConfigSpec.setConfigVersion("");
               com.vmware.vc.DVPortgroupPolicy policy1 = new com.vmware.vc.DVPortgroupPolicy();
               policy1.setLivePortMovingAllowed(false);
               pgConfigSpec.setPolicy(policy1);
               deltaSpec.setSpecification(pgConfigSpec);
               deltaSpec.setOperation(TestConstants.CONFIG_SPEC_ADD);
               deltaSpec.setKey("mykey");

               if (iHostDVSManager.updateDVPortGroups(hostDVSManager,
                        dvSwitchUuid,
                        new HostDVPortgroupConfigSpec[] { deltaSpec })) {
                  log.info("Successfully add the portgroup");

               }

               /*
                * remove Pg
                */
               deltaSpec = new HostDVPortgroupConfigSpec();
               deltaSpec.setKey(this.portgroupKey1);
               deltaSpec.setOperation(TestConstants.CONFIG_SPEC_REMOVE);
               if (iHostDVSManager.updateDVPortGroups(hostDVSManager,
                        dvSwitchUuid,
                        new HostDVPortgroupConfigSpec[] { deltaSpec })) {
                  log.info("Successfully deleted  the portgroup");
               }

               if (!this.ihs.isHostConnected(this.hostMor)) {
                  if (this.hostMor != null
                           && !this.ihs.isHostConnected(this.hostMor)) {
                     Assert.assertTrue(this.ihs.reconnectHost(hostMor,
                              this.hostConnectSpec, null), " Host not connected");
                  }
                  if (this.ihs.isHostConnected(this.hostMor)) {
                     Thread.sleep(1500);
                     log.info("Successfully connected the host back to the "
                              + "VC " + ihs.getHostName(hostMor));
                     /*
                      * verify pg specs
                      */
                     pgSpecs =
                              iHostDVSManager.retrieveDVPortgroupConfigSpec(
                                       hostDVSManager, this.dvSwitchUuid, null);
                     if (pgSpecs.length == origPgs) {
                        pgSpecs =
                                 iHostDVSManager.retrieveDVPortgroupConfigSpec(
                                          hostDVSManager, this.dvSwitchUuid,
                                          new String[] { this.portgroupKey });
                        log
                                 .info(" Comparing DVPortgroupConfigSpe after HostConnected to VC ");
                        assertTrue(TestUtil.compareObject(pgSpecs[0],
                                 pgSpecs0[0], TestUtil.getIgnorePropertyList(
                                          pgSpecs0[0], false)),
                                 " Successfully compared DVPortgroupConfigSpec : "
                                          + portgroupKey,
                                 "Failed verify DVPortgroupConfigSpecs");

                        pgSpecs =
                                 iHostDVSManager.retrieveDVPortgroupConfigSpec(
                                          hostDVSManager, this.dvSwitchUuid,
                                          new String[] { portgroupKey1 });

                        assertTrue(TestUtil.compareObject(pgSpecs[0],
                                 pgSpecs1[0], TestUtil.getIgnorePropertyList(
                                          pgSpecs1[0], false)),
                                 " Successfully compared DVPortgroupConfigSpec : "
                                          + portgroupKey1,
                                 "Failed verify DVPortgroupConfigSpecs");

                     }
                  }
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
    * Method that creates the DVS.
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @Test(description = "PR#489924 : "
               + "1. create a dvs and 2 dvpgs and join 1 host\n"
               + "2. Disconnect the host from VC\n"
               + "3. connect to the host and invoke the HostDvsManager"
               + " API to do the following\n"
               + "    a. change the name of the dvpg1\n"
               + "    b. delete the dvpg2\n" + "    c. create a bogus dvpg\n3"
               + "4. Reconnect the host and wait in a loop and read the"
               + " dvpg info from host HostDvsManager every 10 sec.\n"
               + "   when all of below become true, exit the loop:\n"
               + "    a. dvpg1 name is reverted\n"
               + "    b. dvpg2 is restored\n" + "    c. dvpg3 is deleted\n"
               + "")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      DVSConfigSpec configSpec = null;
      HostNetworkConfig[] hostNetworkConfig = null;
      DistributedVirtualSwitchHostMemberConfigSpec hostMember = null;
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      DistributedVirtualSwitchProductSpec productSpec = null;
      int timeout = TestConstants.MAX_WAIT_CONNECT_TIMEOUT;

         configSpec = new DVSConfigSpec();
         configSpec.setConfigVersion("");
         configSpec.setName(this.getTestId() + 1);
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
                  && (hostVersion.equalsIgnoreCase(VersionConstants.ESX400) || hostVersion.equalsIgnoreCase(VersionConstants.EESX400))) {
            log.info("Got " + hostVersion + " host");
            log.info("Creating product spec for " + hostVersion
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
            hostName = this.ihs.getHostName(hostMor);

            if (this.ins.refresh(this.nsMor)) {
               log.info("Refreshed the network system of the host");
               if (this.iDVS.validateDVSConfigSpec(this.dvsMor, configSpec,
                        null)) {
                  log.info("Successfully validated the DVS config spec");
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
                        pgMor = addPg(ephemeral, ephemeral + "_1");
                        origSpec1 = this.iDVPG.getConfigSpec(this.pgMor);
                        Assert.assertNotNull(pgMor, "Failed to add portgroup "
                                 + early);
                        this.portgroupKey = this.iDVPG.getKey(pgMor);
                        log.info("portgroupKey " + portgroupKey);

                        pgMor1 = addPg(ephemeral, ephemeral + "_2");
                        origSpec2 = this.iDVPG.getConfigSpec(this.pgMor1);
                        Assert.assertNotNull(pgMor1, "Failed to add portgroup "
                                 + ephemeral);
                        this.portgroupKey1 = this.iDVPG.getKey(pgMor1);
                        log.info("portgroupKey " + portgroupKey1);
                        HostProxySwitchConfig originalHostProxySwitchConfig = this.iDVS.getDVSVswitchProxyOnHost(
                                 dvsMor, hostMor);

                        dvSwitchUuid = originalHostProxySwitchConfig.getUuid();
                     if (status && this.ihs.isHostConnected(this.hostMor)
                              && this.ihs.disconnectHost(hostMor)) {
                        status =
                                 performOperationsOnhostd(hostName,
                                          portgroupKey, portgroupKey1,
                                          origSpec1, origSpec2);
                     } else {
                        status = false;
                        log.error("Can not execute the remote command on the"
                                 + " host " + this.hostName);
                     }

                     } else {
                        status = false;
                        log.error("Can not update the host network config");
                     }
                  } else {
                     status = false;
                     log.error("Can not retrieve the original and the updated "
                              + "network config");
                  }
               } else {
                  status = false;
                  log.error("The config spec does not match");
               }
            } else {
               status = false;
               log.error("Can not refresh the network system of the host");
            }

         } else {
            status = false;
            log.error("Can not create the DVS " + this.getTestId());
         }


      assertTrue(status, "Test Failed");
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

         if (this.isVMCreated) {
            log.info("Destroying the created VM");
            status &= this.ivm.destroy(this.vmMor);
         } else if (this.originalVMState != null) {
            log.info("Restoring the VM to its original power state.");
            status &= this.ivm.setVMState(this.vmMor, this.originalVMState,
                     false);
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

      return status;
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
      Iterator<ManagedObjectReference> it = null;
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
                  hostVersion = this.ihs.getHostProductIdVersion(this.hostMor);
                  hostConnectSpec = this.ihs.getHostConnectSpec(this.hostMor);
                  log.info("Found a host with free pnics in the inventory");
                  this.nsMor = this.ins.getNetworkSystem(this.hostMor);
                  if (this.nsMor != null) {
                     pnicIds = this.ins.getPNicIds(this.hostMor);
                     if (pnicIds != null) {
                        status = true;
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

      assertTrue(status, "Cleanup failed");
      assertTrue(status, "Setup failed");
      return status;
   }
}