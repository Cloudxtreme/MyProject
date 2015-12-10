import json
import urllib
import urllib2
import re
import vmware.common.global_config as global_config

from bs4 import BeautifulSoup

log = global_config.pylogger

NICIRA_BUILD_API = 'https://devdashboard.nicira.eng.vmware.com'
NICIRA_BUILD_URL = 'http://apt.nicira.eng.vmware.com/builds'
URL_PREFIX = 'http://buildapi.eng.vmware.com'


def get_resource(url):
    url = '%s%s' % (URL_PREFIX, url)
    log.debug("Getting build resource for %s" % url)
    response = urllib2.urlopen(url).read()
    data = json.loads(response)
    return data


def download_deliverable(url, filename):
    fp = open(filename, 'wb')
    chunk = 1024*1024
    req = urllib2.urlopen(url)
    while 1:
        data = req.read(chunk)
        if not data:
            break
        fp.write(data)
    fp.close()


def get_build_id(py_dict):
    """ Wrapper method for calling get_build

        @param py_dict  dict containing information needed to identity build id
    """

    product = py_dict['build_product']
    branch = py_dict['build_branch']
    build_type = py_dict['build_context'] + '-' + py_dict['build_type']

    build_id = get_build(product, branch, build_type, None)

    return build_id


def get_build(product, branch, build_type='beta', optional=None):
    if re.search('vmware-nsxvswitch', product):
        return get_nvs_build(product, branch, build_type, optional)
    if re.search('vsmva', product):
        return get_latest_vmware_build(product, branch, build_type, optional)


def get_latest_vmware_build(product, branch, build_type='sb-beta', optional=None):
    """ Method to obtain a build number on the basis of input params

        @param product  name of product whose build id is to be obtained
        @param branch   branch name to be used (e.g. vshield-main)
        @param build_type     build type. This is a hyphenated value.
                        Its format is <build-context>-<build-type>
                        e.g. ob-beta
        @param optional extra param for adding extra functionality in future
    """

    log.debug("Get build for: product: %s, branch: %s, build_type: %s, \
      optional:%s   " % (product, branch, build_type, optional))
    if build_type.find('sb-') == 0:
        deliverable_type = 'sb'
    else:
        deliverable_type = 'ob'
    build_type = build_type.split('-')[-1]

    request = '/%s/build/?'\
              'product=%s&'\
              'branch=%s&'\
              'buildtype=%s&'\
              'buildstate=succeeded&'\
              'ondisk=true&'\
              '_limit=1&'\
              '_order_by=-build' % (deliverable_type, product, branch, build_type)
    log.debug("Request passed : %s" % request)
    data = get_resource(request)
    data_list = data['_list']
    build = None
    if data_list :
       build = data_list[0]['_deliverables_url'].split('=')[-1]
       if deliverable_type == 'sb':
          build = 'sb-' + build
       elif deliverable_type == 'ob':
          build = 'ob-' + build
    else :
       log.info("There is no build available for the given request")
    log.debug("Build number obtained: %s" % (build))

    return build


def get_build_from_tuple(build_tuple):
    """ Method to obtain a latest build number on the basis of build tuple

        @param build_tuple build tuple in the form
        product:branch:buildtype:deliverable_type or
        an actual sandbox/official build number
        sb-10000/ob-20000
    """
    match = re.match("^(\w+-)?(\d{4,})", str(build_tuple))
    if match:
        if match.group(1):
            buildtype = match.group(1)
        else:
            buildtype = "ob-"
        log.debug("Using %s build %s" % (buildtype, match.group(2)))
        return (buildtype + match.group(2))
    log.info("Using build tuple %s to find build id" % build_tuple)
    try:
        product = build_tuple.split(':')[0]
        branch = build_tuple.split(':')[1]
        deliverable_type = build_tuple.split(':')[3]
    except IndexError:
        log.error("Unable to find enough elements in build_tuple:%r, expected "
                  "format is: <product>:<branch>:<build_type>:"
                  "deliverable_type" % build_tuple)
        raise
    if 'official' in deliverable_type:
        deliverable_type = 'ob'
    elif 'sandbox' in deliverable_type:
        deliverable_type = 'sb'
    else:
        log.warn("Unknown deliverable type: %r" % deliverable_type)
        return None
    build_type = deliverable_type + '-' + build_tuple.split(':')[2]

    return get_latest_vmware_build(product, branch, build_type, None)


def get_nvs_build(product, branch, build_type='beta', optional=None):
    log.debug("Get NVS build for: product: %s, branch: %s, build_type: %s, \
      optional:%s   " % (product, branch, build_type, optional))
    build_url = NICIRA_BUILD_API + \
        '/buildinfo/latest_good_build/openvswitch-esx/' + branch
    build = urllib.urlopen(build_url).read()
    log.debug('OVS build for query %s: %s ' % (build_url, build))

    # build_url = NICIRA_BUILD_API + '/buildinfo/all_info/%s' % build
    # json_ = urllib.urlopen(build_url).read()
    # build_info = json.loads(json_)
    url = NICIRA_BUILD_URL + "/openvswitch-esx" \
                             "%s/esx" % (build)

    html_page = urllib2.urlopen(url).read()
    #
    # BeutifulSoup is used to parse html output
    #
    soup = BeautifulSoup(html_page)
    regex = re.compile(r'^%s-\d+.*%s-%s\.vib' % (product, optional, build_type))
    for link in soup.findAll('a', href=True):
        file_name = link.get('href')
        if regex.match(file_name):
            log.debug('NVS VIB File %s ' % file_name)
            url = "%s/%s" % (url, file_name)
            return url


def get_build_deliverable_url(build_id, search_string):
    log.debug("Getting ovf url for build: %r using regex: %r" %
              (build_id, search_string))
    download_url = None
    try:
        if not hasattr(search_string, '__iter__'):
            search_string = (search_string, )
        for search_str in search_string:
            (src, build) = re.match("^(?:(\w+)-)?(\d{4,})", build_id).groups()
            params = {
                'build': build,
                'path__iregex': search_str,
            }
            if src is None:
                src = "ob"
            url = '/%s/deliverable/?%s' % (src, urllib.urlencode(params))
            data = get_resource(url)
            if data['_total_count'] != 0:
                download_url = str(data['_list'][0]['_download_url'])
            else:
                log.debug("Zero total count got from %r: %r" % (url, data))
            if download_url is not None:
                break
    except Exception:
        log.exception("Failed to get download URL for build: %r using regex: %r" %
                      (build_id, search_string))
        raise
    if download_url is None:
        raise Exception("Unable to find build url for: %r using regex: %r" %
                        (build_id, search_string))
    else:
        log.debug("Found build url %r for: %r using regex: %r" %
                  (download_url, build_id, search_string))
    return download_url


def get_deliverable(build_id, search_string):
    log.debug("Get deliverable for build: %s, that matches string: %s" %
              (build_id, search_string))
    filename = None
    download_url = get_build_deliverable_url(build_id, search_string)
    if download_url is not None:
        filename = download_url.split('/')[-1]
        path = '/tmp/' + filename
        download_deliverable(download_url, path)
    return filename


if __name__ == "__main__":
    # test case: get latest vmware build on invalid parameters
    # expected output = 'None'
    print get_latest_vmware_build('nsxv','mine')
    # test case :get latest vmware build on valid parameters
    # expected output = <a valid number>
    print get_latest_vmware_build('nsx-controller','avalanche','ob-beta')
