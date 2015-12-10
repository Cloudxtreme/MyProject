/*
 * ************************************************************************
 *
 * Copyright 2011 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.createdvs;

import static com.vmware.vc.DistributedVirtualSwitchHostMemberHostComponentState.*;
import static com.vmware.vcqa.util.Assert.*;

import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Factory;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DVSNameArrayUplinkPortPolicy;
import com.vmware.vc.DistributedVirtualSwitchHostMember;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.IDataDrivenTest;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.execution.TestExecutionUtils;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.NetworkSystem;

import dvs.CreateDVSTestBase;

/**
 * Create DVSwitch with defaultproxyswitchMaxNumports set to valid value
 */
public class Pos084 extends CreateDVSTestBase implements IDataDrivenTest
{
   private HostSystem ihs = null;
   private Vector<ManagedObjectReference> allHosts = null;
   private ManagedObjectReference hostMor = null;
   private NetworkSystem iNetworkSystem = null;
   private String hostName = null;
   private int defaultMaxProxyPorts = 0;

   @Override
   public void setTestDescription()
   {
      super.setTestDescription("Create dvswitch with " +
            "defaultProxyswitchMaxNumPorts set to a valid value");
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
      final DVSNameArrayUplinkPortPolicy uplinkPolicyInst = new
      DVSNameArrayUplinkPortPolicy();
      final String[] uplinkPortNames = new String[32];
      final String dvsName = getTestId();
      if (super.testSetUp()) {
         ihs = new HostSystem(connectAnchor);
         iNetworkSystem = new NetworkSystem(connectAnchor);
         allHosts = ihs.getAllHost();
         assertNotNull(allHosts, "The list of hosts is not null",
                  "The list of hosts is null");
         hostMor = allHosts.get(0);
         hostName = ihs.getHostName(hostMor);
         networkFolderMor = iFolder.getNetworkFolder(dcMor);
         assertNotNull(networkFolderMor, "Found the network folder",
                  "The network folder mor is null");
         configSpec = new DVSConfigSpec();
         configSpec.setName(dvsName);
         defaultMaxProxyPorts = this.data.getInt(DVSTestConstants.
                  DEFAULTHOSTPROXYMAXPORTS);
         configSpec.setDefaultProxySwitchMaxNumPorts(defaultMaxProxyPorts);
         configSpec.setNumStandalonePorts(20);
         final String[] physicalNics = iNetworkSystem.getPNicIds(hostMor);
         assertNotNull(physicalNics, "Found free pnics on the host",
                  "Failed to find free pnics on the host");
         pnicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();
         pnicSpec.setPnicDevice(physicalNics[0]);
         pnicSpec.setUplinkPortKey(null);
         pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
         hostConfigSpecElement = new
            DistributedVirtualSwitchHostMemberConfigSpec();
         pnicBacking.getPnicSpec().clear();
         pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new
                  DistributedVirtualSwitchHostMemberPnicSpec[] { pnicSpec }));
         hostConfigSpecElement.setBacking(pnicBacking);
         hostConfigSpecElement.setHost(hostMor);
         hostConfigSpecElement.setOperation(TestConstants.CONFIG_SPEC_ADD);
         configSpec.getHost().clear();
         configSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new
                  DistributedVirtualSwitchHostMemberConfigSpec[] {
                  hostConfigSpecElement }));
         status = true;
      }
      return status;
   }

   /**
    * Method that creates the DVS.
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @Test(description = "Create DVSwitch with defaultProxySwitchMaxNumPorts " +
         "set to a valid value")
   public void test()
      throws Exception
   {
      boolean status = false;
      DVSConfigInfo dvsConfigInfo = null;
      DistributedVirtualSwitchHostMember hostMember = null;
      dvsMOR = iFolder.createDistributedVirtualSwitch(networkFolderMor,
               configSpec);
      assertNotNull(dvsMOR, "The dvs mor is not null", "The dvs mor is null");
      assertTrue(iDistributedVirtualSwitch.validateDVSConfigSpec(dvsMOR,
               configSpec, null),"Successfully validated that the dvs " +
               "retains all properties in the config spec",
               "The dvs does not retain all the properties in the config spec");
      assertTrue(DVSUtil.getMaxProxyPortsFromHost(hostMor, connectAnchor) ==
                 defaultMaxProxyPorts,"The host reflects the correct number " +
                 "of max default proxy switch ports","The host does not " +
                 "reflect the correct number of max default proxy switch " +
                 "ports");

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

   /**
    * This method retrieves either all the data-driven tests or one
    * test based on the presence of test id in the execution properties
    * file.
    *
    * @return Object[]
    *
    * @throws Exception
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

   public String getTestName()
   {
      return getTestId();
   }
}