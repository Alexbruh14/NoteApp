from rapidfuzz import fuzz

def deduplicate_nodes(nodes: list[dict], threshold: int = 88) -> tuple[list[dict], dict[str, str]]:
    """
    Merge near-duplicate nodes of the same type.
    Returns (canonical_nodes, id_redirect_map).
    id_redirect_map maps old IDs to canonical IDs so edges can be rewritten correctly.
    """
    canonical = []
    id_map = {}

    for node in nodes:
        matched = False
        for canon in canonical:
            if node["type"] == canon["type"]:  # only compare same-type nodes
                score = fuzz.token_sort_ratio(node["label"], canon["label"])
                if score >= threshold:
                    id_map[node["id"]] = canon["id"]
                    matched = True
                    break
        if not matched:
            canonical.append(node)
            id_map[node["id"]] = node["id"]

    return canonical, id_map

def merge_graphs(graphs: list[dict]) -> dict:
    all_nodes = [n for g in graphs for n in g["nodes"]]
    all_edges = [e for g in graphs for e in g["edges"]]

    canonical_nodes, id_map = deduplicate_nodes(all_nodes)

    # Rewrite all edge source/target IDs to canonical IDs
    merged_edges = []
    for edge in all_edges:
        src = id_map.get(edge["source"], edge["source"])
        tgt = id_map.get(edge["target"], edge["target"])
        if src != tgt:  # drop any self-loops created by deduplication
            merged_edges.append({
                "source": src,
                "target": tgt,
                "relationship": edge["relationship"]
            })

    # Deduplicate edges (same source, target, relationship)
    seen = set()
    unique_edges = []
    for e in merged_edges:
        key = (e["source"], e["target"], e["relationship"])
        if key not in seen:
            seen.add(key)
            unique_edges.append(e)

    return {"nodes": canonical_nodes, "edges": unique_edges}
