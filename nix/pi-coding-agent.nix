{ config, ... }:
let
  inherit (config.flake.paths) root;
  versionInfo = builtins.fromJSON (builtins.readFile (root + /VERSION.json));
in
{
  perSystem =
    { pkgs, ... }:
    let
      piSource = pkgs.fetchFromGitHub {
        owner = "earendil-works";
        repo = "pi";
        tag = "v${versionInfo.version}";
        hash = versionInfo.srcHash;
      };
    in
    {
      packages.pi-coding-agent = pkgs.pi-coding-agent.overrideAttrs {
        version = versionInfo.version;
        src = piSource;
        npmDepsHash = versionInfo.npmDepsHash;

        npmDeps = pkgs.fetchNpmDeps {
          src = piSource;
          name = "pi-coding-agent-${versionInfo.version}-npm-deps";
          hash = versionInfo.npmDepsHash;
        };

        modelData = pkgs.fetchurl {
          url = "https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-${versionInfo.version}.tgz";
          hash = versionInfo.modelDataHash;
        };

        buildPhase = ''
          runHook preBuild

          npx tsc -p packages/chord/tsconfig.build.json
          npx tsc -p packages/tui/tsconfig.build.json
          npx tsc -p packages/telemetry/tsconfig.build.json
          npx tsc -p packages/codemode/tsconfig.build.json
          npx tsc -p packages/mcp/tsconfig.build.json
          npx tsc -p packages/ai/tsconfig.build.json
          npx tsc -p packages/agent/tsconfig.build.json
          npx tsc -p packages/protocol/tsconfig.build.json
          npx tsc -p packages/client/tsconfig.build.json
          npm run build --workspace=packages/coding-agent

          runHook postBuild
        '';

        postInstall = ''
          local nm="$out/lib/node_modules/pi-monorepo/node_modules"

          for ws in @earendil-works/chord:packages/chord \
                    @earendil-works/pi-ai:packages/ai \
                    @earendil-works/pi-agent-core:packages/agent \
                    @earendil-works/pi-client:packages/client \
                    @earendil-works/pi-codemode:packages/codemode \
                    @earendil-works/pi-mcp:packages/mcp \
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
      };
    };
}
