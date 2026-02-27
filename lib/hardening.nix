lib: {
  mkUserHardeningDefaults = user: {
    ProtectHome = "tmpfs";
    # TODO: Make this more fine-grained.
    BindReadOnlyPaths = [ "/run/user/${toString user.uid}" ];
  };
  mkAllowUserLocalState = user: appName: {
    BindReadOnlyPaths = [ "-${user.home}/.config/${appName}" ];
    BindPaths = [
      "-${user.home}/.local/share/${appName}"
      "-${user.home}/.local/state/${appName}"
    ];
  };
}
