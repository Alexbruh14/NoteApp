import fitz  # PyMuPDF

def extract_text_from_pdf(filepath: str) -> str:
    doc = fitz.open(filepath)
    return "\n".join(page.get_text() for page in doc)

def chunk_text(text: str, chunk_size: int = 1200, overlap: int = 150) -> list[str]:
    """
    Split text into overlapping windows to preserve context at chunk boundaries.
    overlap ensures an entity mentioned at the end of one chunk and the start
    of the next is not missed.
    """
    words = text.split()
    chunks = []
    i = 0
    while i < len(words):
        chunk = " ".join(words[i:i + chunk_size])
        chunks.append(chunk)
        i += chunk_size - overlap
    return chunks
