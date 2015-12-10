/* ************************************************************************
*
* Copyright 2012 VMware, Inc.  All rights reserved. -- VMware Confidential
*
* ************************************************************************
*/
package com.vmware.vcqa.vim.dvs.testframework;

import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;

import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Calendar;
import java.util.List;
import java.util.Vector;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DVSCreateSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.DistributedVirtualSwitchProductSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.PerfCounterInfo;
import com.vmware.vc.PerfEntityMetric;
import com.vmware.vc.PerfEntityMetricBase;
import com.vmware.vc.PerfEntityMetricCSV;
import com.vmware.vc.PerfMetricId;
import com.vmware.vc.PerfMetricIntSeries;
import com.vmware.vc.PerfMetricSeries;
import com.vmware.vc.PerfMetricSeriesCSV;
import com.vmware.vc.PerfProviderSummary;
import com.vmware.vc.PerfQuerySpec;
import com.vmware.vc.Permission;
import com.vmware.vc.UserSession;
import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.AuthorizationHelper;
import com.vmware.vcqa.vim.AuthorizationManager;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.MessageConstants;
import com.vmware.vcqa.vim.PerformanceManager;
import com.vmware.vcqa.vim.SessionManager;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchHelper;
import com.vmware.vcqa.vim.host.NetworkSystem;
import static com.vmware.vcqa.TestConstants.GENERIC_USER;
import static com.vmware.vcqa.TestConstants.PASSWORD;
import static com.vmware.vcqa.TestConstants.ROLE_READONLY_ID;

/**
 * This class represents the subsystem for netvcops configuration
 * operations.It encompasses all possible states and transitions in any scenario
 * (positive/negative/security) with respect to the feature
 */
public class NetvcopsTestFramework
{
   private HostSystem hs = null;
   private DistributedVirtualSwitch vds = null;
   private DistributedVirtualSwitchHelper vdsHelper = null;
   private DistributedVirtualPortgroup vdsPortgroup = null;
   private ConnectAnchor connectAnchor = null;
   private List<Step> stepList = null;
   private DataFactory xmlFactory = null;
   private DVSConfigSpec dvsConfigSpec = null;
   private ManagedObjectReference vdsMor = null;
   private ManagedObjectReference vdsPgMor = null;
   private static final Logger log = LoggerFactory
         .getLogger(NetvcopsTestFramework.class);
   private final String vdsVersion = DVSTestConstants.VDS_VERSION_60;
   private DVPortgroupConfigSpec dvPortGroupConfigSpec = null;
   private VirtualMachine vm = null;
   private Folder folder = null;
   private List<ManagedObjectReference> hostMors = null;
   private NetworkSystem ns = null;
   private Vector<ManagedObjectReference> vmMors = null;
   private PerformanceManager perf = null;
   private ManagedObjectReference perfMgrMor = null;
   private String vdsName = null;
   private VDSTestFramework vdsTestFramework = null;
   private Integer refreshRate = null;
   private Calendar beginTime = null;
   private Calendar endTime = null;
   private Vector<PerfMetricId> metrics = null;
   private PerfMetricId metricId = null;

   /**
    * Constructor
    *
    * @param connectAnchor
    * @param xmlFilePath
    *
    * @throws Exception
    */
   public NetvcopsTestFramework(ConnectAnchor connectAnchor,
         String xmlFilePath)
      throws Exception
   {
      this.connectAnchor = connectAnchor;
      this.vds = new DistributedVirtualSwitch(connectAnchor);
      this.vdsHelper = new DistributedVirtualSwitchHelper(connectAnchor);
      this.vdsPortgroup = new DistributedVirtualPortgroup(connectAnchor);
      this.xmlFactory = new DataFactory(xmlFilePath);
      this.stepList = new ArrayList<Step>();
      this.hs = new HostSystem(connectAnchor);
      this.vm = new VirtualMachine(connectAnchor);
      this.folder = new Folder(connectAnchor);
      this.ns = new NetworkSystem(connectAnchor);
      this.perf = new PerformanceManager(connectAnchor);
      this.perfMgrMor = this.perf.getPerfManager();
      if (this.perfMgrMor == null) {
         throw new Exception("Returned perfMgrMor is null");
      }
      this.vdsTestFramework = new VDSTestFramework(connectAnchor, xmlFilePath);
   }

   /**
    * Method to execute a list of steps provided
    *
    * @param stepList
    *
    * @throws Exception
    */
     public void execute(List<Step> stepList)
          throws Exception {
        for(Step step : stepList) {
           Class currClass = Class.forName(step.getTestFrameworkName());
           Method method = currClass.getDeclaredMethod(step.getName());
           if(currClass.getName().equals(
              VDSTestFramework.class.getName())) {
              this.vdsTestFramework.addStep(step);
              method.invoke(this.vdsTestFramework);
           } else if (currClass.getName().equals(this.getClass().getName())) {
              addStep(step);
              method.invoke(this);
           }
        }
     }

    /**
     * This method adds a step to the list of steps
     *
     * @param step
     */
    public void addStep(Step step)
    {
       this.stepList.add(step);
    }


   /**
    * This method initializes the data pertaining to the step as mentioned in
    * the data file.
    *
    * @param stepName
    *
    * @throws Exception
    */
   public void init(String stepName)
      throws Exception
   {
      Step step = getStep(stepName);
      if (step != null) {
         List<String> data = step.getData();
         if (data != null) {
            List<Object> objIdList = this.xmlFactory.getData(data);
            if (objIdList != null) {
               initData(objIdList);
            }
         }
      }
   }

   /**
    * This method initializes the data for input parameters like selection sets
    * and runtime.
    *
    * @param objIdList
    *
    * @throws Exception
    */
   public void initData(List<Object> objIdList)
      throws Exception
   {
      for (Object object : objIdList) {
         if (object instanceof String) {
            this.vdsName = (String) object;
         }
         if (object instanceof DVSConfigSpec) {
            this.dvsConfigSpec = (DVSConfigSpec) object;
         }
         if (object instanceof DVPortgroupConfigSpec) {
            this.dvPortGroupConfigSpec = (DVPortgroupConfigSpec) object;
         }
      }
   }

   /**
    * This method gets the step associated with the step name. If the step is
    * not executed, return the step and change executed to true.
    *
    * @param name
    *
    * @return Step
    */
   public Step getStep(String name)
   {
      for (Step step : stepList) {
         if (step.getName().equals(name)) {
            if (!step.getExecuted()) {
               step.setExecuted(true);
               return step;
            }
         }
      }
      return null;
   }

   /**
    * This method performs the basic test setup needed for the test
    *
    * @throws Exception
    */
   public void testSetup()
      throws Exception
   {
      List<Object> objIdList =
            this.xmlFactory.getData(getStep("testSetup").getData());
      initData(objIdList);
   }

   /**
    * This performs the most common cleanup operation of destroying all the
    * created vdses
    *
    * @throws Exception
    */
   public void testCleanup()
      throws Exception
   {
      if (this.vmMors != null && this.vmMors.size() > 0) {
         for (ManagedObjectReference vmMor : vmMors) {
            if (this.vm.setVMState(vmMor, VirtualMachinePowerState.POWERED_OFF,
                  false)) {
               this.vm.destroy(vmMor);
            }
         }
      }
      if (this.vdsMor != null) {
         assertTrue(this.vdsHelper.destroy(vdsMor), "Successfully "
               + "destroyed the vds", "Failed to destroy the vds");
      }
   }

   /**
    * This method sets the list of steps
    *
    * @param stepList
    */
   public void setStepsList(List<Step> stepList)
   {
      this.stepList = stepList;
   }

   /**
    * This method create VMs.
    *
    * @throws Exception
    */
   public void createVms()
      throws Exception
   {
      if (this.hostMors == null) {
         this.hostMors = this.hs.getAllHost();
      }
      if (this.hostMors != null && this.hostMors.size() > 0) {
         Vector<ManagedObjectReference> tmpVmMors = null;
         for (ManagedObjectReference hostMor : hostMors) {
            tmpVmMors = DVSUtil.createVms(this.connectAnchor, hostMor, 1, 0);
            if (this.vmMors == null) {
               this.vmMors = new Vector<ManagedObjectReference>();
            }
            this.vmMors.addAll(tmpVmMors);
            assertTrue(this.vm.setVMState(tmpVmMors.get(0),
                  VirtualMachinePowerState.POWERED_ON, false),
                  MessageConstants.VM_POWERON_FAIL);

            String vmversion = hs.getCfgOption(hostMor).getVersion();
            log.info("Vm version is:" + vmversion);
         }
      }
   }

   /**
    * This method configures vms to connect to DistributedVirtualSwitchPortConnection.
    * @param portConnection
    *
    * @throws Exception
    */
   public void reconfigVms(Vector<DistributedVirtualSwitchPortConnection> portConnection)
      throws Exception
   {
      assertTrue((this.vmMors != null && this.vmMors.size() > 0),
               "Couldn't find any VMs");
      if (this.vmMors != null && this.vmMors.size() > 0) {
         int portConnCount = (this.vmMors.size() < portConnection.size()) ? this.vmMors.size()
                  : portConnection.size();

         for (int i = 0; i < portConnCount; i++) {
            ManagedObjectReference vmMor = this.vmMors.get(i);
            Vector<DistributedVirtualSwitchPortConnection> tmpPortConn = new Vector<DistributedVirtualSwitchPortConnection>();
            tmpPortConn.add(portConnection.get(i));
            VirtualMachineConfigSpec[] vmConfigSpec = DVSUtil.getVMConfigSpecForDVSPort(
                     vmMor, this.connectAnchor,
                     TestUtil.vectorToArray(tmpPortConn));
            assertTrue((vmConfigSpec != null && vmConfigSpec.length == 2
                     && vmConfigSpec[0] != null && vmConfigSpec[1] != null),
                     "Successfully obtained the original and the updated virtual"
                              + " machine config spec",
                     "Can not reconfigure the virtual machine to use the "
                              + "DV port");
            assertTrue(
                     this.vm.reconfigVM(vmMor, vmConfigSpec[0]),
                     "Succeeded to reconfigure the virtual machine to use portconn",
                     "Failed to  reconfigured the virtual machine to use portconnn");
         }
      }
   }

   /**
    * This method adds a port group to the dvs.
    *
    * @throws Exception
    */
   public void addPortgroup()
      throws Exception
   {
      init("addPortgroup");
      assertNotNull(this.vdsMor, "vdsMor is null.");
      List<ManagedObjectReference> pgMorList = null;
      DVPortgroupConfigSpec[] dvPortGroupConfigSpecs =
            new DVPortgroupConfigSpec[1];
      dvPortGroupConfigSpecs[0] = this.dvPortGroupConfigSpec;
      pgMorList = vds.addPortGroups(this.vdsMor, dvPortGroupConfigSpecs);
      this.vdsPgMor = pgMorList.get(0);

      /*
       * If there are VMs created previously, we will reconfigure the VMs to
       * connect to this dvport group before we reconfigure switch security for
       * this dvport group.
       */
      if (this.vmMors != null && this.vmMors.size() > 0) {
         String dvSwitchUuid = this.vds.getConfig(this.vdsMor).getUuid();
         String portgroupKey = this.vdsPortgroup.getKey(this.vdsPgMor);
         Vector<DistributedVirtualSwitchPortConnection> portconns =
               new Vector<DistributedVirtualSwitchPortConnection>();

         for (ManagedObjectReference vmMor : this.vmMors) {
            DistributedVirtualSwitchPortConnection dvsPortConnection =
                  DVSUtil.buildDistributedVirtualSwitchPortConnection(
                        dvSwitchUuid, null, portgroupKey);
            portconns.add(dvsPortConnection);
         }
         reconfigVms(portconns);
      }
   }

   /**
    * This method will get the mor of vds created previously.
    *
    * @throws Exception
    */
   public void getVdsMor()
      throws Exception
   {
      init("getVdsMor");
      assertNotNull(this.vdsName, "vds name is null.");
      Vector<ManagedObjectReference> dcMors = folder.getAllDataCenter();
      assertTrue((dcMors != null && dcMors.size() > 0),
               "Cound't find a datacenter.");
      for (ManagedObjectReference dcMor : dcMors) {
         ManagedObjectReference netFolderMor = this.folder.getNetworkFolder(dcMor);
         this.vdsMor = this.folder.getDistributedVirtualSwitch(netFolderMor,
                  this.vdsName);
         if (this.vdsMor != null) {
            break;
         }
      }

      assertNotNull(this.vdsMor, "Can't find the vds named with "
               + this.vdsName);
   }

   /**
    * This method will get the mors of VMs created previously.
    *
    * @throws Exception
    */
   public void getVMsMors()
      throws Exception
   {
      Vector<ManagedObjectReference> dcMors = folder.getAllDataCenter();
      assertTrue((dcMors != null && dcMors.size() > 0),
               "couldn't find a datacenter.");

      for (ManagedObjectReference dcMor : dcMors) {
         this.vmMors = this.vm.getAllVMs(dcMor);
         if (this.vmMors != null) {
            break;
         }
      }
      // assertNotNull(this.vmMors, "Couldn't find any VMs");
   }

   /**
    * This method is used to generate valid beginTime and endTime for later function calling.
    */
   public void generateValidTimes()
   {
      this.beginTime = Calendar.getInstance();
      this.beginTime.add(Calendar.DATE, -1);
      this.endTime = Calendar.getInstance();
   }

   /**
    * This method is used to generate invalid beginTime and endTime for later function calling.
    */
   public void generateInvalidTimes()
   {
      this.beginTime = Calendar.getInstance();
      this.beginTime.add(Calendar.DATE, 1);
      this.endTime = Calendar.getInstance();
   }

   /**
    * queryRefreshRate: query refresh rate for NetVCOps.
    * @throws Exception
    */
   public void queryRefreshRate() throws Exception
   {
      PerfProviderSummary proSummary =
            this.perf.queryPerfProviderSummary(this.perfMgrMor, this.vdsMor);
      this.refreshRate = proSummary.getRefreshRate();
      assertTrue((refreshRate != null && refreshRate.intValue() > 0),
            "Invalid refreshRate");
   }

   /**
    * generateInvalidRefreshRate: generate an invalid refresh rate.
    * @throws Exception
    */
   public void generateInvalidRefreshRate() throws Exception
   {
      this.refreshRate = 10;
   }

   /**
    * This method invokes queryPerfProviderSummary and verify the results.
    *
    * @throws Exception
    */
   public void queryPerfProviderSummary ()
      throws Exception
   {
      boolean status = false;
      PerfProviderSummary proSummary = null;

      proSummary =
            this.perf.queryPerfProviderSummary(this.perfMgrMor, this.vdsMor);
      if (proSummary != null) {
         this.perf.printProviderSummary(this.vdsMor, proSummary);
         if (proSummary.getRefreshRate() == 20
               && proSummary.isCurrentSupported() == true
               && proSummary.isSummarySupported() == false) {
            status = true;
         } else {
            log.error("Values in proSummary is not expected!");
         }
      } else {
         log.error("Returned providersummary is null");
      }

      assertTrue(status, "queryPerfProviderSummary test failed");
   }

   /**
    * This method invokes queryAvailablePerfMetric and verify the results.
    *
    * @throws Exception
    */
   public void queryAvailablePerfMetric()
      throws Exception
   {
      boolean status = false;

      assertNotNull(this.beginTime,
            "beginTime is null, it needs to be initialized.");
      assertNotNull(this.endTime,
            "endtime is null, it needs to be initialized.");
      assertNotNull(this.refreshRate,
            "refreshRate is null, it needs to be initialized.");
      this.metrics =
            this.perf.queryAvailablePerfMetric(this.perfMgrMor, this.vdsMor,
                  this.beginTime, this.endTime, this.refreshRate);
      assertTrue((metrics != null && !metrics.isEmpty()),
            "Can't find available metrics");
      log.info("Successfully got the available Perf Metric for vds");
      // this.perf.printMetricId(this.perfMgrMor, metrics);

      int length = this.metrics.size();
      int[] counterIds = new int[length];
      for (int i = 0; i < length; i++) {
         counterIds[i] = this.metrics.elementAt(i).getCounterId();
      }
      Vector perfCounterVector =
            this.perf.queryCounter(this.perfMgrMor, counterIds);
      if (perfCounterVector != null && !perfCounterVector.isEmpty()) {
         // this.perf.printCounterInfo(perfCounterVector);
         status = true;
      } else {
         log.error("Unable to find wanted counter info");
      }

      assertTrue(status, "queryAvailablePerfMetric test failed");
   }

   /**
    * This method invokes queryCounterByLevel with level 3 and verify the
    * counter related to vds are included in the results.
    *
    * @throws Exception
    */
   public void queryCounterByLevel()
      throws Exception
   {
      assertNotNull(this.beginTime,
            "beginTime is null, it needs to be initialized.");
      assertNotNull(this.endTime,
            "endtime is null, it needs to be initialized.");
      assertNotNull(this.refreshRate,
            "refreshRate is null, it needs to be initialized.");
      assertNotNull(this.metrics,
            "metrics is null, it needs to be initialized.");
      int length = this.metrics.size();
      int[] counterIds = new int[length];
      for (int i = 0; i < length; i++) {
         counterIds[i] = this.metrics.elementAt(i).getCounterId();
      }
      Vector<PerfCounterInfo> perfCounterInfos =
            this.perf.queryCounterByLevel(this.perfMgrMor, 3);
      assertTrue((perfCounterInfos != null && !perfCounterInfos.isEmpty()),
            "queryCounterByLevel return null or empty.");
      boolean status = true;
      for (int counterId : counterIds) {
         boolean matched = false;
         for (PerfCounterInfo perfCounterInfo : perfCounterInfos) {
            if (counterId == perfCounterInfo.getKey()) {
               matched = true;
               break;
            }
         }
         status &= matched;
      }

      assertTrue(status, "queryCounterByLevel test failed");
   }

   /**
    * This method invokes getPerfCounter and verify the counter related to vds
    * are included in the results.
    *
    * @throws Exception
    */
   public void getPerfCounter()
      throws Exception
   {
      assertNotNull(this.beginTime,
            "beginTime is null, it needs to be initialized.");
      assertNotNull(this.endTime,
            "endtime is null, it needs to be initialized.");
      assertNotNull(this.refreshRate,
            "refreshRate is null, it needs to be initialized.");
      assertNotNull(this.metrics,
            "metrics is null, it needs to be initialized.");
      int length = this.metrics.size();
      int[] counterIds = new int[length];
      for (int i = 0; i < length; i++) {
         counterIds[i] = this.metrics.elementAt(i).getCounterId();
      }
      Vector<PerfCounterInfo> perfCounterInfos =
            this.perf.getPerfCounter(this.perfMgrMor);
      assertTrue((perfCounterInfos != null && !perfCounterInfos.isEmpty()),
            "queryCounterByLevel return null or empty.");
      boolean status = true;
      for (int counterId : counterIds) {
         boolean matched = false;
         for (PerfCounterInfo perfCounterInfo : perfCounterInfos) {
            if (counterId == perfCounterInfo.getKey()) {
               matched = true;
               break;
            }
         }
         status &= matched;
      }

      assertTrue(status, "getPerfCounter test failed");
   }

   /**
    * This method invokes queryCounter to query counter info for all vds
    * counters.
    *
    * @throws Exception
    */
   public void queryCounter()
      throws Exception
   {
      assertNotNull(this.beginTime,
            "beginTime is null, it needs to be initialized.");
      assertNotNull(this.endTime,
            "endtime is null, it needs to be initialized.");
      assertNotNull(this.refreshRate,
            "refreshRate is null, it needs to be initialized.");
      assertNotNull(this.metrics,
            "metrics is null, it needs to be initialized.");

      int length = this.metrics.size();
      int[] counterIds = new int[length];
      for (int i = 0; i < length; i++) {
         counterIds[i] = this.metrics.elementAt(i).getCounterId();
      }
      Vector<PerfCounterInfo> perfCounterInfos =
            this.perf.queryCounter(perfMgrMor, counterIds);
      assertTrue((perfCounterInfos != null && !perfCounterInfos.isEmpty()),
            "queryCounter return null or empty.");
      this.perf.printCounterInfo(perfCounterInfos);
   }

   /**
    * This method invokes queryStats to query statistics data info for all vds
    * counters.
    *
    * @throws Exception
    */
   public void queryStats()
      throws Exception
   {
      assertNotNull(this.beginTime,
            "beginTime is null, it needs to be initialized.");
      assertNotNull(this.endTime,
            "endtime is null, it needs to be initialized.");
      assertNotNull(this.refreshRate,
            "refreshRate is null, it needs to be initialized.");
      assertNotNull(this.metrics,
            "metrics is null, it needs to be initialized.");
      for (int i = 0; i < this.metrics.size(); i++) {
         Vector<PerfEntityMetricBase> entMetric =
               this.perf.queryStatsByCounterId(perfMgrMor, this.vdsMor,
                     this.metrics.elementAt(i).getCounterId(), this.beginTime,
                     this.endTime, "csv");
         if (entMetric != null) {
            for (PerfEntityMetricBase entBase : entMetric) {
               if (entBase instanceof PerfEntityMetricCSV) {
                  PerfEntityMetricCSV emc = (PerfEntityMetricCSV) entBase;
                  log.info("entity: " + emc.getEntity() + "   SampleinfoCSV: "
                        + emc.getSampleInfoCSV().length() + "   MetricSeries: "
                        + emc.getValue().size());
                  List<PerfMetricSeriesCSV> metricSeries = emc.getValue();
                  for (PerfMetricSeries single : metricSeries) {
                     String tmpStr =
                           "counterId:" + single.getId().getCounterId()
                                 + "   instance:"
                                 + single.getId().getInstance() + "  ";
                     log.info(tmpStr);
                     if (single instanceof PerfMetricSeriesCSV) {
                        log.info("value:"
                              + ((PerfMetricSeriesCSV) single).getValue());
                     }
                  }
               } else {
                  assertTrue(false,
                        "Unexpected instance of PerfEntityMetricBase");
               }
            }
         }
      }
   }

   public void Sleep()
     throws Exception
   {
      log.info("Begin to sleep after creating DVS and VMs...");
      Thread.sleep(120000);
   }

   /**
    * This method invokes queryStats to query statistics data info for all vds
    * counters.
    *
    * @throws Exception
    */
   public void analyseResultsForQueryStats()
      throws Exception
   {
      if (this.hostMors == null) {
         this.hostMors = this.hs.getAllHost();
      }
      assertTrue((hostMors != null && hostMors.size() > 0),
            "Can't find usable hosts.");

      assertNotNull(this.beginTime,
            "beginTime is null, it needs to be initialized.");
      assertNotNull(this.endTime,
            "endtime is null, it needs to be initialized.");
      assertNotNull(this.refreshRate,
            "refreshRate is null, it needs to be initialized.");
      assertNotNull(this.metrics,
            "metrics is null, it needs to be initialized.");
      for (int i = 0; i < this.metrics.size(); i++) {
         Vector<PerfEntityMetricBase> entMetric =
               this.perf.queryStatsByCounterId(perfMgrMor, this.vdsMor,
                     this.metrics.elementAt(i).getCounterId(), beginTime,
                     endTime, "csv");
         if (entMetric != null) {
            for (PerfEntityMetricBase entBase : entMetric) {
               if (entBase instanceof PerfEntityMetricCSV) {
                  PerfEntityMetricCSV emc = (PerfEntityMetricCSV) entBase;
                  List<PerfMetricSeriesCSV> metricSeries = emc.getValue();
                  for (PerfMetricSeries single : metricSeries) {
                     String instance = single.getId().getInstance();
                     if (instance != null) {
                        String[] temp = instance.split(" ");
                        String hostInstanceStr = temp[0];
                        boolean found = false;
                        for (ManagedObjectReference hostMor : this.hostMors) {
                           log.info(hostMor.getValue());
                           if (hostMor.getValue().equals(hostInstanceStr)) {
                              found = true;
                              break;
                           }
                        }
                        assertTrue(found,
                              "Coundn't found wanted host instance.");
                     }
                  }
               } else {
                  assertTrue(false,
                        "Unexpected instance of PerfEntityMetricBase");
               }
            }
         }
      }
   }

   public void setValidMetricId()
   {
      assertNotNull(this.metrics,
            "metrics is null, it needs to be initialized.");
      this.metricId = new PerfMetricId();
      this.metricId.setCounterId(this.metrics.get(0).getCounterId());
      this.metricId.setInstance("*");
   }

   public void setInvalidMetricId()
   {
      this.metricId = new PerfMetricId();
      this.metricId.setCounterId(-220);
      this.metricId.setInstance("*");
   }

   public void queryPerf()
      throws Exception
   {
      assertNotNull(this.beginTime, "beginTime is null, it needs to be initialized.");
      assertNotNull(this.endTime, "endtime is null, it needs to be initialized.");
      assertNotNull(this.refreshRate, "refreshRate is null, it needs to be initialized.");
      assertNotNull(this.metrics, "metrics is null, it needs to be initialized.");
      assertNotNull(this.metricId, "metricId is null, it needs to be initialized.");

      PerfQuerySpec[] perfSpec = new PerfQuerySpec[1];
      perfSpec[0] = new PerfQuerySpec();
      perfSpec[0].setEntity(this.vdsMor);
      perfSpec[0].setStartTime(this.beginTime);
      perfSpec[0].setEndTime(this.endTime);
      perfSpec[0].getMetricId().clear();
      perfSpec[0].getMetricId().addAll(Arrays.asList(this.metricId));
      perfSpec[0].setFormat("csv");
      perfSpec[0].setIntervalId(this.refreshRate);

      this.perf.queryPerf(perfMgrMor, perfSpec);
   }

   public void genericuser_login()
      throws Exception
   {
      SessionManager sessionManager = new SessionManager(connectAnchor);
      AuthorizationManager authentication = new AuthorizationManager(
               connectAnchor);
      ManagedObjectReference authManagerMor = new AuthorizationManager(
               connectAnchor).getAuthorizationManager();
      Permission permissionSpec = new Permission();
      permissionSpec.setGroup(false);
      permissionSpec.setPrincipal(GENERIC_USER);
      permissionSpec.setPropagate(true);
      permissionSpec.setRoleId(ROLE_READONLY_ID);
      Permission[] permissionsArr = { permissionSpec };
      assertTrue(
               authentication.setEntityPermissions(authManagerMor,
                        this.folder.getRootFolder(), permissionsArr),
               "Failed to set entity permissions.");
      assertTrue(sessionManager.logout(connectAnchor), "Failed to logout.");
      UserSession loginSession = sessionManager.login(connectAnchor,
               GENERIC_USER, PASSWORD);
      assertNotNull(loginSession, "Failed to login with test user.");
   }
}
