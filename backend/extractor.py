from mlx_lm import load, generate

MODEL_PATH = "mlx-community/Qwen3-4B-Instruct-4bit"

model, tokenizer = load(MODEL_PATH)

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
