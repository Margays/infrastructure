from typing import List


def extract_k8s_labels(labels: list[str], allowed_labels_keys: List[str]) -> dict:
    selected_labels = {}
    for label in labels:
        if label.startswith("k8s:"):
            key, value = label.split(":", 1)[1].split("=", 1)
            if key not in allowed_labels_keys:
                continue
            selected_labels[key] = value

    return selected_labels

def extract_entity_names(labels: list[str]) -> List[str]:
    selected_labels = []
    for label in labels:
        if label.startswith("reserved:"):
            name = label.split(":", 1)[1]
            selected_labels.append(name)

    return selected_labels
