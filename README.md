# pnpm2nix

Loads `pnpm`\'s `pnpm-lock.yaml` into nix expressions.

## Example `default.nix`

```nix
with (import <nixpkgs> {});
with (import /path/to/pnpm2nix { inherit pkgs; });

mkPnpmPackage {
  src = ./.;
  # These default to src/package.json & src/pnpm-lock.yaml
  # packageJSON = ./package.json;
  # pnpmLock = ./pnpm-lock.yaml;
}
```

More comprehensive examples can be found in the [tests](./tests/).

## Managing development environments with pnpm2nix

### default.nix

```nix
with (import <nixpkgs> {});
with (import /path/to/pnpm2nix { inherit pkgs; });

mkPnpmPackage {
  src = ./.;
}
```

### shell.nix

```nix
with (import <nixpkgs> {});
with (import /path/to/pnpm2nix { inherit pkgs; });

mkShell {
  buildInputs = [
    (mkPnpmEnv (import ./default.nix))
  ];
}
```

## Caveats and known bugs

[pnpm does not currently include checksums for
tarballs](https://github.com/pnpm/pnpm/issues/1035)

Until this is fixed in `pnpm` github dependencies won\'t work
unless you opt in to impure builds.

This is currently pre-alpha software, it might eat your kittens.

## License

`pnpm2nix` is released under the terms of the MIT license.
