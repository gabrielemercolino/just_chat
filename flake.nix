{
  inputs = {nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";};

  outputs = inputs: let
    supportedSystems = ["x86_64-linux"];
    forEachSupportedSystem = f:
      inputs.nixpkgs.lib.genAttrs supportedSystems
      (system: f {pkgs = import inputs.nixpkgs {inherit system;};});
    commonEnv = pkgs: {
      MIX_TAILWIND_PATH = pkgs.lib.getExe pkgs.tailwindcss_4;
      MIX_ESBUILD_PATH = pkgs.lib.getExe pkgs.esbuild;
    };

    beam_pkgs = pkgs: pkgs.beam.packagesWith pkgs.beam.interpreters.erlang;
  in {
    devShells = forEachSupportedSystem ({pkgs}: {
      default = pkgs.mkShell {
        packages =
          (
            if pkgs.stdenv.isLinux
            then [pkgs.inotify-tools]
            else []
          )
          ++ [(beam_pkgs pkgs).elixir pkgs.tailwindcss_4 pkgs.esbuild];
        env = commonEnv pkgs;
      };
    });

    packages = forEachSupportedSystem ({pkgs}: rec {
      just_chat = let
        mixNixDeps = pkgs.callPackages ./deps.nix {};
        pname = "just_chat";
        version = "0.5.0";
      in
        (beam_pkgs pkgs).mixRelease {
          inherit pname version mixNixDeps;
          src = pkgs.lib.cleanSource ./.;
          env = commonEnv pkgs;

          postBuild = ''
            # As shown in
            # https://github.com/code-supply/nix-phoenix/blob/2ab9b2f63dd85d5d6a85d61bd4fc5c6d07f65643/flake-template/flake.nix#L62-L64
            ln -sfv ${mixNixDeps.heroicons} deps/heroicons

            mix do \
              loadpaths --no-deps-check, \
              assets.deploy --no-deps-check
          '';

          meta.mainProgram = "server";
        };
      default = just_chat;
    });
  };
}
