#!/usr/bin/env python3
import json
import urllib.request
import urllib.error
import asyncio
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp import types

OLLAMA_URL = "http://192.168.1.252:11434"
DEFAULT_MODEL = "qwen2.5:14b"

app = Server("ollama")

@app.list_tools()
async def list_tools():
    return [
        types.Tool(
            name="ask_ollama",
            description=(
                "Delegate a task to the local Ollama LLM (qwen2.5:14b running on NAS). "
                "Use for: file analysis, code drafts, summarization, repetitive text tasks. "
                "Returns the model's full response."
            ),
            inputSchema={
                "type": "object",
                "properties": {
                    "prompt": {
                        "type": "string",
                        "description": "The full prompt to send to the model"
                    },
                    "model": {
                        "type": "string",
                        "description": "Model to use (default: qwen2.5:14b)",
                        "default": DEFAULT_MODEL
                    }
                },
                "required": ["prompt"]
            }
        )
    ]

@app.call_tool()
async def call_tool(name: str, arguments: dict):
    if name != "ask_ollama":
        raise ValueError(f"Unknown tool: {name}")

    prompt = arguments["prompt"]
    model = arguments.get("model", DEFAULT_MODEL)

    payload = json.dumps({
        "model": model,
        "prompt": prompt,
        "stream": False
    }).encode()

    req = urllib.request.Request(
        f"{OLLAMA_URL}/api/generate",
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST"
    )

    try:
        with urllib.request.urlopen(req, timeout=300) as r:
            result = json.loads(r.read())
        return [types.TextContent(type="text", text=result["response"])]
    except urllib.error.URLError as e:
        return [types.TextContent(type="text", text=f"Ollama unreachable: {e}")]

async def main():
    async with stdio_server() as (read_stream, write_stream):
        await app.run(read_stream, write_stream, app.create_initialization_options())

if __name__ == "__main__":
    asyncio.run(main())
