from abc import abstractmethod, ABCMeta
from network_policy_manager.utils.generic import DictSerializable


class BaseType(DictSerializable, metaclass=ABCMeta):
    @abstractmethod
    def get_type(self) -> str:
        return "Endpoints"
