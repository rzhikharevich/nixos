{ lib, ... }:
let
  rules = {
    nix-modules = {
      body = builtins.readFile ./rules/nix-modules.md;
      paths = [
        "**/*.nix"
        "**/flake.lock"
      ];
      description = "Apply personal Nix conventions when writing or reviewing .nix files or flake.lock, including NixOS, nix-darwin, and Home Manager modules.";
    };
    python-code-style = {
      body = builtins.readFile ./rules/python-code-style.md;
      paths = [
        "**/*.py"
        "**/*.pyi"
        "**/pyproject.toml"
        "**/requirements*.txt"
        "**/ruff.toml"
        "**/.ruff.toml"
        "**/pyrightconfig.json"
        "**/pytest.ini"
      ];
      description = "Apply personal Python conventions when writing or reviewing Python code, type stubs, or Python project and tooling configuration.";
    };
    rust-code-style = {
      body = builtins.readFile ./rules/rust-code-style.md;
      paths = [
        "**/*.rs"
        "**/Cargo.toml"
        "**/.cargo/**"
        "**/rustfmt.toml"
      ];
      description = "Apply personal Rust conventions when writing or reviewing Rust code, Cargo.toml, .cargo configuration, or rustfmt.toml.";
    };
  };

  renderRule = frontmatter: body: ''
    ---
    ${frontmatter}
    ---

    ${body}
  '';
in
{
  programs.claude-code = {
    enable = true;
    rules = lib.mapAttrs (
      _name: rule: renderRule "paths: ${builtins.toJSON rule.paths}" rule.body
    ) rules;
  };

  programs.codex = {
    enable = true;
    skills = lib.mapAttrs (
      name: rule:
      renderRule ''
        name: ${name}
        description: ${builtins.toJSON rule.description}
      '' rule.body
    ) rules;
  };
}
