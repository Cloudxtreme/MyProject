/*
 * ************************************************************************
 *
 * Copyright 2009-2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */

package dvs.querycompatiblehostfornewdvs;

import com.vmware.vcqa.IDataDrivenTest;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.Vector;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.Factory;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;
import com.vmware.vc.DistributedVirtualSwitchProductSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.IDataDrivenTest;
import com.vmware.vcqa.LogUtil;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.execution.TestExecutionUtils;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchManager;

/**
 * DESCRIPTION:<br>
 * (Test case for querycompatiblehostfornewdvs) <br>
 * TARGET: VC <br>
 * <br>
 * SETUP:<br>
 * 1. Get the Compatible Hosts for given vDs version<BR>
 * TEST:<br>>
 * 2.Invoke queryCompatibleHostForNewDvs method by passing container as
 * datacenter, recursive as true and valid  ProductSpec<BR>
 * CLEANUP:<BR>
 */
public class Pos001 extends TestBase implements IDataDrivenTest 
{
   /*
    * private data variables
    */
   private DistributedVirtualSwitchManager dvsManager = null;
   private ManagedObjectReference dvsManagerMor = null;
   private Folder folder = null;
   private HostSystem hostSystem = null;
   private Vector<ManagedObjectReference> allHosts =
            new Vector<ManagedObjectReference>();
   private String hostVersion = null;

   /**
    * Factory method to create the data driven tests.
    *
    * @return Object[] TestBase objects.
    *
    * @throws Exception
    */
   @Factory
   @Parameters({"dataFile"})
   public Object[] getTests(@Optional("")String dataFile) throws Exception {
      return TestExecutionUtils.getTests(this.getClass().getName(), dataFile);
   }
   public String getTestName()
   {
      return getTestId();
   }
   public void setTestDescription()
   {
      setTestDescription("Invoke queryCompatibleHostForNewDvs method by passing container"
               + "as datacenter, recursive as true and  "
               + "as valid ProductSpec .");
   }

   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      dvsManager = new DistributedVirtualSwitchManager(connectAnchor);
      dvsManagerMor = dvsManager.getDvSwitchManager();
      folder = new Folder(connectAnchor);
      hostSystem = new HostSystem(connectAnchor);
      hostVersion = this.data.getString(DVSTestConstants.HOST_VERSION);
      allHosts =
               this.hostSystem.getAllHosts(this.folder.getRootFolder(),
                        hostVersion, true);
      assertTrue((allHosts != null && allHosts.size() > 0),
               "Found required hosts ", "Failed  to get required hosts");
      return true;
   }

   @Test(description = "Invoke queryCompatibleHostForNewDvs method by passing container"
               + "as datacenter, recursive as true and  "
               + "as valid ProductSpec .")
   public void test()
      throws Exception
   {
      DistributedVirtualSwitchProductSpec switchProductSpec = null;
      log.info("Invoking  queryDvsFeatureCapability..");
      switchProductSpec =
               DVSUtil.getProductSpec(connectAnchor, this.data
                        .getString(DVSTestConstants.NEW_VDS_VERSION));
      assertNotNull(switchProductSpec,
               "Successfully obtained  the productSpec",
               "Null returned for productSpec");
      LogUtil.printDetailedObject(switchProductSpec, ":");
      ManagedObjectReference[] hosts =
               this.dvsManager.queryCompatibleHostForNewDVS(dvsManagerMor,
                        this.folder.getDataCenter(), true, switchProductSpec);
      Vector<ManagedObjectReference> hostList = TestUtil.arrayToVector(hosts);
      assertTrue((hostList.containsAll(allHosts)), " Successfully verified"
               + " the compatible host for an new DVS", " Failed to verify "
               + " the compatible host for an new DVS");

   }

   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      return true;
   }
   


}
