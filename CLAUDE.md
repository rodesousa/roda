# Claude Instructions

## Documentation Standards

When adding documentation to code:

- **Write in English**
- **Start with a verb** (e.g., "Returns", "Lists", "Creates", "Uploads")
- **Include an example with `iex>`**

### Example

```elixir
@doc """
Lists all objects in the specified bucket.

## Example

    iex> Minio.list("roda")
    {:ok, %{body: %{contents: []}}}
"""
def list(bucket) do
  # ...
end
```
