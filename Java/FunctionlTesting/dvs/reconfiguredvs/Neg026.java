/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvs;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.HostIpConfig;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.HostNetworkInfo;
import com.vmware.vc.HostVirtualNicSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.ResourceInUse;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.NetworkSystem;

import dvs.CreateDVSTestBase;

/**
 * Reconfigure an existing DVSwitch by setting the ManagedObjectReference to a
 * valid DVSwitch Mor and DVSConfigSpec.configVersion to a valid config version
 * string and uplinkPortgroup to an invalid array.
 */

public class Neg026 extends CreateDVSTestBase
{
   /*
    * private data variables
    */
   private DVSConfigSpec deltaConfigSpec = null;
   private HostSystem ihs = null;
   private Vector<ManagedObjectReference> allHosts = null;
   private ManagedObjectReference hostMor = null;
   private ManagedObjectReference iNetworkMor = null;
   private NetworkSystem iNetworkSystem = null;
   private Map<String, List<String>> usedPorts = null;
   private HostNetworkConfig[] hostNetworkConfig = null;
   private DVPortgroupConfigSpec dvPortgroupConfigSpec = null;
   private List<ManagedObjectReference> dvPortgroupMorList = null;
   private DistributedVirtualPortgroup iDvPortgroup = null;
   private String portgroupKey = null;
   private boolean isEesx = false;
   String vnicId = null;

   /**
    * Sets the test description.
    *
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      super.setTestDescription("Reconfigure an existing DVSwitch by setting "
               + "the ManagedObjectReference to a valid DVSwitch Mor and "
               + "DVSConfigSpec.configVersion to a valid config version string and "
               + "uplinkPortgroup to an invalid array.");
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
      boolean status = false;
      HostVirtualNicSpec hostVnicSpec = null;
      DistributedVirtualSwitchPortConnection portConnection = null;
      HostNetworkInfo networkInfo = null;
      HostIpConfig ipConfig = null;
      log.info("Test setup Begin:");

         if (super.testSetUp()) {
            this.ihs = new HostSystem(connectAnchor);
            this.iNetworkSystem = new NetworkSystem(connectAnchor);
            this.iDvPortgroup = new DistributedVirtualPortgroup(connectAnchor);
            allHosts = this.ihs.getAllHost();
            if (allHosts != null) {
               this.hostMor = (ManagedObjectReference) allHosts.get(0);
            } else {
               log.error("Valid Host MOR not found");
            }
            this.isEesx = this.ihs.isEesxHost(hostMor);
            this.networkFolderMor = this.iFolder.getNetworkFolder(this.dcMor);
            this.iNetworkMor = this.iNetworkSystem.getNetworkSystem(this.hostMor);
            if (this.networkFolderMor != null) {
               this.configSpec = new DVSConfigSpec();
               this.configSpec.setName(this.getClass().getName());
               DistributedVirtualSwitchHostMemberConfigSpec hostConfigSpecElement = new DistributedVirtualSwitchHostMemberConfigSpec();
               hostConfigSpecElement.setOperation(TestConstants.CONFIG_SPEC_ADD);
               hostConfigSpecElement.setHost(this.hostMor);
               this.configSpec.getHost().clear();
               this.configSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostConfigSpecElement }));
               this.dvsMOR = this.iFolder.createDistributedVirtualSwitch(
                        this.networkFolderMor, this.configSpec);
               if (this.dvsMOR != null) {
                  log.info("Successfully created the DVSwitch");
                  this.hostNetworkConfig = this.iDistributedVirtualSwitch.getHostNetworkConfigMigrateToDVS(
                           this.dvsMOR, hostMor);
                  this.iNetworkSystem.refresh(this.iNetworkMor);
                  Thread.sleep(10000);
                  this.iNetworkSystem.updateNetworkConfig(this.iNetworkMor,
                           hostNetworkConfig[0],
                           TestConstants.CHANGEMODE_MODIFY);
                  this.iNetworkSystem.refresh(this.iNetworkMor);
                  Thread.sleep(10000);
                  this.dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
                  this.dvPortgroupConfigSpec.setConfigVersion("");
                  this.dvPortgroupConfigSpec.setName(this.getTestId());
                  this.dvPortgroupConfigSpec.setDescription(DVSTestConstants.DVPORTGROUP_VALID_DESCRIPTION);
                  this.dvPortgroupConfigSpec.getScope().clear();
                  this.dvPortgroupConfigSpec.getScope().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new ManagedObjectReference[] { hostMor }));
                  this.dvPortgroupConfigSpec.setNumPorts(9);
                  this.dvPortgroupConfigSpec.setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
                  dvPortgroupMorList = this.iDistributedVirtualSwitch.addPortGroups(
                           this.dvsMOR,
                           new DVPortgroupConfigSpec[] { this.dvPortgroupConfigSpec });
                  if (this.dvPortgroupMorList != null
                           && this.dvPortgroupMorList.size() == 1) {
                     usedPorts = new HashMap<String, List<String>>();
                     portgroupKey = this.iDvPortgroup.getKey(dvPortgroupMorList.get(0));
                     portConnection = this.iDistributedVirtualSwitch.getPortConnection(
                              this.dvsMOR, null, false, usedPorts,
                              new String[] { portgroupKey });
                     if (portConnection != null) {
                        log.info("Successfully obtained a "
                                 + "DistributedVirtualSwitchPortConnection for the service console "
                                 + "virtual nic");
                        hostVnicSpec = new HostVirtualNicSpec();
                        networkInfo = this.iNetworkSystem.getNetworkInfo(this.iNetworkMor);
                        ipConfig = new HostIpConfig();
                        ipConfig.setDhcp(false);
                        String ipAddress = TestUtil.
                           getAlternateServiceConsoleIP(this.ihs.getIPAddress(
                                    hostMor));
                        if(ipAddress != null){
                           ipConfig.setIpAddress(ipAddress);
                        } else {
                           ipConfig.setDhcp(true);
                        }
                        if(this.isEesx){
                           ipConfig.setSubnetMask(com.vmware.vcqa.util.TestUtil.
                                    vectorToArray(networkInfo.getVnic(), com.vmware.vc.HostVirtualNic.class)[0].getSpec().getIp().
                                    getSubnetMask());
                        } else {
                           ipConfig.setSubnetMask(com.vmware.vcqa.util.TestUtil.
                                    vectorToArray(networkInfo.getConsoleVnic(), com.vmware.vc.HostVirtualNic.class)[0].getSpec().getIp().
                                    getSubnetMask());
                        }
                        hostVnicSpec.setIp(ipConfig);
                        hostVnicSpec.setDistributedVirtualPort(portConnection);
                        if (networkInfo != null) {
                           log.info("Successfully obtained the "
                                    + "network information for the host");
                           vnicId = this.iNetworkSystem.addServiceConsoleVirtualNic(
                                    this.iNetworkMor, "", hostVnicSpec);
                           String sourceIp = this.ihs.getIPAddress(hostMor);
                           if (vnicId != null
                                    && DVSUtil.checkNetworkConnectivity(
                                             sourceIp, ipConfig.getIpAddress())) {
                              log.info("Successfully added the "
                                       + "virtual nic to connect to "
                                       + "a DVPort");
                              this.deltaConfigSpec = new DVSConfigSpec();
                              String validConfigVersion = this.iDistributedVirtualSwitch.getConfig(
                                       dvsMOR).getConfigVersion();
                              this.deltaConfigSpec.setConfigVersion(validConfigVersion);
                              DistributedVirtualSwitchHostMemberConfigSpec hostMemberDeltaConfigSpec = new DistributedVirtualSwitchHostMemberConfigSpec();
                              hostMemberDeltaConfigSpec.setOperation(TestConstants.CONFIG_SPEC_REMOVE);
                              hostMemberDeltaConfigSpec.setHost(this.hostMor);
                              this.deltaConfigSpec.getHost().clear();
                              this.deltaConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostMemberDeltaConfigSpec }));
                              status = true;
                           } else {
                              log.error("Failed to add the virtual "
                                       + "nic");
                              status = false;
                           }
                        } else {
                           log.error("Failed to obtain the network "
                                    + "information for the host");
                           status = false;
                        }
                     }
                     status = true;
                  }
               } else {
                  log.error("Cannot create the distributed virtual "
                           + "switch with the config spec passed");
               }
            } else {
               log.error("Failed to create the network folder");
            }
         } else {
            log.error("Failed to login");
         }

      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that creates the DVS.
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Reconfigure an existing DVSwitch by setting "
               + "the ManagedObjectReference to a valid DVSwitch Mor and "
               + "DVSConfigSpec.configVersion to a valid config version string and "
               + "uplinkPortgroup to an invalid array.")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      try {
         this.iDistributedVirtualSwitch.reconfigure(this.dvsMOR,
                  this.deltaConfigSpec);
         log.error("The API did not throw Exception");
      } catch (Exception actualMethodFaultExcep) {
         MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(actualMethodFaultExcep);
         ResourceInUse expectedMethodFault = new ResourceInUse();
         status = TestUtil.checkMethodFault(actualMethodFault,
                  expectedMethodFault);
      }
      assertTrue(status, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test is started.
    *
    * @param connectAnchor ConnectAnchor object
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = false;

         if (this.iNetworkSystem.removeServiceConsoleVirtualNic(
                  this.iNetworkMor, vnicId)) {
            log.info("Successfully removed the "
                     + "service console virtual nic");
            status = iNetworkSystem.updateNetworkConfig(iNetworkMor,
                     hostNetworkConfig[1], TestConstants.CHANGEMODE_MODIFY);
            if (status) {
               status &= super.testCleanUp();
            } else {
               log.error("Failed to update network configuration");
            }
         } else {
            log.error("Failed to remove "
                     + "the service console virtual nic");
         }

      assertTrue(status, "Cleanup failed");
      return status;
   }
}