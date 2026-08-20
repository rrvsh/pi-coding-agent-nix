{ config, ... }:
let
  inherit (config.flake.paths) root;
  versionInfo = builtins.fromJSON (builtins.readFile (root + /VERSION.json));
in
{
  perSystem =
    { pkgs, ... }:
    {
      packages.pi-coding-agent = pkgs.pi-coding-agent.overrideAttrs {
        version = versionInfo.version;

        src = pkgs.fetchFromGitHub {
          owner = "earendil-works";
          repo = "pi";
          tag = "v${versionInfo.version}";
          hash = versionInfo.srcHash;
        };

        npmDepsHash = versionInfo.npmDepsHash;

        modelData = pkgs.fetchurl {
          url = "https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-${versionInfo.version}.tgz";
          hash = versionInfo.modelDataHash;
        };
      };
    };
}
