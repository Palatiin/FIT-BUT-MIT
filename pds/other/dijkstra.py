from typing import Dict, List, Optional, Tuple


class Graph:
    nodes: List[str]
    edge_costs: Dict[Tuple[str, str], int]

    def __init__(self, nodes: List[str], edge_costs: Dict[Tuple[str, str], int]):
        self.nodes = nodes
        self.edge_costs = edge_costs

    def get_cost(self, src: str, dst: str) -> Optional[int]:
        assert src in self.nodes and dst in self.nodes, "Unknown node(s)"
        if src == dst:
            return 0
        return self.edge_costs.get((src, dst)) or self.edge_costs.get((dst, src))


def dijkstra(graph: Graph, src: str) -> Dict[str, Tuple[float, str]]:
    assert src in graph.nodes, "Unknown node"
    costs: Dict[str, Tuple[float, str]] = {node: (float("inf"), "") for node in graph.nodes}
    costs[src] = (0, "")
    visited = set()

    while len(visited) < len(graph.nodes):
        current = min(
            (node for node in graph.nodes if node not in visited),
            key=lambda node: costs[node][0],
        )

        for node in graph.nodes:
            if node == current or (cost := graph.get_cost(current, node)) is None:
                continue
            new_cost = costs[current][0] + cost
            if new_cost < costs[node][0]:
                costs[node] = (new_cost, current)
        visited.add(current)

    return costs


if __name__ == "__main__":
    g = Graph(
        ["u", "v", "w", "x", "y", "z"],
        {
            ("u", "v"): 2,
            ("u", "x"): 1,
            ("u", "w"): 5,
            ("v", "x"): 2,
            ("v", "w"): 3,
            ("x", "w"): 3,
            ("x", "y"): 1,
            ("w", "y"): 1,
            ("w", "z"): 5,
            ("y", "z"): 2,
        }
    )
    # {'u': (0, ''), 'v': (2, 'u'), 'w': (3, 'y'), 'x': (1, 'u'), 'y': (2, 'x'), 'z': (4, 'y')}
    print(dijkstra(g, "u"))
