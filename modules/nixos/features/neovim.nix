{ ... }:

{
  # Preserve discovery of runtime files contributed by other system packages.
  environment.pathsToLink = [ "/share/nvim" ];
  environment.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
