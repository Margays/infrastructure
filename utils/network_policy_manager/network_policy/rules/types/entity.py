from typing import Any
from network_policy_manager.network_policy.exceptions import UnknownRuleTypeError
from network_policy_manager.utils.labels import extract_entity_names
from network_policy_manager.network_policy.rules.types import BaseType


class EntityRule(BaseType):
    def __init__(self, data: dict) -> None:
        self._entities = extract_entity_names(data["labels"])

    def to_dict(self) -> list[str]:
        return self._entities

    def get_type(self) -> str:
        return "Entities"

    def __eq__(self, obj: Any) -> bool:
        if not isinstance(obj, EntityRule):
            return False

        return self._entities == obj._entities
