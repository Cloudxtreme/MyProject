/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvport;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.ConfigSpecOperation;
import com.vmware.vc.DVPortConfigInfo;
import com.vmware.vc.DVPortConfigSpec;
import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DVSNameArrayUplinkPortPolicy;
import com.vmware.vc.DVSUplinkPortPolicy;
import com.vmware.vc.DistributedVirtualPort;
import com.vmware.vc.DistributedVirtualSwitchPortCriteria;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.DVPortSetting;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VMwareUplinkPortOrderPolicy;
import com.vmware.vc.VmwareUplinkPortTeamingPolicy;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.dvs.DVSUtil;

import dvs.CreateDVSTestBase;

/**
 * Reconfigure DVPort. See setTestDescription for detailed description
 */
public class Pos031 extends CreateDVSTestBase
{

   /*
    * private data variables
    */
   private DistributedVirtualSwitch iDVS = null;
   private DVPortConfigSpec[] portConfigSpecs = null;
   private final int DVS_PORT_NUM = 1;

   /**
    * Sets the test description.
    *
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      super.setTestDescription("Reconfigure DVPort with valid uplink teaming "
               + "policy");
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
      log.info("Test setup Begin:");

         if (super.testSetUp()) {
            this.networkFolderMor = this.iFolder.getNetworkFolder(this.dcMor);
            if (this.networkFolderMor != null) {
               this.iDVS = new DistributedVirtualSwitch(connectAnchor);
               configSpec = new DVSConfigSpec();
               configSpec.setName(this.getClass().getName());
               configSpec.setNumStandalonePorts(DVS_PORT_NUM);

               dvsMOR = this.iFolder.createDistributedVirtualSwitch(
                        this.networkFolderMor, this.configSpec);
               if (this.dvsMOR != null) {
                  log.info("Successfully created the DVSwitch");
                  List<String> portKeyList = iDVS.fetchPortKeys(dvsMOR, null);
                  if (portKeyList != null && portKeyList.size() == DVS_PORT_NUM) {
                     portConfigSpecs = new DVPortConfigSpec[DVS_PORT_NUM];
                     portConfigSpecs[0] = this.createPortConfigSpec(dvsMOR,
                              portKeyList.get(0));
                     DVPortSetting dvPortSetting =
                                    portConfigSpecs[0].getSetting();
                     if (dvPortSetting instanceof VMwareDVSPortSetting) {
                        VMwareDVSPortSetting VMwareDVSPort =
                                    (VMwareDVSPortSetting) dvPortSetting;
                        VMwareDVSPort.setLacpPolicy(null);
                        portConfigSpecs[0].setSetting(VMwareDVSPort);
                     }
                     status = true;
                  } else {
                     log.error("Can't get correct port keys");
                  }
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
   @Test(description = "Reconfigure DVPort with valid uplink teaming "
               + "policy")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;

         status = this.iDVS.reconfigurePort(this.dvsMOR, this.portConfigSpecs);
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

   /**
    * Create DVPort configSpec with valid security policy and valid vlanid range
    */
   private DVPortConfigSpec createPortConfigSpec(ManagedObjectReference dvsMor,
                                                 String key)
      throws Exception
   {

      DistributedVirtualSwitchPortCriteria portCriteria = null;
      DVSConfigInfo dvsConfigInfo = null;
      DVPortConfigSpec configSpec = new DVPortConfigSpec();
      List<DistributedVirtualPort> dvPorts = null;
      VMwareDVSPortSetting setting = null;
      DVPortConfigInfo dvPortConfigInfo = null;
      VmwareUplinkPortTeamingPolicy uplinkTeamingPolicy = null;
      DVSUplinkPortPolicy uplinkPortPolicy = null;
      VMwareUplinkPortOrderPolicy uplinkOrderPolicy = null;
      try {
         dvsConfigInfo = this.iDVS.getConfig(dvsMor);
         uplinkPortPolicy = dvsConfigInfo.getUplinkPortPolicy();
         if (uplinkPortPolicy != null
                  && uplinkPortPolicy instanceof com.vmware.vc.DVSNameArrayUplinkPortPolicy) {
            uplinkOrderPolicy = new VMwareUplinkPortOrderPolicy();
            String[] uplinkPortNames = com.vmware.vcqa.util.TestUtil.vectorToArray(((DVSNameArrayUplinkPortPolicy) uplinkPortPolicy).getUplinkPortName(), java.lang.String.class);
            String[] activePortNames = new String[1];
            activePortNames[0] = uplinkPortNames[0];
            uplinkOrderPolicy.getActiveUplinkPort().clear();
            uplinkOrderPolicy.getActiveUplinkPort().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(activePortNames));
            if (uplinkPortNames.length > 1) {
               String[] standbyPortNames = new String[uplinkPortNames.length - 1];
               for (int i = 0; i < uplinkPortNames.length - 1; i++) {
                  standbyPortNames[i] = uplinkPortNames[i + 1];
               }
               uplinkOrderPolicy.getStandbyUplinkPort().clear();
               uplinkOrderPolicy.getStandbyUplinkPort().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(standbyPortNames));
            }
         }
         portCriteria = new DistributedVirtualSwitchPortCriteria();
         portCriteria.getPortKey().clear();
         portCriteria.getPortKey().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new String[] { key }));
         dvPorts = this.iDVS.fetchPorts(this.dvsMOR, portCriteria);
         if (dvPorts != null && dvPorts.get(0) != null) {
            log.info("Successfully obtained the port");
            dvPortConfigInfo = dvPorts.get(0).getConfig();
            if (dvPortConfigInfo != null) {
               configSpec.setKey(key);
               configSpec.setOperation(ConfigSpecOperation.EDIT.value());
               setting = (VMwareDVSPortSetting) dvPortConfigInfo.getSetting();
               if (setting == null) {
                  setting = (VMwareDVSPortSetting) DVSUtil.getDefaultVMwareDVSPortSetting(null);
               }
               uplinkTeamingPolicy = setting.getUplinkTeamingPolicy();
               if (uplinkTeamingPolicy == null) {
                  uplinkTeamingPolicy = DVSUtil.getUplinkPortTeamingPolicy(
                           false, null, true, true, true, null,
                           uplinkOrderPolicy);
               } else {
                  uplinkTeamingPolicy.setInherited(false);
                  uplinkTeamingPolicy.setUplinkPortOrder(uplinkOrderPolicy);
                  uplinkTeamingPolicy.setNotifySwitches(DVSUtil.getBoolPolicy(
                           false, true));
                  uplinkTeamingPolicy.setReversePolicy(DVSUtil.getBoolPolicy(
                           false, true));
                  uplinkTeamingPolicy.setRollingOrder(DVSUtil.getBoolPolicy(
                           false, true));
               }
               setting.setBlocked(DVSUtil.getBoolPolicy(false, new Boolean(
                        false)));
               configSpec.setSetting(setting);
            } else {
               log.error("Failed to obtain the DVPortConfigInfo");
               configSpec = null;
            }
         } else {
            log.error("Failed to obtain the port " + "config spec");
            configSpec = null;
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
      }
      return configSpec;

   }
}
