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
 * Data driven test class to handle the negative tests for reconfigure dvs
 * with lldp parameters
 */
public class Neg069 extends TestBase implements IDataDrivenTest
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

   /**
    * This method creates a vds
    *
    * @return boolean
    *
    * @throws Exception
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
      /*
       * Create the vds
       */
      this.vdsMor = this.folder.createDistributedVirtualSwitch(
         this.folder.getNetworkFolder(this.dcMor), this.vdsConfigSpec);
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
    * This method reconfigures the vds with the lldp parameters.
    *
    * @throws Exception
    */
   @Test(description="Data driven test class to handle the negative tests " +
      "for reconfigure dvs with lldp parameters")
   public void test()
      throws Exception
   {
      String expectedMethodFaultValue = this.data.
         getString("expectedMethodFault");
      if(expectedMethodFaultValue != null){
         Class<?> faultClass = Class.forName(expectedMethodFaultValue);
         Constructor<?> faultCons = faultClass.getConstructor();
         Object faultObj = faultCons.newInstance();
         if(faultObj instanceof MethodFault){
            expectedMethodFault = (MethodFault)faultObj;
         }
      }
      try{
         /*
          * Reconfigure the vds to set the link layer discovery parameters
          */
         assertTrue(this.vds.reconfigure(this.vdsMor, this.vdsConfigSpec),
            "Successfully reconfigured the vds","Failed to reconfigure " +
               "the vds");
         log.error("Successfully reconfigured the vds and the api did not " +
            "throw an exception");
         throw new Exception();
      } catch(Exception actualMethodFaultExcep){
         MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(actualMethodFaultExcep);
         if(expectedMethodFault != null){
            assertTrue(TestUtil.checkMethodFault(actualMethodFault,
               expectedMethodFault),"There was a mismatch in the " +
                  "exception type thrown");
         } else {
            throw new com.vmware.vc.MethodFaultFaultMsg("", actualMethodFault);
         }
      }
   }

   /**
    * This method destroys the vds created in the setup
    *
    * @return boolean
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
    * This method gets all the test ids as specified in the data file. If
    * a specific test id is mentioned in the dvs execution properties file,
    * it will pick up only one test.
    *
    * @param dataFile
    *
    * @return Object[]
    *
    * @throws Exception
    */
   @Factory
   @Parameters({"dataFile"})
   public Object[] getTests(@Optional("") String dataFile)
      throws Exception
   {
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
    * @see org.testng.ITest#getTestName()
    */
   public String getTestName()
   {
      return getTestId();
   }
}
