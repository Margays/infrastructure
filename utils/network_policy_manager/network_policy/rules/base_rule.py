from network_policy_manager.network_policy.exceptions import UnknownRuleTypeError
from network_policy_manager.network_policy.rules.types import BaseType, EndpointRule, EntityRule


class BaseRule:
    def __init__(self, data: dict, prefix: str, target: str) -> None:
        source = data[target]
        self._ports = self._get_ports(data.get("l4", {}), target)
        self._prefix = prefix
        self._rule_type = self._get_rule_type(source)

    def _get_rule_type(self, data: dict) -> BaseType:
        if "namespace" in data:
            return EndpointRule(data)
        else:
            return EntityRule(data)

    def _get_ports(self, l4_data: dict, target: str) -> list:
        ports = []
        for key, value in l4_data.items():
            port = value.get(f"{target}_port", None)
            if port is None:
                continue

            ports.append({
                "port": port,
                "protocol": key
            })

        return ports

    def to_dict(self) -> dict:
        rule = {
            f"{self._prefix}{self._rule_type.get_type()}": self._rule_type.to_dict(),
        }
        if self._ports:
            rule[f"{self._prefix}Ports"] = {
                "ports": self._ports
            }

        return rule

    def __eq__(self, obj: "BaseRule") -> bool:
        return (self._rule_type == obj._rule_type 
            and self._prefix == obj._prefix
            and self._rule_type == obj._rule_type)
