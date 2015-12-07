/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.merge;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMember;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.HostProxySwitchConfig;
import com.vmware.vc.ManagedObjectReference;
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
 * Merge two distributed virtual switches with two hosts, each connected to one
 * switch. Merge the switches
 */
public class Pos018 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference rootFolderMor = null;
   private ManagedObjectReference destDvsMor = null;
   private ManagedObjectReference srcDvsMor = null;
   private DVSConfigSpec dvsConfigSpec = null;
   private DistributedVirtualSwitch iDVSwitch = null;
   private HostSystem iHostSystem = null;
   private NetworkSystem iNetworkSystem = null;
   private ManagedObjectReference firstHostMor = null;
   private ManagedObjectReference secondHostMor = null;
   private ManagedObjectReference firstNetworkMor = null;
   private ManagedObjectReference secondNetworkMor = null;
   private HostNetworkConfig[][] hostNetworkConfig = null;
   private DistributedVirtualSwitchHostMemberConfigSpec hostConfigSpecElement = null;
   private Vector<ManagedObjectReference> hosts = null;
   private ManagedObjectReference dcMor = null;
   private DistributedVirtualSwitchHostMember[] srcHostMembers = null;
   private int srcMaxPorts = 0;
   private int destnMaxPorts = 0;

   /**
    * Sets the test description.
    *
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      setTestDescription("Merge two distributed virtual switches with two "
               + "hosts, each connected to one switch");
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
      boolean status = false;
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
            this.firstHostMor = hosts.get(0);
            this.secondHostMor = hosts.get(1);
            if (this.firstHostMor != null && this.secondHostMor != null) {
               this.rootFolderMor = this.iFolder.getRootFolder();
               this.dcMor = this.iFolder.getDataCenter();
               if (this.rootFolderMor != null) {
                  // create the dvs spec
                  this.dvsConfigSpec = new DVSConfigSpec();
                  this.dvsConfigSpec.setConfigVersion("");
                  this.dvsConfigSpec.setName(dvsName + ".1");
                  hostConfigSpecElement = new DistributedVirtualSwitchHostMemberConfigSpec();
                  hostConfigSpecElement.setHost(this.firstHostMor);
                  hostConfigSpecElement.setOperation(TestConstants.CONFIG_SPEC_ADD);
                  pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
                  pnicBacking.getPnicSpec().clear();
                  pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] {}));
                  hostConfigSpecElement.setBacking(pnicBacking);
                  this.dvsConfigSpec.getHost().clear();
                  this.dvsConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostConfigSpecElement }));
                  this.destDvsMor = this.iFolder.createDistributedVirtualSwitch(
                           this.iFolder.getNetworkFolder(dcMor), dvsConfigSpec);
                  // get the max ports
                  this.destnMaxPorts = this.iDVSwitch.getConfig(this.destDvsMor).getMaxPorts();
                  if (this.destDvsMor != null) {
                     log.info("Successfully created the dvswitch");
                     hostNetworkConfig = new HostNetworkConfig[2][2];
                     hostNetworkConfig[0] = this.iDVSwitch.getHostNetworkConfigMigrateToDVS(
                              this.destDvsMor, this.firstHostMor);
                     this.firstNetworkMor = this.iNetworkSystem.getNetworkSystem(this.firstHostMor);
                     if (this.firstNetworkMor != null) {
                        this.iNetworkSystem.updateNetworkConfig(
                                 this.firstNetworkMor, hostNetworkConfig[0][0],
                                 TestConstants.CHANGEMODE_MODIFY);
                     } else {
                        log.error("Network config null");
                     }
                     hostConfigSpecElement.setHost(this.secondHostMor);
                     this.dvsConfigSpec = new DVSConfigSpec();
                     this.dvsConfigSpec.getHost().clear();
                     this.dvsConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostConfigSpecElement }));
                     this.dvsConfigSpec.setName(dvsName + ".2");
                     this.srcDvsMor = this.iFolder.createDistributedVirtualSwitch(
                              this.iFolder.getNetworkFolder(dcMor),
                              dvsConfigSpec);
                     if (this.srcDvsMor != null) {
                        log.info("Successfully created the "
                                 + "second distributed virtual switch");
                        hostNetworkConfig[1] = this.iDVSwitch.getHostNetworkConfigMigrateToDVS(
                                 this.srcDvsMor, this.secondHostMor);
                        this.secondNetworkMor = this.iNetworkSystem.getNetworkSystem(this.secondHostMor);
                        if (this.secondNetworkMor != null) {
                           this.iNetworkSystem.updateNetworkConfig(
                                    this.secondNetworkMor,
                                    hostNetworkConfig[1][0],
                                    TestConstants.CHANGEMODE_MODIFY);
                           DVSConfigInfo srcDvsConfigInfo = this.iDVSwitch.getConfig(this.srcDvsMor);
                           this.srcHostMembers = com.vmware.vcqa.util.TestUtil.vectorToArray(srcDvsConfigInfo.getHost(), com.vmware.vc.DistributedVirtualSwitchHostMember.class);
                           status = true;
                        } else {
                           log.error("Network config null");
                        }
                     }
                  }
               }
            }
         }

      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that merges two distributed virtual switches, each containing one
    * host with two uplink portgroups on each switch with the same name
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Merge two distributed virtual switches with two "
               + "hosts, each connected to one switch")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      // get the max ports
      this.srcMaxPorts = this.iDVSwitch.getConfig(this.srcDvsMor).getMaxPorts();
         if (this.iDVSwitch.merge(destDvsMor, srcDvsMor)) {
            log.info("Successfully merged the two switches");
            if (this.iDVSwitch.validateMergedMaxPorts(srcMaxPorts,
                     destnMaxPorts, this.destDvsMor)) {
               log.info("Hosts max ports verified");
               if (this.iDVSwitch.validateMergeHostsJoin(this.srcHostMembers,
                        this.destDvsMor)) {
                  log.info("Hosts join on merge verified");
                  status = true;
               } else {
                  log.info("Hosts join on merge verification failed");
               }
            } else {
               log.info("Max ports verification failed");
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
                  this.destDvsMor, this.secondHostMor);
         config.setSpec(com.vmware.vcqa.util.TestUtil.vectorToArray(hostNetworkConfig[1][1].getProxySwitch(), com.vmware.vc.HostProxySwitchConfig.class)[0].getSpec());
         hostNetworkConfig[1][1].getProxySwitch().clear();
         hostNetworkConfig[1][1].getProxySwitch().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new HostProxySwitchConfig[] { config }));
         status &= this.iNetworkSystem.updateNetworkConfig(
                  this.secondNetworkMor, hostNetworkConfig[1][1],
                  TestConstants.CHANGEMODE_MODIFY);
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

      assertTrue(status, "Cleanup failed");
      return status;
   }
}
