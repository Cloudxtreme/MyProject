/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.functional;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.HostConnectSpec;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.HostProxySwitchConfig;
import com.vmware.vc.HostVirtualNicSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;

/**
 * Disconnect and remove the host from the VC inventory after this host has been
 * previously added to a DVSwitch without removing the host from the DVSwitch.
 * Add the host back to the VC.
 */
public class Pos008 extends FunctionalTestBase
{
   // private instance variables go here.
   private ManagedObjectReference pgMor = null;
   private String portgroupKey = null;
   private HostConnectSpec hostConnectspec = null;
   private HostVirtualNicSpec hostVirtualNicSpec = null;
   private String vnicKey = null;
   private boolean isEESXHost = false;
   private ManagedObjectReference hostFolderMor = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      setTestDescription("Disconnect and remove the host from the VC inventory"
               + " after this host has been previously added to a DVSwitch"
               + " without removing the host from the DVSwitch. "
               + "Add the host back to the VC.");
   }

   /**
    * Method to setup the environment for the test.
    * 
    * @param connectAnchor ConnectAnchor object
    * @return boolean true if successful, false otherwise.
    */
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean setUpDone = false;
      DistributedVirtualSwitchPortConnection portConnection = null;
      HostVirtualNicSpec virtualNicSpec = null;
      DVPortgroupConfigSpec configSpec = null;
      List<ManagedObjectReference> pgMorList = null;
      HostNetworkConfig networkConfig = null;
     
         setUpDone = super.testSetUp();
         if (setUpDone) {
            networkConfig = this.ins.getNetworkConfig(this.nwSystemMor);
            this.hostFolderMor = this.ihs.getHostFolder(this.hostMor);
            this.hostConnectspec = this.ihs.getHostConnectSpec(this.hostMor);
            if (setUpDone) {
               configSpec = new DVPortgroupConfigSpec();
               configSpec.setName(this.getTestId() + "-pg1");
               configSpec.setNumPorts(1);
               configSpec.setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
               pgMorList = this.iDVS.addPortGroups(dvsMor,
                        new DVPortgroupConfigSpec[] { configSpec });
               if (pgMorList != null && pgMorList.size() == 1) {
                  this.pgMor = pgMorList.get(0);
                  if (this.pgMor != null) {
                     this.portgroupKey = this.iDVPortgroup.getKey(pgMor);
                     portConnection = new DistributedVirtualSwitchPortConnection();
                     portConnection.setPortgroupKey(portgroupKey);
                     portConnection.setSwitchUuid(this.dvSwitchUUID);
                     if (this.ihs.isEesxHost(this.hostMor)) {
                        if (com.vmware.vcqa.util.TestUtil.vectorToArray(networkConfig.getVnic(), com.vmware.vc.HostVirtualNicConfig.class) != null
                                 && com.vmware.vcqa.util.TestUtil.vectorToArray(networkConfig.getVnic(), com.vmware.vc.HostVirtualNicConfig.class).length > 0
                                 && com.vmware.vcqa.util.TestUtil.vectorToArray(networkConfig.getVnic(), com.vmware.vc.HostVirtualNicConfig.class)[0] != null) {
                           this.isEESXHost = true;
                           this.vnicKey = com.vmware.vcqa.util.TestUtil.vectorToArray(networkConfig.getVnic(), com.vmware.vc.HostVirtualNicConfig.class)[0].getDevice();
                           virtualNicSpec = com.vmware.vcqa.util.TestUtil.vectorToArray(networkConfig.getVnic(), com.vmware.vc.HostVirtualNicConfig.class)[0].getSpec();
                        }
                     } else {
                        if (com.vmware.vcqa.util.TestUtil.vectorToArray(networkConfig.getConsoleVnic(), com.vmware.vc.HostVirtualNicConfig.class) != null
                                 && com.vmware.vcqa.util.TestUtil.vectorToArray(networkConfig.getConsoleVnic(), com.vmware.vc.HostVirtualNicConfig.class).length > 0
                                 && com.vmware.vcqa.util.TestUtil.vectorToArray(networkConfig.getConsoleVnic(), com.vmware.vc.HostVirtualNicConfig.class)[0] != null) {
                           this.vnicKey = com.vmware.vcqa.util.TestUtil.vectorToArray(networkConfig.getConsoleVnic(), com.vmware.vc.HostVirtualNicConfig.class)[0].getDevice();
                           virtualNicSpec = com.vmware.vcqa.util.TestUtil.vectorToArray(networkConfig.getConsoleVnic(), com.vmware.vc.HostVirtualNicConfig.class)[0].getSpec();
                        }
                     }
                     if (this.vnicKey != null && virtualNicSpec != null) {
                        this.hostVirtualNicSpec = (HostVirtualNicSpec) TestUtil.deepCopyObject(virtualNicSpec);
                        virtualNicSpec.setPortgroup(null);
                        virtualNicSpec.setDistributedVirtualPort(portConnection);
                        if (this.isEESXHost) {
                           this.ins.updateVirtualNic(this.nwSystemMor,
                                    this.vnicKey, virtualNicSpec);
                        } else {
                           this.ins.updateServiceConsoleVirtualNic(
                                    this.nwSystemMor, this.vnicKey,
                                    virtualNicSpec);
                        }
                        if (setUpDone) {
                           log.info("Successfully updated the virtual nic "
                                    + "to connect to the DVS portgroup");
                        } else {
                           log.error("Can not update the virtual nic to connect"
                                    + " to the DVS portgroup");
                        }
                     } else {
                        log.error("Can not get a valid port conenction object");
                        setUpDone = false;
                     }
                  } else {
                     setUpDone = false;
                     log.error("The portgroup Mor is null");
                  }
               } else {
                  setUpDone = false;
                  log.error("Can not add the port group");
               }

            } else {
               setUpDone = false;
               log.error("There are no ethernet cards configured"
                        + " on the VM");
            }
         } else {
            setUpDone = false;
            log.error("The VM does not have any ethernet cards"
                     + " configured");
         }
     
      assertTrue(setUpDone, "Setup failed");
      return setUpDone;
   }

   /**
    * Method to test if the the host DVSwitch will be merged onto the existing
    * DVSwitch on the VC, and all the confilcts will be resolved, After the host
    * gets disconnected from the VC.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Disconnect and remove the host from the VC inventory"
               + " after this host has been previously added to a DVSwitch"
               + " without removing the host from the DVSwitch. "
               + "Add the host back to the VC.")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean testDone = false;
      DVSConfigInfo dvsConfigInfo = null;
      DVSConfigSpec dvsConfigSpec = null;
      DistributedVirtualSwitchHostMemberConfigSpec hostMemberConfigSpec = null;
      HostProxySwitchConfig proxyVSwitchConfig = null;
     
         if (this.ihs.destroy(this.hostMor)) {
            this.hostMor = this.ihs.addStandaloneHost(this.hostFolderMor,
                     this.hostConnectspec, null, true);
            if (this.hostMor != null) {
               this.nwSystemMor = this.ins.getNetworkSystem(this.hostMor);
               log.info("Sleeping for 30 seconds for the host sync to happen");
               Thread.sleep(30 * 1000);
               testDone = this.ins.refresh(this.nwSystemMor);
               if (testDone) {
                  dvsConfigInfo = this.iDVS.getConfig(this.dvsMor);
                  if (dvsConfigInfo != null
                           && com.vmware.vcqa.util.TestUtil.vectorToArray(dvsConfigInfo.getHost(), com.vmware.vc.DistributedVirtualSwitchHostMember.class) != null
                           && com.vmware.vcqa.util.TestUtil.vectorToArray(dvsConfigInfo.getHost(), com.vmware.vc.DistributedVirtualSwitchHostMember.class).length == 1
                           && (this.iDVS.getHostMemberConnectedToDVSwitch(
                                    this.dvsMor, this.hostMor) != null)) {
                     log.info("The host is successfully added back to the DVS");
                  } else {
                     log.warn("The host is not added back to the DVS");
                     proxyVSwitchConfig = this.iDVS.getDVSVswitchProxyOnHost(
                              dvsMor, hostMor);
                     if (proxyVSwitchConfig != null) {
                        log.info("The proxy still exists on the host");
                        dvsConfigSpec = new DVSConfigSpec();
                        dvsConfigSpec.setConfigVersion(dvsConfigInfo.getConfigVersion());
                        hostMemberConfigSpec = new DistributedVirtualSwitchHostMemberConfigSpec();
                        hostMemberConfigSpec.setOperation(TestConstants.CONFIG_SPEC_ADD);
                        hostMemberConfigSpec.setHost(this.hostMor);
                        dvsConfigSpec.getHost().clear();
                        dvsConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostMemberConfigSpec }));
                        testDone = this.iDVS.reconfigure(this.dvsMor,
                                 dvsConfigSpec);
                        log.info("Sleeping for 30 seconds for the host sync to"
                                 + " happen");
                        Thread.sleep(30 * 1000);
                        dvsConfigInfo = this.iDVS.getConfig(this.dvsMor);
                        if (dvsConfigInfo != null
                                 && com.vmware.vcqa.util.TestUtil.vectorToArray(dvsConfigInfo.getHost(), com.vmware.vc.DistributedVirtualSwitchHostMember.class) != null
                                 && com.vmware.vcqa.util.TestUtil.vectorToArray(dvsConfigInfo.getHost(), com.vmware.vc.DistributedVirtualSwitchHostMember.class).length == 1) {
                           log.info("The host is successfully added back to "
                                    + "the DVS");
                        } else {
                           testDone = false;
                           log.error("The host is not added back to the VC");
                        }
                     } else {
                        testDone = false;
                        log.error("The proxy does not exist on the host");
                     }
                  }
               } else {
                  log.error("Can not refresh the network system of the host");
               }
            } else {
               log.error("Can add the host back to the VC ");
            }
         } else {
            log.error("Can not remvoe the host ");
         }
     

      assertTrue(testDone, "Test Failed");
   }

   /**
    * Restores the state prior to running the test.
    * 
    * @param connectAnchor ConnectAnchor Object
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean cleanUpDone = true;
     
         if (!this.ihs.isHostConnected(this.hostMor)) {
            cleanUpDone &= this.ihs.reconnectHost(this.hostMor, null, null);
         }
         if (this.ihs.isHostConnected(this.hostMor)) {
            if (this.vnicKey != null && this.hostVirtualNicSpec != null) {
               if (this.isEESXHost) {
                  if (this.ins.updateVirtualNic(this.nwSystemMor, this.vnicKey,
                           this.hostVirtualNicSpec)) {
                     log.info("Successfully updated the virtual nic to "
                              + "disconnect from the DVS");
                  } else {
                     cleanUpDone = false;
                     log.error("Can not revert the virtual nic to disconnect"
                              + " from the DVS");
                  }
               } else {
                  if (this.ins.updateServiceConsoleVirtualNic(this.nwSystemMor,
                           this.vnicKey, this.hostVirtualNicSpec)) {
                     log.info("Successfully updated the virtual nic to "
                              + "disconnect from the DVS");
                  } else {
                     cleanUpDone = false;
                     log.error("Can not revert the virtual nic to disconnect"
                              + " from the DVS");
                  }
               }
            }
         } else {
            cleanUpDone = false;
            log.error("The host is still disconnected");
         }
         if (cleanUpDone) {
            cleanUpDone &= super.testCleanUp();
         }
     
      assertTrue(cleanUpDone, "Cleanup failed");
      return cleanUpDone;
   }
}