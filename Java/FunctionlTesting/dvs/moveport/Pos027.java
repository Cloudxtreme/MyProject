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

import java.util.Map;

import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DistributedVirtualPort;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * Move a DVPort from a DVPortGroup to same DVPortGroup. Moving a DVPort in a
 * DVPortgroup to itself is a no-op and is a valid operation.
 */
public class Pos027 extends MovePortBase
{
   /**
    * Set the brief description of this test.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Move a DVPort from DVPortGroup to same DVPortGroup.");
   }

   /**
    * Test setup. 1. Create DVS. 2. Create early binding DVPortgroup with one
    * port in it. 3. Use the DVPort in added DVPortgroup as port key. 4. Use the
    * key of DVPortgroup as destination.
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
               portgroupKey = iDVSwitch.addPortGroup(dvsMor,
                        DVPORTGROUP_TYPE_EARLY_BINDING, 1, prefix + "PG-Early");
               if (portgroupKey != null) {
                  // Use port from the same DVPortgroup.
                  portKeys = fetchPortKeys(dvsMor, portgroupKey);
                  if ((portKeys != null) && (portKeys.size() >= 1)) {
                     status = true;
                  }
               } else {
                  log.error("Failed to add the port group.");
               }
            }
         }
     
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Test. Move the DVPort in the DVPortgroup by providing null port key.
    * 
    * @param connectAnchor ConnectAnchor.
    */
   @Override
   @Test(description = "Move a DVPort from DVPortGroup to same DVPortGroup.")
   public void test()
      throws Exception
   {
      boolean status = false;
     
         Map<String, DistributedVirtualPort> connectedEntitiespMap = DVSUtil.getConnecteeInfo(
                  connectAnchor, dvsMor, portKeys);
         status = movePort(dvsMor, portKeys, portgroupKey);
         status &= DVSUtil.verifyConnecteeInfoAfterMovePort(connectAnchor,
                  connectedEntitiespMap, dvsMor, portKeys, portgroupKey);
     
      assertTrue(status, "Test Failed");
   }
}
