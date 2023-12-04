from abc import abstractmethod, ABC


class DictSerializable(ABC):
    @abstractmethod
    def to_dict(self) -> dict | list:
        raise NotImplementedError()
