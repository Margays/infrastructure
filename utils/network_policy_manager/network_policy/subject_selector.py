class SubjectSelector:
    def __init__(self, data: dict) -> None:
        self._suffix = "Selector"
        self._selector_type = self._get_selector_type(data)
        self._match_labels = self._get_labels(data["labels"])

    def _get_selector_type(self, data: dict) -> str:
        if any(label in data.get("labels", []) for label in ["reserved:host", "reserved:remote-node"]):
            return "node"
        elif "namespace" in data:
            return "endpoint"
        else:
            print(data)
            raise Exception("unknown selector type")

    def _get_labels(self, labels: list[str]) -> dict:
        allowed_labels = [
            "app",
            "io.cilium.k8s.policy.serviceaccount",
            "io.kubernetes.pod.namespace",
        ]
        selected_labels = {}
        if self._selector_type == "endpoint":
            for label in labels:
                if label.startswith("k8s:"):
                    key, value = label.split(":", 1)[1].split("=", 1)
                    if key not in allowed_labels:
                        continue
                    selected_labels[key] = value

        return selected_labels

    def to_dict(self) -> dict:
        return {
            f"{self._selector_type}{self._suffix}": {
                "matchLabels": self._match_labels,
            },
        }
