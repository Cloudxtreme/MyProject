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
import com.vmware.vc.DVPortSetting;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DVSTrafficShapingPolicy;
import com.vmware.vc.DistributedVirtualPort;
import com.vmware.vc.DistributedVirtualSwitchPortCriteria;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.dvs.DVSUtil;

import dvs.CreateDVSTestBase;

/**
 * Reconfigure DVPort. See setTestDescription for detailed description
 */
public class Pos021 extends CreateDVSTestBase
{

   /*
    * private data variables
    */
   private DistributedVirtualSwitch iDVS = null;
   private DVPortConfigSpec[] portConfigSpecs = null;
   private final int DVS_PORT_NUM = 4;

   /**
    * Sets the test description.
    *
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      super.setTestDescription("Reconfigure multiple DVPorts with valid "
               + "inShapingPolicy and outShapingPolicy");
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
                     portConfigSpecs = this.createPortConfigSpec(portKeyList);
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
   @Test(description = "Reconfigure multiple DVPorts with valid "
               + "inShapingPolicy and outShapingPolicy")
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
    * Create DVPort configSpec with valid inShapingPolicy and outShapingPolicy
    */
   private DVPortConfigSpec[] createPortConfigSpec(List<String> portKeyList)
      throws Exception
   {
      DVPortConfigSpec[] configSpecs = new DVPortConfigSpec[DVS_PORT_NUM];
      for (int i = 0; i < DVS_PORT_NUM; i++) {
         if (i == 0) {
            configSpecs[i] = createPortConfigSpec(portKeyList.get(i), true,
                     true);
         }
         if (i == 1) {
            configSpecs[i] = createPortConfigSpec(portKeyList.get(i), true,
                     false);
         }
         if (i == 2) {
            configSpecs[i] = createPortConfigSpec(portKeyList.get(i), false,
                     true);
         }
         if (i == 3) {
            configSpecs[i] = createPortConfigSpec(portKeyList.get(i), false,
                     false);
         }
      }
      return configSpecs;

   }

   /**
    * Create DVPort configSpec with valid inShapingPolicy and outShapingPolicy
    */
   private DVPortConfigSpec createPortConfigSpec(String key,
                                                 boolean inshaping,
                                                 boolean defaultPolicy)
   {
      DistributedVirtualSwitchPortCriteria portCriteria = null;
      DVPortConfigSpec configSpec = new DVPortConfigSpec();
      List<DistributedVirtualPort> dvPorts = null;
      DVPortSetting dvPortSetting = null;
      DVSTrafficShapingPolicy inShapingPolicy = null;
      DVSTrafficShapingPolicy outShapingPolicy = null;
      DVPortConfigInfo dvPortConfigInfo = null;
      try {
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
               dvPortSetting = dvPortConfigInfo.getSetting();
               if (dvPortSetting == null) {
                  dvPortSetting = (VMwareDVSPortSetting) DVSUtil.getDefaultVMwareDVSPortSetting(null);
               }
               if (dvPortSetting instanceof VMwareDVSPortSetting) {
                  VMwareDVSPortSetting VMwareDVSPort = (VMwareDVSPortSetting) dvPortSetting;
                  VMwareDVSPort.setLacpPolicy(null);
               }
               dvPortSetting.setBlocked(DVSUtil.getBoolPolicy(false,
                        new Boolean(false)));
               if (inshaping) {
                  if (defaultPolicy) {
                     inShapingPolicy = DVSUtil.getTrafficShapingPolicy(false,
                              true, null, null, null);
                  } else {

                  }
                  inShapingPolicy = dvPortSetting.getInShapingPolicy();
                  if (inShapingPolicy == null) {
                     if (defaultPolicy) {
                        inShapingPolicy = DVSUtil.getTrafficShapingPolicy(
                                 false, true, null, null, null);
                     } else {
                        if (inShapingPolicy == null) {
                           inShapingPolicy = DVSUtil.getTrafficShapingPolicy(
                                    false, true,
                                    TestConstants.DEFAULT_AVERAGE_BAND_WIDTH,
                                    TestConstants.DEFAULT_PEAK_BAND_WIDTH,
                                    TestConstants.DEFAULT_BURST_SIZE);
                        } else {
                           inShapingPolicy.setInherited(false);
                           inShapingPolicy.setEnabled(DVSUtil.getBoolPolicy(
                                    false, true));
                           inShapingPolicy.setPeakBandwidth(DVSUtil.getLongPolicy(
                                    false,
                                    new Long(
                                             TestConstants.DEFAULT_PEAK_BAND_WIDTH)));
                           inShapingPolicy.setAverageBandwidth(DVSUtil.getLongPolicy(
                                    false,
                                    new Long(
                                             TestConstants.DEFAULT_AVERAGE_BAND_WIDTH)));
                           inShapingPolicy.setBurstSize(DVSUtil.getLongPolicy(
                                    false, new Long(
                                             TestConstants.DEFAULT_BURST_SIZE)));
                        }
                     }

                  }
                  dvPortSetting.setInShapingPolicy(inShapingPolicy);
               } else {
                  outShapingPolicy = dvPortSetting.getOutShapingPolicy();
                  if (outShapingPolicy == null) {
                     if (defaultPolicy) {
                        outShapingPolicy = DVSUtil.getTrafficShapingPolicy(
                                 false, true, null, null, null);
                     } else {
                        if (outShapingPolicy == null) {
                           outShapingPolicy = DVSUtil.getTrafficShapingPolicy(
                                    false, true,
                                    TestConstants.DEFAULT_AVERAGE_BAND_WIDTH,
                                    TestConstants.DEFAULT_PEAK_BAND_WIDTH,
                                    TestConstants.DEFAULT_BURST_SIZE);
                        } else {
                           outShapingPolicy.setInherited(false);
                           outShapingPolicy.setEnabled(DVSUtil.getBoolPolicy(
                                    false, true));
                           outShapingPolicy.setPeakBandwidth(DVSUtil.getLongPolicy(
                                    false,
                                    new Long(
                                             TestConstants.DEFAULT_PEAK_BAND_WIDTH)));
                           outShapingPolicy.setAverageBandwidth(DVSUtil.getLongPolicy(
                                    false,
                                    new Long(
                                             TestConstants.DEFAULT_AVERAGE_BAND_WIDTH)));
                           outShapingPolicy.setBurstSize(DVSUtil.getLongPolicy(
                                    false, new Long(
                                             TestConstants.DEFAULT_BURST_SIZE)));
                        }
                     }

                  }
                  dvPortSetting.setOutShapingPolicy(outShapingPolicy);
               }
               configSpec.setSetting(dvPortSetting);
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
