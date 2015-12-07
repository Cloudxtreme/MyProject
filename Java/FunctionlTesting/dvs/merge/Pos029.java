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
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.host.NetworkSystem;

/**
 * Merge two distributed virtual switches with one host connected to the source
 * dvswitch
 */
public class Pos029 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference destDvsMor = null;
   private ManagedObjectReference srcDvsMor = null;
   private DVSConfigSpec dvsConfigSpec = null;
   private DistributedVirtualSwitch iDVSwitch = null;
   private HostSystem iHostSystem = null;
   private NetworkSystem iNetworkSystem = null;
   private ManagedObjectReference hostMor = null;
   private ManagedObjectReference networkMor = null;
   private HostNetworkConfig[] hostNetworkConfig = null;
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
      setTestDescription("Merge two distributed virtual switches with one "
               + "host connected to the source dvswitch");
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
         if (hosts != null && hosts.size() >= 1) {
            log.info("Found one host");
            this.hostMor = hosts.get(0);
            if (this.hostMor != null) {
               this.dcMor = this.iFolder.getDataCenter();
               if (this.dcMor != null) {
                  this.dvsConfigSpec = new DVSConfigSpec();
                  this.dvsConfigSpec.setConfigVersion("");
                  this.dvsConfigSpec.setName(dvsName + ".1");
                  hostConfigSpecElement = new DistributedVirtualSwitchHostMemberConfigSpec();
                  hostConfigSpecElement.setHost(this.hostMor);
                  hostConfigSpecElement.setOperation(TestConstants.CONFIG_SPEC_ADD);
                  /*
                   * TODO Check whether the pnic devices need to be
                   * set in the DistributedVirtualSwitchHostMemberPnicSpec
                   */
                  pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
                  pnicBacking.getPnicSpec().clear();
                  pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] {}));
                  hostConfigSpecElement.setBacking(pnicBacking);
                  this.destDvsMor = this.iFolder.createDistributedVirtualSwitch(
                           this.iFolder.getNetworkFolder(dcMor), dvsConfigSpec);
                  if (this.destDvsMor != null) {
                     log.info("Successfully created the "
                              + "destination dvswitch");
                     this.dvsConfigSpec.getHost().clear();
                     this.dvsConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostConfigSpecElement }));
                     this.dvsConfigSpec.setName(dvsName + ".2");
                     this.srcDvsMor = this.iFolder.createDistributedVirtualSwitch(
                              this.iFolder.getNetworkFolder(dcMor),
                              dvsConfigSpec);
                     if (this.srcDvsMor != null) {
                        log.info("Successfully created the "
                                 + "source distributed virtual switch");
                        hostNetworkConfig = this.iDVSwitch.getHostNetworkConfigMigrateToDVS(
                                 this.srcDvsMor, this.hostMor);
                        this.networkMor = this.iNetworkSystem.getNetworkSystem(this.hostMor);
                        if (this.networkMor != null) {
                           if (this.iNetworkSystem.updateNetworkConfig(
                                    this.networkMor, hostNetworkConfig[0],
                                    TestConstants.CHANGEMODE_MODIFY)) {
                              status = true;
                           } else {
                              log.error("Can not update the network config "
                                       + "of the host");
                           }
                        } else {
                           log.error("Cannot find the "
                                    + "network MOR for the host");
                        }
                     } else {
                        log.error("Failed to create the source"
                                 + " distributed virtual switch");
                     }
                  } else {
                     log.error("Failed to create the destination"
                              + " dvswitch");
                  }
               } else {
                  log.error("Cannot find a valid data center");
               }
            } else {
               log.error("The host MOR is null");
            }
         } else {
            log.error("Cannot find a valid host");
         }
     
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that merges two distributed virtual switches, with one host
    * connected to the source dvswitch
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Merge two distributed virtual switches with one "
               + "host connected to the source dvswitch")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
     
         if (this.iDVSwitch.merge(destDvsMor, srcDvsMor)) {
            log.info("Successfully merged the two switches");
            if (com.vmware.vcqa.util.TestUtil.vectorToArray(this.iDVSwitch.getConfig(destDvsMor).getHost(), com.vmware.vc.DistributedVirtualSwitchHostMember.class).length == 1) {
               log.info("One host was found in the destination DVS");
               status = true;
            } else {
               log.error("The host was not moved to the "
                        + "destination DVS");
            }
         } else {
            log.error("Failed to merge the two switches");
         }
     
      assertTrue(status, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test was started. Restore
    * the original state of the VM. Destroy the distributed virtual switch
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
         if (this.hostNetworkConfig != null
                  && this.hostNetworkConfig[1] != null) {
            HostProxySwitchConfig config = this.iDVSwitch.getDVSVswitchProxyOnHost(
                     this.destDvsMor, this.hostMor);
            config.setSpec(com.vmware.vcqa.util.TestUtil.vectorToArray(hostNetworkConfig[1].getProxySwitch(), com.vmware.vc.HostProxySwitchConfig.class)[0].getSpec());
            hostNetworkConfig[1].getProxySwitch().clear();
            hostNetworkConfig[1].getProxySwitch().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new HostProxySwitchConfig[] { config }));
            status = this.iNetworkSystem.updateNetworkConfig(this.networkMor,
                     hostNetworkConfig[1], TestConstants.CHANGEMODE_MODIFY);
         }
         if (this.destDvsMor != null) {
            status &= this.iManagedEntity.destroy(destDvsMor);
         }
         if (this.srcDvsMor != null
                  && this.iManagedEntity.isExists(this.srcDvsMor)) {
            status &= this.iManagedEntity.destroy(srcDvsMor);
         }
     
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
