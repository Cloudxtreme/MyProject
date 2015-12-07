/* ************************************************************************
 *
 * Copyright 2011 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package com.vmware.vcqa.ssl;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.net.Proxy;
import java.net.ProxySelector;
import java.net.SocketAddress;
import java.net.URI;
import java.util.Collections;

import org.slf4j.LoggerFactory;
import org.slf4j.Logger;

/**
 * Custom proxy selector used when this sample solution talks to both ESX Agent Manager and the vCenter server.<br>
 * We need to login to vCenter server as an extension and this means that vCenter needs to be able to see our
 * certificate we use for our connection. If we just connect to the vCenter server HTTPS reverse proxy at
 * https://<vcenter>/sdk, the certificate is not forwarded to the vCenter server endpoint. <br>
 * We will get an HTTPS connection to the reverse proxy, but the connection from the reverse proxy to vCenter will be
 * HTTP. <br>
 * To handle this we need to tunnel all our traffic through the proxy server when talking to vCenter. <br>
 * When talking to the ESX Agent Manager we don't need to tunnel the traffic through the proxy.
 */
public class CustomProxySelector extends ProxySelector {
    private static final Logger logger = LoggerFactory.getLogger(CustomProxySelector.class);
    private final ProxySelector defaultProxy;
    private final String _host;
    private final int _port;

    public CustomProxySelector(String host, int port, ProxySelector defaultProxy) {
        _host = host;
        _port = port;
        this.defaultProxy = defaultProxy;
    }

    @Override
    public java.util.List<Proxy> select(URI uri) {
        if (uri.toString().contains("sdkTunnel")) {
            // We talk to the vCenter server.
            Proxy p = new Proxy(Proxy.Type.HTTP, new InetSocketAddress(_host, _port));
            logger.debug("Proxy used for URI: {} is {}", uri, p);
            return Collections.singletonList(p);
        } else {
            logger.debug("Proxy used for URI: {} is {}", uri, Proxy.NO_PROXY);
            // We talk to the ESX Agent Manager.
            // return Collections.singletonList(Proxy.NO_PROXY);
            return defaultProxy.select(uri);// Use default selector
        }
    }

    /**
     * @see java.net.ProxySelector#connectFailed(java.net.URI, java.net.SocketAddress, java.io.IOException)
     */
    @Override
    public void connectFailed(URI paramURI, SocketAddress paramSocketAddress, IOException paramIOException) {
        System.out.println("ConnectionFauled for " + paramURI);
        paramIOException.printStackTrace();
    }
}
