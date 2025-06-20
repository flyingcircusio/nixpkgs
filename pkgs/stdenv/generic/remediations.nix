{ lib }:
let
  inherit (builtins)
    filter
    elem
    ;

  inherit (lib)
    getName
    concatStrings
    concatStringsSep
    ;

  getNameWithVersion =
    attrs: attrs.name or "${attrs.pname or "«name-missing»"}-${attrs.version or "«version-missing»"}";

  remediation_env_var =
    allow_attr:
    {
      Unfree = "NIXPKGS_ALLOW_UNFREE";
      UnsupportedSystem = "NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM";
      NonSource = "NIXPKGS_ALLOW_NONSOURCE";
    }
    .${allow_attr};
  remediation_phrase =
    allow_attr:
    {
      Unfree = "unfree packages";
      UnsupportedSystem = "packages that are unsupported for this system";
      NonSource = "packages not built from source";
    }
    .${allow_attr};
  # flakeNote will be printed in the remediation messages below.
  flakeNote = "
   Note: When using `nix shell`, `nix build`, `nix develop`, etc with a flake,
         then pass `--impure` in order to allow use of environment variables.
    ";

in
{
  inherit getNameWithVersion;
  remediateOutputsToInstall =
    attrs:
    let
      expectedOutputs =
        (
          attrs:
          let
            expectedOutputs = attrs.meta.outputsToInstall or [ ];
            actualOutputs = attrs.outputs or [ "out" ];
            missingOutputs = filter (output: !elem output actualOutputs) expectedOutputs;
          in
          ''
            The package ${getNameWithVersion attrs} has set meta.outputsToInstall to: ${concatStringsSep ", " expectedOutputs}

            however ${getNameWithVersion attrs} only has the outputs: ${concatStringsSep ", " actualOutputs}

            and is missing the following outputs:

            ${concatStrings (map (output: "  - ${output}\n") missingOutputs)}
          ''
        ).meta.outputsToInstall or [ ];
      actualOutputs = attrs.outputs or [ "out" ];
      missingOutputs = filter (output: !elem output actualOutputs) expectedOutputs;
    in
    ''
      The package ${getNameWithVersion attrs} has set meta.outputsToInstall to: ${concatStringsSep ", " expectedOutputs}

      however ${getNameWithVersion attrs} only has the outputs: ${concatStringsSep ", " actualOutputs}

      and is missing the following outputs:

      ${concatStrings (map (output: "  - ${output}\n") missingOutputs)}
    '';

  remediate_predicate = predicateConfigAttr: attrs: ''

    Alternatively you can configure a predicate to allow specific packages:
      { nixpkgs.config.${predicateConfigAttr} = pkg: builtins.elem (lib.getName pkg) [
          "${getName attrs}"
        ];
      }
  '';
  remediate_allowlist = allow_attr: rebuild_amendment: ''
    a) To temporarily allow ${remediation_phrase allow_attr}, you can use an environment variable
       for a single invocation of the nix tools.

         $ export ${remediation_env_var allow_attr}=1
         ${flakeNote}
    b) For `nixos-rebuild` you can set
      { nixpkgs.config.allow${allow_attr} = true; }
    in configuration.nix to override this.
    ${rebuild_amendment}
    c) For `nix-env`, `nix-build`, `nix-shell` or any other Nix command you can add
      { allow${allow_attr} = true; }
    to ~/.config/nixpkgs/config.nix.
  '';
  remediate_insecure =
    attrs:
    ''

      Known issues:
    ''
    + (concatStrings (map (issue: " - ${issue}\n") attrs.meta.knownVulnerabilities))
    + ''

      You can install it anyway by allowing this package, using one of the
      following methods:

      a) if this happened while building a NixOS config, e.g. by
         running `fc-manage switch`, you can add ‘${getNameWithVersion attrs}’
         to `flyingcircus.permittedInsecurePackages`, like this:

           {
             flyingcircus.permittedInsecurePackages = [
               "${getNameWithVersion attrs}"
             ];
           }

      b) when using nixpkgs directly, you can set `permittedInsecurePackages` like this:

           {
             config.permittedInsecurePackages = [
               "${getNameWithVersion attrs}"
             ];
           }

         This is relevant when importing a channel tarball from Hydra
         or the machine's nixpkgs (i.e. `import <nixpkgs>`), e.g. in a user env.

      c) temporarily allowing any insecure package can be enabled via

           $ export NIXPKGS_ALLOW_INSECURE=1

         Please note that this only advisable for interactive use, e.g. for `nix-shell`
         and should NOT be used for NixOS configurations or user envs.
    '';
  remediate_unfree = attrs: ''
    You can install it anyway by allowing this package, using one of the
    following methods:

    a) if this happened while building a NixOS config, e.g. by
       running `fc-manage switch`, you can add ‘${lib.getName attrs}’
       to `flyingcircus.allowedUnfreePackageNames`, like this:

         {
           flyingcircus.allowedUnfreePackageNames = [
             "${lib.getName attrs}"
           ];
         }

    b) when using our channel tarballs (e.g. a tarball from the FCIO Hydra or
       `import <fc> {}`), you can the following declarations to the `import` argument:

         {
           config.allowedUnfreePackageNames = [
             "${lib.getName attrs}"
           ];
         }

    c) when using nixpkgs directly (e.g. via `import <nixpkgs> {}`), you can add
       the following declarations to the `import` argument:

         {
           # to allow ANY unfree package
           config.allowUnfree = true;

           # to allow ONLY THIS unfree package
           config.allowUnfreePredicate = pkg: builtins.elem (pkg.pname or (builtins.parseDrvName pkg).name) [
             "${lib.getName attrs}"
           ];
         }

    d) temporarily allowing any unfree package can be enabled via

         $ export NIXPKGS_ALLOW_UNFREE=1

       Please note that this only advisable for interactive use, e.g. for `nix-shell`
       and should NOT be used for NixOS configurations or user envs.
  '';

}
