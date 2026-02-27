lib: {
  mkHardenedUserService = user: appName: {
    ProtectHome = "tmpfs";
    # TODO: Make this more fine-grained.
    BindReadOnlyPaths = [
      "/run/user/${toString user.uid}"
      "-${user.home}/.config/${appName}"
    ];
    BindPaths = [ "${user.home}/.local/share/${appName}" ];
    StateDirectory = appName;
    CacheDirectory = appName;
  };
}
