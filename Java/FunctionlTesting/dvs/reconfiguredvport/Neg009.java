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
import com.vmware.vc.InvalidArgument;
import com.vmware.vc.MethodFault;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.dvs.DVSUtil;

import dvs.CreateDVSTestBase;

/**
 * Reconfigure DVPort. See setTestDescription for detailed description
 */
public class Neg009 extends CreateDVSTestBase
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
      super.setTestDescription("Set averageBandWidth of outShapingPolicy to "
               + "negative value");
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
                     portConfigSpecs[0] = this.createPortConfigSpec(portKeyList.get(0));

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
   @Test(description = "Set averageBandWidth of outShapingPolicy to "
               + "negative value")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      try {
         this.iDVS.reconfigurePort(this.dvsMOR, this.portConfigSpecs);
         log.error("Exception should thrown in this test case");
         status = false;
      } catch (Exception actualMethodFaultExcep) {
         MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(actualMethodFaultExcep);
         InvalidArgument expectedMethodFault = new InvalidArgument();
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
      boolean status = true;
     
         status &= super.testCleanUp();
     
      assertTrue(status, "Cleanup failed");
      return status;
   }

   /**
    * create DVPort ConfigSpec
    */
   private DVPortConfigSpec createPortConfigSpec(String key)
   {
      DVPortConfigSpec configSpec = new DVPortConfigSpec();
      List<DistributedVirtualPort> dvPorts = null;
      DVPortSetting dvPortSetting = null;
      DVSTrafficShapingPolicy outShapingPolicy = null;
      DVPortConfigInfo dvPortConfigInfo = null;
      DistributedVirtualSwitchPortCriteria portCriteria = null;
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
               dvPortSetting.setBlocked(DVSUtil.getBoolPolicy(false,
                        new Boolean(false)));
               outShapingPolicy = dvPortSetting.getInShapingPolicy();
               if (outShapingPolicy == null) {
                  outShapingPolicy = DVSUtil.getTrafficShapingPolicy(false,
                           true, new Long(-1), null, null);
               } else {
                  outShapingPolicy.setEnabled(DVSUtil.getBoolPolicy(false, true));
                  outShapingPolicy.setAverageBandwidth(DVSUtil.getLongPolicy(
                           false, new Long(-1)));
               }
               dvPortSetting.setInShapingPolicy(outShapingPolicy);
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