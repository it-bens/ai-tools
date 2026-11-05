#!/usr/bin/env python3
"""Minimal MCP stdio server that acts as the permission host of a `claude -p` run.

Claude Code offers AskUserQuestion in print mode only when a permission host is
present. Pass this server with --mcp-config and its tool with
--permission-prompt-tool mcp__permission_host__approve.

Every permission request is appended as one JSON line to the log file given as
the only argument; the file is created at startup. The tool allows every call. For AskUserQuestion it answers
each question with the label of its first option, so the call completes.

Python standard library only.
"""

import json
import sys

SERVER_NAME = "permission_host"
TOOL_NAME = "approve"


def fail(message):
    sys.stderr.write(f"permission_host: {message}\n")
    sys.exit(1)


def decide(arguments):
    tool_name = arguments["tool_name"]
    tool_input = arguments["input"]
    if tool_name != "AskUserQuestion":
        return {"behavior": "allow", "updatedInput": tool_input}
    answers = {
        question["question"]: question["options"][0]["label"]
        for question in tool_input["questions"]
    }
    return {
        "behavior": "allow",
        "updatedInput": {"questions": tool_input["questions"], "answers": answers},
    }


def handle(request, log_path):
    method = request.get("method")
    if method == "initialize":
        return {
            "protocolVersion": request["params"]["protocolVersion"],
            "capabilities": {"tools": {}},
            "serverInfo": {"name": SERVER_NAME, "version": "1.0.0"},
        }
    if method == "ping":
        return {}
    if method == "tools/list":
        return {
            "tools": [
                {
                    "name": TOOL_NAME,
                    "description": "Answers Claude Code permission prompts for a test run.",
                    "inputSchema": {
                        "type": "object",
                        "properties": {
                            "tool_name": {"type": "string"},
                            "input": {"type": "object"},
                            "tool_use_id": {"type": "string"},
                        },
                        "required": ["tool_name", "input"],
                    },
                }
            ]
        }
    if method == "tools/call":
        params = request["params"]
        if params["name"] != TOOL_NAME:
            fail(f"unexpected tool call: {params['name']}")
        arguments = params["arguments"]
        decision = decide(arguments)
        with open(log_path, "a", encoding="utf-8") as log:
            log.write(json.dumps({"request": arguments, "decision": decision}) + "\n")
        return {"content": [{"type": "text", "text": json.dumps(decision)}]}
    return None


def main():
    if len(sys.argv) != 2:
        fail("usage: permission_host.py <log file>")
    log_path = sys.argv[1]
    # Create the log at startup: an existing empty log proves the host ran and saw no request.
    open(log_path, "a", encoding="utf-8").close()
    for line in sys.stdin:
        if not line.strip():
            continue
        request = json.loads(line)
        if "id" not in request:
            continue  # notifications need no response
        result = handle(request, log_path)
        if result is None:
            response = {
                "jsonrpc": "2.0",
                "id": request["id"],
                "error": {"code": -32601, "message": f"method not found: {request.get('method')}"},
            }
        else:
            response = {"jsonrpc": "2.0", "id": request["id"], "result": result}
        sys.stdout.write(json.dumps(response) + "\n")
        sys.stdout.flush()


if __name__ == "__main__":
    main()
