/*
 * ************************************************************************
 *
 * Copyright 2008-2009 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.createdvs;

import static com.vmware.vc.DistributedVirtualSwitchHostMemberHostComponentState.*;
import static com.vmware.vcqa.util.Assert.*;

import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DVSNameArrayUplinkPortPolicy;
import com.vmware.vc.DistributedVirtualSwitchHostMember;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.host.NetworkSystem;

import dvs.CreateDVSTestBase;

/**
 * Create DVSwitch with the following parameters with the following parameters
 * set in the configSpec:<br>
 * - DVSConfigSpec.configVersion is set to an empty string.<br>
 * - DVSConfigSpec.name is set to "CreateDVS-Pos017" - DVSConfigSpec.maxPort set
 * to a valid number equal to 2*numPorts <br>
 * - DVSConfigSpec.numPort set to a valid number equal to the number of uplinks
 * ports per host<br>
 * - DVSConfigSpec.uplinkPortPolicy set to a valid array that is equal to the
 * max number of pnics per host.({uplink1, ..., uplink32})<br>
 * - DistributedVirtualSwitchHostMemberConfigSpec.operation set to add<br>
 * - DistributedVirtualSwitchHostMemberConfigSpec.host set to a valid host Mor<br>
 * - DistributedVirtualSwitchHostMemberConfigSpec.proxy set a a valid pnic proxy
 * selection with pnic spec having a valid pnic device and uplinkPortKey set to
 * null<br>
 * - DistributedVirtualSwitchHostMemberConfigSpec.MaxProxySwitchPorts set to a
 * valid number equal to numPorts
 */
public class Pos017 extends CreateDVSTestBase
{
   private HostSystem ihs = null;
   private Vector<ManagedObjectReference> allHosts = null;
   private ManagedObjectReference hostMor = null;
   private NetworkSystem iNetworkSystem = null;
   private String hostName = null;

   @Override
   public void setTestDescription()
   {
      super.setTestDescription("Create DVSwitch with the following parameters"
               + " with the following parameters set in the configSpec:\n"
               + "- DVSConfigSpec.configVersion is set to an empty string,\n"
               + "- DVSConfigSpec.name is set to 'CreateDVS-Pos017',\n"
               + "- DVSConfigSpec.maxPort set to a valid number equal to 2*numPorts,\n"
               + "- DVSConfigSpec.numPort set to a valid number equal to the number of"
               + "uplinks ports per host,\n"
               + "- DVSConfigSpec.uplinkPortPolicy set to a valid array that is equal "
               + "to the max number of pnics per host,\n"
               + "- DistributedVirtualSwitchHostMemberConfigSpec.operation set to add,\n"
               + "- DistributedVirtualSwitchHostMemberConfigSpec.host set to a valid host Mor,\n"
               + "- DistributedVirtualSwitchHostMemberConfigSpec.proxy set a a valid pnic proxy selection "
               + "with pnic spec having a valid pnic device and uplinkPortKey set to "
               + "null,\n"
               + "- DistributedVirtualSwitchHostMemberConfigSpec.MaxProxySwitchPorts set to a valid number "
               + "equal to numPorts.");
   }

   @Override
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      DistributedVirtualSwitchHostMemberPnicSpec pnicSpec = null;
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      DistributedVirtualSwitchHostMemberConfigSpec hostConfigSpecElement = null;
      final DVSNameArrayUplinkPortPolicy uplinkPolicyInst = new DVSNameArrayUplinkPortPolicy();
      final String[] uplinkPortNames = new String[32];
      final String dvsName = getTestId();
      if (super.testSetUp()) {
         ihs = new HostSystem(connectAnchor);
         iNetworkSystem = new NetworkSystem(connectAnchor);
         allHosts = ihs.getAllHost();
         if (allHosts != null) {
            hostMor = allHosts.get(0);
            hostName = ihs.getHostName(hostMor);
         } else {
            log.error("Valid Host MOR not found");
         }
         networkFolderMor = iFolder.getNetworkFolder(dcMor);
         if (networkFolderMor != null) {
            configSpec = new DVSConfigSpec();
            configSpec.setConfigVersion("");
            configSpec.setName(dvsName);
            for (int i = 0; i < 32; i++) {
               uplinkPortNames[i] = "Uplink" + i;
            }
            uplinkPolicyInst.getUplinkPortName().clear();
            uplinkPolicyInst.getUplinkPortName().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(uplinkPortNames));
            configSpec.setMaxPorts(2 * uplinkPortNames.length);
            configSpec.setNumStandalonePorts(uplinkPortNames.length);
            configSpec.setUplinkPortPolicy(uplinkPolicyInst);
            final String[] physicalNics = iNetworkSystem.getPNicIds(hostMor);
            if (physicalNics != null) {
               pnicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();
               pnicSpec.setPnicDevice(physicalNics[0]);
               pnicSpec.setUplinkPortKey(null);
               pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
               hostConfigSpecElement = new DistributedVirtualSwitchHostMemberConfigSpec();
               pnicBacking.getPnicSpec().clear();
               pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] { pnicSpec }));
               hostConfigSpecElement.setBacking(pnicBacking);
               hostConfigSpecElement.setHost(hostMor);
               hostConfigSpecElement.setMaxProxySwitchPorts(new Integer(
                        uplinkPortNames.length));
               hostConfigSpecElement.setOperation(TestConstants.CONFIG_SPEC_ADD);
               configSpec.getHost().clear();
               configSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostConfigSpecElement }));
               status = true;
            } else {
               log.error("No free pnics found on the host.");
            }
         } else {
            log.error("Failed to create the network folder");
         }
      } else {
         log.error("Test setup failed.");
      }
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that creates the DVS.
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @Test(description = "Create DVSwitch with the following parameters"
            + " with the following parameters set in the configSpec:\n"
            + "- DVSConfigSpec.configVersion is set to an empty string,\n"
            + "- DVSConfigSpec.name is set to 'CreateDVS-Pos017',\n"
            + "- DVSConfigSpec.maxPort set to a valid number equal to 2*numPorts,\n"
            + "- DVSConfigSpec.numPort set to a valid number equal to the number of"
            + "uplinks ports per host,\n"
            + "- DVSConfigSpec.uplinkPortPolicy set to a valid array that is equal "
            + "to the max number of pnics per host,\n"
            + "- DistributedVirtualSwitchHostMemberConfigSpec.operation set to add,\n"
            + "- DistributedVirtualSwitchHostMemberConfigSpec.host set to a valid host Mor,\n"
            + "- DistributedVirtualSwitchHostMemberConfigSpec.proxy set a a valid pnic proxy selection "
            + "with pnic spec having a valid pnic device and uplinkPortKey set to "
            + "null,\n"
            + "- DistributedVirtualSwitchHostMemberConfigSpec.MaxProxySwitchPorts set to a valid number "
            + "equal to numPorts.")
   public void test()
      throws Exception
   {
      boolean status = false;
      DVSConfigInfo dvsConfigInfo = null;
      DistributedVirtualSwitchHostMember hostMember = null;
      if (configSpec != null) {
         dvsMOR = iFolder.createDistributedVirtualSwitch(networkFolderMor,
                  configSpec);
         if (dvsMOR != null) {
            log.info("Successfully created the DVSwitch");
            if (iDistributedVirtualSwitch.validateDVSConfigSpec(dvsMOR,
                     configSpec, null)) {
               Thread.sleep(10000);
               dvsConfigInfo = iDistributedVirtualSwitch.getConfig(dvsMOR);
               if ((dvsConfigInfo != null) && (com.vmware.vcqa.util.TestUtil.vectorToArray(dvsConfigInfo.getHost(), com.vmware.vc.DistributedVirtualSwitchHostMember.class) != null)
                        && (com.vmware.vcqa.util.TestUtil.vectorToArray(dvsConfigInfo.getHost(), com.vmware.vc.DistributedVirtualSwitchHostMember.class).length > 0)
                        && (com.vmware.vcqa.util.TestUtil.vectorToArray(dvsConfigInfo.getHost(), com.vmware.vc.DistributedVirtualSwitchHostMember.class)[0] != null)) {
                  hostMember = com.vmware.vcqa.util.TestUtil.vectorToArray(dvsConfigInfo.getHost(), com.vmware.vc.DistributedVirtualSwitchHostMember.class)[0];
                  if ((hostMember.getStatus() != null)
                           && hostMember.getStatus().equals(UP.value())) {
                     log.info("Verified the DVS status of the host " + hostName);
                     status = true;
                  } else {
                     log.error("The DVS status for ths host member is not "
                              + "updated " + hostName + "Status"
                              + hostMember.getStatus());
                  }
               } else {
                  log.error("The host did not appear in the DVS "
                           + "configuration " + hostName);
               }
            } else {
               log.info("The config spec of the Distributed Virtual "
                        + "Switch is not created as per specifications");
            }
         } else {
            log.error("Cannot create the distributed "
                     + "virtual switch with the config spec passed");
         }
      }
      assertTrue(status, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test is started.
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      final boolean status = super.testCleanUp();
      assertTrue(status, "Cleanup failed");
      return status;
   }
}