lib: {
  mkHardenedUserService = user: appName: { usesShareDir ? false }: lib.mkMerge [
    {
      ProtectHome = "tmpfs";
      ProtectClock = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectProc = "invisible";
      ProcSubset = "pid";
      PrivateNetwork = true;
      RestrictSUIDSGID = true;
      CapabilityBoundingSet = "";
      KeyringMode = "private";
      UMask = "0077";
      # TODO: Make this more fine-grained.
      BindReadOnlyPaths = [
        "/run/user/${toString user.uid}"
        "-${user.home}/.config/${appName}"
      ];
      StateDirectory = appName;
      CacheDirectory = appName;
    }
    (lib.mkIf usesShareDir {
      BindPaths = [ "${user.home}/.local/share/${appName}" ];
    })
  ];
}
