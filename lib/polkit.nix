lib: {
  mkPolkitAllow = user: actionIds:
    let
      conds = map (id: ''action.id == "${id}"'') actionIds;
      joined = builtins.concatStringsSep " ||\n       " conds;
    in ''
      polkit.addRule(function(action, subject) {
        if ((${joined}) &&
            subject.user == "${user}") {
          return polkit.Result.YES;
        }
      });
    '';
}
