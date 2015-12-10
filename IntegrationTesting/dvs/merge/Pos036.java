/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.merge;

import static com.vmware.vcqa.util.Assert.*;

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
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.MessageConstants;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.host.NetworkSystem;

/**
 * Create a dvswitch( destination) with one standalone host connected to it and
 * another dvswitch (source) with another standalone host connected to it with
 * the host service console vnic connected to a DVPortgroup
 */
public class Pos036 extends TestBase
{
   private Folder iFolder = null;
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
   private DVPortgroupConfigInfo[] srcPortgroups = null;
   private DVPortSetting[] srcPortSetting = null;
   private String scVNicId = null;
   private boolean merged;
   private String srcDvsName;
   private String dstDvsName;

   /**
    * Sets the test description.
    *
    * @param testDescription the testDescription to set
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Create a dvswitch( destination) with one standalone "
               + "host connected to it and another dvswitch (source) with another "
               + "standalone host connected to it with the host serviceconsole vnic "
               + "connected to a DVPortgroup");
   }

   /**
    * Method to setup the environment for the test. This method creates a
    * distributed virtual switch.
    *
    * @param connectAnchor ConnectAnchor object
    * @return boolean true if successful, false otherwise.
    */
   @Override
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      boolean destDvsConfigured = false;
      boolean srcDvsConfigured = false;
      final String dvsName = DVSTestConstants.DVS_CREATE_NAME_PREFIX
               + getTestId();
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      log.info("Test setup Begin:");
      iFolder = new Folder(connectAnchor);
      iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
      iHostSystem = new HostSystem(connectAnchor);
      iNetworkSystem = new NetworkSystem(connectAnchor);
      hosts = iHostSystem.getAllHost();
      assertTrue(hosts.size() >= 2, MessageConstants.HOST_GET_FAIL);
      boolean gotSrc = false;
      boolean gotDst = false;
      for (int i = 0; i < hosts.size(); i++) {
         if (!gotSrc && !iHostSystem.isEesxHost(hosts.get(i))) {
            srcDvsHostMor = hosts.get(i);
            gotSrc = true;
            continue;
         }
         if (!gotDst) {
            destnDvsHostMor = hosts.get(i);
            gotDst = true;
            continue;
         }
      }
      assertTrue(gotSrc && gotDst, "Failed to get the hosts.");
      // create the dvs spec
      dvsConfigSpec = new DVSConfigSpec();
      dvsConfigSpec.setConfigVersion("");
      srcDvsName = dvsName + "-src";
      dstDvsName = dvsName + "-dst";
      dvsConfigSpec.setName(dstDvsName);
      hostConfigSpecElement = new DistributedVirtualSwitchHostMemberConfigSpec();
      hostConfigSpecElement.setHost(destnDvsHostMor);
      hostConfigSpecElement.setOperation(TestConstants.CONFIG_SPEC_ADD);
      pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
      pnicBacking.getPnicSpec().clear();
      pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] {}));
      hostConfigSpecElement.setBacking(pnicBacking);
      dvsConfigSpec.getHost().clear();
      dvsConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostConfigSpecElement }));
      final ManagedObjectReference networkFolder = iFolder.getNetworkFolder(iFolder.getDataCenter());
      destfolder = iFolder.createFolder(networkFolder, getTestId()
               + "-destFolder");
      // create the destn dvs
      destDvsMor = iFolder.createDistributedVirtualSwitch(destfolder,
               dvsConfigSpec);
      // get the max ports
      destnMaxPorts = iDVSwitch.getConfig(destDvsMor).getMaxPorts();
      if (destDvsMor != null) {
         log.info("Successfully created the " + "dvswitch");
         hostNetworkConfig = new HostNetworkConfig[2][2];
         hostNetworkConfig[0] = iDVSwitch.getHostNetworkConfigMigrateToDVS(
                  destDvsMor, destnDvsHostMor);
         firstNetworkMor = iNetworkSystem.getNetworkSystem(destnDvsHostMor);
         if (firstNetworkMor != null) {
            if (iNetworkSystem.updateNetworkConfig(firstNetworkMor,
                     hostNetworkConfig[0][0], TestConstants.CHANGEMODE_MODIFY)) {
               destDvsConfigured = true;
            } else {
               log.error("Update network config " + "failed");
            }
         } else {
            log.error("Network config null");
         }
         hostConfigSpecElement.setHost(srcDvsHostMor);
         dvsConfigSpec = new DVSConfigSpec();
         dvsConfigSpec.getHost().clear();
         dvsConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostConfigSpecElement }));
         dvsConfigSpec.setName(srcDvsName);
         srcfolder = iFolder.createFolder(networkFolder, getTestId()
                  + "-srcFolder");
         // create the src dvs
         srcDvsMor = iFolder.createDistributedVirtualSwitch(srcfolder,
                  dvsConfigSpec);
         if (srcDvsMor != null) {
            log.info("Successfully created the "
                     + "second distributed virtual switch");
            hostNetworkConfig[1] = iDVSwitch.getHostNetworkConfigMigrateToDVS(
                     srcDvsMor, srcDvsHostMor);
            secondNetworkMor = iNetworkSystem.getNetworkSystem(srcDvsHostMor);
            if (secondNetworkMor != null) {
               iNetworkSystem.updateNetworkConfig(secondNetworkMor,
                        hostNetworkConfig[1][0],
                        TestConstants.CHANGEMODE_MODIFY);
               final DVSConfigInfo srcDvsConfigInfo = iDVSwitch.getConfig(srcDvsMor);
               srcHostMembers = com.vmware.vcqa.util.TestUtil.vectorToArray(srcDvsConfigInfo.getHost(), com.vmware.vc.DistributedVirtualSwitchHostMember.class);
               // get the max ports
               srcMaxPorts = iDVSwitch.getConfig(srcDvsMor).getMaxPorts();
               /*
                * create the portgroup, set the vm to connect to pg
                */
               srcDvsConfigured = configureSrcDvs();
            } else {
               log.error("Network config null");
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
   @Override
   @Test(description = "Create a dvswitch( destination) with one standalone "
            + "host connected to it and another dvswitch (source) with another "
            + "standalone host connected to it with the host serviceconsole vnic "
            + "connected to a DVPortgroup")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      if (iDVSwitch.merge(destDvsMor, srcDvsMor)) {
         merged = true;
         log.info("Successfully merged the two switches");
         if (iNetworkSystem.refresh(secondNetworkMor)) {
            log.info("Succesfully refresh the network system of the host");
            if (iDVSwitch.validateMergedMaxPorts(srcMaxPorts, destnMaxPorts,
                     destDvsMor)) {
               log.info("Hosts max ports verified");
               if (iDVSwitch.validateMergeHostsJoin(srcHostMembers, destDvsMor)) {
                  log.info("Hosts join on merge verified");
                  if (iDVSwitch.validateMergePortgroups(srcPortgroups,
                           srcPortSetting, srcDvsName, destDvsMor)) {
                     status = true;
                  } else {
                     log.info("Portgroup verification failed");
                  }
               } else {
                  log.info("Hosts join on merge verification " + "failed");
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
   @Override
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      /*
       * Restore the original network config
       */
      status = iNetworkSystem.updateNetworkConfig(firstNetworkMor,
               hostNetworkConfig[0][1], TestConstants.CHANGEMODE_MODIFY);
      final HostProxySwitchConfig config = iDVSwitch.getDVSVswitchProxyOnHost(
               destDvsMor, srcDvsHostMor);
      config.setSpec(com.vmware.vcqa.util.TestUtil.vectorToArray(hostNetworkConfig[1][1].getProxySwitch(), com.vmware.vc.HostProxySwitchConfig.class)[0].getSpec());
      hostNetworkConfig[1][1].getProxySwitch().clear();
      hostNetworkConfig[1][1].getProxySwitch().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new HostProxySwitchConfig[] { config }));
      status &= iNetworkSystem.updateNetworkConfig(secondNetworkMor,
               hostNetworkConfig[1][1], TestConstants.CHANGEMODE_MODIFY);
      // restore the vm's state
      status &= cleanUpServiceConsoleVNic();
      // check if src dvs exists
      if (!merged && srcDvsMor == null) {
         srcDvsMor = iFolder.getDistributedVirtualSwitch(srcfolder, srcDvsName);
      }
      if (!merged && srcDvsMor != null) {
         status &= iDVSwitch.destroy(srcDvsMor);
      }
      // check if destn dvs exists
      if (destDvsMor == null) {
         destDvsMor = iFolder.getDistributedVirtualSwitch(destfolder,
                  dstDvsName);
      }
      if (destDvsMor != null) {
         status &= iDVSwitch.destroy(destDvsMor);
      }
      if (srcfolder != null) {
         status &= iFolder.destroy(srcfolder);
      }
      if (destfolder != null) {
         status &= iFolder.destroy(destfolder);
      }
      return status;
   }

   private boolean cleanUpServiceConsoleVNic()
      throws Exception
   {
      boolean status = false;
      if (scVNicId != null
               && iNetworkSystem.removeServiceConsoleVirtualNic(
                        secondNetworkMor, scVNicId)) {
         log.info("Successfully removed the service console Virtual NIC "
                  + scVNicId);
         status = true;
      } else {
         log.error("Unable to remove the service console Virtual NIC "
                  + scVNicId);
      }
      return status;
   }

   private boolean configureSrcDvs()
      throws Exception
   {
      boolean status = false;
      Map<String, Object> portgroupInfo = null;
      final String portgroupKey = iDVSwitch.addPortGroup(srcDvsMor,
               DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING, 1,
               "DVPORTGROUP-SRC");
      if (portgroupKey != null) {
         log.info("Successfully get the standalone DVPortgroup");
         final DVSConfigInfo info = iDVSwitch.getConfig(srcDvsMor);
         final String dvSwitchUuid = info.getUuid();
         // create the DistributedVirtualSwitchPortConnection object.
         final DistributedVirtualSwitchPortConnection dvsPortConnection = buildDistributedVirtualSwitchPortConnection(
                  dvSwitchUuid, null, portgroupKey);
         scVNicId = addVnic(srcDvsHostMor, dvsPortConnection);
         if (scVNicId != null) {
            log.info("Successfully added the service console virtual NIC "
                     + scVNicId);
            srcPortgroups = new DVPortgroupConfigInfo[1];
            // get the portgroups
            portgroupInfo = iDVSwitch.getPortgroupList(srcDvsMor);
            if (portgroupInfo != null) {
               srcPortgroups = (DVPortgroupConfigInfo[]) portgroupInfo.get(DVSTestConstants.PORT_GROUP_CONFIG_KEY);
               srcPortSetting = (DVPortSetting[]) portgroupInfo.get(DVSTestConstants.PORT_GROUP_SETTING_KEY);
            }
            status = true;
         } else {
            log.error("Unable to add the service console virtual NIC");
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
   private String addVnic(final ManagedObjectReference aHostMor,
                          final DistributedVirtualSwitchPortConnection portConnection)
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
         vnicId = iNetworkSystem.addServiceConsoleVirtualNic(nsMor, "",
                  hostVnicSpec);
         if (vnicId != null) {
            log.info("Successfully added the service cvirtual Nic.");
            networkInfo = iNetworkSystem.getNetworkInfo(nsMor);
            if (networkInfo != null) {
               final HostVirtualNic[] vNics = com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getConsoleVnic(), com.vmware.vc.HostVirtualNic.class);
               if (vNics != null) {
                  for (final HostVirtualNic vnic : vNics) {
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
      } catch (final Exception e) {
      }
      return device;
   }

   private HostVirtualNicSpec buildVnicSpec(final DistributedVirtualSwitchPortConnection portConnection,
                                            final ManagedObjectReference hostMor)
      throws Exception
   {
      HostVirtualNicSpec hostVNicSpec = null;
      HostVirtualNicSpec vnicSpec = null;
      final HostNetworkInfo networkInfo = iNetworkSystem.getNetworkInfo(
               iNetworkSystem.getNetworkSystem(hostMor));
      if (iHostSystem.isEesxHost(hostMor)) {
         if (networkInfo != null && com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getVnic(), com.vmware.vc.HostVirtualNic.class) != null
                  && com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getVnic(), com.vmware.vc.HostVirtualNic.class)[0] != null
                  && com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getVnic(), com.vmware.vc.HostVirtualNic.class)[0].getSpec() != null) {
            vnicSpec = com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getVnic(), com.vmware.vc.HostVirtualNic.class)[0].getSpec();
         }
      } else {
         if (networkInfo != null && com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getConsoleVnic(), com.vmware.vc.HostVirtualNic.class) != null
                  && com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getConsoleVnic(), com.vmware.vc.HostVirtualNic.class)[0] != null
                  && com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getConsoleVnic(), com.vmware.vc.HostVirtualNic.class)[0].getSpec() != null) {
            vnicSpec = com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getConsoleVnic(), com.vmware.vc.HostVirtualNic.class)[0].getSpec();
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
   private DistributedVirtualSwitchPortConnection buildDistributedVirtualSwitchPortConnection(final String switchUuid,
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
}
