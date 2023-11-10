import os
import sys
file_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(file_dir)

import subprocess
import json
from typing import List, Iterator
from network_policy_manager.network_policy.rule import NetworkPolicyRule
from network_policy_manager.network_policy import NetworkPolicy


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
