from fastapi import FastAPI
from pydantic import BaseModel
from extractor import extract_graph
from chunker import extract_text_from_pdf, chunk_text
from deduplicator import merge_graphs
from ddgs import DDGS
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

class PDFRequest(BaseModel):
    filepath: str

@app.post("/extract-pdf", response_model=GraphResponse)
async def extract_pdf(request: PDFRequest):
    text = extract_text_from_pdf(request.filepath)
    chunks = chunk_text(text)
    graphs = [extract_graph(chunk) for chunk in chunks]
    merged = merge_graphs(graphs)
    return merged

class VerifyRequest(BaseModel):
    source: str
    target: str
    relationship: str

class VerifyResponse(BaseModel):
    verified: bool
    confidence: str  # "high" | "medium" | "low"
    source_urls: list[str]

@app.post("/verify", response_model=VerifyResponse)
async def verify_connection(request: VerifyRequest):
    query = f"{request.source} {request.relationship} {request.target}"
    with DDGS() as ddgs:
        results = list(ddgs.text(query, max_results=5))

    urls = [r["href"] for r in results if "href" in r]

    if len(urls) >= 3:
        confidence = "high"
        verified = True
    elif len(urls) >= 1:
        confidence = "medium"
        verified = True
    else:
        confidence = "low"
        verified = False

    return {"verified": verified, "confidence": confidence, "source_urls": urls}

if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8000)
