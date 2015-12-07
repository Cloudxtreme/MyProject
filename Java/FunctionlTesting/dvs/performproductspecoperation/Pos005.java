/*
 * ************************************************************************
 *
 * Copyright 2009-2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */

package dvs.performproductspecoperation;

import com.vmware.vcqa.IDataDrivenTest;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.Factory;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DVSCreateSpec;
import com.vmware.vc.DistributedVirtualSwitchProductSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.TaskInfo;
import com.vmware.vc.TaskInfoState;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.execution.TestExecutionUtils;
import com.vmware.vcqa.util.ThreadUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Task;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * DESCRIPTION:<br>
 * (Test case for ProductSpecOperation ) <br>
 * TARGET: VC <br>
 * SETUP:<br>
 * 1.Create two DVSs source and destination with older vDs version <br>
 * 2.Create new vDs version product spec<BR>
 * 3.Merge both source and destination DVS<BR>
 * TEST:<br>>
 * 4.Invoke perform ProductSpecOperation while merge task is in progress.
 * CLEANUP:<br>
 * 5. Destroy vDs<br>
 */
public class Pos005 extends TestBase implements IDataDrivenTest
{
   /*
    * private data variables
    */
   private DistributedVirtualSwitch DVS = null;
   private ManagedObjectReference dvsMor = null;
   private DistributedVirtualSwitchProductSpec productSpec = null;
   private ManagedObjectReference taskMor = null;
   private Task itask = null;
   private TaskInfo taskInfo = null;

   /**
    * Factory method to create the data driven tests.
    *
    * @return Object[] TestBase objects.
    *
    * @throws Exception
    */
   @Factory
   @Parameters( { "dataFile" })
   public Object[] getTests(@Optional("") String dataFile)
      throws Exception
   {
      return TestExecutionUtils.getTests(this.getClass().getName(), dataFile);
   }

   public String getTestName()
   {
      return getTestId();
   }

   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      DVSCreateSpec createSpec = null;
      ManagedObjectReference srcDVSMor = null;
      DVS = new DistributedVirtualSwitch(connectAnchor);
      this.itask = new Task(connectAnchor);

      /*
       * Create DVS with older vDs version
       */
      productSpec =
               DVSUtil.getProductSpec(connectAnchor, this.data
                        .getString(DVSTestConstants.OLD_VDS_VERSION));
      createSpec =
               DVSUtil.createDVSCreateSpec(DVSUtil
                        .createDefaultDVSConfigSpec(null), productSpec, null);
      dvsMor = DVSUtil.createDVSFromCreateSpec(connectAnchor, createSpec);
      assertNotNull(dvsMor, "Successfully created the DVSwitch",
               "Null returned for Distributed Virtual Switch MOR");
      DVSConfigSpec spec = DVSUtil.createDefaultDVSConfigSpec(null);
      spec.setNumStandalonePorts(500);
      createSpec = DVSUtil.createDVSCreateSpec(spec, productSpec, null);
      srcDVSMor = DVSUtil.createDVSFromCreateSpec(connectAnchor, createSpec);
      assertNotNull(srcDVSMor, "Successfully created the DVSwitch",
               "Null returned for Distributed Virtual Switch MOR");
      productSpec =
               DVSUtil.getProductSpec(connectAnchor, this.data
                        .getString(DVSTestConstants.NEW_VDS_VERSION));
      assertNotNull(productSpec, "Successfully created  the productSpec",
               "Null returned for productSpec");
      this.taskMor = this.DVS.asyncMerge(dvsMor, srcDVSMor);
      taskInfo = this.itask.getTaskInfo(this.taskMor);
      int i = 0;
      while ((taskInfo.getState().equals(TaskInfoState.QUEUED)
         || taskInfo.getState().equals(TaskInfoState.SUCCESS)
         || taskInfo.getState().equals(TaskInfoState.RUNNING)) && i <= 10) {
         log.info("Task is in queued/running/success State");
         taskInfo = this.itask.getTaskInfo(this.taskMor);
         if (taskInfo.getState().equals(TaskInfoState.RUNNING)) {
            log.info("Merge task is running");
            status = true;
            break;
         } else if (taskInfo.getState().equals(TaskInfoState.SUCCESS)) {
            status = true;
            break;
         } else {
            log.warn("Merge task is not running.. try again" + i);
            i++;
            ThreadUtil.sleep(10000);
         }
      }
      assertTrue(status, "Merge task is " + taskInfo.getState().toString(), "Merge task is not running");
      return true;
   }

   @Test(description = "1.Create two DVSs source and destination with"
            + " older vDs version\n"
            + "  2.Create new vDs version product spec .\n"
            + " 3.Merge both source and destination DVS\n"
            + " 2.Invoke perform ProductSpecOperation while merge "
            + "task is in progress.")
   public void test()
      throws Exception
   {
      log.info("Invoking  ProductSpecOperation..");
      assertTrue(this.DVS.performProductSpecOperation(dvsMor,
               DVSTestConstants.OPERATION_UPGRADE, productSpec),
               " Successfully completed performProductSpecOperation",
               " performProductSpecOperation failed");
      assertTrue(DVSUtil.getUpgradedEvent(dvsMor, connectAnchor),
               " Failed to get DvsUpgradedEvent");
      taskInfo = this.itask.getTaskInfo(this.taskMor);
      /*
       * Check if the task of merge task succeeded
       */
      assertTrue((taskInfo.getState().equals(TaskInfoState.SUCCESS)),
               "merge task succeeded", "merge task  not succeeded");

   }

   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      if (this.dvsMor != null) {
         assertTrue((this.DVS.destroy(dvsMor)), "Successfully deleted DVS",
                  "Unable to delete DVS");
      }

      return true;
   }

}
