{ config, lib, ... }:

let
  mkLink = { source, target }: let
    name = builtins.replaceStrings ["/" "."] ["_" "_"] target;
  in {
    "symlink_${name}" = lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir -p "$(dirname "${target}")"
      ln -sfn "${source}" "${target}"
    '';
  };
in
  pairs: lib.mkMerge (map mkLink pairs)
