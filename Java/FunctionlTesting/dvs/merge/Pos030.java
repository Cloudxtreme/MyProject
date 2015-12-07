/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.merge;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.List;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortConfigSpec;
import com.vmware.vc.DVPortSetting;
import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualPort;
import com.vmware.vc.DistributedVirtualSwitchHostMember;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.DistributedVirtualSwitchPortCriteria;
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
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.NetworkSystem;

/**
 * Create a dvswitch( destination) with one standalone host connected to it and
 * another dvswitch (source) with another standalone host connected to it with
 * the host vmknic connected to a DVPort
 */
public class Pos030 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference dcMor = null;
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

   // variables for vm on the host on src dvs
   private DistributedVirtualPort[] srcPorts = null;
   private DistributedVirtualPort[] destPorts = null;

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
               + "standalone host connected to it with the host vmknic connected "
               + "to a DVPort");
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
               this.dcMor = this.iFolder.getDataCenter();
               if (this.dcMor != null) {
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
                  this.destfolder = this.iFolder.createFolder(networkFolder,
                           this.getTestId() + "-destFolder");
                  // create the destn dvs
                  this.destDvsMor = this.iFolder.createDistributedVirtualSwitch(
                           this.destfolder, this.dvsConfigSpec);
                  // get the max ports
                  this.destnMaxPorts = this.iDVSwitch.getConfig(this.destDvsMor).getMaxPorts();

                  if (this.destDvsMor != null) {
                     log.info("Successfully created the dvswitch");
                     hostNetworkConfig = new HostNetworkConfig[2][2];
                     hostNetworkConfig[0] = this.iDVSwitch.getHostNetworkConfigMigrateToDVS(
                              this.destDvsMor, this.destnDvsHostMor);
                     this.firstNetworkMor = this.iNetworkSystem.getNetworkSystem(this.destnDvsHostMor);
                     if (this.firstNetworkMor != null) {
                        if (this.iNetworkSystem.updateNetworkConfig(
                                 this.firstNetworkMor, hostNetworkConfig[0][0],
                                 TestConstants.CHANGEMODE_MODIFY)) {
                           // add the ports
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
                     this.dvsConfigSpec.setName(dvsName + ".2");
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
                           // create the port, set the vm to connect to pg
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
               + "standalone host connected to it with the host vmknic connected "
               + "to a DVPort")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;

         if (this.iDVSwitch.merge(destDvsMor, srcDvsMor)) {
            log.info("Successfully merged the two switches");
            if (this.iNetworkSystem.refresh(this.secondNetworkMor)) {
               log.info("Succesfully refreshed the network system of the host");
               if (this.iDVSwitch.validateMergedMaxPorts(this.srcMaxPorts,
                        this.destnMaxPorts, this.destDvsMor)) {
                  log.info("Hosts max ports verified");
                  if (this.iDVSwitch.validateMergeHostsJoin(
                           this.srcHostMembers, this.destDvsMor)) {
                     log.info("Hosts join on merge verified");
                     if (this.iDVSwitch.validateMergePorts(this.srcPorts,
                              this.destPorts, this.destDvsMor)) {
                        status = true;
                     } else {
                        log.info("Port verification failed");
                     }
                  } else {
                     log.info("Hosts join on merge verification failed");
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
         if (this.srcDvsMor != null
                  && this.iManagedEntity.isExists(this.srcDvsMor)) {
            // check if able to destroy it
            status &= this.iManagedEntity.destroy(this.srcDvsMor);
         }
         // check if destn dvs exists
         if (this.destDvsMor != null
                  && this.iManagedEntity.isExists(this.destDvsMor)) {
            // destroy the destn
            status &= this.iManagedEntity.destroy(this.destDvsMor);
         }
         if (this.destfolder != null) {
            if (this.iFolder.destroy(this.destfolder)) {
               log.info("Succesfully destroyed the destination folder");
            } else {
               status &= false;
               log.error("Can not destroy the destination folder");
            }
         }
         if (this.srcfolder != null) {
            if (this.iFolder.destroy(this.srcfolder)) {
               log.info("Succesfully destroyed the source folder");
            } else {
               status &= false;
               log.error("Can not destroy the source folder");
            }
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
      DistributedVirtualSwitchPortConnection dvsPortConnection = null;
      String dvSwitchUuid = null;
      DVSConfigInfo info = null;
      List<String> portKeys = iDVSwitch.addStandaloneDVPorts(this.srcDvsMor, 1);
      if (portKeys != null) {
         log.info("Successfully get the standalone DVPortkeys");
         String portKey = portKeys.get(0);
         info = this.iDVSwitch.getConfig(this.srcDvsMor);
         dvSwitchUuid = info.getUuid();
         // create the DistributedVirtualSwitchPortConnection object.
         dvsPortConnection = buildDistributedVirtualSwitchPortConnection(
                  dvSwitchUuid, portKey, null);
         this.scVNicId = addVnic(this.srcDvsHostMor, dvsPortConnection);
         if (this.scVNicId != null) {
            log.info("Successfully added the vm kernel NIC "
                     + this.scVNicId);
            if (this.iDVSwitch.refreshPortState(this.srcDvsMor,
                     new String[] { portKey })) {
               log.info("Successfully refreshed the port state of the port "
                        + portKey);
               this.srcPorts = new DistributedVirtualPort[] { reconfigureSrcPort(
                        portKey, "SOURCEDVPORT") };
               if (this.srcPorts != null) {
                  log.info("Successfully reconfigured the port to be the given"
                           + " name");
                  status = true;
               }
            } else {
               log.error("Can not refresh the port state of the port "
                        + portKey);
            }
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
            log.error("Failed to  add the virtula Nic.");
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
      HostNetworkInfo networkInfo = this.iNetworkSystem.getNetworkInfo(
               this.iNetworkSystem.getNetworkSystem(hostMor));
      String staticIpAddress = TestUtil.getAlternateServiceConsoleIP(
               this.iHostSystem.getIPAddress(hostMor));
      if (iHostSystem.isEesxHost(hostMor)) {
         if (networkInfo != null && com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getVnic(), com.vmware.vc.HostVirtualNic.class) != null
                  && com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getVnic(), com.vmware.vc.HostVirtualNic.class)[0] != null
                  && com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getVnic(), com.vmware.vc.HostVirtualNic.class)[0].getSpec() != null) {
            vnicSpec = com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getVnic(), com.vmware.vc.HostVirtualNic.class)[0].getSpec();
            if(staticIpAddress != null){
               hostVNicSpec = buildVnicSpec(
                        portConnection,
                        staticIpAddress,
                        vnicSpec.getIp().getSubnetMask(), false);
            } else {
               hostVNicSpec = buildVnicSpec(
                        portConnection,
                        null,null,true);
            }
         }
      } else {
         if (networkInfo != null && com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getConsoleVnic(), com.vmware.vc.HostVirtualNic.class) != null
                  && com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getConsoleVnic(), com.vmware.vc.HostVirtualNic.class)[0] != null
                  && com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getConsoleVnic(), com.vmware.vc.HostVirtualNic.class)[0].getSpec() != null) {
            vnicSpec = com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getConsoleVnic(), com.vmware.vc.HostVirtualNic.class)[0].getSpec();
            if(staticIpAddress != null){
               hostVNicSpec = buildVnicSpec(
                        portConnection,
                        staticIpAddress,
                        vnicSpec.getIp().getSubnetMask(), false);
            } else {
               hostVNicSpec = buildVnicSpec(
                        portConnection,
                        null,null,true);
            }
         }
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

   /**
    * Reconfigure the port to set a name to it
    *
    * @param portKey String
    * @param portName String
    * @return DistributedVirtualPort Object
    * @throws MethodFault, Exception
    */
   private DistributedVirtualPort reconfigureSrcPort(String portKey,
                                                     String portName)
      throws Exception
   {
      DistributedVirtualPort vp = null;
      DVPortConfigSpec spec = null;
      DVPortSetting[] portSettingArray = new DVPortSetting[2];
      // get the port config spec
      DVPortConfigSpec[] specs = this.iDVSwitch.getPortConfigSpec(
               this.srcDvsMor, new String[] { portKey });
      if (specs != null && specs.length > 0) {
         spec = specs[0];
         DVPortSetting dvPortSetting = new DVPortSetting();
         spec.setSetting(dvPortSetting);
         spec.setName(portName);
         spec.setOperation(TestConstants.CONFIG_SPEC_EDIT);
         // reconfigure the port to set the name
         if (this.iDVSwitch.reconfigurePort(this.srcDvsMor,
                  new DVPortConfigSpec[] { spec })) {
            // fetch the port config info for storing
            DistributedVirtualSwitchPortCriteria criteria = this.iDVSwitch.getPortCriteria(
                     null, null, null, null, new String[] { portKey }, false);
            List<DistributedVirtualPort> allPorts = this.iDVSwitch.fetchPorts(
                     this.srcDvsMor, criteria);
            if (allPorts != null && !allPorts.isEmpty() && allPorts.size() == 1) {
               vp = allPorts.get(0);
            }
         }
      }
      return vp;
   }
}
