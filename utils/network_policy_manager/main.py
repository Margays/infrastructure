import subprocess
import json
from typing import List, Iterator

DATA = {
    "flow": {
        "time": "2023-11-05T20:19:40.823892249Z",
        "uuid": "6040efc3-7c9b-4355-942a-712716be5eb1",
        "verdict": "AUDIT",
        "ethernet": {
            "source": "ea:a8:f9:05:05:5e",
            "destination": "26:ac:ac:fd:d3:3a"
        },
        "IP": {
            "source": "10.244.1.147",
            "destination": "172.18.0.3",
            "ipVersion": "IPv4"
        },
        "l4": {
            "TCP": {
                "source_port": 47960,
                "destination_port": 6443,
                "flags": {
                    "SYN": True
                }
            }
        },
        "source": {
            "identity": 8757,
            "namespace": "flux-system",
            "labels": [
                "k8s:app=source-controller",
                "k8s:io.cilium.k8s.namespace.labels.app.kubernetes.io/instance=flux-system",
                "k8s:io.cilium.k8s.namespace.labels.app.kubernetes.io/part-of=flux",
                "k8s:io.cilium.k8s.namespace.labels.app.kubernetes.io/version=v2.1.2",
                "k8s:io.cilium.k8s.namespace.labels.kubernetes.io/metadata.name=flux-system",
                "k8s:io.cilium.k8s.namespace.labels.pod-security.kubernetes.io/warn-version=latest",
                "k8s:io.cilium.k8s.namespace.labels.pod-security.kubernetes.io/warn=restricted",
                "k8s:io.cilium.k8s.policy.cluster=default",
                "k8s:io.cilium.k8s.policy.serviceaccount=source-controller",
                "k8s:io.kubernetes.pod.namespace=flux-system"
            ],
            "pod_name": "source-controller-9dfbc5cd-cz76x"
        },
        "destination": {
            "identity": 1,
            "labels": [
                "reserved:host",
                "reserved:kube-apiserver"
            ]
        },
        "Type": "L3_L4",
        "node_name": "kind-control-plane",
        "event_type": {
            "type": 5
        },
        "traffic_direction": "INGRESS",
        "is_reply": False,
        "Summary": "TCP Flags: SYN"
    },
    "node_name": "kind-control-plane",
    "time": "2023-11-05T20:19:40.823892249Z"
}


class NetworkPolicyRuleSelector:
    def __init__(self, data: dict) -> None:
        self._selector_type = self._get_selector_type(data)
        self._match_labels = self._get_labels(data)

    def _get_selector_type(self, data: dict) -> str:
        if "reserved:host" in data.get("labels"):
            return "nodeSelector"
        elif "namespace" in data:
            return "endpointSelector"
        else:
            raise Exception("unknown selector type")

    def _get_labels(self, data: dict) -> dict:
        labels = {}
        if self._selector_type == "endpointSelector":
            for label in data["labels"]:
                if label.startswith("k8s:"):
                    key, value = label.split(":", 1)[1].split("=", 1)
                    labels[key] = value

        return labels

    def to_dict(self) -> dict:
        return {
            self._selector_type: {
                "matchLabels": self._match_labels,
            },
        }


class NetworkPolicyRule:
    def __init__(self) -> None:
        self._selector = None
        self._egress = []
        self._ingress = []

    def set_selector(self, data: dict) -> None:
        self._selector = NetworkPolicyRuleSelector(data)

    def add_egress(self, data: dict) -> None:
        return
        self._egress.append(data)

    def add_ingress(self, data: dict) -> None:
        return
        self._ingress.append(data)

    def to_dict(self) -> dict:
        if self._selector is None:
            raise Exception("selector is not set")

        rule = {
            "egress": self._egress,
            "ingress": self._ingress,
        }
        rule.update(self._selector.to_dict())
        return rule


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
            rule.add_egress(data)
        else:
            rule.set_selector(data["flow"]["destination"])
            rule.add_ingress(data)

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


class NetworkPolicyManager:
    def __init__(self):
        self._network_policies: List[NetworkPolicy] = []

    def parse_flow(self, data: dict) -> None:
        network_policy = NetworkPolicy()
        network_policy.add_rule(data)
        self._network_policies.append(network_policy)

    def to_dict(self) -> Iterator[dict]:
        for network_policy in self._network_policies:
            yield network_policy.to_dict() 


def executeCmd(cmd):
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, universal_newlines=True)
    for stdout_line in iter(proc.stdout.readline, ""):
        yield stdout_line

    proc.stdout.close()
    return_code = proc.wait()
    if return_code:
        raise subprocess.CalledProcessError(return_code, cmd)


def main() -> None:
    manager = NetworkPolicyManager()
    manager.parse_flow(DATA)
    print(list(manager.to_dict()))
    return
    for json_data in executeCmd(["hubble", "observe", "--follow", "--output", "json"]):
        data = json.loads(json_data)
        print(data)


if __name__ == "__main__":
    main()
