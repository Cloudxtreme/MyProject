/*
 * ************************************************************************
 *
 * Copyright 2007 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */

package com.vmware.vcqa;

import static com.vmware.vcqa.stress.StressConstants.PROP_DELIM;

import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.vmware.vcqa.stress.DBLogger;
import com.vmware.vcqa.stress.StressBase;
import com.vmware.vcqa.stress.StressConstants;
import com.vmware.vcqa.stress.StressThread;

/**
 * TestRunner takes a list of tests and runs them in separate threads to achieve
 * concurrent execution of test cases. User can specify the number of hours /
 * number of iterations.
 *
 * @author kirane
 * @since 1.5
 * @version 1.0
 */
public class TestRunner
{
   private static final Logger log = LoggerFactory.getLogger(TestRunner.class);
   final private List<TestBase> allTests;

   final private int numOfHours;

   final private int numOfIterations;

   final private Config cfg;

   final private StringBuffer result;

   private Connection conn;

   private int tid;
   private int lid;
   private int cid;
   private DBLogger dbLogger = null;

   /**
    * variable to check whether all threads are passing. If some thread fails it
    *  will update this value to false and the tests are terminated.
    */
   private volatile boolean canRun = true;

   /**
    * This constructor starts the tests upon successful creation of threads.
    *
    * If the list contains only one test it will be run in a separate thread.
    *
    * @param tests a list of object's of type {@link TestBase}TestBase
    * @param duration the duration of the test.
    * @param iterations number of iterations the test should run.
    * @throws IllegalArgumentException if any error occurs in configuration.
    */
   public
   TestRunner(final List<TestBase> tests,
              Config config)
   {

      StressBase.setOutputAndErrorStreams();
         int duration = config.getDuration();
         int iterations = config.getIterate();
         if (tests == null || tests.isEmpty()) {
            log.error("Atleast one test should be provided to run.");
            throw new IllegalArgumentException(
               "Atleast one test should be provided to run the tests.");
   }
         if (duration > 0 && iterations > 0) {
            log.error("Only one of the hours/iterations to be "
                     + "specified.");
            throw new IllegalArgumentException(
               "Only one of the hours/ iterations to be specified.");
   }
         allTests = tests;
         numOfHours = duration;
         numOfIterations = iterations;
         cfg = config;
         int size = tests.size() * Math.max(duration, iterations) * 100;
         result = new StringBuffer(size);
         result.append("\n--------------- FINAL RESULT ---------------");
         try {
            this.initDBOps();

   } catch (Exception e) {
            log.error("Exception raised : " + e);
            log.error(e.getMessage());
      e.printStackTrace();
   }
   }

   /**
    * This method is used to start the tests. We call this method in the
    * constructor so that successful creation of the TestRunner object will
    * start the tests. This blocks until all test threads started by this method
    * are completed.
    */
   public void
   startTests()
              throws IllegalAccessException
   {
      long totalTimeTaken = 0;
      final long startTime = System.currentTimeMillis();
      int passCount = 0;// holds the number of pass instances.
      final int size = allTests.size();
      log.info("~~ Starting " + allTests.size() + " test instances ~~");
      // here for every test we run it for n hours / iterate for n times
      // depending on the test's config.

      final List<Thread> threads = new ArrayList<Thread>(size);
      final List<StressThread> tests = new ArrayList<StressThread>(size);
      Map<String, String> instancePropertyMap = null;

      /*
       * Insert details into StressInstParam table.
       */
      ArrayList<ArrayList<Object>> listOfBatches = new ArrayList<ArrayList<Object>>();
      PreparedStatement pstmt = dbLogger.getStressInstParamInsertStmt();
      for (int i = 0; i < size; i++) {
         int delay = 0;
         final StressBase test = (StressBase) allTests.get(i);
         String classname = test.getClass().getName();
         int inst = i + 1;
         final String[] prefixInstance = new String[] {
                  StressConstants.ALL_INSTANCE, String.valueOf(inst) };
         instancePropertyMap = new HashMap<String, String>();
         for (String prefixInst : prefixInstance) {
            final String prefix = classname + PROP_DELIM + prefixInst
                     + PROP_DELIM;
            log.info("[Instance : " + (i + 1) + " ] Prefix Used: " + prefix);

            for (Field fld : StressConstants.class.getFields()) {
               String propValue = cfg.getProperty(prefix + fld.getName());
               if (propValue != null) {
                  log.info("[Instance : " + (i + 1) + " ] Property name : "
                           + fld.getName() + " , Property Value : " + propValue);
                  /*
                         * Add to instancePropertyMap to log into DB.
                         */
                  instancePropertyMap.put(fld.getName(), propValue);

                  String methodName = "set" + fld.get(fld).toString();
                   methodName = methodName.replace("_", "");
                  Class[] methodArgs = new Class[] { String.class };
                  try {
                     Method method = StressBase.class.getMethod(methodName,
                              methodArgs);
                     if (method != null) {
                        log.info("[Instance : " + (i + 1) + " ] Invoke "
                                 + methodName + " on StressBase for instance "
                                 + (i + 1));
                        method.invoke(test, propValue);
                     }
                  } catch (Exception e) {
                     log.error("[Instance : " + (i + 1)
                              + " ] Please check if method " + methodName
                              + " exists in "
                              + StressBase.class.getName().toString());
                  }
               }
            } // end of fields for loop
         } // end of prefix instance for loop

         try {
            final StressThread stressThread = new StressThread(test,
                     numOfHours, numOfIterations, test.getDelay(), this);
            final String name = test.getClass().getName()
                     + StressConstants.PROP_DELIM + "Thread-" + (i + 1);
            final Thread aThread = new Thread(stressThread, name);
            // add the StressThread objects to use it for updating the result.
            tests.add(stressThread);
            threads.add(aThread); // add the threads to join them later.
            log.info("[Instance : " + (i + 1) + " ]  Starting "
                     + aThread.getName());
            aThread.start();

            /*
             * Log instance properties to DB.
             */
            if (instancePropertyMap != null && instancePropertyMap.size() > 0
                     && conn != null) {
               String dbPropertyString = "";
               for (String property : instancePropertyMap.keySet().toArray(
                        new String[0])) {
                  String value = instancePropertyMap.get(property);
                  if (dbPropertyString.length() > 0) {
                     dbPropertyString = dbPropertyString + "; " + property
                              + "=" + value;
                  } else {
                     dbPropertyString = property + "=" + value;
                  }
               }
               ArrayList<Object> values = new ArrayList<Object>();
               values.add(lid);
               values.add(i + 1);
               values.add(dbPropertyString);
               listOfBatches.add(values);
            }
         } catch (final Exception e) {
            log.error("[Instance : " + (i + 1)
                     + " ] Could not create a test thread to run"
                     + e.getMessage());
            throw new IllegalArgumentException(e);
         }
      } // End of for loop
      dbLogger.addBatchToPreparedStatement(pstmt, listOfBatches);
      dbLogger.executeQuery(pstmt, listOfBatches);
      result.append("\n");
      // now wait till all the threads complete.
      for (int i = 0; i < threads.size(); i++) {
         try {
            threads.get(i).join();
            if (tests.get(i).getResult()) {
               passCount++;
               // result.append("\n# ").append(threads.get(i).getName()).append(" PASSED");
            } else {
               // result.append("\n# ").append(threads.get(i).getName()).append(" FAILED");
            }
         } catch (final InterruptedException e) {
            log.error("Error while joining.");
            throw new IllegalArgumentException(e);
         }
      }
      totalTimeTaken = (System.currentTimeMillis() - startTime) / 1000;
      result.append("\nTotal time taken: " + totalTimeTaken + " seconds");
      log.info(result.toString());
      log.info(" Threads Result: " + passCount + "/" + size);
      if (passCount < size) {
         log.error(" Overall result: FAIL ");
      } else {
         log.info("All Stress tests completed successfully");
      }

   }

   /**
    * Accessor for canRun.
    *
    * @return whether the stress test can be continued or not.
    */
   public synchronized boolean
   canRun()
   {
      return this.canRun;
   }

   /**
    * mutator for canRun.
    *
    * @param value will be set to false by StressThread if a test fails.
    */
   public synchronized void
   setCanRun(final boolean value)
   {
      this.canRun = value;
   }

   /**
    * Method to append the result of individual tests by StressThread(s).
    * @param log the result string.
    */
   public void appendResult(final Object log) {
      result.append(log);
   }

   /**
    * Get Connection to Database.
    *
    * @return   Connection      If connection was successful to DB.
    *           null            Otherwise.
    */
    private Connection
    initDBConnection(){
       Connection connection = null;
       String driverName = "sun.jdbc.odbc.JdbcOdbcDriver";
       String username = "sa";
       String password = "ca$hc0w";

       try {
           // Load the JDBC driver
           Class.forName(driverName);

           // Create a connection to the database
           connection = DriverManager.getConnection("jdbc:odbc:SQLServer2005",
                                                    username,
                                                    password);

           if(connection!=null){
              DatabaseMetaData dbMetaData = connection.getMetaData();
              log.info(" Product Name : " +  dbMetaData.getDatabaseProductName());
              log.info(" Product Version : " +  dbMetaData.getDatabaseProductVersion());
              log.info(" Driver Name : " +dbMetaData.getDriverName());
              log.info(" Driver Version : " +dbMetaData.getDriverVersion());
              log.info("Connected to DB server for the DSN ");
           } else{
              log.warn("Connection failed to DB server for the DSN");
           }
       } catch (ClassNotFoundException e) {
          log.warn("Could not find the database driver " + driverName);
       } catch (SQLException e) {
          log.warn("Could not connect to Database ", e);
       }

       return connection = (connection!=null) ? connection : null ;

    }

    /**
     * Return Connection object
     *
     * @return  conn        Connection object.
     */
    public Connection
    getConnection()
    {
       return conn;
    }


    /**
     * Method to perform some basic database operations. It is called in the
       * constructor.
     *
     * @throws SQLException
       */
      private void
      initDBOps()throws SQLException
      {
         dbLogger = DBLogger.getSingletonInstance();
         /*
          * Get connection to DB.
          */
         conn = dbLogger.getConnection();
         String username = cfg.getArgs()[2];
         if (conn != null) {
            String stressName = this.allTests.get(0).getClass().getName();
            String prefix = stressName + PROP_DELIM + "*" + PROP_DELIM;
            String cloneType = cfg.getProperty(prefix + "CLONE_TYPE");
            log.info("Clone type is " + cloneType);
            /*
             * Get test ID given the test name. In case the test name has a clone
             * type appended to it, try with the clone type within parentheses.
             */
            tid = dbLogger.getStressTid(stressName);
            if (tid < 0) {
               if (cloneType != null) {
                  stressName += " (" + cloneType + ")";
                  tid = dbLogger.getStressTid(stressName);
               } else {
                  log.info("No Clone type specified in parameters file.");
               }
            }
            if (tid < 0) {
               log.warn("Could not obtain test id");
               log.warn("DB Logging for test " + stressName
                        + " failed.");
               this.dbLogger.setDBLoggingEnabled(false);
            } else {
               /*
                * Insert data into TestLaunch table.
                */
               String cidObj = System.getProperty(TestConstants.STRESS_CYCLE_ID);
               if (cidObj == null) {
                  log.warn("No Cycle ID found. DB Logging for test "
                           + stressName + " failed.");
                  this.dbLogger.setDBLoggingEnabled(false);
               } else {
                  ArrayList<Object> values = new ArrayList<Object>();
                  cid = Integer.parseInt(cidObj);
                  values.add(cid);
                  values.add(tid);
                  values.add(cfg.getInstances());
                  values.add(cfg.getIterate());
                  values.add(cfg.getDuration());
                  String dateTime = DBLogger.getCurrentTime();
                  values.add(dateTime);
                  lid = dbLogger.insertTestLaunch(values, true);
                  if (lid < 0) {
                     this.dbLogger.setDBLoggingEnabled(false);
                     log.warn("Could not insert into TestLaunch "
                              + "table. DB Logging for test " + stressName
                              + " failed.");
                  }
               }
            }
         } else {
            log.warn("Connection object is null.");
            this.dbLogger.setDBLoggingEnabled(false);
         }
      }

      /**
       * @return the lid
     */
    public int getLid()
      {
         return lid;
      }

    /**
       * @return the dbLogger
       */
      public DBLogger getDbLogger()
      {
         return dbLogger;
      }

    /**
       * @return the cid
       */
      public int getCid()
      {
         return cid;
      }
}
