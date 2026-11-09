# Python Code Style

Opinionated conventions for writing clear, efficient, idiomatic Python.

## Core Philosophy

Show, don't tell. Code should be self-describing through precise names for types,
functions, and variables. Comments and docstrings explain tricky logic and
interface contracts, rather than restating what the code already says.

## Style Rules

### Naming and Clarity
- Use precise, descriptive names. A reader should understand intent without
  cross-referencing other code.
- Prefer qualified names (`module.Type`) for ambiguous types and functions.
  Import names directly when they are unambiguous and used frequently enough
  that qualifying them would bloat the code. Avoid wildcard imports.

### DRY and Abstraction
- Don't repeat yourself. Extract shared logic into reusable functions, classes,
  or modules.
- Avoid unnecessary dependencies. Prefer the standard library when it solves
  the problem clearly without ballooning the codebase.
- Prefer simple functions and data structures. Introduce classes when they
  encapsulate meaningful state or behavior.

### Safety and Types
- Use precise type hints for function interfaces and structured data. Avoid
  using `Any`, unchecked casts, or blanket type ignores to hide type errors.
- Validate external data at the boundary; type hints do not perform runtime
  validation.
- Use `with` / `async with` for resources that need deterministic cleanup.
- Avoid mutable default arguments and hidden shared mutable state.

### Performance
- Avoid unnecessary copies and intermediate containers. Use iterators or
  generators when results can be consumed incrementally.
- Keep mutation local and explicit. Avoid introducing shared state or
  synchronization when ordinary local variables suffice.

### Testing
- Only add tests for code that could genuinely break. Don't test trivial or
  self-evident logic.

### API Design
- Follow the principle of least surprise. APIs, flags, and configuration should
  behave the way a reasonable user would expect — no silent gotchas.

### Repository Hygiene
- Keep virtual environments, bytecode caches, build outputs, and generated
  artifacts out of version control. Provide on-demand generation instead.

## Error Handling

- Use built-in exceptions when their meaning fits. Define focused domain
  exceptions when callers need to distinguish failures programmatically.
- Let exceptions propagate unless a caller can recover, add useful context,
  or translate the failure at an API boundary. Keep `try` blocks narrow and
  catch specific exception types.
- Preserve the cause with `raise ... from exc` when translating an exception.
  Use bare `raise` when re-raising the same exception.
- Include relevant values or operation details in error messages so failures
  are easy to trace back to their origin.
- Don't silently swallow errors or replace failures with success-shaped
  defaults.

**Example:**

```python
class ConfigError(ValueError):
    """A configuration value is invalid."""


def parse_count(value: str) -> int:
    try:
        return int(value)
    except ValueError as exc:
        raise ConfigError(f"invalid item count {value!r}") from exc
```

## Pre-Commit Checklist

Before committing Python changes, run the project's configured formatter, linter,
type checker, and relevant tests. Use its existing environment and commands, and
follow its supported Python versions.
