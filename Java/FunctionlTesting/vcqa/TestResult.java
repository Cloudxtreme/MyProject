/*
 * ************************************************************************
 *
 * Copyright 2004-2009 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package com.vmware.vcqa;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.vmware.vc.MethodFault;


public class TestResult {
   private static final Logger log = LoggerFactory.getLogger(TestResult.class);
   
   private Object expectedOutcome;
   private ResultsEnum testResult;
   
   public void setExpectedOutcome(MethodFault fault){
      this.expectedOutcome = fault;
   }
   
   public String getOutcome(){
      return testResult.toString();
   }
   
   public void setOutcome(ResultsEnum result){
         if ((testResult == null) ||
              (this.testResult.equals(ResultsEnum.PASS))) {
         this.testResult = result;
         } else {
           log.warn("Outcome already set.");
         }
   }
}