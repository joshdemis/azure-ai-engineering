import os
from fastapi import FastAPI

app = FastAPI(title="AI-200 Retrieval API")
VERSION = os.getenv("APP_VERSION", "0.2.0")

@app.get("/health")
def health():
    return {"status": "ok", "version": VERSION}

@app.get("/search")
def search(q: str):
    # todo: week6
    return {"query": q, "results": [], "backend": "none-yet"}