/* ************************************************************************
*
* Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
*
* ************************************************************************
*/
package com.vmware.vcqa.vim.dvs.testframework;


import java.lang.reflect.Constructor;
import java.util.ArrayList;
import java.util.List;

import org.apache.commons.configuration.HierarchicalConfiguration;
import org.apache.commons.configuration.XMLConfiguration;
import org.apache.commons.configuration.tree.ConfigurationNode;

import com.vmware.vc.MethodFault;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;


/**
 * This class performs some useful functions such as extracting the steps from
 * the data file and the attributes associated with it.
 *
 * @author sabesanp
 *
 */
public class StepReader
{
   private HierarchicalConfiguration currentConfig = null;

   /**
    * Constructor
    *
    * @param currentConfig
    */
   public StepReader(HierarchicalConfiguration currentConfig)
   {
      this.currentConfig = currentConfig;
   }

   /**
    * This method returns all the steps in the data file.
    *
    * @return List<Step>
    */
   @SuppressWarnings("unchecked")
   public List<Step> getAllSteps()
      throws Exception
   {
      List<Step> stepList = new ArrayList<Step>();
      List<HierarchicalConfiguration> hierarchicalConfigList = this.
         currentConfig.configurationsAt(DVSTestConstants.TEST_STEP);
      String testFrameworkName = this.getData(DVSTestConstants.
         TEST_FRAMEWORK);
      for(HierarchicalConfiguration h : hierarchicalConfigList){
         Step step = new Step();
         List<?> attr = h.getRoot().getAttributes();
         for(Object configNode : attr){
            if(configNode instanceof ConfigurationNode){
               ConfigurationNode cNode = (ConfigurationNode)configNode;
               if(cNode.getName().equals(DVSTestConstants.ATTRIB_NAME)){
                  step.setName((String)cNode.getValue());
               }
               if(cNode.getName().equals(DVSTestConstants.ATTRIB_GROUP)){
                  step.setGroupName((String)cNode.getValue());
               }
               if(cNode.getName().equals(DVSTestConstants.TEST_FRAMEWORK)){
                  step.setTestFramework((String)cNode.getValue());
               }
            }
         }
         /*
          * Get all the data specified inside the step
          */
         if(h.getKeys(DVSTestConstants.TEST_DATA).hasNext()){
            HierarchicalConfiguration dataConfig = h.configurationAt(
               DVSTestConstants.TEST_DATA);
            List<String> dataList = null;
            if(dataConfig != null){
               dataList = (List<String>)dataConfig.getList(DVSTestConstants.
                  ATTRIB_TEST_DATA_ID);
               /*
                * TODO The api returns a list rather than a list of string.
                * This part of the code needs to be revisited later to
                * explicitly convert it into a list of string objects.
                */
               step.setData(dataList);
            }
         }
         /*
          * If the test framework was not specified, it might have been
          * specified at the top. Use that. If that is not specified as well,
          * it is a fatal error. Throw an exception.
          */
         if(step.getTestFrameworkName()==null){
            step.setTestFramework(testFrameworkName);
         }
         stepList.add(step);
      }
      return stepList;
   }

   /**
    * This method contructs the actual method fault class from the name
    * of the fault provided in the data file.
    *
    * @return MethodFault
    *
    * @throws Exception
    */
   public MethodFault getExpectedMethodFault()
      throws Exception
   {
      MethodFault expectedMethodFault = null;
      String expectedMethodFaultString = getData(DVSTestConstants.
         EXPECTED_METHOD_FAULT);
      if(expectedMethodFaultString != null){
         Class<?> faultClass = Class.forName(expectedMethodFaultString);
         Constructor<?> faultCons = faultClass.getConstructor();
         Object faultObj = faultCons.newInstance();
         if(faultObj instanceof MethodFault){
            expectedMethodFault = (MethodFault)faultObj;
         }
      }
      return expectedMethodFault;
   }

   /**
    * This method gets all the steps given the name of the group
    *
    * @param groupName
    *
    * @return List<Step>
    */
   public List<Step> getSteps(String groupName)
      throws Exception
   {
      List<Step> stepList = new ArrayList<Step>();
      List<Step> allStepsList = getAllSteps();
      for(Step step : allStepsList){
         if(step.getGroupName().equals(groupName)){
            stepList.add(step);
         }
      }
      return  stepList;
   }

   /**
    * This method gets the data from the XML tag name
    *
    * @param tagName
    *
    * @return String
    */
   public String getData(String tagName){
      return this.currentConfig.getString(tagName);
   }
}
