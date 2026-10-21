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

  programs.gpg = {
    enable = true;
  };

  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry_mac;
  };
}
