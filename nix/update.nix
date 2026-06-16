{
  perSystem =
    { pkgs, ... }:
    {
      packages.update = pkgs.writeShellApplication {
        name = "update-pi-coding-agent";

        runtimeInputs = [
          pkgs.coreutils
          pkgs.curl
          pkgs.git
          pkgs.gnutar
          pkgs.gzip
          pkgs.jq
          pkgs.nix
          pkgs.prefetch-npm-deps
        ];

        text = ''
          tag=$(curl -fsSL https://api.github.com/repos/earendil-works/pi/releases/latest | jq -r .tag_name)
          version="''${tag#v}"
          archive_url="https://github.com/earendil-works/pi/archive/refs/tags/''${tag}.tar.gz"
          src_hash=$(nix store prefetch-file --json --unpack "$archive_url" | jq -r .hash)

          workdir=$(mktemp -d)
          trap 'rm -rf "$workdir"' EXIT
          curl -fsSL "$archive_url" | tar -xz -C "$workdir"
          src_dir="$workdir/pi-''${version}"
          npm_hash=$(prefetch-npm-deps "$src_dir/package-lock.json")

          jq -n \
            --arg version "$version" \
            --arg srcHash "$src_hash" \
            --arg npmDepsHash "$npm_hash" \
            '{version: $version, srcHash: $srcHash, npmDepsHash: $npmDepsHash}' > VERSION.json

          nix flake update
        '';
      };
    };
}
