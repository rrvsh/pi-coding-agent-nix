{ lib, config, ... }:
let
  cfg = config.flake;
  inherit (cfg.paths) root;
  versionInfo = builtins.fromJSON (builtins.readFile (root + /VERSION.json));
in
{
  perSystem =
    { pkgs, ... }:
    {
      packages.pi-coding-agent = pkgs.buildNpmPackage {
        pname = "pi-coding-agent";
        version = versionInfo.version;

        src = pkgs.fetchFromGitHub {
          owner = "earendil-works";
          repo = "pi";
          tag = "v${versionInfo.version}";
          hash = versionInfo.srcHash;
        };

        npmDepsHash = versionInfo.npmDepsHash;
        npmWorkspace = "packages/coding-agent";
        npmRebuildFlags = [ "--ignore-scripts" ];

        nativeBuildInputs = [ pkgs.makeBinaryWrapper ];

        buildPhase = ''
          runHook preBuild
          npx tsgo -p packages/ai/tsconfig.build.json
          npx tsgo -p packages/tui/tsconfig.build.json
          npx tsgo -p packages/agent/tsconfig.build.json
          npm run build --workspace=packages/coding-agent
          runHook postBuild
        '';

        postInstall = ''
          local nm="$out/lib/node_modules/pi-monorepo/node_modules"
          for ws in @earendil-works/pi-ai:packages/ai \
                    @earendil-works/pi-agent-core:packages/agent \
                    @earendil-works/pi-tui:packages/tui; do
            IFS=: read -r pkg src <<< "$ws"
            rm "$nm/$pkg"
            cp -r "$src" "$nm/$pkg"
          done
          find "$nm" -type l -lname '*/packages/*' -delete
          find "$nm/.bin" -xtype l -delete
        ''
        + lib.optionalString pkgs.stdenvNoCC.hostPlatform.isDarwin ''
          rm -rf \
            "$nm/@anthropic-ai/sandbox-runtime/dist/vendor/seccomp" \
            "$nm/@anthropic-ai/sandbox-runtime/vendor/seccomp"
        '';

        postFixup = "wrapProgram $out/bin/pi --prefix PATH : ${
          lib.makeBinPath [
            pkgs.ripgrep
            pkgs.fd
          ]
        }";

        doInstallCheck = true;
        nativeInstallCheckInputs = [
          pkgs.writableTmpDirAsHomeHook
          pkgs.versionCheckHook
        ];
        versionCheckKeepEnvironment = [ "HOME" ];
        versionCheckProgram = "${placeholder "out"}/bin/pi";
        versionCheckProgramArg = "--version";

        meta = {
          description = "Pi coding agent";
          homepage = "https://pi.dev/";
          changelog = "https://github.com/earendil-works/pi/blob/main/packages/coding-agent/CHANGELOG.md";
          license = lib.licenses.mit;
          mainProgram = "pi";
          platforms = [
            "aarch64-darwin"
            "x86_64-linux"
          ];
        };
      };
    };
}
