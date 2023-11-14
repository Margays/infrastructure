from .base_rule import BaseRule


class EgressRule(BaseRule):
    def __init__(self, data: dict) -> None:
        super().__init__(data, "to", "destination")
