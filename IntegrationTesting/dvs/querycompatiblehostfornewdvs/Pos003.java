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
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.Factory;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;
import java.util.*;

import com.vmware.vc.*;
import com.vmware.vcqa.IDataDrivenTest;
import com.vmware.vcqa.LogUtil;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.execution.TestExecutionUtils;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.*;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchManager;

/**
 * DESCRIPTION:<br>
 * (Test case for queryCompatibleHostForExistingDvs) <br>
 * TARGET: VC <br>
 * <br>
 * SETUP:<br>
 * 1.Get the Compatible Hosts for given vDs version and move hosts to cluster<BR>
 * TEST:<br>>
 * 2.Invoke querycompatiblehostfornewdvs method by passing container as
 * cluster, recursive as true and valid ProductSpec <BR>
 * CLEANUP:<br>
 */
public class Pos003 extends TestBase implements IDataDrivenTest 
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
   private ClusterComputeResource clusterComputeResource = null;
   private ManagedObjectReference clusterMor = null;
   private ManagedObjectReference hostFolderMor = null;
   private ManagedObjectReference dcMor = null;
   private boolean moved = false;
   private final int TIMEOUT_MULTIPLIER = 3;

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
      setTestDescription("1.Get the Compatible Hosts for given vDs version and move hosts to cluster\n" +
      		"2.Invoke queryCompatibleHostForNewDvs method by passing container"
               + "as cluster, recursive as true and switchProductSpec "
               + "as valid ProductSpec.");
   }

   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      ClusterConfigSpec clusterSpec = null;
      dvsManager = new DistributedVirtualSwitchManager(connectAnchor);
      dvsManagerMor = dvsManager.getDvSwitchManager();
      folder = new Folder(connectAnchor);
      hostSystem = new HostSystem(connectAnchor);
      clusterComputeResource = new ClusterComputeResource(connectAnchor);
      hostVersion = this.data.getString(DVSTestConstants.HOST_VERSION);
      allHosts =
               this.hostSystem.getAllHosts(this.folder.getRootFolder(),
                        hostVersion, true);
      assertTrue((allHosts != null && allHosts.size() > 0),
               "Found required hosts ", "Failed  to get required hosts");
      /*
       * Move two hosts to cluster
       */
      dcMor = folder.getDataCenter();
      hostFolderMor = folder.getHostFolder(dcMor);
      clusterSpec = folder.createClusterSpec();
      clusterMor = folder.createCluster(hostFolderMor, getTestId()
               + "-cluster", clusterSpec);
      assertTrue(clusterComputeResource.moveInto(clusterMor,
               TestUtil.vectorToArray(allHosts)),
               "hosts  moved successfully ",
               "Unable to move the hosts to cluster");
      moved = true;
      return true;
   }

   @Test(description = "1.Get the Compatible Hosts for given vDs version and move hosts to cluster\n" +
      		"2.Invoke queryCompatibleHostForNewDvs method by passing container"
               + "as cluster, recursive as true and switchProductSpec "
               + "as valid ProductSpec.")
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
                        clusterMor, true, switchProductSpec);
      Vector<ManagedObjectReference> hostList = TestUtil.arrayToVector(hosts);
      assertTrue((hostList.containsAll(allHosts)), " Successfully verified"
               + " the compatible host for an new DVS", " Failed to verify "
               + " the compatible host for an new DVS");

   }

   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      if (moved) {
          /*
           * reset the hosts back
           */
         hostFolderMor = folder.getHostFolder(dcMor);
         VirtualMachine ivm = new VirtualMachine(connectAnchor);
         ivm.powerOffVMs(ivm.getAllVM());
         try {
             hostSystem.enterMaintenanceModes(allHosts,
                 TestConstants.ENTERMAINTENANCEMODE_TIMEOUT
                 * TIMEOUT_MULTIPLIER, false);
             assertTrue((folder.moveInto(hostFolderMor, allHosts)),
                 "Moved hosts  successfully", " Move hosts failed ");
         } catch (Exception e) {
             log.error("Unable to enter MT mode or enter MT mode timeout!");
         } finally {
             try {
                 hostSystem.exitMaintenanceModes(allHosts,
                     TestConstants.EXIT_MAINTMODE_DEFAULT_TIMEOUT_SECS);
             } catch (Exception e) {
                 log.error("Unable to exit MT mode or currently not in MT mode!");
             } finally {
                 assertTrue((folder.destroy(clusterMor)),
                     "Successfully destroyed cluster",
                     "Unable to  destroy cluster");
             }
         }
      }
      return true;
   }
}
