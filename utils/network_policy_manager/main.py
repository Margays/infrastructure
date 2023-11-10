import subprocess
import json
from typing import List, Iterator
from network_policy_manager.network_policy.rule import NetworkPolicyRule
from network_policy_manager.network_policy import NetworkPolicy


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


class NetworkPolicyManager:
    def __init__(self):
        self._rules: List[NetworkPolicyRule] = []
        self._network_policies: List[NetworkPolicy] = []

    def parse_flow(self, data: dict) -> None:
        rule = NetworkPolicyRule()
        try:
            traffic_direction = data["flow"]["traffic_direction"]
        except Exception:
            print("SKIPPED")
            return

        if traffic_direction == "EGRESS":
            rule.set_selector(data["flow"]["source"])
            rule.add_egress(data["flow"])
        else:
            rule.set_selector(data["flow"]["destination"])
            rule.add_ingress(data["flow"])
        
        self._rules.append(rule)

    def to_dict(self) -> Iterator[dict]:
        for rule in self._rules:
            yield rule.to_dict() 


def executeCmd(cmd):
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, universal_newlines=True)
    for stdout_line in iter(proc.stdout.readline, ""):
        yield stdout_line

    proc.stdout.close()
    return_code = proc.wait()
    if return_code:
        raise subprocess.CalledProcessError(return_code, cmd)


def main() -> None:
    with open("../kube-system.json", "r") as stream:
        data = json.load(stream)

    manager = NetworkPolicyManager()
    for flow in data:
        manager.parse_flow(flow)

    print(json.dumps(list(manager.to_dict())))
    return
    for json_data in executeCmd(["hubble", "observe", "--follow", "--output", "json"]):
        data = json.loads(json_data)
        print(data)


if __name__ == "__main__":
    main()
