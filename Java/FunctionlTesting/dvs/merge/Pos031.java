/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.merge;

import static com.vmware.vcqa.util.Assert.*;

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
import com.vmware.vc.HostVirtualNicSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.MessageConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.NetworkSystem;

/**
 * Create a dvswitch( destination) with one standalone host connected to it and
 * another dvswitch (source) with another standalone host connected to it with
 * the host serviceconsolenic connected to a DVPort
 */
public class Pos031 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
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
   private DVSConfigSpec dvsConfigSpec = null;
   private String srcDvsName;
   private String dstDvsName;
   private Vector<ManagedObjectReference> hosts = null;
   private int srcMaxPorts = 0;
   private int destnMaxPorts = 0;
   private DistributedVirtualPort[] srcPorts = null;
   private final DistributedVirtualPort[] destPorts = null;
   private String scVNicId = null;
   private DistributedVirtualSwitchHostMemberConfigSpec hostConfigSpecElement = null;
   private DistributedVirtualSwitchHostMember[] srcHostMembers = null;
   private boolean merged;

   @Override
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      boolean destDvsConfigured = false;
      boolean srcDvsConfigured = false;
      final String dvsName = getTestId();
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      log.info("Test setup Begin:");
      iFolder = new Folder(connectAnchor);
      iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
      iHostSystem = new HostSystem(connectAnchor);
      iManagedEntity = new ManagedEntity(connectAnchor);
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
      dvsConfigSpec.setName(srcDvsName);
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
         log.info("Successfully created the dvswitch");
         hostNetworkConfig = new HostNetworkConfig[2][2];
         hostNetworkConfig[0] = iDVSwitch.getHostNetworkConfigMigrateToDVS(
                  destDvsMor, destnDvsHostMor);
         firstNetworkMor = iNetworkSystem.getNetworkSystem(destnDvsHostMor);
         if (firstNetworkMor != null) {
            if (iNetworkSystem.updateNetworkConfig(firstNetworkMor,
                     hostNetworkConfig[0][0], TestConstants.CHANGEMODE_MODIFY)) {
               // add the ports
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
         dvsConfigSpec.setName(dstDvsName);
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
               // create the pg, set the vm to connect to pg
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
   @Test(description = "Create two early binding portgroups having different "
            + "names with two VMKnics connected to each one of the portgroups "
            + "having different policies")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      if (iDVSwitch.merge(destDvsMor, srcDvsMor)) {
         merged = true;
         log.info("Successfully merged the two switches");
         if (iNetworkSystem.refresh(secondNetworkMor)) {
            log.info("Succesfully refreshed the network system of the host");
            if (iDVSwitch.validateMergedMaxPorts(srcMaxPorts, destnMaxPorts,
                     destDvsMor)) {
               log.info("Hosts max ports verified");
               if (iDVSwitch.validateMergeHostsJoin(srcHostMembers, destDvsMor)) {
                  log.info("Hosts join on merge verified");
                  if (iDVSwitch.validateMergePorts(srcPorts, destPorts,
                           destDvsMor)) {
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
   @Override
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      /*
       * Restore the original network config
       */
      if (hostNetworkConfig != null) {
         status = iNetworkSystem.updateNetworkConfig(firstNetworkMor,
                  hostNetworkConfig[0][1], TestConstants.CHANGEMODE_MODIFY);
         final HostProxySwitchConfig config = iDVSwitch.getDVSVswitchProxyOnHost(
                  destDvsMor, srcDvsHostMor);
         config.setSpec(com.vmware.vcqa.util.TestUtil.vectorToArray(hostNetworkConfig[1][1].getProxySwitch(), com.vmware.vc.HostProxySwitchConfig.class)[0].getSpec());
         hostNetworkConfig[1][1].getProxySwitch().clear();
         hostNetworkConfig[1][1].getProxySwitch().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new HostProxySwitchConfig[] { config }));
         status &= iNetworkSystem.updateNetworkConfig(secondNetworkMor,
                  hostNetworkConfig[1][1], TestConstants.CHANGEMODE_MODIFY);
      }
      // restore the vm's state
      status &= cleanUpServiceConsoleNic();
      // check if src dvs exists
      if (!merged && srcDvsMor == null) {
         srcDvsMor = iFolder.getDistributedVirtualSwitch(srcfolder, srcDvsName);
      }
      if (!merged && srcDvsMor != null) {
         status &= iManagedEntity.destroy(srcDvsMor);
      }
      // check if destn dvs exists
      if (destDvsMor == null) {
         destDvsMor = iFolder.getDistributedVirtualSwitch(destfolder,
                  dstDvsName);
      }
      if (destDvsMor != null) {
         status &= iManagedEntity.destroy(destDvsMor);
      }
      if (destfolder != null) {
         if (iFolder.destroy(destfolder)) {
            log.info("Succesfully destroyed the destination folder");
         } else {
            status &= false;
            log.error("Can not destroy the destination folder");
         }
      }
      if (srcfolder != null) {
         if (iFolder.destroy(srcfolder)) {
            log.info("Succesfully destroyed the source folder");
         } else {
            status &= false;
            log.error("Can not destroy the source folder");
         }
      }
      return status;
   }

   private boolean cleanUpServiceConsoleNic()
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

   /**
    * Configures the src DVS. Setup a service console nic on a DVPort
    *
    * @throws MethodFault,Exception
    */
   private boolean configureSrcDvs()
      throws Exception
   {
      boolean status = false;
      final List<String> portKeys = iDVSwitch.addStandaloneDVPorts(srcDvsMor, 1);
      if (portKeys != null) {
         log.info("Successfully get the standalone DVPortkeys");
         final String portKey = portKeys.get(0);
         final DVSConfigInfo info = iDVSwitch.getConfig(srcDvsMor);
         final String dvSwitchUuid = info.getUuid();
         // create the DistributedVirtualSwitchPortConnection object.
         final DistributedVirtualSwitchPortConnection dvsPortConnection = buildDistributedVirtualSwitchPortConnection(
                  dvSwitchUuid, portKey, null);
         // Get the alternateIPAddress of the host.
         final String ipAddress = iHostSystem.getIPAddress(srcDvsHostMor);
         final String alternateIPAddress = TestUtil.getAlternateServiceConsoleIP(ipAddress);
         log.info("AlternateIPAddress : " + alternateIPAddress);
         final HostVirtualNicSpec hostVNicSpec = buildVnicSpec(
                  dvsPortConnection, alternateIPAddress,
                  getSubnetMask(srcDvsHostMor), false);
         scVNicId = iNetworkSystem.addServiceConsoleVirtualNic(
                  secondNetworkMor, "", hostVNicSpec);
         if (scVNicId != null) {
            srcPorts = new DistributedVirtualPort[] { reconfigureSrcPort(
                     portKey, "SOURCEDVPORT") };
            log.info("Successfully added the service console Virtual NIC "
                     + scVNicId);
            if (DVSUtil.checkNetworkConnectivity(alternateIPAddress, null)) {
               log.info("Successfully established the Network Connection.");
               status = true;
            } else {
               log.error("Failed to establish the Network Connection.");
            }
         } else {
            log.error("Unable to add the service console Virtual NIC");
         }
      } else {
         log.error("Failed to get the standalone DVPortkeys ");
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }

   private String getSubnetMask(final ManagedObjectReference hostMor)
      throws Exception
   {
      String subnetMask = null;
      final ManagedObjectReference networkSystem = iNetworkSystem.getNetworkSystem(hostMor);
      HostNetworkInfo networkInfo = null;
      HostVirtualNicSpec hostVirtualNicSpec = null;
      if (networkSystem != null) {
         networkInfo = iNetworkSystem.getNetworkInfo(networkSystem);
         if (networkInfo != null && com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getConsoleVnic(), com.vmware.vc.HostVirtualNic.class) != null
                  && com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getConsoleVnic(), com.vmware.vc.HostVirtualNic.class).length > 0
                  && com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getConsoleVnic(), com.vmware.vc.HostVirtualNic.class)[0] != null
                  && com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getConsoleVnic(), com.vmware.vc.HostVirtualNic.class)[0].getSpec() != null) {
            hostVirtualNicSpec = com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getConsoleVnic(), com.vmware.vc.HostVirtualNic.class)[0].getSpec();
            if (hostVirtualNicSpec != null
                     && hostVirtualNicSpec.getIp() != null) {
               subnetMask = hostVirtualNicSpec.getIp().getSubnetMask();
            }
         }
      }
      return subnetMask;
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

   /**
    * Reconfigure the port to set a name to it
    *
    * @param portKey
    * @param portName
    * @return
    * @throws MethodFault
    * @throws Exception
    */
   private DistributedVirtualPort reconfigureSrcPort(final String portKey,
                                                     final String portName)
      throws Exception
   {
      DistributedVirtualPort vp = null;
      DVPortConfigSpec spec = null;
      final DVPortSetting[] portSettingArray = new DVPortSetting[2];
      // get the port config spec
      final DVPortConfigSpec[] specs = iDVSwitch.getPortConfigSpec(srcDvsMor,
               new String[] { portKey });
      if (specs != null && specs.length > 0) {
         spec = specs[0];
         spec.setName(portName);
         spec.setOperation(TestConstants.CONFIG_SPEC_EDIT);
         // reconfigure the port to set the name
         if (iDVSwitch.reconfigurePort(srcDvsMor,
                  new DVPortConfigSpec[] { spec })) {
            log.info("Successfully reconfigured the port");
            if (iDVSwitch.refreshPortState(srcDvsMor, new String[] { portKey })) {
               // fetch the port config info for storing
               final DistributedVirtualSwitchPortCriteria criteria = iDVSwitch.getPortCriteria(
                        null, null, null, null, new String[] { portKey }, false);
               final List<DistributedVirtualPort> allPorts = iDVSwitch.fetchPorts(
                        srcDvsMor, criteria);
               if (allPorts != null && !allPorts.isEmpty()
                        && allPorts.size() == 1) {
                  vp = allPorts.get(0);
               }
            } else {
               log.error("Can not refresh the port state");
            }
         } else {
            log.error("Can not reconifgure the port");
         }
      }
      return vp;
   }
}
