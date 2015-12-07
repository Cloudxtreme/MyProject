/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.merge;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.Map;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortSetting;
import com.vmware.vc.DVPortgroupConfigInfo;
import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMember;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.HostIpConfig;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.HostNetworkInfo;
import com.vmware.vc.HostProxySwitchConfig;
import com.vmware.vc.HostVirtualNic;
import com.vmware.vc.HostVirtualNicSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.host.NetworkSystem;

/**
 * Create a dvswitch( destination) with one standalone host connected to it and
 * another dvswitch (source) with another standalone host connected to it with
 * the host vmknic connected to a DVPortgroup
 */
public class Pos035 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference rootFolderMor = null;
   private ManagedObjectReference destDvsMor = null;
   private ManagedObjectReference srcDvsMor = null;
   private DistributedVirtualSwitch iDVSwitch = null;
   private HostSystem iHostSystem = null;
   private NetworkSystem iNetworkSystem = null;

   private ManagedObjectReference destnDvsHostMor = null;
   private ManagedObjectReference srcDvsHostMor = null;
   private ManagedObjectReference firstNetworkMor = null;
   private ManagedObjectReference secondNetworkMor = null;
   private ManagedObjectReference srcfolder = null;
   private ManagedObjectReference destfolder = null;

   private HostNetworkConfig[][] hostNetworkConfig = null;
   private DistributedVirtualSwitchHostMemberConfigSpec hostConfigSpecElement = null;
   private DVSConfigSpec dvsConfigSpec = null;
   private Vector<ManagedObjectReference> hosts = null;
   private DistributedVirtualSwitchHostMember[] srcHostMembers = null;
   private int srcMaxPorts = 0;
   private int destnMaxPorts = 0;
   private String srcDVSName = null;
   private DVPortSetting[] srcPortSetting = null;

   private DVPortgroupConfigInfo[] srcPortgroups = null;

   private String scVNicId = null;

   /**
    * Sets the test description.
    *
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      setTestDescription("Create a dvswitch( destination) with one standalone "
               + "host connected to it and another dvswitch (source) with another "
               + "standalone host connected to it with the host vmknic connected to "
               + "a DVPortgroup");
   }

   /**
    * Method to setup the environment for the test. This method creates a
    * distributed virtual switch.
    *
    * @param connectAnchor ConnectAnchor object
    * @return boolean true if successful, false otherwise.
    */
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean destDvsConfigured = false;
      boolean srcDvsConfigured = false;
      final String dvsName = DVSTestConstants.DVS_CREATE_NAME_PREFIX
               + getTestId();
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      log.info("Test setup Begin:");

         this.iFolder = new Folder(connectAnchor);
         this.iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
         this.iHostSystem = new HostSystem(connectAnchor);
         this.iManagedEntity = new ManagedEntity(connectAnchor);
         this.iNetworkSystem = new NetworkSystem(connectAnchor);
         hosts = this.iHostSystem.getAllHost();
         if (hosts != null && hosts.size() >= 2) {
            log.info("Found two hosts");
            this.destnDvsHostMor = hosts.get(0);
            this.srcDvsHostMor = hosts.get(1);
            if (this.destnDvsHostMor != null && this.srcDvsHostMor != null) {
               this.rootFolderMor = this.iFolder.getRootFolder();
               if (this.rootFolderMor != null) {
                  // create the dvs spec
                  this.dvsConfigSpec = new DVSConfigSpec();
                  this.dvsConfigSpec.setConfigVersion("");
                  this.dvsConfigSpec.setName(dvsName + ".1");
                  hostConfigSpecElement = new DistributedVirtualSwitchHostMemberConfigSpec();
                  hostConfigSpecElement.setHost(this.destnDvsHostMor);
                  hostConfigSpecElement.setOperation(TestConstants.CONFIG_SPEC_ADD);
                  pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
                  pnicBacking.getPnicSpec().clear();
                  pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] {}));
                  hostConfigSpecElement.setBacking(pnicBacking);
                  this.dvsConfigSpec.getHost().clear();
                  this.dvsConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostConfigSpecElement }));
                  ManagedObjectReference networkFolder = this.iFolder.getNetworkFolder(this.iFolder.getDataCenter());
                  this.destfolder = iFolder.createFolder(networkFolder,
                           this.getTestId() + "-destFolder");
                  // create the destn dvs
                  this.destDvsMor = this.iFolder.createDistributedVirtualSwitch(
                           this.destfolder, dvsConfigSpec);
                  // get the max ports
                  this.destnMaxPorts = this.iDVSwitch.getConfig(this.destDvsMor).getMaxPorts();

                  if (this.destDvsMor != null) {
                     log.info("Successfully created the " + "dvswitch");
                     hostNetworkConfig = new HostNetworkConfig[2][2];
                     hostNetworkConfig[0] = this.iDVSwitch.getHostNetworkConfigMigrateToDVS(
                              this.destDvsMor, this.destnDvsHostMor);
                     this.firstNetworkMor = this.iNetworkSystem.getNetworkSystem(this.destnDvsHostMor);
                     if (this.firstNetworkMor != null) {
                        if (this.iNetworkSystem.updateNetworkConfig(
                                 this.firstNetworkMor, hostNetworkConfig[0][0],
                                 TestConstants.CHANGEMODE_MODIFY)) {
                           destDvsConfigured = true;
                        } else {
                           log.error("Update network config " + "failed");
                        }
                     } else {
                        log.error("Network config null");
                     }
                     hostConfigSpecElement.setHost(this.srcDvsHostMor);
                     this.dvsConfigSpec = new DVSConfigSpec();
                     this.dvsConfigSpec.getHost().clear();
                     this.dvsConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostConfigSpecElement }));
                     this.srcDVSName = dvsName + ".2";
                     this.dvsConfigSpec.setName(this.srcDVSName);
                     this.srcfolder = iFolder.createFolder(networkFolder,
                              this.getTestId() + "-srcFolder");

                     // create the src dvs
                     this.srcDvsMor = this.iFolder.createDistributedVirtualSwitch(
                              srcfolder, dvsConfigSpec);
                     if (this.srcDvsMor != null) {
                        log.info("Successfully created the "
                                 + "second distributed virtual switch");
                        hostNetworkConfig[1] = this.iDVSwitch.getHostNetworkConfigMigrateToDVS(
                                 this.srcDvsMor, this.srcDvsHostMor);
                        this.secondNetworkMor = this.iNetworkSystem.getNetworkSystem(this.srcDvsHostMor);
                        if (this.secondNetworkMor != null) {
                           this.iNetworkSystem.updateNetworkConfig(
                                    this.secondNetworkMor,
                                    hostNetworkConfig[1][0],
                                    TestConstants.CHANGEMODE_MODIFY);
                           DVSConfigInfo srcDvsConfigInfo = this.iDVSwitch.getConfig(this.srcDvsMor);
                           this.srcHostMembers = com.vmware.vcqa.util.TestUtil.vectorToArray(srcDvsConfigInfo.getHost(), com.vmware.vc.DistributedVirtualSwitchHostMember.class);
                           // get the max ports
                           this.srcMaxPorts = this.iDVSwitch.getConfig(
                                    this.srcDvsMor).getMaxPorts();
                           /*create the portgroup, set the vm to connect
                             to pg
                           */
                           srcDvsConfigured = configureSrcDvs(connectAnchor);
                        } else {
                           log.error("Network config null");
                        }
                     }
                  }
               }
            }
         }

      return (destDvsConfigured && srcDvsConfigured);
   }

   /**
    * Method that merges two distributed virtual switches, each containing one
    * host with two uplink portgroups on each switch with the same name
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Create a dvswitch( destination) with one standalone "
               + "host connected to it and another dvswitch (source) with another "
               + "standalone host connected to it with the host vmknic connected to "
               + "a DVPortgroup")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;

         if (this.iDVSwitch.merge(destDvsMor, srcDvsMor)) {
            log.info("Successfully merged the two switches");
            if (this.iNetworkSystem.refresh(this.secondNetworkMor)) {
               log.info("Succesfully refresh the network system of the host");
               if (this.iDVSwitch.validateMergedMaxPorts(srcMaxPorts,
                        destnMaxPorts, this.destDvsMor)) {
                  log.info("Hosts max ports verified");
                  if (this.iDVSwitch.validateMergeHostsJoin(
                           this.srcHostMembers, this.destDvsMor)) {
                     log.info("Hosts join on merge verified");
                     if (this.iDVSwitch.validateMergePortgroups(
                              this.srcPortgroups, this.srcPortSetting,
                              this.srcDVSName, this.destDvsMor)) {
                        status = true;
                     } else {
                        log.info("Portgroup verification failed");
                     }
                  } else {
                     log.info("Hosts join on merge verification "
                              + "failed");
                  }
               } else {
                  log.info("Max ports verification failed");
               }
            } else {
               log.error("Can not refresh the network system of the host");
            }
         } else {
            log.error("Failed to merge the two switches");
         }

      assertTrue(status, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test was started. Restore
    * the original state of the VM. Destroy the portgroup, followed by the
    * distributed virtual switch
    *
    * @param connectAnchor ConnectAnchor object
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;

         /*
          * Restore the original network config
          */
         status = this.iNetworkSystem.updateNetworkConfig(this.firstNetworkMor,
                  hostNetworkConfig[0][1], TestConstants.CHANGEMODE_MODIFY);
         HostProxySwitchConfig config = this.iDVSwitch.getDVSVswitchProxyOnHost(
                  this.destDvsMor, this.srcDvsHostMor);
         config.setSpec(com.vmware.vcqa.util.TestUtil.vectorToArray(hostNetworkConfig[1][1].getProxySwitch(), com.vmware.vc.HostProxySwitchConfig.class)[0].getSpec());
         hostNetworkConfig[1][1].getProxySwitch().clear();
         hostNetworkConfig[1][1].getProxySwitch().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new HostProxySwitchConfig[] { config }));
         status &= this.iNetworkSystem.updateNetworkConfig(
                  this.secondNetworkMor, hostNetworkConfig[1][1],
                  TestConstants.CHANGEMODE_MODIFY);
         // restore the vm's state
         status &= cleanUpVmkernelNic(connectAnchor);
         // check if src dvs exists
         if (this.iManagedEntity.isExists(this.srcDvsMor)) {
            // check if able to destroy it
            status &= this.iManagedEntity.destroy(this.srcDvsMor);
         }
         // check if destn dvs exists
         if (this.iManagedEntity.isExists(this.destDvsMor)) {
            // destroy the destn
            status &= this.iManagedEntity.destroy(this.destDvsMor);
         }
         if (this.srcfolder != null) {
            status &= this.iFolder.destroy(this.srcfolder);
         }
         if (this.destfolder != null) {
            status &= this.iFolder.destroy(this.destfolder);
         }

      return status;
   }

   private boolean cleanUpVmkernelNic(ConnectAnchor connectAnchor)
      throws Exception
   {
      boolean status = false;
      if (scVNicId != null
               && iNetworkSystem.removeVirtualNic(this.secondNetworkMor,
                        scVNicId)) {
         log.info("Successfully removed the service console Virtual NIC "
                  + this.scVNicId);
         status = true;
      } else {
         log.error("Unable to remove the service console Virtual NIC "
                  + this.scVNicId);
      }
      return status;
   }

   private boolean configureSrcDvs(ConnectAnchor connectAnchor)
      throws Exception
   {
      boolean status = false;
      String portgroupKey = iDVSwitch.addPortGroup(this.srcDvsMor,
               DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING, 1,
               "DVPORTGROUP-SRC");
      Map<String, Object> portgroupInfo = null;
      if (portgroupKey != null) {
         log.info("Successfully get the standalone DVPortgroup");
         DVSConfigInfo info = iDVSwitch.getConfig(this.srcDvsMor);
         String dvSwitchUuid = info.getUuid();
         // create the DistributedVirtualSwitchPortConnection object.
         DistributedVirtualSwitchPortConnection dvsPortConnection = buildDistributedVirtualSwitchPortConnection(
                  dvSwitchUuid, null, portgroupKey);
         scVNicId = addVnic(this.srcDvsHostMor, dvsPortConnection);
         if (scVNicId != null) {
            log.info("Successfully added the vm kernel NIC " + scVNicId);
            this.srcPortgroups = new DVPortgroupConfigInfo[1];
            // get the portgroups
            portgroupInfo = this.iDVSwitch.getPortgroupList(this.srcDvsMor);
            if (portgroupInfo != null) {
               this.srcPortgroups = (DVPortgroupConfigInfo[]) portgroupInfo.get(DVSTestConstants.PORT_GROUP_CONFIG_KEY);
               this.srcPortSetting = (DVPortSetting[]) portgroupInfo.get(DVSTestConstants.PORT_GROUP_SETTING_KEY);
            }
            status = true;
         } else {
            log.error("Unable to add the vmkernel NIC");
         }
      } else {
         log.error("Failed to get the standalone DVPortkeys ");
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }

   /**
    * Configures the src DVS. Setup a vmkernel nic on a DVPort
    *
    * @throws MethodFault,Exception
    */
   private String addVnic(ManagedObjectReference aHostMor,
                          DistributedVirtualSwitchPortConnection portConnection)
      throws Exception
   {
      String device = null;
      HostVirtualNicSpec hostVnicSpec = null; // use to create VNIC.
      String vnicId = null;
      ManagedObjectReference nsMor = null;// Network System of give host.
      HostNetworkInfo networkInfo = null;
      DistributedVirtualSwitchPortConnection newConn = null;
      try {
         hostVnicSpec = buildVnicSpec(portConnection, aHostMor);
         nsMor = iNetworkSystem.getNetworkSystem(aHostMor);
         vnicId = iNetworkSystem.addVirtualNic(nsMor, "", hostVnicSpec);
         if (vnicId != null) {
            log.info("Successfully added the virtual Nic.");
            networkInfo = iNetworkSystem.getNetworkInfo(nsMor);
            if (networkInfo != null) {
               HostVirtualNic[] vNics = com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getVnic(), com.vmware.vc.HostVirtualNic.class);
               if (vNics != null) {
                  for (HostVirtualNic vnic : vNics) {
                     log.info("Vnic Key: " + vnic.getKey());
                     log.info("Vnic Device: " + vnic.getDevice());
                     if (vnic.getSpec() != null) {
                        newConn = vnic.getSpec().getDistributedVirtualPort();
                        if (newConn != null
                                 && TestUtil.compareObject(portConnection,
                                          newConn,
                                          TestUtil.getIgnorePropertyList(
                                                   portConnection, false))) {
                           device = vnic.getDevice();
                        } else {
                           log.error("Failed to match the PortConnections");
                        }
                     } else {
                        log.error("Failed to get the HostVirtualNicSpec.");
                     }
                  }
               } else {
                  log.error("Failed to get the HostVirtualnic.");
               }
            } else {
               log.error("There are no vnics on the host");
            }
         } else {
            log.error("Failed to add the virtula Nic.");
         }
      } catch (Exception e) {
      }
      return device;
   }

   private HostVirtualNicSpec buildVnicSpec(DistributedVirtualSwitchPortConnection portConnection,
                                            ManagedObjectReference hostMor)
      throws Exception
   {
      HostVirtualNicSpec hostVNicSpec = null;
      HostVirtualNicSpec vnicSpec = null;
      HostNetworkInfo networkInfo = this.iNetworkSystem.getNetworkInfo(this.iNetworkSystem.getNetworkSystem(hostMor));
      if (iHostSystem.isEesxHost(hostMor)) {
         if (networkInfo != null && com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getVnic(), com.vmware.vc.HostVirtualNic.class) != null
                  && com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getVnic(), com.vmware.vc.HostVirtualNic.class)[0] != null
                  && com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getVnic(), com.vmware.vc.HostVirtualNic.class)[0].getSpec() != null) {
            vnicSpec = com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getVnic(), com.vmware.vc.HostVirtualNic.class)[0].getSpec();
            hostVNicSpec = buildVnicSpec(
                     portConnection,
                     TestUtil.getAlternateServiceConsoleIP(this.iHostSystem.getIPAddress(hostMor)),
                     vnicSpec.getIp().getSubnetMask(), false);
         }
      } else {
         if (networkInfo != null && com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getConsoleVnic(), com.vmware.vc.HostVirtualNic.class) != null
                  && com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getConsoleVnic(), com.vmware.vc.HostVirtualNic.class)[0] != null
                  && com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getConsoleVnic(), com.vmware.vc.HostVirtualNic.class)[0].getSpec() != null) {
            vnicSpec = com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getConsoleVnic(), com.vmware.vc.HostVirtualNic.class)[0].getSpec();
            hostVNicSpec = buildVnicSpec(
                     portConnection,
                     TestUtil.getAlternateServiceConsoleIP(this.iHostSystem.getIPAddress(hostMor)),
                     vnicSpec.getIp().getSubnetMask(), false);
         }
      }
      String ipAddress = TestUtil.getAlternateServiceConsoleIP(
               this.iHostSystem.getIPAddress(hostMor));
      if(ipAddress != null){
         hostVNicSpec = buildVnicSpec(portConnection,ipAddress,
                  vnicSpec.getIp().getSubnetMask(), false);
      }else{
         hostVNicSpec = buildVnicSpec(portConnection,null,null,true);
      }
      return hostVNicSpec;
   }

   /**
    * Create the DVPortconnection object and set the values.
    *
    * @param switchUuid DVS switch uuid.
    * @param portKey Key of the given port.
    * @param portgroupKey Key of the portgroup.
    * @return connection DistributedVirtualSwitchPortConnection.
    */
   private DistributedVirtualSwitchPortConnection buildDistributedVirtualSwitchPortConnection(String switchUuid,
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
    * Create HostVirtualNicSpec Object and set the values.
    *
    * @param portConnection DistributedVirtualSwitchPortConnection
    * @param ipAddress IPAddress
    * @param subnetMask subnetMask
    * @param dhcp boolean
    * @return HostVirtualNicSpec
    * @throws MethodFault, Exception
    */
   public HostVirtualNicSpec buildVnicSpec(DistributedVirtualSwitchPortConnection portConnection,
                                           String ipAddress,
                                           String subnetMask,
                                           boolean dhcp)
      throws Exception
   {
      HostVirtualNicSpec spec = new HostVirtualNicSpec();
      spec.setDistributedVirtualPort(portConnection);
      HostIpConfig ip = new HostIpConfig();
      ip.setDhcp(dhcp);
      ip.setIpAddress(ipAddress);
      ip.setSubnetMask(subnetMask);
      spec.setIp(ip);
      return spec;
   }
}
