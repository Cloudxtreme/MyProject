/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package com.vmware.vcqa.vim.dvs;

import static com.vmware.vcqa.TestConstants.CONFIG_SPEC_ADD;
import static com.vmware.vcqa.TestConstants.CONFIG_SPEC_EDIT;
import static com.vmware.vcqa.TestConstants.CONFIG_SPEC_REMOVE;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.PVLAN_TYPE_PROMISCUOUS;

import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Vector;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.vmware.vc.ConfigSpecOperation;
import com.vmware.vc.DVPortConfigInfo;
import com.vmware.vc.DVPortConfigSpec;
import com.vmware.vc.DVPortSetting;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualPort;
import com.vmware.vc.DistributedVirtualSwitchPortCriteria;
import com.vmware.vc.DvsFilterPolicy;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.TaskInfo;
import com.vmware.vc.VMwareDVSConfigInfo;
import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VMwareDVSPvlanConfigSpec;
import com.vmware.vc.VMwareDVSPvlanMapEntry;
import com.vmware.vc.VMwareDVSVspanConfigSpec;
import com.vmware.vc.VMwareDvsLacpApiVersion;
import com.vmware.vc.VMwareDvsLacpGroupConfig;
import com.vmware.vc.VMwareDvsLacpGroupSpec;
import com.vmware.vc.VMwareVspanSession;
import com.vmware.vc.VmwareDistributedVirtualSwitchPvlanPortType;
import com.vmware.vc.VmwareDistributedVirtualSwitchPvlanSpec;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.PropertyConstants;
import com.vmware.vcqa.query.PropertyCollector;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.MORConstants;
import com.vmware.vcqa.vim.Task;

/**
 * Implementation class for VMware Distributed Virtual Switch operations.
 */
public class DistributedVirtualSwitchHelper extends DistributedVirtualSwitch
{
   private static final Logger log = LoggerFactory.getLogger(DistributedVirtualSwitchHelper.class);

   /*
    * Constants
    */
   /*
    * ========= constructor should go here ==================================
    */
   /**
    * Constructor
    *
    * @param connectAnchor Reference to the ConnectAnchor object
    */
   public DistributedVirtualSwitchHelper(final ConnectAnchor connectAnchor)
      throws Exception
   {
      super(connectAnchor);
   }

   /**
    * Reconfigure the PVLAN configuration on the DVS. This is a generic method
    * to add/remove a PVLAN entry.
    *
    * @param dvSwitchMOR ManagedObjectReference object.
    * @param configSpec VMwareDVSPvlanConfigSpec object.
    * @return boolean true if successful false otherwise.
    * @throws MethodFault, Exception.
    * @see #addPvlan(ManagedObjectReference, String, int, int) for adding a
    *      PVLAN.
    * @see #addPrimaryPvlan(ManagedObjectReference, int) for adding primary
    *      PVLAN.
    */
   public boolean reconfigurePvlan(final ManagedObjectReference dvSwitchMOR,
                                   final VMwareDVSPvlanConfigSpec[] configSpec)
      throws Exception
   {
      boolean reconfigured = false;
      final VMwareDVSConfigSpec vmwareDVSConfigSpec = new VMwareDVSConfigSpec();
      VMwareDVSConfigInfo vmwareDVSConfigInfo = null;
      VMwareDVSPvlanMapEntry[] oldEntries = null;// before reconfiguring.
      List<VMwareDVSPvlanMapEntry> currMapEntry; // after reconfiguring.
      List<VMwareDVSPvlanMapEntry> expMapEntry;
      log.info("start Reconfigure PVLAN ");
      if (dvSwitchMOR != null && dvSwitchMOR.getType() != null) {
         vmwareDVSConfigInfo = getConfig(dvSwitchMOR);
         oldEntries = com.vmware.vcqa.util.TestUtil.vectorToArray(vmwareDVSConfigInfo.getPvlanConfig(), com.vmware.vc.VMwareDVSPvlanMapEntry.class);
         vmwareDVSConfigSpec.setConfigVersion(vmwareDVSConfigInfo.getConfigVersion());
         vmwareDVSConfigSpec.setDefaultPortConfig(vmwareDVSConfigInfo.getDefaultPortConfig());
      }
      vmwareDVSConfigSpec.getPvlanConfigSpec().clear();
      vmwareDVSConfigSpec.getPvlanConfigSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(configSpec));
      reconfigure(dvSwitchMOR, vmwareDVSConfigSpec);
      log.info("Reconfigure PVLAN done...  Verifying...");
      final VMwareDVSConfigInfo currentCfgInfo = getConfig(dvSwitchMOR);
      currMapEntry = new ArrayList<VMwareDVSPvlanMapEntry>(0);
      if (currentCfgInfo != null) {
         VMwareDVSPvlanMapEntry[] currentPvlanMapEntry = null;
         currentPvlanMapEntry = com.vmware.vcqa.util.TestUtil.vectorToArray(currentCfgInfo.getPvlanConfig(), com.vmware.vc.VMwareDVSPvlanMapEntry.class);
         if (currentPvlanMapEntry != null) {
            currMapEntry = Arrays.asList(currentPvlanMapEntry);
         }
      }
      expMapEntry = getExpectedMapEntries(oldEntries, configSpec);
      // Both the expected and current entries should be equal.
      reconfigured = currMapEntry.containsAll(expMapEntry);
      if (!reconfigured) {
         log.error("Verification failed.");
      } else {
         log.info("Successfully verified.");
      }
      return reconfigured;
   }

   /**
    * Add a PVLAN map entry to given DVS.
    *
    * @param dvsMor MOD of the DVS.
    * @param type PVLAN type.
    * @param primaryId primary PVLAN ID.
    * @param secondaryId secondary PVALN ID.
    * @return true, if successful. false, therwise.
    * @throws Exception If any problem in adding.
    * @see #addPrimaryPvlan(ManagedObjectReference, int)
    */
   public boolean addPvlan(final ManagedObjectReference dvsMor,
                           final String type,
                           final int primaryId,
                           final int secondaryId)
      throws Exception
   {
      final VMwareDVSPvlanConfigSpec[] configSpec = new VMwareDVSPvlanConfigSpec[1];
      configSpec[0] = getPvlanCfgSpec(type, primaryId, secondaryId,
               CONFIG_SPEC_ADD);
      return reconfigurePvlan(dvsMor, configSpec);
   }

   /**
    * Add a primary PVLAN entry to DVS where the type is promiscuous. In a
    * primary PVLAN the primary and secondary ID's will be same.
    *
    * @param dvsMor MOR of the DVS to which PVLAn has to be added.
    * @param primaryId PVLAN ID.
    * @return true, if PVLAN is successfully added. false, on failing to add the
    *         PVLAN.
    * @throws Exception On any errors.
    */
   public boolean addPrimaryPvlan(final ManagedObjectReference dvsMor,
                                  final int primaryId)
      throws Exception
   {
      return addPvlan(dvsMor, PVLAN_TYPE_PROMISCUOUS, primaryId, primaryId);
   }

   /**
    * Add secondary PVLAN map entry to DVS by providing the PVALN type, primary
    * ID and secondary ID.
    *
    * @param dvsMor MOR of the DVS in question.
    * @param pvlanType type of the PVLAN.
    * @param primaryId ID of the primary PVLAN to which the given secondary
    *           PLVAN should belong to.
    * @param secondaryId secondary ID to be created.
    * @param addPrimary If true the given primary ID will be added to PVLAN
    *           entry before adding secondary.
    * @return true, if added.
    * @throws Exception
    */
   public boolean addSecondaryPvlan(final ManagedObjectReference dvsMor,
                                    final String pvlanType,
                                    final int primaryId,
                                    final int secondaryId,
                                    final boolean addPrimary)
      throws Exception
   {
      boolean status = false;
      if (addPrimary) {
         if (addPrimaryPvlan(dvsMor, primaryId)) {
            log.info("Successfully added primary PVLAN entry: " + primaryId);
            status = addPvlan(dvsMor, pvlanType, primaryId, secondaryId);
         } else {
            log.warn("Unable to add  the primary PVALN entry.");
         }
      } else {
         status = addPvlan(dvsMor, pvlanType, primaryId, secondaryId);
      }
      return status;
   }

   /**
    * Removes the PVLAN entry from the DVS.
    *
    * @param dvsMor
    * @param pvlanType PVALN type.
    * @param primaryId primary PVLAN ID.
    * @param secondaryId secondary PVLAN ID.
    * @param removeSecondary If true removes the secondary ID's before trying to
    *           remove primary.
    * @return true, if the removal is successful.
    * @throws Exception
    */
   public boolean removePvlan(final ManagedObjectReference dvsMor,
                              final String pvlanType,
                              final int primaryId,
                              final int secondaryId,
                              final boolean removeSecondary)
      throws Exception
   {
      boolean status = false;
      VMwareDVSPvlanMapEntry givenEntry;
      List<VMwareDVSPvlanConfigSpec> pvlanCfgs = null;
      VMwareDVSPvlanMapEntry[] secondary;
      // Create the entry using given parameters.
      givenEntry = getPvlanMapEntry(pvlanType, primaryId, secondaryId);
      pvlanCfgs = new ArrayList<VMwareDVSPvlanConfigSpec>();
      if (removeSecondary && isPrimaryPvlan(givenEntry)) {
         // If the given entry is primary.
         log.info("Collecting secondary ID's to remove...");
         // To remove the secondary ID's, add them at the beginning.
         secondary = getSecondaryPvlans(dvsMor, primaryId);
         for (final VMwareDVSPvlanMapEntry mapEntry : secondary) {
            pvlanCfgs.add(getPvlanCfgSpec(mapEntry, CONFIG_SPEC_REMOVE));
         }
      }
      // we have to remove the given entry.
      pvlanCfgs.add(getPvlanCfgSpec(givenEntry, CONFIG_SPEC_REMOVE));
      status = reconfigurePvlan(
               dvsMor,
               pvlanCfgs.toArray(new VMwareDVSPvlanConfigSpec[pvlanCfgs.size()]));
      return status;
   }

   /**
    * Fetches all the secondary PVLAN's belonging the primary ID represented by
    * given primaryId.
    *
    * @param dvsMor MOD of DVS.
    * @param primaryId primary ID.
    * @return Array of secondary VMwareDVSPvlanMapEntries.
    * @throws MethodFault, Exception.
    */
   public VMwareDVSPvlanMapEntry[] getSecondaryPvlans(final ManagedObjectReference dvsMor,
                                                      final int primaryId)
      throws Exception
   {
      List<VMwareDVSPvlanMapEntry> entries = null;
      entries = new ArrayList<VMwareDVSPvlanMapEntry>();
      final Map<Integer, VMwareDVSPvlanMapEntry> pvlans = getPvlanMap(dvsMor);
      final Iterator<VMwareDVSPvlanMapEntry> it = pvlans.values().iterator();
      while (it.hasNext()) {
         final VMwareDVSPvlanMapEntry entry = it.next();
         if (primaryId == entry.getPrimaryVlanId()
                  && primaryId != entry.getSecondaryVlanId()) {
            entries.add(entry);
         }
      }
      return entries.toArray(new VMwareDVSPvlanMapEntry[entries.size()]);
   }

   /**
    * Method to get the expected map entries in the DVS after reconfiguring it
    * using cfgSpecs.
    *
    * @param oldEntries Old PVLAN map entries before configuration.
    * @param cfgSpecs changes made to the entries.
    * @return list containing expected {@link VMwareDVSPvlanMapEntry} objects.
    */
   public List<VMwareDVSPvlanMapEntry> getExpectedMapEntries(final VMwareDVSPvlanMapEntry[] oldEntries,
                                                             final VMwareDVSPvlanConfigSpec[] cfgSpecs)
   {
      final List<VMwareDVSPvlanMapEntry> expected;
      VMwareDVSPvlanMapEntry changed;
      // add the old entries.
      if (oldEntries != null && oldEntries.length > 0) {
         expected = new ArrayList<VMwareDVSPvlanMapEntry>(oldEntries.length);
         expected.addAll(Arrays.asList(oldEntries));
      } else {
         expected = new ArrayList<VMwareDVSPvlanMapEntry>();
      }
      for (int i = 0; i < cfgSpecs.length; i++) {// for ever change
         final VMwareDVSPvlanConfigSpec aCfgChange = cfgSpecs[i];
         log.info("Operation: " + aCfgChange.getOperation());
         if (aCfgChange != null && aCfgChange.getPvlanEntry() != null) {
            changed = aCfgChange.getPvlanEntry();
            log.info("PVLAN ID: " + changed.getPrimaryVlanId());
            if (CONFIG_SPEC_ADD.equals(aCfgChange.getOperation())) {
               expected.add(changed); // add it to expected entries.
            } else if (CONFIG_SPEC_REMOVE.equals(aCfgChange.getOperation())) {
               expected.remove(changed); // remove the primary entry.
               // remove the secondary PVLAN entries of this primary PVLAN.
               if (isPrimaryPvlan(changed)) {
                  final int primaryId = changed.getPrimaryVlanId();
                  for (final Iterator<VMwareDVSPvlanMapEntry> iterator = expected.iterator(); iterator.hasNext();) {
                     final VMwareDVSPvlanMapEntry entry = iterator.next();
                     if (primaryId == entry.getPrimaryVlanId()) {
                        iterator.remove();
                     }
                  }
               }
            } else {
               log.warn("Invalid operation: " + aCfgChange.getOperation());
            }
         }
      }
      return expected;
   }

   /**
    * Method to merge original & delta VSPAN configs to get expected Cfg.<br>
    * This method can be used incrementally so that many re-configs can be
    * verified at once if needed.<br>
    *
    * @param originalCfgInfo
    * @param reCfg
    * @return Expected VSPAN sessions.
    */
   public List<VMwareVspanSession> mergeVspansCfgs(final VMwareVspanSession[] originalSessions,
                                                   final VMwareDVSVspanConfigSpec[] reCfgSpec)
      throws Exception
   {
      List<VMwareVspanSession> expVspanSession;
      if (originalSessions != null) {
         log.debug("Original VSPAN sessions count: {}", originalSessions.length);
         // Assume original and expected are same for now.
         expVspanSession = new ArrayList<VMwareVspanSession>(
                  Arrays.asList(originalSessions));
         // expVspanSession = Arrays.asList(originalSessions);
      } else {
         log.debug("Currently no VSPAN sessions are available in DVS.");
         expVspanSession = new Vector<VMwareVspanSession>();
      }
      if (reCfgSpec != null && reCfgSpec.length > 0) {
         log.debug("Reconfig VSPAN sessions count: {}", reCfgSpec.length);
         for (final VMwareDVSVspanConfigSpec config : reCfgSpec) {
            if (config != null && config.getOperation() != null) {
               final VMwareVspanSession aSession = config.getVspanSession();
               final String operation = config.getOperation();
               log.debug("Operation: {}  Name: {}  Key: " + aSession.getKey(),
                        operation, aSession.getName());
               if (operation.equals(CONFIG_SPEC_REMOVE)) {
                  if (expVspanSession.size() != 0 && aSession != null) {
                     for (final VMwareVspanSession session : expVspanSession) {
                        if (session.getKey().equals(aSession.getKey())) {
                           expVspanSession.remove(session);
                           break;
                        }
                     }
                  } else {
                     log.warn("Cannot remove an vspan session if the DVS does "
                              + "not have any vspan sessions configured");
                  }
               } else if (operation.equals(CONFIG_SPEC_ADD)) {
                  expVspanSession.add(aSession);
               } else if (operation.equals(CONFIG_SPEC_EDIT)) {
                  if (expVspanSession.size() != 0 && aSession != null) {
                     final Iterator<VMwareVspanSession> expVspanIter;
                     expVspanIter = expVspanSession.iterator();
                     while (expVspanIter.hasNext()) {
                        final VMwareVspanSession expectedVspan = expVspanIter.next();
                        if (expectedVspan.getKey().equals(aSession.getKey())) {
                           TestUtil.mergeObject(expectedVspan, aSession);
                           break;
                        }
                     }
                  } else {
                     log.warn("Cannot edit an vspan session "
                              + "if the DVS does not have any"
                              + "vspan sessions configured");
                  }
               } else {
                  log.warn("The operation is not defined");
               }
            } else {
               log.warn("Operation cannot be null");
            }
         }
      } else {
         log.warn("Config spec cannot be empty or null");
      }
      log.info("Expected VSPAN sessions count: {}", expVspanSession.size());
      return expVspanSession;
   }

   /**
    * Method to verify that the Current and expected VSPAN sessions match.<br>
    * <br>
    *
    * @param currentSessions VSPAN sessions on DVS.
    * @param expectedSessions expected sessions as per Config spec.
    * @return boolean true if successful, false otherwise
    * @throws Exception
    * @see {@link #merge(ManagedObjectReference, ManagedObjectReference)}
    */
   public boolean verifyVspan(final List<VMwareVspanSession> currentSessions,
                              final List<VMwareVspanSession> expectedSessions)
      throws Exception
   {
      log.info("Verifyting VSPANs...");
      boolean result = true;
      boolean flag = true;// whether to proceed further or not.
      Map<String, VMwareVspanSession> currentVspans = null;
      Map<String, VMwareVspanSession> expectedVspans = null;
      if (currentSessions == null || currentSessions.isEmpty()
               || expectedSessions == null || expectedSessions.isEmpty()) {
         flag = false;// The VSPAN's are null/empty so don't go further.
         if ((currentSessions == null || currentSessions.isEmpty())
                  && (expectedSessions == null || expectedSessions.isEmpty())) {
            log.info("Both VSPAN sssions are null/empty.");
            result = true;// both are null.
         } else {
            log.info("One of VSPAN session is null/empty.");
            result = false;// either one of them are null so not equal.
         }
      }// null checks over.
      if (flag) {
         log.debug("Current : {}", currentSessions.size());
         log.debug("Expected: {}", expectedSessions.size());
         if (currentSessions.size() == expectedSessions.size()) {
            Iterator<String> currentKeys = null;
            currentVspans = new LinkedHashMap<String, VMwareVspanSession>();
            expectedVspans = new LinkedHashMap<String, VMwareVspanSession>();
            for (final VMwareVspanSession aVspan : currentSessions) {
               currentVspans.put(aVspan.getName(), aVspan);
            }
            for (final VMwareVspanSession aVspan : expectedSessions) {
               expectedVspans.put(aVspan.getName(), aVspan);
            }
            log.info("Current Names : {}", currentVspans.keySet());
            log.info("Expected Names: {}", expectedVspans.keySet());
            // now compare every VSPAN with respect to key.
            currentKeys = currentVspans.keySet().iterator();
            while (currentKeys.hasNext()) {
               final String aVspanKey = currentKeys.next();
               VMwareVspanSession aExpectedVspan = null;
               aExpectedVspan = expectedVspans.get(aVspanKey);
               if (aExpectedVspan != null) {
                  final VMwareVspanSession currentVspan = currentVspans.get(aVspanKey);
                  final Vector<String> ignorePropList = new Vector<String>();
                  ignorePropList.addAll(TestUtil.getIgnorePropertyList(
                           aExpectedVspan, false));
                  ignorePropList.add("VMwareVspanSession.Key");
                  log.debug("Ignoring: {}", ignorePropList);
                  if (!TestUtil.compareObject(currentVspan, aExpectedVspan,
                           ignorePropList, true)) {
                     log.error("Expected didn't match with current.");
                     log.error("Expected {}",
                              VspanHelper.toString(aExpectedVspan));
                     log.error("Actual   {}",
                              VspanHelper.toString(currentVspan));
                     result = false;// Don't break, lets compare all sessions.
                  }
               } else {
                  log.warn("Expected not found in current{}", aVspanKey);
                  result = false;// Don't break here, lets compare all sessions.
               }
            }
         } else {
            log.warn("Lengths not equal");
            result = false;
         }
      }
      return result;
   }

   /**
    * Method to return the config info of the vmware dvswitch.
    *
    * @param dvSwitchMOR MOD of DVS.
    * @return VMwareDVSConfigInfo configInfo of the DVS MOR.
    * @throws MethodFault, Exception
    */
   @Override
   public VMwareDVSConfigInfo getConfig(final ManagedObjectReference dvSwitchMOR)
      throws Exception
   {
      PropertyCollector iPropertyCollector;
      iPropertyCollector = new PropertyCollector(getConnectAnchor());
      return iPropertyCollector.getDynamicProperty(dvSwitchMOR,
               VMwareDVSConfigInfo.class,
               PropertyConstants.DVS_CONFIG_PROPERTY_NAME);
   }

   /**
    * Method to generate the ConfigSpec of an existing VMware DVS MOR Object.
    *
    * @param dvSwitchMOR ManagedObjectReference Object.
    * @return VMwareDVSConfigSpec vmware dvs config spec object.
    * @throws MethodFault, Exception
    */
   @Override
   public VMwareDVSConfigSpec getConfigSpec(final ManagedObjectReference dvSwitchMOR)
      throws Exception
   {
      DVSConfigSpec dvsConfigSpec = null;
      VMwareDVSConfigSpec configSpec = null;
      VMwareDVSConfigInfo configInfo = null;
      dvsConfigSpec = super.getConfigSpec(dvSwitchMOR);
      Vector<String> allProperties = null;
      Vector<String> nullProperties = null;
      String methodName = null;
      int dotIndex = -1;
      HashMap<String, Method> methodMap = null;
      Method method1 = null;
      Method method2 = null;
      HashMap<String, Method> otherMethodMap = null;
      if (dvsConfigSpec != null) {
         configSpec = new VMwareDVSConfigSpec();
         configInfo = getConfig(dvSwitchMOR);
         if (configInfo != null) {
            configSpec.setDefaultPortConfig(configInfo.getDefaultPortConfig());
            configSpec.setMaxMtu(configInfo.getMaxMtu());
            configSpec.setIpfixConfig(configInfo.getIpfixConfig());
            configSpec.setLinkDiscoveryProtocolConfig(configInfo.getLinkDiscoveryProtocolConfig());
            configSpec.setLacpApiVersion(configInfo.getLacpApiVersion());
            allProperties = TestUtil.getIgnorePropertyList(dvsConfigSpec, true);
            nullProperties = TestUtil.getIgnorePropertyList(dvsConfigSpec,
                     false);
            if (allProperties != null) {
               // find the non null properties of the config spec
               allProperties.removeAll(nullProperties);
               if (allProperties != null && allProperties.size() > 0) {
                  methodMap = TestUtil.findMethods(configSpec, false, true,
                           false);
                  otherMethodMap = TestUtil.findMethods(dvsConfigSpec, true,
                           false, true);
                  for (final String propertyName : allProperties) {
                     // Set all the objects that are non null only at the
                     // ConfigSpec level. Ignore all the nested properties.
                     if (propertyName.startsWith("DVSConfigSpec")) {
                        dotIndex = propertyName.indexOf('.');
                        if (dotIndex >= 0
                                 && propertyName.length() >= dotIndex + 1) {
                           methodName = propertyName.substring(dotIndex + 1);
                           if (methodName != null && methodName.length() > 0) {
                              method1 = methodMap.get(methodName);
                              method2 = otherMethodMap.get(methodName);
                              // set the value in the vmware DVS config spec
                              if (method1 != null && method2 != null) {
                                 method1.invoke(configSpec, method2.invoke(
                                          dvsConfigSpec, new Object[] {}));
                              }
                           }
                        }
                     }
                  }
               }
            }
         } else {
            log.warn("The config info is null");
         }
      }
      return configSpec;
   }

   /**
    * Checks whether given {@link VMwareDVSPvlanMapEntry} is primary of not. A
    * PvlanEntry that has the same value for PvlanEntry#primaryVlanId and
    * PvlanEntry#secondaryVlanId is referred to as a primary PVLAN entry.
    *
    * @param mapEntry VMwareDVSPvlanMapEntry.
    * @return true, if primary PVLAN. false, otherwise.
    */
   public boolean isPrimaryPvlan(final VMwareDVSPvlanMapEntry mapEntry)
   {
      boolean flag = false;
      if (mapEntry != null) {
         if (PVLAN_TYPE_PROMISCUOUS.equals(mapEntry.getPvlanType())) {
            if (mapEntry.getPrimaryVlanId() == mapEntry.getSecondaryVlanId()) {
               flag = true;
            }
         }
      }
      return flag;
   }

   /**
    * Method to get all the PVLAN's (primary and secondary) and associated map
    * entries from the given DVS.
    *
    * @param dvsMor The DVS to use.
    * @return A map containing the PVLAN ID as key and corresponding
    *         {@link VMwareDVSPvlanMapEntry} as value. Empty map if the DVS
    *         doesn't contain any PVLAN entries.
    * @throws MethodFault, Exception
    */
   public Map<Integer, VMwareDVSPvlanMapEntry> getPvlanMap(final ManagedObjectReference dvsMor)
      throws Exception
   {
      String dvsName;
      VMwareDVSConfigInfo info;
      VMwareDVSPvlanMapEntry[] pvlanEntries;
      Map<Integer, VMwareDVSPvlanMapEntry> pvlans;
      pvlans = new HashMap<Integer, VMwareDVSPvlanMapEntry>();
      if (dvsMor != null) {
         dvsName = getName(dvsMor);
         info = getConfig(dvsMor);
         if (info != null) {
            pvlanEntries = com.vmware.vcqa.util.TestUtil.vectorToArray(info.getPvlanConfig(), com.vmware.vc.VMwareDVSPvlanMapEntry.class);
            if (pvlanEntries != null) {
               for (final VMwareDVSPvlanMapEntry aEntry : pvlanEntries) {
                  if (isPrimaryPvlan(aEntry)) {
                     pvlans.put(aEntry.getPrimaryVlanId(), aEntry);
                  } else {
                     pvlans.put(aEntry.getSecondaryVlanId(), aEntry);
                  }
               }
               log.info("Got " + pvlans.size() + " PVLAN entries in DVS "
                        + dvsName);
            } else {
               log.warn("No PVLAN map entries found in DVS " + dvsName);
            }
         } else {
            log.warn("No config found on DVS " + dvsName);
         }
      } else {
         log.warn("Given DVS MOR is null");
      }
      return pvlans;
   }

   /**
    * Method to check whether the given PVLAN ID is present in the given DVS.
    *
    * @param dvsMor DVS to use.
    * @param pvlanId PVLAN ID.
    * @return true, if the PVLAN ID is present. false, otherwise.
    * @throws MethodFault, Exception
    */
   public boolean isPvlanIdPresent(final ManagedObjectReference dvsMor,
                                   final int pvlanId)
      throws Exception
   {
      return getPvlanMap(dvsMor).containsKey(pvlanId);
   }

   /**
    * Assign the given PVLAN ID to a port in the DVS. Any active free port will
    * be use to assign the PVLAN.
    *
    * @param dvsMor The DVS to be used.
    * @param pvlanId PVLAN ID.
    * @return String the port key of the reconfigured Port.
    * @throws MethodFault, Exception
    */
   public String assignPvlanToPort(final ManagedObjectReference dvsMor,
                                   final int pvlanId)
      throws Exception
   {
      String portKey = null;
      final List<String> ports = super.addStandaloneDVPorts(dvsMor, 1);
      log.info("assignPvlanToPort(): DVPorts: " + ports);
      if (ports != null && !ports.isEmpty()) {
         portKey = ports.get(0);// got the port key.
         log.info("PLVAN ID: " + pvlanId + " PortKey: " + portKey);
         if (assignPvlanToPort(dvsMor, pvlanId, portKey)) {
            log.info("Successfully assigned the PVLAN ID '" + pvlanId
                     + "' to port '" + portKey + "'");
         }
      }
      return portKey;// return the portKey of the port.
   }

   /**
    * Assign the given PVLAN ID to the port in the DVS.
    *
    * @param dvsMor MOR of the DVS.
    * @param pvlanId PVLAN ID.
    * @param portKey port key of the DVPort.
    * @return true, if successful. false, otherwise.
    * @throws MethodFault, Exception
    */
   public boolean assignPvlanToPort(final ManagedObjectReference dvsMor,
                                    final int pvlanId,
                                    final String portKey)
      throws Exception
   {
      final Map<String, Object> settingsMap = new HashMap<String, Object>();
      VMwareDVSPortSetting portSetting = null;
      VmwareDistributedVirtualSwitchPvlanSpec pvlanSpec = null;
      // create the PortSetting object to set the PVLAN ID.
      pvlanSpec = new VmwareDistributedVirtualSwitchPvlanSpec();
      pvlanSpec.setPvlanId(pvlanId);
      pvlanSpec.setInherited(false);
      settingsMap.put(DVSTestConstants.VLAN_KEY, pvlanSpec);
      portSetting = DVSUtil.getDefaultVMwareDVSPortSetting(settingsMap);
      final DVPortConfigSpec[] portCfgs = new DVPortConfigSpec[1];
      final DVPortConfigSpec portCfg = new DVPortConfigSpec();
      portCfg.setKey(portKey);
      portCfg.setSetting(portSetting);
      portCfg.setOperation(ConfigSpecOperation.EDIT.value());
      portCfgs[0] = portCfg;
      return reconfigurePort(dvsMor, portCfgs);
   }

   /**
    * Create the VMwareDVSPvlanMapEntry using given properties.
    *
    * @param pvlanType type of the PVLAN.
    * @param primaryId Primary ID.
    * @param secondaryId secondary ID.
    * @return VMwareDVSPvlanMapEntry.
    */
   public VMwareDVSPvlanMapEntry getPvlanMapEntry(final String pvlanType,
                                                  final int primaryId,
                                                  final int secondaryId)
   {
      final VMwareDVSPvlanMapEntry entry = new VMwareDVSPvlanMapEntry();
      entry.setPvlanType(pvlanType);
      entry.setPrimaryVlanId(primaryId);
      entry.setSecondaryVlanId(secondaryId);
      return entry;
   }

   /**
    * Create a PVLAN Config with given properties.
    *
    * @param pvlanType type of the PVLAN.
    * @param primaryId Primary ID of the PVLAN.
    * @param secondaryId Secondary ID of the PVLAN.
    * @param operation Operation.
    * @return VMwareDVSPvlanConfigSpec.
    * @see VmwareDistributedVirtualSwitchPvlanPortType for PVLAN port types.
    */
   public VMwareDVSPvlanConfigSpec getPvlanCfgSpec(final String pvlanType,
                                                   final int primaryId,
                                                   final int secondaryId,
                                                   final String operation)
   {
      return getPvlanCfgSpec(
               getPvlanMapEntry(pvlanType, primaryId, secondaryId), operation);
   }

   /**
    * Method to get the VMwareDVSPvlanConfigSpec.
    *
    * @param entry VMwareDVSPvlanMapEntry
    * @param operation Operation.
    * @return VMwareDVSPvlanConfigSpec
    */
   public VMwareDVSPvlanConfigSpec getPvlanCfgSpec(final VMwareDVSPvlanMapEntry entry,
                                                   final String operation)
   {
      final VMwareDVSPvlanConfigSpec spec = new VMwareDVSPvlanConfigSpec();
      spec.setPvlanEntry(entry);
      spec.setOperation(operation);
      return spec;
   }

	/**
	 * Set DVS LACP version
	 *
	 * @param dvsMor
	 *            ManagedObjectReference Object
	 * @param version
	 *            LacpVersion
	 *
	 * @return boolean, true if the dvs is reconfigured, false otherwise.
	 *
	 * @throws MethodFault, Exception
	 *
	 */
	public boolean setLacpVersion(final ManagedObjectReference dvsMor,
			final VMwareDvsLacpApiVersion version) throws Exception
	{
		VMwareDVSConfigSpec configSpec = null;
		if (dvsMor != null && dvsMor.getType() != null) {
			configSpec = this.getConfigSpec(dvsMor);
		} else {
			log.error("DVS MOR is null!");
			return false;
		}
		if (version != null) {
			configSpec.setLacpApiVersion(version.value());
			reconfigure(dvsMor, configSpec);
		} else {
			log.error("LAG version is wrong!");
			return false;
		}
		return true;
	}

	/**
	 * Update LACP configuration for multiplelag version
	 *
	 * @param dvsMor
	 *            ManagedObjectReference Object
	 * @param lacpSpec
	 *            LacpSpec[]
	 *
	 * @return boolean, true if the dvs is reconfigured, false otherwise.
	 *
	 * @throws MethodFault, Exception
	 *
	 */
	public boolean updateLacpConfig(final ManagedObjectReference dvsMor,
			final VMwareDvsLacpGroupSpec[] lacpSpec) throws Exception
	{
		boolean taskSuccess = false;
		ManagedObjectReference taskMor = null;
		final Task mTasks = new Task(super.getConnectAnchor());
		super.setOpStartTime();
		taskMor = getPortType().updateDVSLacpGroupConfigTask(dvsMor,
				com.vmware.vcqa.util.TestUtil.arrayToVector(lacpSpec));
		super.setOpMiddleTime();
		taskSuccess = mTasks.monitorTask(taskMor);
		if (!taskSuccess) {
			final TaskInfo taskInfo = mTasks.getTaskInfo(taskMor);
			throw new com.vmware.vc.MethodFaultFaultMsg(taskInfo.getError().getLocalizedMessage(), taskInfo.getError()
					.getFault());
		}
		taskSuccess = this.validateLacpGroupSpec(dvsMor, lacpSpec);
		return taskSuccess;
	}

	/**
	 * get LACP configuration Spec(s) of a specified DVS
	 *
	 * @param dvsMor
	 *            ManagedObjectReference Object
	 *
	 * @return VMwareDvsLacpGroupSpec arrays in a specified DVS
	 *
	 * @throws MethodFault, Exception
	 *
	 */
	public VMwareDvsLacpGroupSpec[] getLagGroupSpec(
			final ManagedObjectReference dvsMor) throws Exception
	{
		List<VMwareDvsLacpGroupSpec> entries = new ArrayList<VMwareDvsLacpGroupSpec>();
		VMwareDVSConfigInfo configInfo = getConfig(dvsMor);
		if (configInfo != null) {
			List<VMwareDvsLacpGroupConfig> m = configInfo.getLacpGroupConfig();
			final Iterator<VMwareDvsLacpGroupConfig> it = m.iterator();
			while (it.hasNext()) {
				VMwareDvsLacpGroupConfig lgc = it.next();
				VMwareDvsLacpGroupSpec lgs = new VMwareDvsLacpGroupSpec();
				lgs.setLacpGroupConfig(lgc);
				entries.add(lgs);
			}
		}
		return entries.toArray(new VMwareDvsLacpGroupSpec[entries.size()]);
	}

	/**
	 * compare LACP configuration Spec(s) of a DVS with original setting(s)
	 *
	 * @param dvsMor
	 *            ManagedObjectReference Object
	 * @param orig
	 *            Original VmwareDvsLacpGroupSpec setting(s)
	 *
	 * @return true if equal, false otherwise
	 *
	 * @throws MethodFault, Exception
	 *
	 */
	public boolean validateLacpGroupSpec(final ManagedObjectReference dvsMor,
			VMwareDvsLacpGroupSpec[] orig) throws Exception
	{
		boolean validate = false;
		int i = 0, j = 0;
		Vector<String> props;
		Vector<String> ignorePropertyList = new Vector<String>();
		ignorePropertyList.add(DVSTestConstants.LACP_KEY);
		ignorePropertyList.add(DVSTestConstants.LACP_UPLINKNAME);
		ignorePropertyList.add(DVSTestConstants.LACP_UPLINKPORTKEY);
		VMwareDvsLacpGroupSpec[] newconfig = this.getLagGroupSpec(dvsMor);
		for (i = 0; i < orig.length; i++) {
			VMwareDvsLacpGroupSpec lgs = orig[i];
         if (lgs.getOperation().equals(ConfigSpecOperation.REMOVE.value())) {
            continue;
         }
			props = TestUtil.getIgnorePropertyList( 
			              lgs.getLacpGroupConfig(), false, ignorePropertyList);
			validate = false;
			for (j = 0; j < newconfig.length; j++) {
				VMwareDvsLacpGroupSpec newlgs = newconfig[j];
				/* LacpGroupSpec name is unique */
				if (newlgs.getLacpGroupConfig().getName().equals(
						lgs.getLacpGroupConfig().getName())) {
					validate = TestUtil.compareObject(newlgs
							.getLacpGroupConfig(), lgs.getLacpGroupConfig(),
							props);
				}
				if (validate == true) {
					break;
				}
			}
			if (validate == false) {
				/* at least one spec unequal, return directly */
				return false;
			}
		}
		return true;
	}

   /**
    * Reconfigure traffic filter policy on DVS.
    * This is a generic method to configure traffic filter.
    *
    * @param dvsMor ManagedObjectReference object.
    * @param dvsFilterPolicy DvsFilterPolicy object.
    *
    * @return boolean true if successful false otherwise.
    * @throws Exception
    */
   public boolean reconfigureFilterPolicy(
                      final ManagedObjectReference dvsMor,
                      final DvsFilterPolicy dvsFilterPolicy)
      throws Exception
   {
      if (dvsMor == null || dvsMor.getType() == null) {
         log.warn("DVS mor is null.");
      }
      if (dvsFilterPolicy == null) {
         log.warn("Traffic Filter Policy is null.");
      }

      log.info("start reconfiguring traffic filter for DVS ");
      final VMwareDVSConfigSpec vmwareDVSConfigSpec = new VMwareDVSConfigSpec();
      VMwareDVSConfigInfo vmwareDVSConfigInfo = getConfig(dvsMor);
      if (vmwareDVSConfigInfo == null) {
         log.error("VMwareDVSConfigInfo is null.");
         return false;
      }
      vmwareDVSConfigSpec.setConfigVersion(vmwareDVSConfigInfo
            .getConfigVersion());
      vmwareDVSConfigSpec.setDefaultPortConfig(new DVPortSetting());
      vmwareDVSConfigSpec.getDefaultPortConfig().setFilterPolicy(
            dvsFilterPolicy);
      reconfigure(dvsMor, vmwareDVSConfigSpec);
      if (dvsFilterPolicy == null) {
          return true;
      }
      log.info("Reconfigure traffic filter policy done...  Verifying...");
      final VMwareDVSConfigInfo currentCfgInfo = getConfig(dvsMor);
      if (currentCfgInfo == null) {
         log.error("VMwareDVSConfigInfo is null.");
         return false;
      }
      DvsFilterPolicy currDvsFilterPolicy =
            currentCfgInfo.getDefaultPortConfig().getFilterPolicy();
      Vector<String> props =
            TestUtil.getIgnorePropertyList(dvsFilterPolicy, false);
      boolean reconfigured =
            TestUtil.compareObject(currDvsFilterPolicy, dvsFilterPolicy,
                  props);
      if (!reconfigured) {
         log.error("Verification failed.");
      } else {
         log.info("Successfully verified.");
      }

      return reconfigured;
   }

   /**
    * Reconfigure traffic filter policy to a dvs port.
    *
    * @param dvsMor ManagedObjectReference object.
    * @param dvsFilterPolicy DvsFilterPolicy object.
    * @param portKey
    *
    * @return boolean true if successful false otherwise.
    * @throws Exception
    */
   public boolean reconfigureFilterPolicyToPort(
         final ManagedObjectReference dvsMor,
         final DvsFilterPolicy dvsFilterPolicy,
         final String portKey)
      throws Exception
   {
      if (dvsMor == null || dvsMor.getType() == null) {
         log.warn("DVS mor is null.");
      }
      if (dvsFilterPolicy == null) {
         log.warn("Traffic Filter Policy is null.");
      }
      if (portKey == null) {
         log.warn("Port key is null.");
      }

      DVPortConfigSpec[] portCfgs = new DVPortConfigSpec[1];
      DVPortConfigSpec portCfg = new DVPortConfigSpec();

      DistributedVirtualSwitchPortCriteria portCriteria =
            new DistributedVirtualSwitchPortCriteria();
      portCriteria.getPortKey().add(portKey);
      List<DistributedVirtualPort> dvPorts = fetchPorts(dvsMor, portCriteria);
      if (dvPorts == null || dvPorts.get(0) == null) {
         log.error("fetchPorts return null.");
         return false;
      }
      log.info("Successfully obtained the port");
      DVPortConfigInfo dvPortConfigInfo = dvPorts.get(0).getConfig();
      if (dvPortConfigInfo == null) {
         log.error("Failed to obtain the DVPortConfigInfo.");
         return false;
      }
      portCfg.setKey(portKey);
      portCfg.setOperation(ConfigSpecOperation.EDIT.value());
      VMwareDVSPortSetting setting =
            DVSUtil.getDefaultVMwareDVSPortSetting(null);
      setting.setFilterPolicy(dvsFilterPolicy);
      portCfg.setSetting(setting);
      portCfgs[0] = portCfg;
      return reconfigurePort(dvsMor, portCfgs);
   }
   
   /**
    * Get all Distributed Virtual MORs. 
    * @return list of dvsMors, null otherwise;
    * @throws Exception
    */
   public List<ManagedObjectReference> getAllDistributedVirtualSwitches()
      throws Exception
   {
      ConnectAnchor connectAnchor = super.getConnectAnchor();
      Folder folder = new Folder(connectAnchor);
      ManagedObjectReference folderMor = folder.getNetworkFolder(folder.getDataCenter());
      return super.getAllChildEntity(folderMor,
               MORConstants.VMWARE_DVSWITCH_MOR_TYPE);
   }

   /**
    * Set multicastfilteringMode on DVS.
    *
    * @param dvsMor        ManagedObjectReference object.
    * @param multicastMode String, maybe 'legacyFiltering' or 'snooping'
    *
    * @return boolean true if successful false otherwise.
    * @throws Exception
    */
   public boolean setMulticastFilteringMode(
                      final ManagedObjectReference dvsMor,
                      final String multicastMode)
      throws Exception
   {
      if (multicastMode == null) {
         log.warn("multicastMode is null.");
      }
      log.info("start set multicast mode for DVS ");
      final VMwareDVSConfigSpec vmwareDVSConfigSpec = new VMwareDVSConfigSpec();
      VMwareDVSConfigInfo vmwareDVSConfigInfo = getConfig(dvsMor);
      if (vmwareDVSConfigInfo == null) {
         log.error("VMwareDVSConfigInfo is null.");
         return false;
      }
      vmwareDVSConfigSpec.setConfigVersion(vmwareDVSConfigInfo
            .getConfigVersion());
      vmwareDVSConfigSpec.setMulticastFilteringMode(multicastMode);
      reconfigure(dvsMor, vmwareDVSConfigSpec);
      // If input multicastMode is null, skip the verification step
      if (multicastMode == null) {
          return true;
      }
      log.info("Set multicast mode for DVS done...  Verifying...");
      final VMwareDVSConfigInfo currentCfgInfo = getConfig(dvsMor);
      if (currentCfgInfo == null) {
         log.error("VMwareDVSConfigInfo is null.");
         return false;
      }
      String currMulticastMode =
            currentCfgInfo.getMulticastFilteringMode();
      boolean reconfigured = multicastMode.equals(currMulticastMode);
      if (!reconfigured) {
         log.error("Verification failed.");
      } else {
         log.info("Successfully verified.");
      }
      return reconfigured;
   }
}
