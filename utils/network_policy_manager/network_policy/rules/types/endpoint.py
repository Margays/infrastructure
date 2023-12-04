from typing import Any
from network_policy_manager.network_policy.exceptions import UnknownRuleTypeError
from network_policy_manager.utils.labels import extract_k8s_labels
from network_policy_manager.network_policy.rules.types.base import BaseType


class EndpointRule(BaseType):
    def __init__(self, data: dict) -> None:
        self._supported_labels = [
            "app",
            "io.cilium.k8s.policy.serviceaccount",
            "io.kubernetes.pod.namespace",
        ]
        self._labels = extract_k8s_labels(data["labels"], self._supported_labels)

    def to_dict(self) -> dict:
        return  {
            "matchLabels": self._labels,
        }

    def get_type(self) -> str:
        return "Endpoints"

    def __eq__(self, obj: Any) -> bool:
        if not isinstance(obj, EndpointRule):
            return False

        return self._labels == obj._labels
