/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvs;

import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;

import java.lang.reflect.Constructor;
import java.util.ArrayList;
import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Factory;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;

import com.vmware.vc.LinkDiscoveryProtocolConfig;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.PhysicalNic;
import com.vmware.vc.PhysicalNicHintInfo;
import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vcqa.IDataDrivenTest;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.execution.TestExecutionUtils;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchHelper;
import com.vmware.vcqa.vim.host.NetworkSystem;


/**
 * Data driven test class to handle all positive test cases for lldp
 * in reconfigure vds api
 *
 * @author sabesanp
 */
public class Pos098 extends TestBase implements IDataDrivenTest
{

   private DistributedVirtualSwitch vds = null;
   private Folder folder = null;
   private HostSystem host = null;
   private ManagedObjectReference hostMor = null;
   private ManagedObjectReference vdsMor = null;
   private ManagedObjectReference dcMor = null;
   private VMwareDVSConfigSpec vdsConfigSpec = null;
   private NetworkSystem networkSystem = null;
   private ManagedObjectReference nsMor = null;
   private MethodFault expectedMethodFault = null;
   private LinkDiscoveryProtocolConfig linkDiscoveryProtocolConfig = null;
   private LinkDiscoveryProtocolConfig srcLinkDiscoveryProtocolConfig = null;

   /**
    * This method sets up the environment for the test.It creates the
    * vds and populates the lldp parameters for reconfiguring the vds.
    */
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      this.folder = new Folder(this.connectAnchor);
      this.dcMor = this.folder.getDataCenter();
      assertNotNull(this.dcMor, "Failed to find a datacenter");
      /*
      * This test needs atleast one host in the inventory. Test should not
      * proceed if there is no host in the inventory.
      */
      this.host = new HostSystem(this.connectAnchor);
      this.hostMor = this.host.getConnectedHost(false);
      this.vds = new DistributedVirtualSwitchHelper(connectAnchor);
      assertNotNull(this.hostMor,"Failed to find a host in the " +
         "inventory");
      this.networkSystem = new NetworkSystem(this.connectAnchor);
      this.nsMor = this.networkSystem.getNetworkSystem(this.hostMor);
      /*
       * Create the config spec for a vmware distributed switch with
       * lldp parameters as read from the data file
       */
      vdsConfigSpec = new VMwareDVSConfigSpec();
      vdsConfigSpec.setName(this.data.getString(DVSTestConstants.VDS_NAME));
      srcLinkDiscoveryProtocolConfig = new LinkDiscoveryProtocolConfig();
      if(data.containsKey(DVSTestConstants.LLDP_SRC_PROTOCOL)){
         srcLinkDiscoveryProtocolConfig.setProtocol(data.
            getString(DVSTestConstants.LLDP_SRC_PROTOCOL));
      }
      if(data.containsKey(DVSTestConstants.LLDP_SRC_OPERATION)){
         srcLinkDiscoveryProtocolConfig.setOperation(data.
            getString(DVSTestConstants.LLDP_SRC_OPERATION));
      }
      if(srcLinkDiscoveryProtocolConfig.getOperation() != null &&
         srcLinkDiscoveryProtocolConfig.getProtocol() != null){
         vdsConfigSpec.setLinkDiscoveryProtocolConfig(
            srcLinkDiscoveryProtocolConfig);
      }
      /*
       * Create the vds
       */
      this.vdsMor = this.folder.createDistributedVirtualSwitch(
         this.folder.getNetworkFolder(this.dcMor), this.vdsConfigSpec);
      assertNotNull(this.vdsMor,"Successfully created the vds in the " +
         "inventory","Failed to create the vds in the inventory");
      /*
       * Add the host with the free pnic to the vds
       */
      List<ManagedObjectReference> vdsMorList = new
      ArrayList<ManagedObjectReference>();
      vdsMorList.add(this.vdsMor);
      assertTrue(DVSUtil.addFreePnicAndHostToDVS(this.connectAnchor,
      this.hostMor,vdsMorList),"Successfully added the free pnic on the " +
         "host to the vds","Failed to add the free pnic on the host to " +
            "the vds");
      this.vdsConfigSpec = new VMwareDVSConfigSpec();
      this.vdsConfigSpec.setConfigVersion(this.vds.getConfig(this.vdsMor).
         getConfigVersion());
      linkDiscoveryProtocolConfig = new LinkDiscoveryProtocolConfig();
      linkDiscoveryProtocolConfig.setOperation(this.data.
         getString(DVSTestConstants.LLDP_OPERATION));
      linkDiscoveryProtocolConfig.setProtocol(this.data.getString(
         DVSTestConstants.LLDP_PROTOCOL));
      vdsConfigSpec.setLinkDiscoveryProtocolConfig(linkDiscoveryProtocolConfig);
      return true;
   }

   /**
    * This method reconfigures the vds
    *
    * @throws Exception
    */
   @Test(description="Data driven test class to handle all positive " +
      "test cases for lldp in reconfigure vds api")
   public void test()
      throws Exception
   {
      /*
       * Reconfigure the vds to set the link layer discovery parameters
       */
      assertTrue(this.vds.reconfigure(this.vdsMor, this.vdsConfigSpec),
         "Successfully reconfigured the vds","Failed to reconfigure " +
            "the vds");
      assertTrue(DVSUtil.verifyLldpInfo(this.connectAnchor, this.hostMor,
         this.vdsMor, this.linkDiscoveryProtocolConfig),"The expected " +
            "and actual lldp parameters match","The expected and actual "+
               "lldp parameters do not match");
   }

   /**
    * This method destroys the vds
    *
    * @throws Exception
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      assertTrue(this.vds.destroy(this.vdsMor),"Successfully destroyed " +
         "the vds","Failed to destroy the vds");
      return true;
   }

   /**
    * This method retrieves either all the data-driven tests or one
    * test based on the presence of test id in the execution properties
    * file.
    *
    * @param dataFile
    *
    * @return Object[]
    */
   @Factory
   @Parameters({"dataFile"})
   public Object[] getTests(@Optional("") String dataFile)
      throws Exception {
      Object[] tests = TestExecutionUtils.getTests(this.getClass().getName(),
         dataFile);
      /*
       * Load the dvs execution properties file
       */
      String testId = TestUtil.getPropertyValue(this.getClass().getName(),
         DVSTestConstants.DVS_EXECUTION_PROP_FILE);
      if(testId == null){
         return tests;
      } else {
         for(Object test : tests){
            if(test instanceof TestBase){
               TestBase testBase = (TestBase)test;
               if(testBase.getTestId().equals(testId)){
                  return new Object[]{testBase};
               }
            } else {
               log.error("The current test is not an instance of TestBase");
            }
         }
         log.error("The test id " + testId + "could not be found");
      }
      /*
       * TODO : Examine the possibility of a custom exception here since
       * the test id provided is wrong and the user needs to be notified of
       * that.
       */
      return null;
   }

   /**
    * (non-Javadoc)
    * @see org.testng.ITest#getTestName()
    */
   public String getTestName()
   {
      return getTestId();
   }
}
