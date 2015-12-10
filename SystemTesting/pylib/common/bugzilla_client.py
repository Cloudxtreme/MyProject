import re
import json
import string
import urllib2
import urllib
from cookie_transport import *
from table_parser import TableParser

BUGZILLA_URL = 'https://bugzilla.eng.vmware.com/xmlrpc.cgi'

class BugzillaClient(object):
    '''Class provides methods to interact with bugzilla.
    '''

    def __init__(self, uname, password):
        self.url = BUGZILLA_URL
        self.cookie_file = self.cookiefile()
        self.cookie_jar = cookielib.MozillaCookieJar(self.cookie_file)
        self.user = uname
        self.password = password
        self.server = xmlrpclib.ServerProxy(self.url, SafeCookieTransport())
        self.columns = None
        self.bug_info = {}
        self.bug_cache = {}


    def cookiefile(self):
        '''Method to find the file of cookie file to store login cookies
        '''

        if 'USERPROFILE' in os.environ:
            homepath = os.path.join(os.environ["USERPROFILE"], "Local Settings",
            "Application Data")
        elif 'HOME' in os.environ:
            homepath = os.environ["HOME"]
        else:
            homepath = ''

        cookiefile = os.path.join(homepath, ".bugzilla-cookies.txt")
        return cookiefile


    def login(self):
        '''Function to login to bugzilla
           Must be called before any other function is called.
        '''

        if self.has_valid_cookie():
            return

        logging.debug("Bugzilla Login Required")

        logging.debug('Logging in with username "%s"' % self.user)
        try:
            self.server.User.login({"login" : self.user,
                                    "password" : self.password})
        except xmlrpclib.Fault, err:
            logging.debug("A fault occurred:")
            logging.debug("Fault code: %s" % err.faultCode)
            logging.debug("Fault string: %s" % err.faultString)
        logging.debug("logged in")
        self.cookie_jar.save;


    def saved_queries(self, user):
        '''returns all the saved queries associated to the username
           Param          Type         Description
           user           String       Username
        '''
        try:
            self.queries = self.server.Search.get_all_saved_queries(user)
        except xmlrpclib.Fault, err:
                logging.debug("A fault occurred:")
                logging.debug("Fault code: %s" % err.faultCode)
                logging.debug("Fault string: %s" % err.faultString)
                sys.exit(1)
        return queries


    def add_comment(self, bug_id, comment):
        '''Add a new comment to the given bug
           Param          Type         Description
           bug_id         Integer      Bug ID
           comment        String       Comment string to be added to the bug
        '''
        try:
            self.server.Bug.add_comment(bug_id, comment)
        except xmlrpclib.Fault, err:
            logging.debug("A fault occurred:")
            logging.debug("Fault code: %s" % err.faultCode)
            logging.debug("Fault string: %s" % err.faultString)
            sys.exit(1)

        logging.debug("Comment added to bug %s" % bug_id)


    def create(self):
        '''Create a new bug according to given bug parameters
        '''
        try:
            new_bug_id = self.server.Bug.create(self.bug_info)
        except xmlrpclib.Fault, err:
            logging.debug("A fault occurred:")
            logging.debug("Fault code: %s" % err.faultCode)
            logging.debug("Fault string: %s" % err.faultString)
            sys.exit(1)

        logging.debug("Bug Filed. Bug ID: %d" % new_bug_id['id'])
        return new_bug_id['id']


    def reopen_bug(self, bug_id):
        '''Reopens a closed or resolved bug.
           Param          Type         Description
           bug_id         Integer      Bug ID
        '''
        try:
            bug_status = self.server.Bug.reopen({'bug_id':bug_id})
        except xmlrpclib.Fault, err:
            logging.debug("A fault occurred:")
            logging.debug("Fault code: %s" % err.faultCode)
            logging.debug("Fault string: %s" % err.faultString)
            sys.exit(1)

        return bug_status


    def get_bug(self, bug_id):
        '''This method takes a single integer argument as a bug_id and
           returns back a bug object with the same id.

           Param          Type         Description
           bug_id         Integer      Bug ID
        '''
        try:
            bug = self.server.Bug.show_bug(bug_id)
        except xmlrpclib.Fault, err:
            logging.debug("A fault occurred:")
            logging.debug("Fault code: %s" % err.faultCode)
            logging.debug("Fault string: %s" % err.faultString)
            sys.exit(1)

        return bug


    def search_bug(self, summary = '', description = '',
                   keywords = '', reporter = '',
                   product = '', category = '',
                   in_days = 0, search_open = True):
        '''Custom search bugzilla for bugs based on summary,
           description, keywords and reporter.
           Atleast one criteria must be provided.
           Returns a dictionary of bug id and its details.

           Param          Type         Description
           summary        String       Search by summary line
           description    String       Search by string in comments
           keywords       String       Search by keywords
           reporter       String       Search by reporter's username
           product        String       Product
           category       String       Category
           in_days        Integer      Bugs in last # days
           search_open    Boolean      Search only open bugs (default)
        '''
        if (not (summary or description or keywords or reporter or\
                 product or category or in_days)):
            logging.debug("Atleast one search criteria must be provided.")
            return None

        search_params = {}
        search_params['query_format'] = 'advanced'
        search_params['short_desc_type'] = 'allwordssubstr'
        search_params['longdesc_type'] = 'allwordssubstr'
        search_params['keywords_type'] = 'allwords'
        search_params['cmdtype'] = 'doit'
        search_params['columnlist'] = ''
        search_params['backButton'] = 'true'
        if summary:
            search_params['short_desc'] = '"%s"' % summary
        if description:
            search_params['longdesc'] = '"%s"' % description
        search_params['keywords'] = keywords

        if reporter:
            search_params['emailreporter2'] = '1'
            search_params['emailtype2'] = 'exact'
            search_params['email2'] = reporter

        search_params['product'] = product
        search_params['category'] = category

        if in_days:
            search_params['changedin'] = in_days
            search_params['chfield'] = '[Bug creation]'

        url_data = urllib.urlencode(search_params)

        if search_open:
            search_params['chfield'] = '[Bug creation]'

        url_data = urllib.urlencode(search_params)

        if search_open:
            # search for only open bug
            url_data += "&bug_status=new&bug_status=assigned&bug_status=reopened"

        search_url = '%s?%s' % (BUGZILLA_URL.replace('https', 'http'), url_data)
        search_url = search_url.replace('xmlrpc.cgi', 'buglist.cgi')

        self.cookie_jar.load(self.cookie_file, ignore_expires=True)
        login_cookie = self.cookie_jar._cookies['bugzilla.eng.vmware.com']['/']['Bugzilla_logincookie'].value
        bug_cookie = self.cookie_jar._cookies['bugzilla.eng.vmware.com']['/']['Bugzilla_login'].value

        opener = urllib2.build_opener(urllib2.HTTPCookieProcessor(self.cookie_jar))
        opener.addheaders = [('Cookie','Bugzilla_logincookie=%s; Bugzilla_login=%s' % (login_cookie, bug_cookie)),('Connection', 'close')]

        response = opener.open(search_url)

        content = response.read()
        tpars = TableParser()
        bug_dict = tpars.get_table_data('buglistSorter', content)

        # Change bug_ids from string to integers
        for bug_id,value in bug_dict.iteritems():
            bug_dict[int(bug_id)] = bug_dict.pop(bug_id)

        return bug_dict


    def has_valid_cookie(self):
        '''Checks if login cookies are present and valid
        '''
        try:
            parsed_url = urlparse(self.url)
            host = parsed_url[1]
            path = parsed_url[2] or '/'

            # Cookie files don't store port numbers, unfortunately, so
            # get rid of the port number if it's present.
            host = host.split(":")[0]

            logging.debug( "Looking for '%s' cookie in %s" % \
                  (host, self.cookie_file))
            self.cookie_jar.load(self.cookie_file, ignore_expires=True)

            try:
                cookie = self.cookie_jar._cookies[host]['/']['Bugzilla_logincookie']

                if not cookie.is_expired():
                    logging.debug("Loaded valid cookie -- no login required")
                    return True

                logging.debug("Cookie file loaded, but cookie has expired")
            except KeyError:
                logging.debug("Cookie file loaded, but no cookie for this server")
        except IOError, error:
            logging.debug("Couldn't load cookie file: %s" % error)

        return False


    def get_cached_bugs(self, key):
        for bug_id, key_array in self.bug_cache.iteritems():
            if key in key_array:
                return bug_id
        return None


    def update_cache(self, bug_id, keys):
        self.bug_cache[bug_id] = keys


    def search_recent(self, keys):
        # Get bugs filed in last 3 day for given category and product
        recent_bugs = self.search_bug(product = self.bug_info['product'],
                                   category = self.bug_info['category'],
                                   in_days = 3)

        bug_ids = recent_bugs.keys()

        recent_bugs = {}

        for bug_id in bug_ids:
            recent_bugs[bug_id] = 0
            # get description of each bug
            description = self.get_bug(bug_id)['description']

            if (type(description) is str):
                # count no. of matches
                for key in keys:
                    if re.search(key, description):
                        recent_bugs[bug_id] += 1
            else:
                logging.debug("Unexpected data in the bug description for PR: %d" % bug_id)

            # discard bugs with no match
            if recent_bugs[bug_id] == 0:
                recent_bugs.pop(bug_id)

        # Return bug_ids with most number of matches
        for bug_id, count in recent_bugs.items():
            if count != max(recent_bugs.values()):
                recent_bugs.pop(bug_id)

        return recent_bugs


    def check_and_create_bug(self, search_keys, bug_info, max_keywords_match):
        '''Searches for similar open bugs and files new bug if no similar bug is
           found, adds comment if the similar bug found.
           Param                 Type               Description
           search_keys          String array      Array of search keyword strings
           bug_info             Dictionary        Bug details
           max_keywords_match   Int               Max. no of keywords to match from keystring
        '''
        self.bug_info = bug_info

        # Search if similar bug is already filed in same session
        bug_id = self.get_cached_bugs(search_keys[0])
        # Update if found
        if bug_id:
            logging.debug("Bug ID: %d found in cache" % bug_id)
            # Temporary action: Return bug id
            return bug_id

        key_subset = []

        for idx, key in enumerate(search_keys[:max_keywords_match]):
            key_subset.append(key)
            keystring = '"%s"' % string.join(key_subset,'","')

            # Search for bugs with same words in their initial comments
            bug_dict = self.search_bug(description = keystring)

            if idx == 0:
                multiple_bugs_found_bug_dict = bug_dict

            logging.debug("Search keystring: %s" % key)

            if len(bug_dict) == 0:
                # May be a Unique failure.Search recent bugs and
                # update the bug which matches most keywords
                logging.debug("No similar bug found. Searching recent bugs")
                bug_dict = self.search_recent(search_keys[:max_keywords_match])

                # If still no bugs found, file a new bug
                # Truely unique failure
                if not bug_dict:
                    logging.debug("No similar recent bugs")
                    bug_id = self.create()
                    # Update local cache with bug number
                    self.update_cache(bug_id, search_keys)
                    return bug_id

            if len(bug_dict) == 1:
                # Temporary action: Return bug id
                bug_id = bug_dict.keys()[0]
                logging.debug("One Bug found: %d" % int(bug_id))
                return bug_id

            elif len(bug_dict) > 1:
                # discard the current key and continue with rest
                key_subset = key_subset[:-1]

        # If multiple bugs are present for given keywords
        # Temporary action: Return the latest bug_id
        logging.debug("Multiple bugs %s with similar keywords found." % bug_dict.keys())

        if multiple_bugs_found_bug_dict:
            bugs = []
            for bug_ids in multiple_bugs_found_bug_dict.keys():
                bugs.append(int(bug_ids))
            bug_id = max(bugs)
        else:
            bug_id = max(bug_dict.keys())
        logging.debug("Selected for update %d" % int(bug_id))
        return bug_id


    def make_concise(self):
        '''Returns short descripton with the summary line,
           testcase name and log file location
        '''
        comment = re.split('\n',self.bug_info['description'])[:2]
        self.bug_info['description'] = "%s\n%s" % \
                (self.bug_info['summary'], string.join(comment,'\n'))
        bug_info['description']


    def check_unresolved(self, bug_dict):
        '''Returns most recent unresolved bug from given list
           Param          Type         Description
           bug_dict       dictionary   dictionary containing bug number,
                                       status and other details.
        '''

        unresolved_bugs = []

        for bug_id, attr in bug_dict.items():
            if attr['Status'] in ['new', 'reopened', 'assigned']:
                unresolved_bugs.append(bug_id);

        # return the most recent bug id
        if unresolved_bugs:
            return max(unresolved_bugs)
        else:
            return None


    def check_resolved(self, bug_dict):
        '''Returns most recent resolved bug from given list
           Param          Type         Description
           bug_dict       dictionary   dictionary containing bug number,
                                       status and other details.
        '''

        resolved_bugs = []

        for bug_id, attr in bug_dict.items():
            if attr['Status'] in ['resolved', 'closed']:
                resolved_bugs.append(bug_id);

        # return the most recent bug id
        if resolved_bugs:
            return max(resolved_bugs)
        else:
            return None

