---
paths:
  - "**/.rs"
  - "**/Cargo.toml"
  - "**/.cargo/**"
  - "**/rustfmt.toml"
---

# Rust Code Style

Opinionated conventions for writing clear, fast, idiomatic Rust.

## Core Philosophy

Show, don't tell. Code should be self-describing through precise names for types,
functions, and variables. Comments exist for genuinely tricky logic and concise
interface documentation — not for restating what the code already says.

## Style Rules

### Naming and Clarity
- Use precise, descriptive names. A reader should understand intent without
  cross-referencing other code.
- Prefer qualified paths (`module::Type`) over bare imports for ambiguous type names.
  Only import names that are unambiguous and used frequently enough that qualifying
  them would bloat the code.

### DRY and Abstraction
- Don't repeat yourself. Extract shared logic into reusable functions, traits,
  or modules.
- Avoid unnecessary dependencies. If rolling your own is straightforward and doesn't
  balloon the codebase, prefer that over pulling in a crate.

### Safety
- `unsafe` is a last resort. If unavoidable, wrap it in a safe abstraction and
  annotate with `// SAFETY: <reason>`.

### Performance
- Avoid unnecessary allocations. Prefer zero-copy and borrowed approaches when
  a simple alternative exists.
- Avoid interior mutability (`Cell`, `RefCell`, `Mutex`) when the framework already
  provides a mutable slot. Reach for `Cell`/`RefCell` only when no owned-mutability
  path exists.

### Testing
- Only add tests for code that could genuinely break. Don't test trivial or
  self-evident logic.

### API Design
- Follow the principle of least surprise. APIs, flags, and configuration should
  behave the way a reasonable user would expect — no silent gotchas.

### Repository Hygiene
- Keep binary and generated artifacts out of version control. Provide on-demand
  generation instead.

## Error Handling

Use `thiserror` + `anyhow` as a two-tier strategy:

- **`thiserror`** — for domain/subsystem errors where callers need to match on
  variants and handle them differently. Define concrete error enums with
  `#[derive(thiserror::Error)]`.
- **`anyhow::Result`** — for application-level and propagation-only paths where
  the specific error type doesn't matter, just the context and the message.
- Add context with `.context()` / `.with_context()` when propagating through `?`
  so failures are easy to trace back to their origin.

**Example:**

```rust
// Domain error — callers can match variants
#[derive(Debug, thiserror::Error)]
enum TileError {
    #[error("tile {id} not found")]
    NotFound { id: u32 },
    #[error("tile dimensions {w}x{h} exceed maximum")]
    TooLarge { w: u32, h: u32 },
}

// Application-level propagation — just context + message
fn load_map(path: &Path) -> anyhow::Result<Map> {
    let data = std::fs::read(path)
        .with_context(|| format!("failed to read map file {}", path.display()))?;
    parse_map(&data).context("failed to parse map data")
}
```

## Pre-Commit Checklist

Before committing Rust code, always run:
```sh
cargo fmt     # format
cargo clippy  # lint
cargo test    # verify nothing is broken
```
