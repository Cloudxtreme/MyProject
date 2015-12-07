/*
 * ************************************************************************
 *
 * Copyright 2007 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */

package com.vmware.vcqa;

import java.io.BufferedInputStream;
import java.io.FileInputStream;
import java.util.Enumeration;
import java.util.Properties;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.vmware.vcqa.stress.StressConstants;
import com.vmware.vcqa.util.TestUtil;

/**
 * Config is used to validate, load and access the arguments in a single place.
 *
 * @author kirane
 * @version 1.0
 * @since 1.5
 */
public final class Config extends Properties
{
   private static final Logger log = LoggerFactory.getLogger(Config.class);
   private final String[] args;
   private int duration;
   private int iterate;
   private int instances;

   /**
    * Given with the arguments this constructor validates and loads the
    * necessary properties.
    *
    * @param arguments arguments to load the properties and values.
    * @throws IllegalArgumentException if any arguments are not valid.
    */
   public
   Config(final String[] arguments) throws IllegalArgumentException
   {
      args = arguments;
      if (!validateAndLoad()) {
         throw new IllegalArgumentException(
               "The arguments / properties are not valid");
      }
   }

   /**
    * Method to validate and load the configuration.
    *
    * @return true is everything goes fine else false.
    */
   private boolean
   validateAndLoad()
   {
      final int numOfArgs = 10;
      boolean result = true;
      // 1. validate the args
      if (TestUtil.validNumOfArgs(numOfArgs, args)) {
         // 2. check duration/hours, only one of them should be present.
         String propfileName = TestUtil.getOptionValue(
               StressConstants.PROP_FILE, args);
         if (propfileName == null) {
            log.error("Please specify valid param file: ");
            result = false;
         } else {
            try {
               if (TestUtil.hasOption(StressConstants.ITERATE, args)) {
                  if (TestUtil.hasOption(StressConstants.DURATION, args)) {
                     log.error("Only one of the hours / iterations"
                           + " should be specified.");
                     result = false;
                  } else {
                     iterate = Integer.parseInt(TestUtil.getOptionValue(
                           StressConstants.ITERATE, args));
                     log.info(" Config - number of iterations: "
                           + iterate);
                  }
               } else if (TestUtil.hasOption(StressConstants.DURATION, args)) {
                  duration = Integer.parseInt(TestUtil.getOptionValue(
                        StressConstants.DURATION, args));
                  log.info(" Config - duration of the test: "
                        + duration);
               } else {
                  log.error("Atleast one of the hours / iterations"
                        + "has to be specified.");
                  result = false;// if none of the options are specified.
               }
               // check +ve values for iterate and duration
               instances = Integer.parseInt(TestUtil.getOptionValue(
                     StressConstants.INSTANCE, args));
               log.info(" Config - number of instances: " + instances);
               if (instances <= 0) {
                  log.error(StressConstants.INSTANCE
                        + " argument is Mandatory and should "
                        + " be a postive Integer greater than 0.");
                  result = false;
               } else {
                  log.info(" Loading: paramfile: " + propfileName);
                  String USER_DIR_KEY = "user.dir";
                  String currentDir = System.getProperty(USER_DIR_KEY);
                  
                  System.out.println("Working Directory: " + currentDir);

                  BufferedInputStream bis = new BufferedInputStream(
                        new FileInputStream(propfileName));
                  load(bis);
                  log.info(entrySet().size() + " properties loaded.");
               }
            } catch (final Exception e) {
               log.error("Please specify valid arguments: "
                     + e.getMessage());
               throw new IllegalArgumentException(e);
            }
         }
      } else {
         log.error("Number of arguments are less than expected: "
               + numOfArgs + " Given: " + args.length);
         result = false;
      }
      return result;
   }

   /**
    * Accessor for Duration.
    *
    * @return the duration
    */
   public int
   getDuration()
   {
      return duration;
   }

   /**
    * Accessor for instances, which represents the number of instances of tests
    * to be created.
    *
    * @return the instances
    */
   public int
   getInstances()
   {
      return instances;
   }

   /**
    * Accessor for iterate.
    *
    * @return the iterate
    */
   public int
   getIterate()
   {
      return iterate;
   }

   /**
    * Prints the properties matching given name space.
    *
    * @param nameSapce starting name of property.
    */
   public void
   list(final String nameSapce)
   {
      log.info("*** Properties for '" + nameSapce + "' ***");
      Enumeration<?> names = propertyNames();
      while (names.hasMoreElements()) {
         String oneProp = (String) names.nextElement();
         if (oneProp.startsWith(nameSapce)) {
            log.info("* Name: " + oneProp + "=" + getProperty(oneProp));
         }
      }
   }

   /**
    * @return the args
    */
   public String[] getArgs()
   {
      return args;
   }
}
