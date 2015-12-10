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

import com.vmware.vc.DVSConfigSpec;
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
import com.vmware.vcqa.vim.host.NetworkSystem;

/**
 * Merge two distributed virtual switches with two hosts, each connected to one
 * switch
 */
public class Pos008 extends TestBase
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
      final String dvsName = this.getTestId();
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      log.info("Test setup Begin:");
     
         this.iFolder = new Folder(connectAnchor);
         this.iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
         this.iHostSystem = new HostSystem(connectAnchor);
         this.iManagedEntity = new ManagedEntity(connectAnchor);
         this.iNetworkSystem = new NetworkSystem(connectAnchor);
         this.dcMor = this.iFolder.getDataCenter();
         hosts = this.iHostSystem.getAllHost();
         if (hosts != null && hosts.size() >= 2) {
            log.info("Found two hosts");
            this.firstHostMor = hosts.get(0);
            this.secondHostMor = hosts.get(1);
            if (this.firstHostMor != null && this.secondHostMor != null) {
               this.rootFolderMor = this.iFolder.getRootFolder();
               if (this.rootFolderMor != null) {
                  this.dvsConfigSpec = new DVSConfigSpec();
                  this.dvsConfigSpec.setConfigVersion("");
                  this.dvsConfigSpec.setName(dvsName + ".1");
                  hostConfigSpecElement = new DistributedVirtualSwitchHostMemberConfigSpec();
                  hostConfigSpecElement.setHost(this.firstHostMor);
                  hostConfigSpecElement.setOperation(TestConstants.CONFIG_SPEC_ADD);
                  /*
                   * TODO Check whether the pnic devices need to be
                   * set in the DistributedVirtualSwitchHostMemberPnicSpec
                   */
                  pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
                  pnicBacking.getPnicSpec().clear();
                  pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] {}));
                  hostConfigSpecElement.setBacking(pnicBacking);
                  this.dvsConfigSpec.getHost().clear();
                  this.dvsConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostConfigSpecElement }));
                  this.destDvsMor = this.iFolder.createDistributedVirtualSwitch(
                           this.iFolder.getNetworkFolder(dcMor), dvsConfigSpec);
                  if (this.destDvsMor != null) {
                     log.info("Successfully created the dvswitch");
                     hostNetworkConfig = new HostNetworkConfig[2][2];
                     this.firstNetworkMor = this.iNetworkSystem.getNetworkSystem(this.firstHostMor);
                     Thread.sleep(10000);
                     hostNetworkConfig[0] = this.iDVSwitch.getHostNetworkConfigMigrateToDVS(
                              this.destDvsMor, this.firstHostMor);
                     if (this.firstNetworkMor != null) {
                        this.iNetworkSystem.refresh(this.firstNetworkMor);
                        Thread.sleep(10000);
                        this.iNetworkSystem.updateNetworkConfig(
                                 this.firstNetworkMor, hostNetworkConfig[0][0],
                                 TestConstants.CHANGEMODE_MODIFY);
                        hostConfigSpecElement = new DistributedVirtualSwitchHostMemberConfigSpec();
                        hostConfigSpecElement.setHost(this.secondHostMor);
                        hostConfigSpecElement.setOperation(TestConstants.CONFIG_SPEC_ADD);
                        pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
                        pnicBacking.getPnicSpec().clear();
                        pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] {}));
                        hostConfigSpecElement.setBacking(pnicBacking);
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
                           this.secondNetworkMor = this.iNetworkSystem.getNetworkSystem(this.secondHostMor);
                           Thread.sleep(10000);
                           hostNetworkConfig[1] = this.iDVSwitch.getHostNetworkConfigMigrateToDVS(
                                    this.srcDvsMor, this.secondHostMor);
                           if (this.secondNetworkMor != null) {
                              this.iNetworkSystem.refresh(this.firstNetworkMor);
                              Thread.sleep(10000);
                              this.iNetworkSystem.updateNetworkConfig(
                                       this.secondNetworkMor,
                                       hostNetworkConfig[1][0],
                                       TestConstants.CHANGEMODE_MODIFY);
                              status = true;
                           } else {
                              log.error("Cannot find the second "
                                       + "network MOR");
                           }
                        } else {
                           log.error("Failed to create the second"
                                    + " distributed virtual switch");
                        }
                     } else {
                        log.error("Cannot find the first network"
                                 + " MOR");
                     }
                  } else {
                     log.error("Failed to create the dvswitch");
                  }
               } else {
                  log.error("Cannot find the root folder");
               }
            } else {
               log.error("The host MOR is null");
            }
         } else {
            log.error("Cannot find two valid hosts");
         }
     
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that merges two distributed virtual switches, each containing one
    * host
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
     
         if (this.iDVSwitch.merge(destDvsMor, srcDvsMor)) {
            log.info("Successfully merged the two switches");
            if (com.vmware.vcqa.util.TestUtil.vectorToArray(this.iDVSwitch.getConfig(destDvsMor).getHost(), com.vmware.vc.DistributedVirtualSwitchHostMember.class).length == 2) {
               log.info("Two hosts were found in the destination DVS");
               status = true;
            } else {
               log.error("The second host was not moved to the "
                        + "destination DVS");
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
      HostProxySwitchConfig proxySwitchConfig = null;
     
         /*
          * Restore the original network config
          */
         if (hostNetworkConfig != null && hostNetworkConfig.length > 0
                  && hostNetworkConfig[0] != null
                  && hostNetworkConfig[0][1] != null) {
            if (this.iNetworkSystem.updateNetworkConfig(this.firstNetworkMor,
                     this.hostNetworkConfig[0][1],
                     TestConstants.CHANGEMODE_MODIFY)) {
               log.info("Successfully updated the network config of the host "
                        + this.iHostSystem.getHostName(this.firstHostMor));
            } else {
               status &= false;
               log.error("Can not update the network config of the host "
                        + this.iHostSystem.getHostName(this.firstHostMor));
            }
         }

         if (this.srcDvsMor != null) {
            if (this.iDVSwitch.isExists(this.srcDvsMor)) {
               if (hostNetworkConfig != null && hostNetworkConfig.length > 1
                        && hostNetworkConfig[1] != null
                        && hostNetworkConfig[1].length > 1
                        && hostNetworkConfig[1][1] != null) {
                  if (this.iNetworkSystem.updateNetworkConfig(
                           this.secondNetworkMor, hostNetworkConfig[1][1],
                           TestConstants.CHANGEMODE_MODIFY)) {
                     log.info("Successfully updated the network config for "
                              + "the host "
                              + this.iHostSystem.getHostName(this.secondHostMor));

                  } else {
                     log.error("Can not update the network config of the "
                              + "second host "
                              + this.iHostSystem.getHostName(this.secondHostMor));
                     status &= false;
                  }
               }
               if (this.iDVSwitch.destroy(this.srcDvsMor)) {
                  log.info("Successfully destroyed the source DVS");
               } else {
                  log.error("Can not destroy the source DVS");
                  status &= false;
               }
            } else if (this.iDVSwitch.getDVSVswitchProxyOnHost(this.destDvsMor,
                     this.secondHostMor) != null) {
               if (hostNetworkConfig != null && hostNetworkConfig.length > 1
                        && hostNetworkConfig[1] != null
                        && hostNetworkConfig[1].length > 1
                        && hostNetworkConfig[1][1] != null
                        && com.vmware.vcqa.util.TestUtil.vectorToArray(hostNetworkConfig[1][1].getProxySwitch(), com.vmware.vc.HostProxySwitchConfig.class).length > 0) {
                  proxySwitchConfig = com.vmware.vcqa.util.TestUtil.vectorToArray(hostNetworkConfig[1][1].getProxySwitch(), com.vmware.vc.HostProxySwitchConfig.class)[0];
                  if (proxySwitchConfig != null) {
                     proxySwitchConfig.setUuid(this.iDVSwitch.getConfig(
                              this.destDvsMor).getUuid());
                     if (this.iNetworkSystem.updateNetworkConfig(
                              this.secondNetworkMor, hostNetworkConfig[1][1],
                              TestConstants.CHANGEMODE_MODIFY)) {
                        log.info("Successfully updated the network config of"
                                 + " the host "
                                 + this.iHostSystem.getHostName(this.secondHostMor));
                     } else {
                        status &= false;
                        log.error("Can not update the network config of the "
                                 + "host "
                                 + this.iHostSystem.getHostName(this.secondHostMor));
                     }
                  }
               }
            }
         }

         if (this.destDvsMor != null) {
            status &= this.iManagedEntity.destroy(destDvsMor);
         }

     
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
