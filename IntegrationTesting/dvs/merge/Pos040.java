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
import java.util.Map;
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
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.HostProxySwitchConfig;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualDevice;
import com.vmware.vc.VirtualMachineConfigInfo;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.host.NetworkSystem;

/**
 * Merge three distributed virtual switches with two hosts, each connected to
 * one switch
 */
public class Pos040 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference rootFolderMor = null;
   private ManagedObjectReference destDvsMor = null;
   private ManagedObjectReference srcDvsMor = null;
   private DVSConfigSpec dvsConfigSpec = null;
   private DistributedVirtualSwitch iDVSwitch = null;
   private VirtualMachine iVirtualMachine = null;
   private HostSystem iHostSystem = null;
   private NetworkSystem iNetworkSystem = null;
   private ManagedObjectReference dvPortgroupMor = null;
   private ManagedObjectReference firstHostMor = null;
   private ManagedObjectReference secondHostMor = null;
   private ManagedObjectReference vmMor = null;
   private ManagedObjectReference firstNetworkMor = null;
   private ManagedObjectReference secondNetworkMor = null;
   private DVPortgroupConfigSpec dvPortgroupConfigSpec = null;
   private HostNetworkConfig[][] hostNetworkConfig = null;
   private HostNetworkConfig originalNetworkConfig = null;
   private VirtualMachinePowerState vmPowerState = null;
   private DistributedVirtualSwitchHostMemberConfigSpec hostConfigSpecElement = null;
   private List<ManagedObjectReference> dvPortgroupMorList = null;
   private DVPortgroupConfigSpec[] dvPortgroupConfigSpecArray = null;
   private DistributedVirtualSwitchPortConnection portConnection = null;
   private VirtualMachineConfigSpec origVMConfigSpec = null;
   private DistributedVirtualPortgroup iDVPortgroup = null;
   private String portgroupKey = null;
   private Map<String, List<String>> usedPorts = null;
   private VirtualMachineConfigSpec[] updatedDeltaConfigSpec = null;
   private DistributedVirtualSwitchHostMemberPnicSpec[] dvsHostMemberPnicSpec = null;
   private Vector<ManagedObjectReference> hosts = null;
   private ManagedObjectReference dcMor = null;
   private ManagedObjectReference origDestDvsMor = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      setTestDescription("Merge three distributed virtual switches with two "
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
      String className = null;
      String nameParts[] = null;
      String portgroupName = null;
      final String dvsName = DVSTestConstants.DVS_CREATE_NAME_PREFIX
               + getTestId();
      String[] physicalNics = null;
      int len = 0;
      int i = 0;
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      VirtualMachineConfigInfo vmConfigInfo = null;
      VirtualDevice[] vds = null;
      Vector allVMs = null;
      log.info("Test setup Begin:");
     
         this.iFolder = new Folder(connectAnchor);
         this.iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
         this.iDVPortgroup = new DistributedVirtualPortgroup(connectAnchor);
         this.iVirtualMachine = new VirtualMachine(connectAnchor);
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
                  this.origDestDvsMor = this.iFolder.createDistributedVirtualSwitch(
                           this.iFolder.getNetworkFolder(dcMor), dvsConfigSpec);
                  hostConfigSpecElement = new DistributedVirtualSwitchHostMemberConfigSpec();
                  hostConfigSpecElement.setHost(this.firstHostMor);
                  hostConfigSpecElement.setOperation(TestConstants.CONFIG_SPEC_ADD);
                  /*
                   * TODO Check whether the pnic devices need to be
                   * set in the DistributedVirtualSwitchHostMemberPnicSpec
                   */
                  this.dvsConfigSpec.setName(dvsName + ".2");
                  pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
                  pnicBacking.getPnicSpec().clear();
                  pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] {}));
                  hostConfigSpecElement.setBacking(pnicBacking);
                  this.dvsConfigSpec.getHost().clear();
                  this.dvsConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostConfigSpecElement }));
                  this.destDvsMor = this.iFolder.createDistributedVirtualSwitch(
                           this.iFolder.getNetworkFolder(dcMor), dvsConfigSpec);
                  if (this.destDvsMor != null && this.origDestDvsMor != null) {
                     log.info("Successfully created the " + "dvswitches");
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
                        this.dvsConfigSpec.setName(dvsName + ".3");
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
    * Method that merges three distributed virtual switches, each containing one
    * host
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Merge three distributed virtual switches with two "
               + "hosts, each connected to one switch")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
     
         if (this.iDVSwitch.merge(destDvsMor, srcDvsMor)) {
            log.info("Successfully merged the second and the third "
                     + "switch");
            if (this.iDVSwitch.merge(this.origDestDvsMor, this.destDvsMor)) {
               log.info("Successfully merged the first and the "
                        + "second switch");
               if (com.vmware.vcqa.util.TestUtil.vectorToArray(this.iDVSwitch.getConfig(origDestDvsMor).getHost(), com.vmware.vc.DistributedVirtualSwitchHostMember.class).length == 2) {
                  log.info("Two hosts were found in " + "the first DVS");
                  status = true;
               } else {
                  log.error("The two hosts were not moved to the "
                           + "first DVS");
               }
            } else {
               log.error("Failed to merge the first and the "
                        + "second switch");
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
         HostProxySwitchConfig config = this.iDVSwitch.getDVSVswitchProxyOnHost(
                  this.origDestDvsMor, this.firstHostMor);
         config.setSpec(com.vmware.vcqa.util.TestUtil.vectorToArray(hostNetworkConfig[0][1].getProxySwitch(), com.vmware.vc.HostProxySwitchConfig.class)[0].getSpec());
         hostNetworkConfig[0][1].getProxySwitch().clear();
         hostNetworkConfig[0][1].getProxySwitch().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new HostProxySwitchConfig[] { config }));
         status = this.iNetworkSystem.updateNetworkConfig(this.firstNetworkMor,
                  hostNetworkConfig[0][1], TestConstants.CHANGEMODE_MODIFY);
         config = this.iDVSwitch.getDVSVswitchProxyOnHost(this.origDestDvsMor,
                  this.secondHostMor);
         config.setSpec(com.vmware.vcqa.util.TestUtil.vectorToArray(hostNetworkConfig[1][1].getProxySwitch(), com.vmware.vc.HostProxySwitchConfig.class)[0].getSpec());
         hostNetworkConfig[1][1].getProxySwitch().clear();
         hostNetworkConfig[1][1].getProxySwitch().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new HostProxySwitchConfig[] { config }));
         status &= this.iNetworkSystem.updateNetworkConfig(
                  this.secondNetworkMor, hostNetworkConfig[1][1],
                  TestConstants.CHANGEMODE_MODIFY);
         if (this.destDvsMor != null
                  && this.iManagedEntity.isExists(this.destDvsMor)) {
            status &= this.iManagedEntity.destroy(destDvsMor);
         }
         if (this.srcDvsMor != null
                  && this.iManagedEntity.isExists(this.srcDvsMor)) {
            status &= this.iManagedEntity.destroy(srcDvsMor);
         }
         if (this.origDestDvsMor != null
                  && this.iManagedEntity.isExists(this.origDestDvsMor)) {
            status &= this.iManagedEntity.destroy(origDestDvsMor);
         }
     
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
