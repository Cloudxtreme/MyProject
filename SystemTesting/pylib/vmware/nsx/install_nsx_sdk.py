#!/usr/bin/env python

import argparse
import glob
import os
import subprocess
import sys
import urllib

import build_utilities
import mh.lib.lockutils as lockutils
import vmware.common.global_config as global_config

NSX_PYTHON_SDK = 'nsx_python_sdk'
NSX_PYTHON_SDK_SUFFIX = '.egg'
DEFAULT_SDK_INSTALL_PATH = '/tmp/vdnet/nsx-sdk'
DEFAULT_BUILD_ID = '2423348'
DEFAULT_LOG_DIR = '/tmp'
LOCK_FILE_NAME_SUFFIX = 'py_sdk_installation.lock'

pylogger = global_config.pylogger


def download_install_sdk(target_dir, build_no, sdk_name):
    """
    Download nsx sdk from url into target_dir
    @type url: str @param url: URL of sdk
    @type target_dir: str
    @param target_dir: target_dir on vdnet controller
    @rtype: None
    """
    pylogger.info("PYTHON SDK installing from build id: %s" % build_no)

    download_url = build_utilities.get_build_deliverable_url(build_no,
                                                             sdk_name)
    pylogger.info("PYTHON SDK download url <%s>" % download_url)

    lock_file_name = "%s_%s" % (build_no, LOCK_FILE_NAME_SUFFIX)
    file_lock = lockutils.FileBasedLock(DEFAULT_LOG_DIR, lock_file_name)
    pylogger.info("Acquiring file lock for SDK installation "
                  "file path: %s"
                  % os.path.join(DEFAULT_LOG_DIR, lock_file_name))

    file_lock.acquire()

    try:
        if not os.path.exists(target_dir):
            os.makedirs(target_dir)
            os.chmod(target_dir, 0777)

        pylogger.info("PYTHON SDK installing in %s" % target_dir)

        file_path = os.path.join(target_dir, download_url.split(os.sep)[-1])
        urllib.urlretrieve(download_url, file_path)

        os.environ["PYTHONPATH"] += ":%s" % target_dir
        original, os.environ["PYTHONDONTWRITEBYTECODE"] = (
            os.environ["PYTHONDONTWRITEBYTECODE"], "")
        subprocess.check_call(['easy_install', '--install-dir=' + target_dir,
                               file_path], env=os.environ)
        os.environ["PYTHONDONTWRITEBYTECODE"] = original
    finally:
        file_lock.release()

    pylogger.info("File lock for SDK installation released")

    pylogger.info("PYTHON SDK installed in %s" % target_dir)
    file_path = os.path.join(target_dir, download_url.split(os.sep)[-1])
    pylogger.info("Adding <%s> to python path" % file_path)
    os.environ["PYTHONPATH"] += ":%s" % target_dir
    sys.path.insert(1, file_path)


def get_sdk_installation_path(sdk_installation_path):
    """
    Checks if sdk is already installed by searching for *.egg in
    sdk_installation_path
    @type sdk_installation_path: str
    @param sdk_installation_path: Path where sdk has to be installed
    @rtype: str
    @return: Path to the egg file where sdk is installed
    """
    package_search = ("%s%s%s*%s" %
                      (sdk_installation_path, os.sep,
                       NSX_PYTHON_SDK, NSX_PYTHON_SDK_SUFFIX))
    matches = glob.glob(package_search)
    if matches:
        egg_file = matches[0]
        pylogger.info("Adding <%s> to python path" % egg_file)
        sys.path.insert(1, egg_file)
        try:
            subprocess.check_output(["python", "-c", "import vmware.nsx_api"],
                                    env={'PYTHONPATH': egg_file})
        except subprocess.CalledProcessError:
            pylogger.error("Invalid nsx-sdk egg file at %s" % egg_file)
            return
        return egg_file
    else:
        pylogger.warn('Failed to locate %s package' % package_search)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--install-dir', action='store', default=DEFAULT_SDK_INSTALL_PATH,
        help='Install directory for python nsx sdk [%(default)s]')
    parser.add_argument(
        '--build-id', action='store', required=True,
        help='Build id to be used for fetching nsx sdk egg file [REQUIRED]')
    parser.add_argument(
        '--log-dir', action='store', default=DEFAULT_LOG_DIR,
        help='Log directory for nsx sdk [%(default)s]')

    options = parser.parse_args()

    global pylogger
    pylogger = global_config.configure_global_pylogger(
        log_dir=options.log_dir)
    # Assuming the path is properly formatted and ends with /ob-<build-id>
    if "ob-" in options.install_dir or "sb-" in options.install_dir:
        if options.build_id:
            raise RuntimeError("--build-id %s or path to build installation "
                               "folder needs to be provided, but not both")
        else:
            options.build_id = options.install_dir.split("/")[-1]
    else:
        if ':' in options.build_id:
            options.build_id = build_utilities.get_build_from_tuple(
                options.build_id)
    if not options.install_dir.endswith(options.build_id):
        options.install_dir = os.path.join(
            options.install_dir, options.build_id)
    pylogger.info("PYTHON SDK install path set to: %s" % options.install_dir)
    if not get_sdk_installation_path(options.install_dir):
        download_install_sdk(options.install_dir, options.build_id,
                             NSX_PYTHON_SDK)
    egg_file = get_sdk_installation_path(options.install_dir)
    if egg_file:
        # Dont change this line this is used by Session.pm for figuring out the
        # path to egg file and adding it to environment
        print "PYTHON SDK configured at: %s" % egg_file
        sys.exit(0)
    else:
        sys.exit(1)

if __name__ == '__main__':
    main()
