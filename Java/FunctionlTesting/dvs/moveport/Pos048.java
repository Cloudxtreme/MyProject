/*
 * ************************************************************************
 *
 * Copyright 2009 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.moveport;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.List;

import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;

/**
 * Move a DVPort from a DVPortGroup to same DVPortGroup. Discard the moveports
 * for the ports where source and destination potGroup are same
 */
public class Pos048 extends MovePortBase
{
   DVPortgroupConfigSpec pgConfigSpec = null;
   String pgName = null;
   List<ManagedObjectReference> pgList = null;
   ManagedObjectReference pgMor = null;

   @Override
   public void setTestDescription()
   {
      setTestDescription("Move a DVPort from DVPortGroup to same DVPortGroup."
               + "Discard the moveports for the ports where source and "
               + " destination potGroup are same");
   }

   /**
    * Test setup.<br>
    * 1. Create DVS. <br>
    * 2. Create early binding DVPortgroup with one port in it.<br>
    * 3. Use the DVPort in added DVPortgroup as port key.<br>
    * 4. Use the key of DVPortgroup as destination.<br>
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
               pgConfigSpec = new DVPortgroupConfigSpec();
               pgName = getTestId() + "_earlypg";
               pgConfigSpec.setName(pgName);
               pgConfigSpec.setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
               pgConfigSpec.setNumPorts(1);
               pgList = iDVSwitch.addPortGroups(dvsMor,
                        new DVPortgroupConfigSpec[] { pgConfigSpec });
               if ((pgList != null) && (pgList.size() == 1)) {
                  log.info("Successfully added the early binding "
                           + "portgroup to the DVS " + pgName);
                  pgMor = pgList.get(0);
                  if (pgMor != null) {
                     portgroupKey = iDVPortGroup.getKey(pgMor);
                     if (portgroupKey != null) {
                        // Use port from the same DVPortgroup.
                        portKeys = fetchPortKeys(dvsMor, portgroupKey);
                        if ((portKeys != null) && (portKeys.size() >= 1)) {
                           status = true;
                        }
                     }
                  }
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
    * @throws Exception
    */
   @Override
   @Test(description = "Move a DVPort from DVPortGroup to same DVPortGroup."
               + "Discard the moveports for the ports where source and "
               + " destination potGroup are same")
   public void test()
      throws Exception
   {
      assertTrue(movePort(dvsMor, portKeys, portgroupKey), "Successfully "
               + "moved the port", "Failed to move the port");
   }
}
