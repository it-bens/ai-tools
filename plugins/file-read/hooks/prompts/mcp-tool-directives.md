ALWAYS use the file-read MCP tool to read local text files. NEVER use Bash commands to print file contents when the MCP tool can perform the read.

## Tool (file-read)

- `read_file(file_path, offset?, limit?, max_bytes?, cwd?)` - read a local text file with line-numbered output. Use `offset` and `limit` for bounded ranges, and `cwd` to resolve a relative path against an absolute directory.

## Bash equivalents

Use `read_file` instead of file-content commands such as `cat`, `sed -n`, `head`, or `tail`. Bash remains available for shell operations that are not file-content reads.

The tool rejects likely binary files, strips a UTF-8 BOM, normalizes CRLF line endings, and applies configurable byte and token caps.
