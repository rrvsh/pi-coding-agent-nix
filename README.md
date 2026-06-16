# pi-coding-agent-nix

Minimal flake exporting a `pi-coding-agent` Nix package for `aarch64-darwin` and `x86_64-linux`. We use the [nixpkgs package definition](https://github.com/NixOS/nixpkgs/blob/nixos-26.05/pkgs/by-name/pi/pi-coding-agent/package.nix) but the version and hashes are stored in ./VERSION.json so updating is easier. Any package fixes that may be made will be upstreamed if needed.
