/* ************************************************************************
 *
 * Copyright 2007-2011 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package com.vmware.vcqa;

import java.net.URL;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * ExtensionConnectAnchor is an anchor class that allows the client to establish connection to an
 * extension associated to a host agent/VC.
 */
public abstract class ExtensionConnectAnchor extends GenericConnectAnchor {
    private static final Logger log = LoggerFactory.getLogger(ExtensionConnectAnchor.class);

    /**
     * Constructor to initialize the extension's end point URL
     * 
     * @param URL end point url of the extension service
     * 
     * @throws Exception
     */
    protected ExtensionConnectAnchor(URL url) throws Exception {
        endPointURL = url.toString();
        this.hostName = url.getHost();
        this.port = url.getPort();
    }

    /**
     * Setup the connect anchor by creating getting the end point URL and binding it to the service
     * and creating service instance and service content
     * 
     * @throws Exception
     */
    @Override
    protected void setup() throws Exception {
        boolean connectAnchorCreated = false;
        if (endPointURL == null) {
            log.error("ConnectAnchor: EndpointURL not specified");
        } else {
            createService(endPointURL);
            if (this.stub == null) {
                log.error("ConnectAnchor: Failed to create Binding");
            } else {
                /*
                 * If binding is created connectAnchorCreated flag set to true SMS extension service
                 * does not populate ServiceInstance or ServiceContent
                 */
                connectAnchorCreated = true;
                createServiceInstance();
                createServiceContent();
                if (this.serviceContent == null) {
                    log.warn("ConnectAnchor: Failed to create " + "Service Content");
                } else {
                    log.info("-------------------------------------");
                    log.info("Extension ConnectAnchor: Connected Server " + "Info :");
                    if (log.isTraceEnabled()) {
                        LogUtil.printObject(this.getAboutInfo());
                    } else {
                       if(this.getAboutInfo() != null){
                          log.info(this.getAboutInfo().getFullName());
                       }
                    }
                    log.info("-------------------------------------");
                }
            }
        }
        if (!connectAnchorCreated) {
            log.error("ConnectAnchor: Failed to create Connect" + " Anchor for extension.");
            throw new Exception("Failed to create connect anchor for extension");
        }
    }
}
