/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.moveport;

import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING;

import java.util.ArrayList;
import java.util.Map;

import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DistributedVirtualPort;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * Move DVPorts to DVS where 1. A DVPort is in an early bind DVPortgroup. 2. A
 * standalone DVPort in the DVS.
 */
public class Pos029 extends MovePortBase
{
   /**
    * Set the brief description of this test.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Move DVPorts to DVS where\r\n"
               + "1. A DVPort is in an early bind DVPortgroup.\r\n"
               + "2. A standalone DVPort in the DVS.");
   }

   /**
    * Test setup. 1. Create DVS. 2. Create a standalone port in DVS. 3. Create a
    * early binding DVPortgroup with one port. 4. Use key of DVPort in this
    * DVPortgroup along with standalone DVPort as ports to be moved.
    * 
    * @param connectAnchor ConnectAnchor.
    * @return boolean true, if test setup was successful. false, otherwise.
    */
   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
     
         if (super.testSetUp()) {
            dvsMor = iFolder.createDistributedVirtualSwitch(dvsName);
            if (dvsMor != null) {
               portKeys = new ArrayList<String>(2);
               log.info("Adding standalone DVPort...");
               portKeys.addAll(iDVSwitch.addStandaloneDVPorts(dvsMor, 1));
               log.info("Adding early binding DVPortgroup...");
               portgroupKey = iDVSwitch.addPortGroup(dvsMor,
                        DVPORTGROUP_TYPE_EARLY_BINDING, 1, prefix + "PG");
               if (portgroupKey != null) {
                  log.info("Successfully added early binding DVPortgroup.");
                  portKeys.addAll(fetchPortKeys(dvsMor, portgroupKey));
                  log.info("DVPorts to be moved: " + portKeys);
                  if (portKeys.size() >= 2) {
                     status = true;
                  } else {
                     log.error("Failed to get required number of DVPorts.");
                  }
               } else {
                  log.error("Failed to add early binding DVPortgroup.");
               }
            }
         }
     
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Test. Move DVPorts (standalone + early) -> DVS.
    * 
    * @param connectAnchor ConnectAnchor.
    */
   @Override
   @Test(description = "Move DVPorts to DVS where\r\n"
               + "1. A DVPort is in an early bind DVPortgroup.\r\n"
               + "2. A standalone DVPort in the DVS.")
   public void test()
      throws Exception
   {
      boolean status = false;
     
         Map<String, DistributedVirtualPort> connectedEntitiespMap = DVSUtil.getConnecteeInfo(
                  connectAnchor, dvsMor, portKeys);
         status = movePort(dvsMor, portKeys, null);// move it to DVS.
         status &= DVSUtil.verifyConnecteeInfoAfterMovePort(connectAnchor,
                  connectedEntitiespMap, dvsMor, portKeys, portgroupKey);
     
      assertTrue(status, "Test Failed");
   }
}
