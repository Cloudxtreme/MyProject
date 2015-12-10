/*
 * ************************************************************************
 *
 * Copyright 2011 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.nrp.addnrp;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Factory;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;

import com.vmware.vc.DVSNetworkResourcePoolAllocationInfo;
import com.vmware.vc.DVSNetworkResourcePoolConfigSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.SharesInfo;
import com.vmware.vc.SharesLevel;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.execution.TestExecutionUtils;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.NetworkResourcePoolHelper;

/**
 * DESCRIPTION:Add maximum user defined NRPs on a vDS.<BR>
 * TARGET:VC<BR>
 * SETUP:<BR>
 * 1.create the dvs<BR>
 * 2.enable netiorm<BR>
 * 3.set the values in the config spec<BR>
 * TEST:<BR>
 * 4.add maximum number of user defined nrps on vDS<BR>
 * CLEANUP:<BR>
 * 5.Destroy dvs<BR>
 */
public class Pos006 extends TestBase
{
   private DistributedVirtualSwitch dvs;
   private ManagedObjectReference dvsMor;

   @Factory
   @Parameters( { "dataFile" })
   public Object[] getTests(@Optional("") String dataFile)
      throws Exception
   {
      return TestExecutionUtils.getTests(this.getClass().getName(), dataFile);
   }

   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      Folder folder = new Folder(connectAnchor);
      dvs = new DistributedVirtualSwitch(connectAnchor);
      // create the dvs
      dvsMor = folder.createDistributedVirtualSwitch(getTestId(),
               DVSUtil.getvDsVersion());
      // enable netiorm
      Assert.assertTrue(dvs.enableNetworkResourceManagement(dvsMor, true),
               "Netiorm not enabled");
      Assert.assertTrue(NetworkResourcePoolHelper.isNrpEnabled(connectAnchor,
               dvsMor), "NRP not enabled");
      return true;
   }

   @Test(description = "Add maximum user defined NRPs on a vDS.")
   public void test()
      throws Exception
   {
      for(int i=0;i<DVSUtil.getMaxNRPs();i++) {
         DVSNetworkResourcePoolConfigSpec spec = new DVSNetworkResourcePoolConfigSpec();
         spec.setKey(DVSTestConstants.NRP_DEFAULT_KEY);
         spec.setName(DVSTestConstants.NRP_DEFAULT_NAME);
         spec.setDescription(DVSTestConstants.NRP_DEFAULT_DESC);
         DVSNetworkResourcePoolAllocationInfo info = new DVSNetworkResourcePoolAllocationInfo();
         info.setLimit(DVSTestConstants.NRP_DEFAULT_LIMIT);
         SharesInfo shares = new SharesInfo();
         shares.setLevel(SharesLevel.CUSTOM);
         shares.setShares(25);
         info.setShares(shares);
         info.setLimit(DVSTestConstants.NRP_DEFAULT_LIMIT);
         info.setPriorityTag(DVSTestConstants.NRP_DEFAULT_PTAG);
         spec.setAllocationInfo(info);
         dvs.addNetworkResourcePool(dvsMor,
                  new DVSNetworkResourcePoolConfigSpec[] { spec });
         if(i==52){
        	 ++i;
        	 --i;
         }
         log.info(" Created :"+ (i +1) + "user defined  NRP(s)"  );
      }
   }

   /**
    * Cleanup method Destroy the dvs
    */
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      // delete the dvs
      Assert.assertTrue(dvs.destroy(dvsMor), "DVS destroyed",
               "Unable to destroy DVS");

      return true;
   }

}
