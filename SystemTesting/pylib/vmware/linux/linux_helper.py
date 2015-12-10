import os

import vmware.common.compute_utilities as compute_utilities
import vmware.common.utilities as utilities
import vmware.common.global_config as global_config

pylogger = global_config.pylogger


class Linux(object):
    """Helper class for containing common Linux related operations"""
    WGET = "wget"

    @classmethod
    def copy_dir(cls, client_object, src_dir=None, dst_dir=None, timeout=None):
        """
        Copies one directory over to another.

        @type client_object: BaseClient
        @param client_object: Provides access to execute commands on the remote
            host.
        @type src_dir: str
        @param src_dir: Source directory being copied.
        @type dst_dir: str
        @param dst_dir: Location to which the source directory will be copied
            over to.
        @type timeout: int
        @param timeout: Time in seconds after which the copy command will be
            aborted.
        """
        cmd = "cp -r %s %s" % (src_dir, dst_dir)
        return client_object.connection.request(cmd, timeout=timeout)

    @classmethod
    def replace_in_file(cls, client_object=None, path=None, regex=None,
                        substitution=None):
        """
        Helper for replacing text in a file.

        @type client_object: BaseClient
        @param client_object: Provides access to execute commands on the remote
            host. If this param is not provided then the method will do a
            replace on local file.
        @type path: str
        @param path: Path to file
        @type regex: str
        @param regex: Regex that will be used to match the text that needs
            to be replaced.
        @type substitution: str
        @param substitution: Specifies the text that needs to be substituted
            in place of regex.
        @rtype: None
        @return: Returns nothing.
        """
        cmd = r"sed -i 's/%s/%s/' %s" % (regex, substitution, path)
        if client_object:
            client_object.connection.request(cmd)
        else:
            compute_utilities.run_command_sync(cmd)

    @classmethod
    def tar(cls, client_object, create=None, extract=None, verbose=None,
            gz=None, tar_file=None, directory=None):
        if (create is None and extract is None) or (create and extract):
            raise ValueError("Either create or extract needs to be set, got: "
                             "create=%r, extract=%r" % (create, extract))
        operation = "create" if create else "extract"
        if tar_file is None:
            raise ValueError("Can not %s a tar since file name is not "
                             "provided" % operation)
        if create and directory is None:
            raise ValueError("Directory to be compressed is not provided")
        if verbose is None:
            verbose = True
        if gz is None:
            gz = True
        if directory is None:
            directory = "."
        cmd = ["tar"]
        opts = ["f"]
        if verbose:
            opts.append("v")
        if gz:
            opts.append("z")
        if create:
            opts.append("c")
        if extract:
            opts.append("x")
        opts = "".join(opts)
        if create:
            cmd.extend([opts, "%s %s" % (tar_file, directory)])
        if extract:
            cmd.extend([opts, "%s -C %s" % (tar_file, directory)])
        return client_object.connection.request(" ".join(cmd))

    @classmethod
    def get_temp_dir(cls):
        return global_config.DEFAULT_LOG_DIR

    @classmethod
    def tempfile(cls, prefix=None):
        file_name = utilities.get_random_name(prefix=prefix)
        return os.path.join(cls.get_temp_dir(), file_name)

    @classmethod
    def check_file_exists(cls, client_object, path):
        cmd = "ls %s" % path
        return not client_object.connection.request(
            cmd, strict=False).status_code

    @classmethod
    def delete_file(cls, client_object, path, force=False, check=True):
        if check and not cls.check_file_exists(client_object, path):
            pylogger.warn("Not removing file %s: does not exist." % path)
            return
        force_str = force and "-f " or ""
        cmd = "rm %s%s" % (force_str, path)
        return client_object.connection.request(cmd)

    @classmethod
    def put_file(cls, client_object, local_path, remote_path, **put_kwargs):
        sftp = client_object.connection.anchor.open_sftp()
        sftp.put(local_path, remote_path, **put_kwargs)
        sftp.close()

    @classmethod
    def get_file(cls, client_object, remote_path, local_path, **get_kwargs):
        pylogger.debug("Fetching file %r from remote host %r to local path "
                       "%r" % (remote_path, client_object.ip, local_path))
        sftp = client_object.connection.anchor.open_sftp()
        sftp.get(remote_path, local_path, **get_kwargs)
        sftp.close()

    @classmethod
    def create_file(cls, client_object, path, content='', overwrite=False,
                    stream=None, close_input_stream=True):
        if cls.check_file_exists(client_object, path):
            pylogger.warn('File %s already exists.' % path)
            if not overwrite:
                return
            pylogger.warn('Deleting existing file %s.' % path)
            cls.delete_file(client_object, path)
        temp_file = cls.tempfile("create_file")
        f = open(temp_file, 'w')
        if stream and not content:
            for _ in xrange(4096):  # Limit to 4096 iterations: max 4GB file
                buf = stream.read((2 ** 20) * 8)  # MB
                if not buf:
                    break
                f.write(buf)
            else:
                pylogger.warning("Hit max file size while iterating stream.")
            if close_input_stream:
                stream.close()
        else:
            f.write(content)
        f.close()
        cls.put_file(client_object, temp_file, path)
        os.remove(temp_file)

    @classmethod
    def wget_files(cls, client_object, files=None, directory=None,
                   accept=None, timeout=None, content_disposition=None):
        """
        Helper for getting files from the provided filess and storing
        them locally.

        @type client_object: BaseClient
        @param client_object: Used to pass commands to the host.
        @type files: list
        @param files: List of URLs to files or directories.
        @type directory: str
        @param directory: Target directory in which the files will be
            stored. Directory is created if not there already.
        @type accept: list
        @param accept: Specifies the list of file type/patterns to download
            from the remote url directory.
        @type timeout: int
        @param timeout: Time after which the attempt to configure package is
            aborted.
        @type content_disposition: bool
        @param content_disposition: Used to specify if the content_disposition
            is to be used in wget command.
        @rtype: str
        @return: Directory in which the files are stored.
        """
        date_and_time = utilities.current_date_time()
        files = utilities.as_list(files)
        if directory is None:
            # XXX(Salman): Needed the separator of the target host here.
            directory = os.sep.join([cls.get_temp_dir(), date_and_time])
        client_object.connection.request('mkdir -p %s' % directory)
        # XXX(Salman): This might need adjustment if the specified url does
        # not support HTTP(s)/FTP.
        fetch_cmd = ["%s -q -r -nH -nd -P %s --no-parent" %
                     (cls.WGET, directory)]
        if accept:
            accept = utilities.as_list(accept)
            pylogger.debug("Will only fetch packages matching %r" % accept)
            fetch_cmd.append("--accept %s" % ','.join(accept))
        if content_disposition:
            fetch_cmd.append("--content-disposition")
        fetch_cmd.append('%s')
        fetch_cmd = ' '.join(fetch_cmd)
        for package in files:
            client_object.connection.request(fetch_cmd % package,
                                             timeout=timeout)
        return directory
