from network_policy_manager.network_policy.exceptions import UnknownRuleTypeError
from network_policy_manager.network_policy.rules.types import BaseType, EndpointRule, EntityRule


class BaseRule:
    def __init__(self, data: dict, prefix: str, target: str) -> None:
        self.data = data
        source = data[target]
        self._is_reply = data.get("is_reply", False)
        self._ports = self._get_ports(data.get("l4", {}))
        self._prefix = prefix
        self._rule_type = self._get_rule_type(source)

    def _get_rule_type(self, data: dict) -> BaseType:
        if "namespace" in data:
            return EndpointRule(data)
        else:
            return EntityRule(data)

    def _get_ports(self, l4_data: dict) -> list:
        ports = []
        target = "source" if self._is_reply else "destination"
        for key, value in l4_data.items():
            port = value.get(f"{target}_port", None)
            if port is None:
                continue

            if port > 32767:
                if "hubble-relay" in str(self.data):
                    continue

                print(self.data)
                print(target, port, l4_data)
                raise Exception("Port is too high")

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
            rule[f"toPorts"] = {
                "ports": self._ports
            }

        return rule

    def __eq__(self, obj: "BaseRule") -> bool:
        return (self._rule_type == obj._rule_type
            and self._prefix == obj._prefix
            and self._rule_type == obj._rule_type)
