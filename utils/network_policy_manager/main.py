import os
import sys
file_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(file_dir)

import subprocess
import json
from pathlib import Path
from typing import List, Iterator
from network_policy_manager.network_policy.rule import NetworkPolicyRule
from network_policy_manager.network_policy import NetworkPolicy
from network_policy_manager.network_policy.exceptions import UnknownSelectorError, UnknownRuleTypeError


class NetworkPolicyManager:
    def __init__(self):
        self._rules: Dict[int, NetworkPolicyRule] = {}
        self._network_policies: List[NetworkPolicy] = []

    def parse_flow(self, data: dict) -> None:
        flow = data["flow"]
        if flow["verdict"] == "TRACED?":
            return

        rule = NetworkPolicyRule()
        try:
            traffic_direction = flow["traffic_direction"]
        except Exception:
            if flow["sock_xlate_point"] in [
                    "SOCK_XLATE_POINT_POST_DIRECTION_FWD",
                    "SOCK_XLATE_POINT_PRE_DIRECTION_REV",
                    "SOCK_XLATE_POINT_POST_DIRECTION_REV",
                    "SOCK_XLATE_POINT_PRE_DIRECTION_FWD",
                ]:
                return
            print(data)
            return

        try:
            if traffic_direction == "EGRESS":
                rule.set_selector(flow["source"])
                rule.add_egress(flow)
            else:
                rule.set_selector(flow["destination"])
                rule.add_ingress(flow)
        except (UnknownSelectorError, UnknownRuleTypeError):
            return
        
        if rule.identity() in self._rules:
            self._rules[rule.identity()] += rule
        else:
            self._rules[rule.identity()] = rule

    def to_dict(self) -> Iterator[dict]:
        for _, rule in self._rules.items():
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
    data = []
    with open(Path(__file__).parent.parent.parent.joinpath("all.json"), "r") as stream:
        for line in stream:
            data.append(json.loads(line))

    manager = NetworkPolicyManager()
    for flow in data:
        manager.parse_flow(flow)

    for item in manager.to_dict():
        print(json.dumps(item))

    return

    for json_data in executeCmd(["hubble", "observe", "--follow", "--output", "json"]):
        data = json.loads(json_data)
        manager.parse_flow(data)

if __name__ == "__main__":
    main()
