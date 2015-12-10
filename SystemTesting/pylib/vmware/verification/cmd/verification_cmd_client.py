import vmware.verification.verification as verification
import vmware.common.base_client as base_client


class VerificationCMDClient(verification.Verification,
                            base_client.BaseCMDClient):

    def __init__(self, parent=None):
        super(VerificationCMDClient, self).__init__(parent=parent)
