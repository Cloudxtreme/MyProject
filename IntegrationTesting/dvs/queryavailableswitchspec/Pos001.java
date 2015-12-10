/*
 * ************************************************************************
 *
 * Copyright 2009 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */

package dvs.queryavailableswitchspec;

import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.Test;
import com.vmware.vc.DistributedVirtualSwitchProductSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.LogUtil;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchManager;

/**
 * Query the switch product specifications that are supported by the Virtual
 * Center Server
 */
public class Pos001 extends TestBase
{
   /*
    * private data variables
    */
   private DistributedVirtualSwitchManager iDistributedVirtualSwitchManager = null;
   private ManagedObjectReference dvsManagerMor = null;

   public void setTestDescription()
   {
      setTestDescription("Query the switch product specifications that are "
               + "supported by the Virtual Center Server");
   }

   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
   {
      boolean setupDone = false;
      try {
         iDistributedVirtualSwitchManager = new DistributedVirtualSwitchManager(
                  connectAnchor);
         dvsManagerMor = iDistributedVirtualSwitchManager.getDvSwitchManager();
         setupDone = true;
      } catch (Exception e) {
         TestUtil.handleException(e);
      }
      assertTrue(setupDone, "Setup failed");
      return setupDone;
   }

   @Test(description = "Query the switch product specifications that are "
               + "supported by the Virtual Center Server")
   public void test()
      throws Exception
   {
      boolean testDone = false;
      DistributedVirtualSwitchProductSpec switchProductSpec[] = null;
      ;
      try {
         log.info("Invoking  queryDvsFeatureCapability..");
         switchProductSpec = this.iDistributedVirtualSwitchManager.queryAvailableSwitchSpec(dvsManagerMor);
         assertNotNull(switchProductSpec,
                  "Successfully obtained  the productSpec",
                  "Null returned for productSpec");
         LogUtil.printDetailedObject(switchProductSpec, ":");
         testDone = true;
      } catch (Exception e) {
         TestUtil.handleException(e);
      }
      assertTrue(testDone, "Test Failed");
   }

   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      return true;
   }
}
