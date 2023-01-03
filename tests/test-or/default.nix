{ pkgs ? (import <nixpkgs> { }) }:
with (import ../../. { inherit pkgs; });
let
  package = mkPnpmPackage {

    src = lib.cleanSource ./.;
    packageJSON = ./package.json;
    pnpmLock = ./pnpm-lock.yaml;
  };

in
package
