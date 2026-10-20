{ pkgs, ... }:
{
  programs.zed-editor.userSettings.lsp = {
    clangd.binary.path = "/usr/bin/clangd";
  };

  home.packages = with pkgs; [
    google-cloud-sdk
    uv
    pnpm
  ];
}
