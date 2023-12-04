class NetworkPolicy:
    def __init__(self) -> None:
        self.name = ""
        self.namespace = ""
        self._rules: List[NetworkPolicyRule] = []

    def add_rule(self, data: dict) -> None:
        rule = NetworkPolicyRule()
        traffic_direction = data["flow"]["traffic_direction"]
        if traffic_direction == "EGRESS":
            rule.set_selector(data["flow"]["source"])
            rule.add_egress(data["flow"])
        else:
            rule.set_selector(data["flow"]["destination"])
            rule.add_ingress(data["flow"])

        self._rules.append(rule)

    def to_dict(self) -> dict:
        return {
            "apiVersion": "cilium.io/v2",
            "kind": "CiliumNetworkPolicy",
            "metadata": {
                "name": self.name,
                "namespace": self.namespace,
            },
            "specs": [rule.to_dict() for rule in self._rules],
        }
