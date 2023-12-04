from .base_rule import BaseRule


class IngressRule(BaseRule):
    def __init__(self, data: dict) -> None:
        super().__init__(data, "from", "source")
