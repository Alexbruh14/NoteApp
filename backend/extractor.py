import json
import outlines
from mlx_lm import load

MODEL_PATH = "mlx-community/Qwen3-4B-4bit"

model, tokenizer = load(MODEL_PATH)
outline_model = outlines.from_mlxlm(model, tokenizer)

GRAPH_SCHEMA = {
    "type": "object",
    "properties": {
        "nodes": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "id":    { "type": "string" },
                    "label": { "type": "string" },
                    "type":  { "type": "string", "enum": ["Person", "Concept", "Book", "Event", "Place"] }
                },
                "required": ["id", "label", "type"]
            }
        },
        "edges": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "source":       { "type": "string" },
                    "target":       { "type": "string" },
                    "relationship": { "type": "string" }
                },
                "required": ["source", "target", "relationship"]
            }
        }
    },
    "required": ["nodes", "edges"]
}

json_generator = outlines.Generator(outline_model, outlines.json_schema(GRAPH_SCHEMA))

SYSTEM_PROMPT = """
You are a knowledge graph extraction engine. Your sole job is to read the provided text and extract entities and relationships.

Rules:
- Extract only entities explicitly mentioned in the text. Do not invent or infer entities not present.
- Never create an edge where source and target are the same node.
- Assign each node a short unique ID (e.g. "n1", "n2").
- Classify each node as exactly one of: Person, Concept, Book, Event, Place.

Example (unrelated domain — do not extract these into real outputs):
Input: "Charles Darwin published On the Origin of Species in 1859, establishing the theory of natural selection."
Output: {
  "nodes": [
    {"id": "n1", "label": "Charles Darwin", "type": "Person"},
    {"id": "n2", "label": "On the Origin of Species", "type": "Book"},
    {"id": "n3", "label": "Natural Selection", "type": "Concept"}
  ],
  "edges": [
    {"source": "n1", "target": "n2", "relationship": "authored"},
    {"source": "n2", "target": "n3", "relationship": "establishes"}
  ]
}

Now extract from the following text:
"""

def extract_graph(text: str) -> dict:
    prompt = SYSTEM_PROMPT + text
    result = json_generator(prompt)
    if isinstance(result, str):
        return json.loads(result)
    return result
