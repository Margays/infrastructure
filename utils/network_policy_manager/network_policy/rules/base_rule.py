class BaseRule:
    def __init__(self, data: dict, prefix: str, source_name: str) -> None:
        source = data[source_name]
        self._prefix = prefix
        self._rule_type = self._get_rule_type(source)
        self._match_labels = self._get_labels(source["labels"])

    def _get_rule_type(self, data: dict) -> str:
        entities = [
            "reserved:host",
            "reserved:remote-node",
            "reserved:world",
        ]
        if any(label in data.get("labels", []) for label in entities):
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

    def __eq__(self, obj: "BaseRule") -> bool:
        return (self._rule_type == obj._rule_type 
            and self._prefix == obj._prefix
            and self._match_labels == obj._match_labels)