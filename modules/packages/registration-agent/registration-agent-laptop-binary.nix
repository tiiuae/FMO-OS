{ pkgs,
}:
pkgs.buildPackages.runCommand "registrationAgentOrig"
{
  # for `nix run`
  meta.mainProgram = "registrationAgentOrig";
} ''
  mkdir -p $out/bin
  ${pkgs.coreutils}/bin/cp -R ${./RA-binary} $out/bin/registration-agent-laptop-orig
''