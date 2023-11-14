from .rules import IngressRule, EgressRule
from .subject_selector import SubjectSelector


class NetworkPolicyRule:
    def __init__(self) -> None:
        self._subject_selector = None
        self._egress = []
        self._ingress = []

    def set_selector(self, data: dict) -> None:
        self._selector = SubjectSelector(data)

    def add_egress(self, data: dict) -> None:
        rule = EgressRule(data)
        if rule in self._egress:
            return

        self._egress.append(rule)

    def add_ingress(self, data: dict) -> None:
        rule = IngressRule(data)
        if rule in self._ingress:
            return

        self._ingress.append(rule)

    def to_dict(self) -> dict:
        if self._selector is None:
            raise Exception("selector is not set")

        rule = {
            "egress": [egress.to_dict() for egress in self._egress],
            "ingress": [ingress.to_dict() for ingress in self._ingress],
        }
        rule.update(self._selector.to_dict())
        return rule

    def __add__(self, obj: "NetworkPolicyRule") -> "NetworkPolicyRule":
        if self._selector != obj._selector:
            raise Exception("selector is not equal")

        for egress in obj._egress:
            if egress not in self._egress:
                self._egress.append(egress)

        for ingress in obj._ingress:
            if ingress not in self._ingress:
                self._ingress.append(ingress)

        return self

    def identity(self) -> int:
        return hash(self._selector)
