import vmware.base.base as base
import vmware.common.base_facade as base_facade
import vmware.interfaces.labels as labels

auto_resolve = base_facade.auto_resolve


class Profile(base.Base):

    def __init__(self, name=None, parent=None, id_=None):
        super(Profile, self).__init__()
        self.name = name
        self.parent = parent
        self.id_ = id_

    @auto_resolve(labels.CRUD)
    def create(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.PROFILE)
    def check_compliance(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.PROFILE)
    def associate_profile(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.CRUD)
    def delete(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.PROFILE)
    def get_profile_info(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.PROFILE)
    def get_network_policy_info(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.PROFILE)
    def apply_profile(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.PROFILE)
    def export_answer_file(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.PROFILE)
    def import_answer_file(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.PROFILE)
    def update_ip_address_option(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.PROFILE)
    def update_answer_file(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.PROFILE)
    def get_answer_file(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.CRUD)
    def update(self, execution_type=None, **kwargs):
        pass

    def get_id(self):
        return self.id_
