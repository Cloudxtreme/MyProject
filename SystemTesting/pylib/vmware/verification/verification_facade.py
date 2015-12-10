#!/usr/bin/env python
import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.verification.verification as verification
import vmware.verification.cmd.verification_cmd_client as \
    verification_cmd_client


class VerificationFacade(verification.Verification, base_facade.BaseFacade):

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.CMD

    def __init__(self, parent=None):
        super(VerificationFacade, self).__init__(parent=parent)

        cmd_client = verification_cmd_client.VerificationCMDClient(
            parent=parent.get_client(constants.ExecutionType.CMD))
        self._clients = {constants.ExecutionType.CMD: cmd_client}
