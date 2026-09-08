{ config, ... }:
let
  inherit (config.flake.paths) root;
  versionInfo = builtins.fromJSON (builtins.readFile (root + /VERSION.json));
in
{
  perSystem =
    { pkgs, ... }:
    {
      packages.pi-coding-agent = pkgs.pi-coding-agent.overrideAttrs (finalAttrs: {
        version = versionInfo.version;

        src = pkgs.fetchFromGitHub {
          owner = "earendil-works";
          repo = "pi";
          tag = "v${versionInfo.version}";
          hash = versionInfo.srcHash;
        };

        npmDepsHash = versionInfo.npmDepsHash;

        npmDeps = pkgs.fetchNpmDeps {
          src = finalAttrs.src;
          name = "pi-coding-agent-${versionInfo.version}-npm-deps";
          hash = versionInfo.npmDepsHash;
        };

        modelData = pkgs.fetchurl {
          url = "https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-${versionInfo.version}.tgz";
          hash = versionInfo.modelDataHash;
        };

        buildPhase = ''
          runHook preBuild

          npx tsgo -p packages/chord/tsconfig.build.json
          npx tsgo -p packages/tui/tsconfig.build.json
          npx tsgo -p packages/telemetry/tsconfig.build.json
          npx tsgo -p packages/ai/tsconfig.build.json
          npx tsgo -p packages/agent/tsconfig.build.json
          npx tsgo -p packages/protocol/tsconfig.build.json
          npx tsgo -p packages/client/tsconfig.build.json
          npm run build --workspace=packages/coding-agent

          runHook postBuild
        '';

        postInstall = ''
          local nm="$out/lib/node_modules/pi-monorepo/node_modules"

          for ws in @earendil-works/chord:packages/chord \
                    @earendil-works/pi-ai:packages/ai \
                    @earendil-works/pi-agent-core:packages/agent \
                    @earendil-works/pi-client:packages/client \
                    @earendil-works/pi-protocol:packages/protocol \
                    @earendil-works/pi-telemetry:packages/telemetry \
                    @earendil-works/pi-tui:packages/tui; do
            IFS=: read -r pkg src <<< "$ws"
            rm "$nm/$pkg"
            cp -r "$src" "$nm/$pkg"
          done

          find "$nm" -type l -lname '*/packages/*' -delete
          find "$nm/.bin" -xtype l -delete
        '';
      });
    };
}
