from fastapi import FastAPI, Request
import httpx

# Ollama 地址
OLLAMA_BASE = "http://localhost:11434"
# embedding 模型
OLLAMA_MODEL = "qwen3-embedding:latest"

app = FastAPI()


def _to_text_list(body: dict) -> list[str]:
    """
    Open WebUI/客户端可能会传 input 或 prompt，且可能是 str 或 list[str]
    这里统一变成 list[str]
    """
    if "input" in body:
        x = body["input"]
    elif "prompt" in body:
        x = body["prompt"]
    else:
        x = ""

    if isinstance(x, list):
        return [str(i) for i in x]
    return [str(x)]


@app.post("/v1/embeddings")
async def embeddings(req: Request):
    body = await req.json()
    texts = _to_text_list(body)

    vectors = []
    async with httpx.AsyncClient(timeout=120) as client:
        for t in texts:
            # Ollama /api/embed 只认 input
            r = await client.post(
                f"{OLLAMA_BASE}/api/embed",
                json={"model": OLLAMA_MODEL, "input": t},
            )
            r.raise_for_status()
            data = r.json()

            # 兼容不同返回格式
            vec = data.get("embedding")
            if vec is None:
                embs = data.get("embeddings")
                if isinstance(embs, list) and len(embs) > 0:
                    vec = embs[0]

            if vec is None:
                raise RuntimeError(f"Unexpected Ollama response: {data}")

            vectors.append(vec)

    # 返回 OpenAI embeddings 兼容格式
    return {
        "object": "list",
        "data": [
            {"object": "embedding", "index": i, "embedding": v}
            for i, v in enumerate(vectors)
        ],
        "model": body.get("model", OLLAMA_MODEL),
        "usage": {"prompt_tokens": 0, "total_tokens": 0},
    }
