package dvs.functional.opaquenetwork;

import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.util.Assert.assertNotNull;

import java.util.Vector;

import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualMachineCloneSpec;
import com.vmware.vc.VirtualMachineRelocateSpec;
import com.vmware.vcqa.util.TestUtil;

public class T28 extends OpaqueNetworkBase
{
   private ManagedObjectReference firstHost = null;
   private ManagedObjectReference secondHost = null;

   @BeforeMethod
   public boolean testSetUp()
      throws Exception
   {
      /*
       * Init code for all entities in the inventory
       */
      initialize();
      /*
       * Find cluster which hosts are placed in
       */
      ClusterPreparation("NONE");
      /*
       * Get a usable vm.
       */
      getOneTestVm();
      /*
       * Prepare hosts, set firstHost and secondHost properly.
       */
      ManagedObjectReference hostMor = vm.getHost(vmMor);
      this.firstHost = hostMor;
      for (ManagedObjectReference tmpHostMor : this.clusterHosts) {
         if (!ihs.getHostName(tmpHostMor).equals(ihs.getHostName(firstHost))) {
            this.secondHost = tmpHostMor;
         }
      }
      /* start nsxa on both hosts */
      Vector<ManagedObjectReference> hostVector = new Vector<ManagedObjectReference>();
      hostVector.add(this.firstHost);
      hostVector.add(this.secondHost);
      for (ManagedObjectReference tmpMor : hostVector) {
         String tmpName = this.ihs.getHostName(tmpMor);
         assertTrue(startNsxa(null, null, opaque_uplink, tmpMor),
                  "Succeeded to start nsxa on " + tmpName,
                  "Failed to start nsxa on " + tmpName);
      }
      /*
       * Query for the opaque network
       */
      getOpaqueNetwork(this.firstHost);
      /*
       * Set up one test vm to reconfigure vnic to connect to opaque
       * networking and power on the vm.
       */
      oneTestVmSetup();

      return true;
   }

   @Test(description = "Clone a vm from template connecting to an"
            + " opaque network")
   public void test()
      throws Exception
   {
      String templateName = "template" + TestUtil.getTime() + "-"
               + this.getClass().getName();
      String vmName = vm.getVMName(this.vmMor);

      /*
       * Generate template
       */
      VirtualMachineRelocateSpec relSpec = new VirtualMachineRelocateSpec();
      VirtualMachineCloneSpec cloneSpec = new VirtualMachineCloneSpec();
      cloneSpec.setLocation(relSpec);
      cloneSpec.setTemplate(true);
      cloneSpec.setCustomization(null);
      cloneSpec.setPowerOn(false);
      log.info("Generate a template " + templateName + " from vm " + vmName);
      templateVmMor = vm.cloneVM(this.vmMor, vm.getParentNode(this.vmMor),
               templateName, cloneSpec);
      assertNotNull(templateVmMor, "VM successfully cloned to template",
               "Unable to clone vm to a template");

      /*
       * Deploy VM from template
       */
      cloneSpec.setPowerOn(true);
      cloneSpec.setTemplate(false);
      relSpec.setPool(this.vm.getResourcePool(this.vmMor));
      log.info("Deploy VM from template " + templateName);
      deployedVmMor = this.vm.cloneVM(templateVmMor, vm.getVMFolder(),
               vm.getVMName(this.vmMor) + "-DeployedVM", cloneSpec);
      assertNotNull(deployedVmMor,
               "Successfully deployed the vm from template",
               "Unable to deploy the vm from template");
      /*
       * Verifies VM backinfo is still opaque network.
       */
      verifyVmBackingInfo(deployedVmMor);
   }
}
