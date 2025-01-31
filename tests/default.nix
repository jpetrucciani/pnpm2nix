with (import
  ((import <nixpkgs> { }).fetchFromGitHub {
    repo = "nixpkgs";
    owner = "NixOS";
    rev = "293a28df6d7ff3dec1e61e37cc4ee6e6c0fb0847";
    sha256 = "1m6smzjz3agkyc6dm83ffd8zr744m6jpjmffppvcdngk82mf3s3r";
  })
  { });
with lib.attrsets;
with lib;

let
  importTest = testFile: (import testFile { inherit pkgs; });

  pnpm2nix = ../.;

  _node = "${pkgs.nodejs-16_x}/bin/node";
  lolcatjs = importTest ./lolcatjs;
  test-sharp = importTest ./test-sharp;
  test-impure = importTest ./test-impure;
  test-or = importTest ./test-or;
  nested-dirs = importTest ./nested-dirs;
  test-peerdependencies = importTest ./test-peerdependencies;
  test-devdependencies = importTest ./test-devdependencies;
  web3 = importTest ./web3;
  issue-1 = importTest ./issues/1;
  test-falsy-script = importTest ./test-falsy-script;
  test-filedeps = importTest ./file-dependencies;
  test-circular = importTest ./test-circular;
  test-scoped = importTest ./test-scoped;
  test-recursive-link = importTest ./recursive-link/packages/a;

  mkTest = (name: test: pkgs.runCommand "${name}" { } (''
    mkdir $out
  '' + test));

in
lib.listToAttrs (map (drv: nameValuePair drv.name drv) [

  # Assert that we set correct version numbers in builds
  (mkTest "assert-version" ''
    if test $(${lolcatjs}/bin/lolcatjs --version | grep "${lolcatjs.version}" | wc -l) -ne 1; then
      echo "Incorrect version attribute! Was: ${lolcatjs.version}, got:"
      ${lolcatjs}/bin/lolcatjs --version
      exit 1
    fi
  '')

  # Make sure we build optional dependencies
  (mkTest "assert-optionaldependencies" ''
    if test $(${lolcatjs}/bin/lolcatjs --help |& grep "Unable to load" | wc -l) -ne 0; then
      echo "Optional dependency missing"
      exit 1
    fi
  '')

  # Test a natively linked overriden dependency
  (mkTest "native-overrides" "${_node} ${test-sharp}/bin/testsharp")

  # Test to imupurely build a derivation
  (mkTest "impure" "${_node} ${test-impure}/bin/testapn")

  # test with deps that have weirdly formatted ||s with extra spacing
  (mkTest "test-or" "${_node} ${test-or}/bin/test-or")

  (mkTest "python-lint" ''
    echo ${(python3.withPackages (ps: [ ps.flake8 ]))}/bin/flake8 ${pnpm2nix}/
  '')

  (mkTest "python-formatting" ''
    echo ${(python3.withPackages (ps: [ ps.black ]))}/bin/black --check ${pnpm2nix}/
  '')

  # Check if nested directory structures work properly
  (mkTest "nested-dirs" ''
    test -e ${lib.getLib nested-dirs}/node_modules/@types/node || (echo "Nested directory structure does not exist"; exit 1)
  '')

  # Check if peer dependencies are resolved
  (mkTest "peerdependencies" ''
    winstonPeer=$(readlink -f ${lib.getLib test-peerdependencies}/node_modules/winston-logstash/../winston)
    winstonRoot=$(readlink -f ${lib.getLib test-peerdependencies}/node_modules/winston)

    test "''${winstonPeer}" = "''${winstonRoot}" || (echo "Different versions in root and peer dependency resolution"; exit 1)
  '')

  # Test a "weird" package with -beta in version number spec
  (
    let
      web3Drv = lib.elemAt (lib.filter (x: x.name == "web3-1.0.0-beta.55") web3.buildInputs) 0;
    in
    mkTest "test-beta-names" ''
      test "${web3Drv.name}" = "web3-1.0.0-beta.55" || (echo "web3 name mismatch"; exit 1)
      test "${web3Drv.version}" = "1.0.0-beta.55" || (echo "web3 version mismatch"; exit 1)
    ''
  )

  # Check if checkPhase is being run correctly
  (mkTest "devdependencies" ''
    for testScript in "pretest" "test" "posttest"; do
      test -f ${lib.getLib test-devdependencies}/node_modules/test-devdependencies/build/''${testScript}
    done
  '')

  # Reported as "Infinite recursion"
  #
  # I didn't get that error while using the same code
  # Instead I got an issue accessing a peer-dependency which is not
  # in the shrinkwrap
  # This test passes using nix 2.0.4
  #
  # See github issue https://github.com/adisbladis/pnpm2nix/issues/1
  (mkTest "issue-1" ''
    echo ${issue-1}
  '')

  # Ensure package with falsy script (async-lock) builds
  (mkTest "test-falsy-scripts" ''
    echo ${test-falsy-script}
  '')

  # Test module local (file dependencies)
  (mkTest "test-filedeps" ''
    ${_node} ${test-filedeps}/bin/test-module
  '')

  # Test circular dependencies are broken up and still works
  (mkTest "test-circular" ''
    HOME=$(mktemp -d) ${_node} ${test-circular}/bin/test-circular
  '')

  # Test scoped package
  (mkTest "test-scoped" ''
    ${_node} ${test-scoped}/bin/test-scoped
  '')

  # # Test pnpm workspace recursive linked packages
  # (mkTest "test-recursive-link" ''
  #   ${test-recursive-link}/bin/test-recursive-link
  # '')
])
