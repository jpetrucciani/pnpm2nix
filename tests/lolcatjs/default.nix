{ pkgs ? (import <nixpkgs> { }) }:
with pkgs;
with (import ../../. { inherit pkgs; });
let
  package = mkPnpmPackage {

    src = fetchFromGitHub {
      owner = "robertboloc";
      repo = "lolcatjs";
      rev = "7a511b29ac73c67e796ee5d5acd26b0417435079";
      sha256 = "sha256-YLtN11byiT3jtpV2hb1iRkDlm91aReCdqZxXSfh5pak=";
    };

    packageJSON = ./package.json;
    pnpmLock = ./pnpm-lock.yaml;
  };

in
package
