class EgressRule:
    def __init__(self, data: dict) -> None:
        source = data["source"]
        self._prefix = "to"
        self._rule_type = self._get_rule_type(source)
        self._match_labels = self._get_labels(source["labels"])

    def _get_rule_type(self, data: dict) -> str:
        if any(label in data.get("labels", []) for label in ["reserved:host", "reserved:remote-node"]):
            return f"Entities"
        elif "namespace" in data:
            return f"Endpoints"
        else:
            raise Exception("unknown selector type")

    def _get_labels(self, labels: list[str]) -> dict:
        allowed_labels = [
            "app",
            "io.cilium.k8s.policy.serviceaccount",
            "io.kubernetes.pod.namespace",
        ]
        if self._rule_type == "Endpoints":
            selected_labels = {}
            for label in labels:
                if label.startswith("k8s:"):
                    key, value = label.split(":", 1)[1].split("=", 1)
                    if key not in allowed_labels:
                        continue
                    selected_labels[key] = value
            return selected_labels
        elif self._rule_type == "Entities":
            selected_labels = []
            for label in labels:
                if label.startswith("reserved:"):
                    name = label.split(":", 1)[1]
                    selected_labels.append(name)
            return selected_labels
        
        raise Exception("unknown selector type")

    def to_dict(self) -> dict:
        return {
            f"{self._prefix}{self._rule_type}": {
                "matchLabels": self._match_labels,
            },
        }
