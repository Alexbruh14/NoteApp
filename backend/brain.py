from fastapi import FastAPI
from pydantic import BaseModel
from extractor import extract_graph
import uvicorn

app = FastAPI()

class NoteRequest(BaseModel):
    text: str

class GraphResponse(BaseModel):
    nodes: list
    edges: list

@app.post("/extract", response_model=GraphResponse)
async def extract(request: NoteRequest):
    graph = extract_graph(request.text)
    return graph

if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8000)
