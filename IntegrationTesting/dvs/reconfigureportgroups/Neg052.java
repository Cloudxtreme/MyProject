package dvs.reconfigureportgroups;

import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Factory;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortConfigSpec;
import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSSecurityPolicy;
import com.vmware.vc.InvalidArgument;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VMwareDVSPortgroupPolicy;
import com.vmware.vcqa.IDataDrivenTest;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.execution.TestExecutionUtils;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * DESCRIPTION:<br>
 * Data-driven test to reconfigure Portgroup with IpfixOverrideAllowed to true
 * SETUP:<br>
 * 1. Create a DVS with a host adding to it, and with the 1 standalone port<br>
 * 2. Create a PortSetting with IpfixEnabled as false<br>
 * 3. Reconfigure port with the above portsetting<br>
 * 4. Create PortGroup and add it to the vDS<br>
 * 5. Move the standalone port into the portgroup<br>
 * TEST:
 * 1. Reconfigure DVPortGroup with IpfixEnabled to false
 * CLEANUP:<br>
 * 3. Destroy the portgroup and dvSwitch<br>
 */

public class Neg052 extends TestBase implements IDataDrivenTest
{

   private Folder folder = null;
   private ManagedObjectReference rootFolderMor = null;
   private ManagedObjectReference dvsMor = null;
   private VMwareDVSConfigSpec dvsConfigSpec = null;
   private DistributedVirtualSwitch iDVSwitch = null;
   private List<ManagedObjectReference> dvPortgroupMorList = null;
   private DVPortgroupConfigSpec[] dvPortgroupConfigSpecArray = null;
   private DVPortgroupConfigSpec dvPortgroupConfigSpec = null;
   private DistributedVirtualPortgroup iDVPortgroup = null;
   private String portKey = null;
   private ManagedObjectReference hostMor = null;
   private HostSystem hs = null;
   private ManagedObjectReference networkFolderMor = null;

   /**
    * Test Setup
    */
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      DVPortConfigSpec portConfigSpec = null;
      VMwareDVSPortSetting portSetting = null;
      VMwareDVSPortgroupPolicy dvPortgroupPolicy = null;
      Map<String, Object> settingsMap = null;
      this.hs = new HostSystem(connectAnchor);
      this.hostMor = this.hs.getConnectedHost(null);
      this.folder = new Folder(connectAnchor);
      this.iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
      this.iDVPortgroup = new DistributedVirtualPortgroup(connectAnchor);
      this.rootFolderMor = this.folder.getRootFolder();
      Assert.assertNotNull(this.rootFolderMor, "Unable to get RootFolderMor");
      this.dvsConfigSpec = new VMwareDVSConfigSpec();
      this.dvsConfigSpec.setConfigVersion("");
      this.dvsConfigSpec.setName(this.getClass().getName());
      this.dvsConfigSpec.setNumStandalonePorts(1);
      this.dvsConfigSpec = (VMwareDVSConfigSpec) DVSUtil.addHostsToDVSConfigSpec(
               dvsConfigSpec, Arrays.asList(this.hostMor));
      this.networkFolderMor = this.folder.getNetworkFolder(this.folder.getDataCenter());
      this.dvsMor = this.folder.createDistributedVirtualSwitch(
               this.networkFolderMor, this.dvsConfigSpec);
      Assert.assertNotNull(this.dvsMor, "Failed to create DVS");
      portKey = iDVSwitch.getFreeStandaloneDVPortKey(dvsMor, null);
      Assert.assertNotNull(portKey, "Could not find DVPort Key");
      log.info("Successfully found a DVPort key");
      portConfigSpec = new DVPortConfigSpec();
      portConfigSpec.setKey(portKey);
      portConfigSpec.setOperation(TestConstants.CONFIG_SPEC_EDIT);
      settingsMap = new HashMap<String, Object>();
      settingsMap.put(DVSTestConstants.SECURITY_POLICY_KEY,
               DVSUtil.getDVSSecurityPolicy(false, true, true, true));
      portSetting = DVSUtil.getDefaultVMwareDVSPortSetting(settingsMap);
      // Set IpfixEnabled to true
      portSetting.setIpfixEnabled(DVSUtil.getBoolPolicy(false, true));
      portConfigSpec.setSetting(portSetting);
      Assert.assertTrue(iDVSwitch.reconfigurePort(dvsMor,
               new DVPortConfigSpec[] { portConfigSpec }),
               "Successfully reconfigured the port");
      this.dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
      this.dvPortgroupConfigSpec.setName(this.getTestId());
      this.dvPortgroupConfigSpec.setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
      dvPortgroupPolicy = new VMwareDVSPortgroupPolicy();
      dvPortgroupPolicy.setLivePortMovingAllowed(true);
      dvPortgroupPolicy.setIpfixOverrideAllowed(this.data.getBoolean(
               DVSTestConstants.IPFIXOVERRIDEALLOWED, true));
      dvPortgroupPolicy.setSecurityPolicyOverrideAllowed(true);
      this.dvPortgroupConfigSpec.setPolicy(dvPortgroupPolicy);
      dvPortgroupConfigSpecArray = new DVPortgroupConfigSpec[] { dvPortgroupConfigSpec };
      dvPortgroupMorList = iDVSwitch.addPortGroups(dvsMor,
               dvPortgroupConfigSpecArray);
      Assert.assertNotNull(dvPortgroupMorList, "Could not add PortGroups");
      Assert.assertTrue(
               dvPortgroupMorList.size() == dvPortgroupConfigSpecArray.length,
               "Failed to move the port into portgroup",
               "Successfully added all the " + "portgroups");
      Assert.assertTrue(this.iDVSwitch.movePort(dvsMor,
               new String[] { portKey },
               this.iDVPortgroup.getKey(dvPortgroupMorList.get(0))),
               "Successfully moved the " + "port into the portgroup.");
      return status;
   }

   /**
    * Test method
    */
   @Test(description="Data-driven test to Reconfigure PortGroup to a DistributedVirtualSwitch with "
               + "ipfixOverrideAllowed set to true")
   public void test()
      throws Exception
   {
      try {
         VMwareDVSPortSetting portgroupSetting = null;
         VMwareDVSPortgroupPolicy policy = null;
         DVSSecurityPolicy portgroupSecurityPolicy = null;
         Map<String, Object> settingsMap = null;
         Assert.assertTrue(dvPortgroupMorList != null
                  && dvPortgroupMorList.size() > 0,
                  "There are no portgroups to be reconfigured");
         this.dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
         this.dvPortgroupConfigSpec.setConfigVersion(this.iDVPortgroup.getConfigInfo(
                  dvPortgroupMorList.get(0)).getConfigVersion());
         portgroupSetting = (VMwareDVSPortSetting) this.iDVSwitch.getConfig(dvsMor).getDefaultPortConfig();
         portgroupSecurityPolicy = portgroupSetting.getSecurityPolicy();
         if (portgroupSecurityPolicy == null) {
            portgroupSecurityPolicy = DVSUtil.getDVSSecurityPolicy(false,
                     Boolean.TRUE, Boolean.TRUE, Boolean.TRUE);
         } else {
            portgroupSecurityPolicy.setInherited(false);
            portgroupSecurityPolicy.setAllowPromiscuous(DVSUtil.getBoolPolicy(
                     false, Boolean.TRUE));
            portgroupSecurityPolicy.setForgedTransmits(DVSUtil.getBoolPolicy(
                     false, Boolean.TRUE));
            portgroupSecurityPolicy.setMacChanges(DVSUtil.getBoolPolicy(false,
                     Boolean.TRUE));
         }
         settingsMap = new HashMap<String, Object>();
         settingsMap.put(DVSTestConstants.SECURITY_POLICY_KEY,
                  portgroupSecurityPolicy);
         portgroupSetting = DVSUtil.getDefaultVMwareDVSPortSetting(settingsMap);
         // Set IpfixEnabled to false
         portgroupSetting.setIpfixEnabled(DVSUtil.getBoolPolicy(false, false));
         policy = new VMwareDVSPortgroupPolicy();
         policy.setSecurityPolicyOverrideAllowed(false);
         this.dvPortgroupConfigSpec.setPolicy(policy);
         this.dvPortgroupConfigSpec.setDefaultPortConfig(portgroupSetting);
         Assert.assertTrue(
                  this.iDVPortgroup.reconfigure(dvPortgroupMorList.get(0),
                           this.dvPortgroupConfigSpec),
                  "Successfully reconfigured the portgroup. The API did not throw an exception",
                  "Failed to reconfigure the portgroup. The API did not throw an exception");
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         com.vmware.vc.MethodFault expectedMethodFault = new InvalidArgument();
         com.vmware.vcqa.util.Assert.assertTrue(
                  com.vmware.vcqa.util.TestUtil.checkMethodFault(
                           actualMethodFault, expectedMethodFault),
                  "MethodFault mismatch!");
      }
   }

   /**
    * Test Cleanup
    */
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = false;
      if (this.dvPortgroupMorList != null) {
         for (ManagedObjectReference mor : dvPortgroupMorList) {
            status &= this.iDVPortgroup.destroy(mor);
         }
      }
      if (this.dvsMor != null) {
         status &= this.iDVSwitch.destroy(dvsMor);
      }
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
