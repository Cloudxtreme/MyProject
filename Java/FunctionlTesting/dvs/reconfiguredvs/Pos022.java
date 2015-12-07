/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvs;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DVSNameArrayUplinkPortPolicy;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VMwareUplinkPortOrderPolicy;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.host.NetworkSystem;

import dvs.CreateDVSTestBase;

/**
 * Reconfigure an existing DVS as follows: - Set the DVSConfigSpec.configVersion
 * to a valid config version string - Set the DVSConfigSpec.name to a valid
 * string - Set DVSConfigSpec.maxPort to a valid number that is equal to the
 * numPort - Set DVSConfigSpec.numPort to a valid number equal to the number of
 * uplink ports per host - Set DVSConfigSpec.uplinkPortPolicy to a valid array
 * that has number of elements equal to the number of pnics being
 * added({uplink1, .. uplink(n)}) The following spec for two hosts: - Set
 * DistributedVirtualSwitchHostMemberConfigSpec.operation to ADD - Set
 * DistributedVirtualSwitchHostMemberConfigSpec.host to a valid hostMor - Set
 * DistributedVirtualSwitchHostMemberConfigSpec.proxy to a valid pnic proxy
 * selection with the pnic spec(s) containing a valid pnic key and a null value
 * for uplinkPortKey - Set
 * DistributedVirtualSwitchHostMemberConfigSpec.MaxProxySwitchPorts to a valid
 * number equal to the number uplink ports per host
 */
public class Pos022 extends CreateDVSTestBase
{

   /*
    * private data variables
    */
   private HostSystem ihs = null;
   private Vector<ManagedObjectReference> allHosts = null;
   private ManagedObjectReference hostMor1 = null;
   private ManagedObjectReference hostMor2 = null;
   private NetworkSystem iNetworkSystem = null;
   private DistributedVirtualSwitch iDistributedVirtualSwitch = null;
   private DVSConfigSpec deltaConfigSpec = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      super.setTestDescription("Reconfigure an existing DVS as follows:\n"
               + "  - Set the DVSConfigSpec.configVersion to a valid config version"
               + " string\n"
               + "  - Set the DVSConfigSpec.name to a valid string\n"
               + "  - Set DVSConfigSpec.maxPort to a valid number that is equal to the"
               + " numPort\n"
               + "  - Set DVSConfigSpec.numPort to a valid number equal to the number "
               + "of uplink ports per host\n"
               + "  - Set DVSConfigSpec.uplinkPortPolicy to a valid array that has "
               + "number of elements equal to the number of pnics being added. "
               + "({uplink1, .. uplink(n)})\n"
               + "The following spec for two hosts:\n"
               + "  - Set DistributedVirtualSwitchHostMemberConfigSpec.operation to ADD\n"
               + "  - Set DistributedVirtualSwitchHostMemberConfigSpec.host to a valid "
               + "hostMor\n"
               + "  - Set DistributedVirtualSwitchHostMemberConfigSpec.proxy  to a valid "
               + "pnic proxy selection"
               + " with the pnic spec(s) containing a valid pnic key and a null value "
               + " for uplinkPortKey\n"
               + "  - Set DistributedVirtualSwitchHostMemberConfigSpec.MaxProxySwitchPorts "
               + "to a valid number equal to the number uplink ports per host.");
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
      DVSConfigInfo configInfo = null;
      DistributedVirtualSwitchHostMemberPnicSpec hostOnepnicSpec = null;
      DistributedVirtualSwitchHostMemberPnicBacking hostOnePnicBacking = null;
      DistributedVirtualSwitchHostMemberPnicSpec hostTwoPnicSpec = null;
      DistributedVirtualSwitchHostMemberPnicBacking hostTwoPnicBacking = null;
      String[] uplinkPortNames = null;
      String[] standbyUplinkPorts = null;
      VMwareDVSPortSetting defaultPortConfig = null;
      VMwareUplinkPortOrderPolicy portOrder = null;
      log.info("Test setup Begin:");

     
         if (super.testSetUp()) {
            this.networkFolderMor = this.iFolder.getNetworkFolder(this.dcMor);
            if (this.networkFolderMor != null) {
               this.ihs = new HostSystem(connectAnchor);
               this.iNetworkSystem = new NetworkSystem(connectAnchor);
               this.iDistributedVirtualSwitch = new DistributedVirtualSwitch(
                        connectAnchor);
               allHosts = this.ihs.getAllHost();

               if (allHosts != null) {
                  this.hostMor1 = (ManagedObjectReference) allHosts.get(0);
                  this.hostMor2 = (ManagedObjectReference) allHosts.get(1);
               } else {
                  log.error("Valid Host MOR not found");
               }
               this.configSpec = new DVSConfigSpec();
               this.configSpec.setName(this.getClass().getName());
               this.dvsMOR = this.iFolder.createDistributedVirtualSwitch(
                        this.networkFolderMor, this.configSpec);
               if (this.dvsMOR != null) {
                  log.info("Successfully created the DVSwitch");
                  configInfo = this.iDistributedVirtualSwitch.getConfig(this.dvsMOR);
                  this.deltaConfigSpec = new DVSConfigSpec();
                  DistributedVirtualSwitchHostMemberConfigSpec[] hostConfigSpecElement = new DistributedVirtualSwitchHostMemberConfigSpec[2];
                  String validConfigVersion = configInfo.getConfigVersion();
                  this.deltaConfigSpec.setConfigVersion(validConfigVersion);
                  String[] hostOnephysicalNics = iNetworkSystem.getPNicIds(this.hostMor1);
                  String[] hostTwophysicalNics = iNetworkSystem.getPNicIds(this.hostMor2);
                  if (hostOnephysicalNics != null) {
                     hostOnepnicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();
                     hostOnepnicSpec.setPnicDevice(hostOnephysicalNics[0]);
                     hostOnepnicSpec.setUplinkPortKey(null);
                  }
                  if (hostTwophysicalNics != null) {
                     hostTwoPnicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();
                     hostTwoPnicSpec.setPnicDevice(hostTwophysicalNics[0]);
                     hostTwoPnicSpec.setUplinkPortKey(null);
                  }
                  if (hostOnephysicalNics.length > hostTwophysicalNics.length) {
                     uplinkPortNames = new String[hostOnephysicalNics.length];
                  } else {
                     uplinkPortNames = new String[hostTwophysicalNics.length];
                  }

                  for (int i = 0; i < uplinkPortNames.length; i++)
                     uplinkPortNames[i] = "Uplink" + i;
                  DVSNameArrayUplinkPortPolicy uplinkPolicyInst = new DVSNameArrayUplinkPortPolicy();
                  uplinkPolicyInst.getUplinkPortName().clear();
                  uplinkPolicyInst.getUplinkPortName().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(uplinkPortNames));
                  this.deltaConfigSpec.setUplinkPortPolicy(uplinkPolicyInst);
                  this.deltaConfigSpec.setMaxPorts(2 * (uplinkPortNames.length + 1));
                  for (int i = 0; i < hostConfigSpecElement.length; i++) {
                     hostConfigSpecElement[i] = new DistributedVirtualSwitchHostMemberConfigSpec();
                  }
                  if (configInfo.getDefaultPortConfig() instanceof VMwareDVSPortSetting) {
                     defaultPortConfig = (VMwareDVSPortSetting) configInfo.getDefaultPortConfig();
                     portOrder = new VMwareUplinkPortOrderPolicy();
                     if (uplinkPortNames != null && uplinkPortNames.length > 0) {
                        portOrder.getActiveUplinkPort().clear();
                        portOrder.getActiveUplinkPort().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new String[] { uplinkPortNames[0] }));
                        if (uplinkPortNames.length > 1) {
                           standbyUplinkPorts = new String[uplinkPortNames.length - 1];
                           System.arraycopy(uplinkPortNames, 1,
                                    standbyUplinkPorts, 0,
                                    uplinkPortNames.length - 1);
                           portOrder.getStandbyUplinkPort().clear();
                           portOrder.getStandbyUplinkPort().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(standbyUplinkPorts));
                        } else {
                           portOrder.getStandbyUplinkPort().clear();
                           portOrder.getStandbyUplinkPort().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new String[] {}));
                        }
                     }
                     defaultPortConfig.getUplinkTeamingPolicy().setUplinkPortOrder(
                              portOrder);
                  }
                  this.deltaConfigSpec.setDefaultPortConfig(defaultPortConfig);
                  hostOnePnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
                  hostTwoPnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
                  hostOnePnicBacking.getPnicSpec().clear();
                  hostOnePnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] { hostOnepnicSpec }));
                  hostTwoPnicBacking.getPnicSpec().clear();
                  hostTwoPnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] { hostTwoPnicSpec }));
                  hostConfigSpecElement[0].setBacking(hostOnePnicBacking);
                  hostConfigSpecElement[1].setBacking(hostTwoPnicBacking);
                  hostConfigSpecElement[0].setHost(this.hostMor1);
                  hostConfigSpecElement[1].setHost(this.hostMor2);
                  hostConfigSpecElement[0].setMaxProxySwitchPorts(new Integer(
                           uplinkPortNames.length + 1));
                  hostConfigSpecElement[1].setMaxProxySwitchPorts(new Integer(
                           uplinkPortNames.length + 1));
                  hostConfigSpecElement[0].setOperation(TestConstants.CONFIG_SPEC_ADD);
                  hostConfigSpecElement[1].setOperation(TestConstants.CONFIG_SPEC_ADD);
                  this.deltaConfigSpec.getHost().clear();
                  this.deltaConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(hostConfigSpecElement));
                  status = true;
               } else {
                  log.error("Cannot create the distributed virtual "
                           + "switch with the config spec passed");
               }
            } else {
               log.error("Failed to create the network folder");
            }
         }
     
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that creates the DVS.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Reconfigure an existing DVS as follows:\n"
               + "  - Set the DVSConfigSpec.configVersion to a valid config version"
               + " string\n"
               + "  - Set the DVSConfigSpec.name to a valid string\n"
               + "  - Set DVSConfigSpec.maxPort to a valid number that is equal to the"
               + " numPort\n"
               + "  - Set DVSConfigSpec.numPort to a valid number equal to the number "
               + "of uplink ports per host\n"
               + "  - Set DVSConfigSpec.uplinkPortPolicy to a valid array that has "
               + "number of elements equal to the number of pnics being added. "
               + "({uplink1, .. uplink(n)})\n"
               + "The following spec for two hosts:\n"
               + "  - Set DistributedVirtualSwitchHostMemberConfigSpec.operation to ADD\n"
               + "  - Set DistributedVirtualSwitchHostMemberConfigSpec.host to a valid "
               + "hostMor\n"
               + "  - Set DistributedVirtualSwitchHostMemberConfigSpec.proxy  to a valid "
               + "pnic proxy selection"
               + " with the pnic spec(s) containing a valid pnic key and a null value "
               + " for uplinkPortKey\n"
               + "  - Set DistributedVirtualSwitchHostMemberConfigSpec.MaxProxySwitchPorts "
               + "to a valid number equal to the number uplink ports per host.")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
     
         status = this.iDistributedVirtualSwitch.reconfigure(this.dvsMOR,
                  this.deltaConfigSpec);
         assertTrue(status, "Test Failed");
     
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
      boolean status = true;
     
         status &= super.testCleanUp();
     
      assertTrue(status, "Cleanup failed");
      return status;
   }
}