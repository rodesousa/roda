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

## Frontend Standards

When building UI components:

- **Use DaisyUI components as much as possible**
- **Prefer DaisyUI utility classes over custom Tailwind**
- **Leverage DaisyUI themes for consistent styling**
- **ALWAYS use form components from `lib/roda_web/components/core_components.ex`**
  - Use `<.input>` instead of raw `<input>`, `<textarea>`, `<select>` tags
  - Never write raw HTML form elements directly
  - The core components handle styling, errors, and accessibility automatically
- **ALWAYS use `gettext/1` for all user-facing text**
  - Every string displayed to the user MUST be wrapped in `gettext("Your text here")`
  - This includes: labels, placeholders, buttons, titles, descriptions, error messages, etc.
  - Example: `<h1>{gettext("Welcome")}</h1>` instead of `<h1>Welcome</h1>`
  - Example: `placeholder={gettext("Enter your name")}` instead of `placeholder="Enter your name"`

### Common DaisyUI Components

**Buttons:**
```heex
<button class="btn btn-primary">Primary</button>
<button class="btn btn-secondary">Secondary</button>
<button class="btn btn-accent">Accent</button>
<button class="btn btn-ghost">Ghost</button>
```

**Forms:**
```heex
<!-- Use core_components.ex forms -->
<.input type="text" name="username" label="Username" placeholder="Type here" />
<.input type="email" name="email" label="Email" />
<.input type="password" name="password" label="Password" />
<.input type="select" name="role" label="Role" options={["Admin", "User"]} prompt="Choose a role" />
<.input type="textarea" name="bio" label="Bio" placeholder="Tell us about yourself" />
<.input type="checkbox" name="terms" label="I agree to the terms" />
```

**Cards:**
```heex
<div class="card bg-base-100 shadow-xl">
  <div class="card-body">
    <h2 class="card-title">Card title</h2>
    <p>Card content</p>
    <div class="card-actions justify-end">
      <button class="btn btn-primary">Action</button>
    </div>
  </div>
</div>
```

**Modals:**
```heex
<dialog id="my_modal" class="modal">
  <div class="modal-box">
    <h3 class="font-bold text-lg">Modal title</h3>
    <p class="py-4">Modal content</p>
    <div class="modal-action">
      <form method="dialog">
        <button class="btn">Close</button>
      </form>
    </div>
  </div>
</dialog>
```

**Alerts:**
```heex
<div class="alert alert-info">
  <span>Info alert</span>
</div>
<div class="alert alert-success">
  <span>Success alert</span>
</div>
<div class="alert alert-warning">
  <span>Warning alert</span>
</div>
<div class="alert alert-error">
  <span>Error alert</span>
</div>
```
