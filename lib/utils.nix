lib:
let
  isMatching =
    matcher: value:
    if builtins.isAttrs matcher then lib.attrsets.matchAttrs matcher value else matcher == value;
  getIfNotNull = value: if value == null then throw "no matching patterns" else value;
  matchDefault =
    value: cases:
    {
      default ? null,
    }:
    getIfNotNull
    <| builtins.elemAt (lib.lists.findFirst (cs: isMatching (builtins.elemAt cs 0) value) [
      null
      default
    ] cases) 1;
in
{
  rzMatchDefault = matchDefault;
  rzMatch = value: cases: matchDefault value cases { };
}
