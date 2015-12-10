#!/usr/bin/env python

import sys
import logging

LOG_FORMAT = '%(asctime)s %(levelname)-8s %(message)s'

logging.basicConfig(level=logging.DEBUG,
                    format=LOG_FORMAT,
                    datefmt='%a, %d %b %Y %H:%M:%S')


''' check for recent python; older versions don't have the right cookielib and
xmlrpclib
'''
version = sys.version_info
if not ( version[0] >= 2 and version [1] >= 5 ):
    logging.debug("bz.py requires python >= 2.5. Please use the python from \
                    the bldmnt systems or upgrade your current installation.")
    sys.exit(1);

import xmlrpclib, urllib2, cookielib, os, getpass, sys
import pprint
from types import *
from datetime import datetime, time
from urlparse import urljoin, urlparse
from cookielib import CookieJar
from optparse import OptionParser
from operator import itemgetter

DEBUG = True
VERSION = "0.1"

class CookieTransport(xmlrpclib.Transport):
    '''A subclass of xmlrpclib.Transport that supports cookies.'''
    cookiejar = None
    scheme = 'https'

    def cookiefile(self):
        if 'USERPROFILE' in os.environ:
            homepath = os.path.join(os.environ["USERPROFILE"], "Local Settings",
            "Application Data")
        elif 'HOME' in os.environ:
            homepath = os.environ["HOME"]
        else:
            homepath = ''

        cookiefile = os.path.join(homepath, ".bugzilla-cookies.txt")
        return cookiefile

    def send_cookies(self, connection, cookie_request):
        '''Cribbed from xmlrpclib.Transport.send_user_agent'''

        if self.cookiejar is None:
            self.cookiejar = cookielib.MozillaCookieJar(self.cookiefile())

            if os.path.exists(self.cookiefile()):
                self.cookiejar.load(self.cookiefile())
            else:
                self.cookiejar.save(self.cookiefile())

        # Let the cookiejar figure out what cookies are appropriate
        self.cookiejar.add_cookie_header(cookie_request)

        # Pull the cookie headers out of the request object...
        cookielist=list()
        for name,value in cookie_request.header_items():
            if name.startswith('Cookie'):
                cookielist.append([name,value])

        # ...and put them over the connection
        for name,value in cookielist:
            connection.putheader(name,value)

    def request(self, host, handler, request_body, verbose=0):
        '''This is the same request() method from xmlrpclib.Transport, with a
        couple additions noted below'''

        connection = self.make_connection(host)
        if verbose:
            connection.set_debuglevel(1)

        # ADDED: construct the URL and Request object for proper cookie handling
        request_url = "%s://%s/" % (self.scheme,host)
        cookie_request  = urllib2.Request(request_url)

        self.send_request(connection,handler,request_body)
        self.send_host(connection,host)
        self.send_cookies(connection,cookie_request)
        self.send_user_agent(connection)
        self.send_content(connection,request_body)

        try:
            errcode, errmsg, headers = connection.getreply()
        except AttributeError:
            errcode = None
            errmsg = ""
            headers = ""

        # ADDED: parse headers and get cookies here
        # fake a response object that we can fill with the headers above
        class CookieResponse:
            def __init__(self,headers): self.headers = headers
            def info(self): return self.headers
        cookie_response = CookieResponse(headers)
        #Extract the cookies from the headers
        self.cookiejar.extract_cookies(cookie_response,cookie_request)
        # And write back any changes
        if hasattr(self.cookiejar,'save'):
            self.cookiejar.save(self.cookiejar.filename)

        if errcode != 200:
            raise xmlrpclib.ProtocolError(
                host + handler,
                errcode, errmsg,
                headers
                )

        self.verbose = verbose

        try:
            sock = connection._conn.sock
        except AttributeError:
            sock = None

        return self._parse_response(connection.getfile(), sock)


class SafeCookieTransport(xmlrpclib.SafeTransport,CookieTransport):
    '''SafeTransport subclass that supports cookies.'''
    scheme = 'https'
    request = CookieTransport.request

