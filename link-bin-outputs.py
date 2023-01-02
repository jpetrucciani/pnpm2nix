import itertools
import argparse
import os
import os.path
import json
import sys
from typing import Dict, Tuple


argparser = argparse.ArgumentParser(
    description="Link bin outputs based on package.json contents"
)
argparser.add_argument("bin_out", type=str, help="bin output path")
argparser.add_argument("lib_out", type=str, help="lib output path")


def get_bin_attr_files(package_json: Dict[str, str | Dict]) -> Tuple:
    try:
        bins = package_json["bin"]
    except KeyError:
        return tuple()
    else:
        if isinstance(bins, str):
            return ((package_json["name"], bins),)
        if isinstance(bins, dict):
            return tuple(bins.items())


def get_directories_bin_attr_files(package_json: Dict[str, str | Dict], lib_out: str):
    try:
        bins = package_json["directories"]["bin"]
    except Exception:
        print("unable to get bin for package.json!", file=sys.stderr)
    else:
        for f in os.listdir(os.path.join(lib_out, bins)):
            yield os.path.join(lib_out, f)


def resolve_bin_outputs(bin_out: str, lib_out: str, entries):
    for entry in entries:
        yield (os.path.join(bin_out, entry[0]), os.path.join(lib_out, entry[1]))


if __name__ == "__main__":
    args = argparser.parse_args()

    with open(os.path.join(args.lib_out, "package.json"), "r", encoding="utf8") as f:
        package_json = json.load(f)

    for fout, fin in resolve_bin_outputs(
        args.bin_out,
        args.lib_out,
        itertools.chain(
            get_bin_attr_files(package_json),
            get_directories_bin_attr_files(args.lib_out, package_json),
        ),
    ):

        os.symlink(fin, fout)
        os.chmod(fout, 0o755)  # nosec

        # Print input file to stdout so we can pipe it to patchShebangs
        print(fin)
