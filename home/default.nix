{
  config,
  pkgs,
  inputs,
  ...
}:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "nick";
  home.homeDirectory = "/home/nick";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.11"; # Please update this if necessary

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # hello

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
    ".ideavimrc".source = ./dotfiles/dot-ideavimrc;
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. If you don't want to manage your shell through Home
  # Manager then you have to manually source 'hm-session-vars.sh' located at
  # either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/nick/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
    EDITOR = "nvim";
    TERMINAL = "alacritty";
    BROWSER = "brave";
    # MANPAGER is set below in programs.bat if enabled, or can be set here
    MANPAGER = "sh -c 'col -bx | bat -l man -p'";
    MANROFFOPT = "-c";

    # Path additions are better handled via home.path or programs configurations,
    # but for custom stuff:
    # PATH = "$PATH:$HOME/.config/emacs/bin"; # handled by doom-emacs usually or needs manual shellInit
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Programs
  programs.bash = {
    enable = true;
    enableCompletion = true;
    # enableViMode = true; # Setting this manually in initExtra to match existing config perfectly if needed, or use options.
    # Existing config uses 'set -o vi' and some binds.

    shellAliases = {
      cp = "cp -i";
      mv = "mv -i";
      eza = "eza --long --header --classify --group-directories-first --git --icons --color=automatic --icons=automatic";
      timestamp = "date -u \"+%Y-%m-%d-%H-%M-%S\"";
      gtss = "git add . && git commit -m \"$(date -u)\"";
      cdrr = "cd \"$(git rev-parse --show-toplevel)\"";
    };

    initExtra = ''
      # Vi keybindings
      set -o vi
      bind -m vi-command 'Control-l: clear-screen'
      bind -m vi-insert 'Control-l: clear-screen'

      # Functions from dot-bashrc
      umask 077

      # file manager (quick navigation)
      fm () {
        cd "$(command lf -print-last-dir "$@")" || return 1
      }

      # directory fuzzy finder
      ff () {
        fm "$(command fd --type directory --color never | command fzf --tiebreak=chunk,begin,length --scheme=path --preview='command ls {}' "$@")" || return 1
      }
    '';

    profileExtra = ''
      # Add Doom Emacs to PATH
      export PATH="$PATH:$XDG_CONFIG_HOME/emacs/bin"
    '';

    historyFile = "${config.xdg.stateHome}/bash_history";
  };

  programs.starship = {
    enable = true;
    # settings = builtins.fromTOML (builtins.readFile ./dotfiles/dot-config/starship.toml);
    # Or just source the file if we want to keep it exact
  };
  # Symlink starship.toml to ensure it uses the exact file content if not using settings option
  xdg.configFile."starship.toml".source = ./dotfiles/dot-config/starship.toml;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Configuration files
  xdg.configFile = {
    "alacritty/alacritty.toml".source = ./dotfiles/dot-config/alacritty/alacritty.toml;
    "bat/config".source = ./dotfiles/dot-config/bat/config;
    "lf/lfrc".source = ./dotfiles/dot-config/lf/lfrc;
    "readline/inputrc".source = ./dotfiles/dot-config/readline/inputrc;
    "ripgrep/ripgreprc".source = ./dotfiles/dot-config/ripgrep/ripgreprc;
    "wget/wgetrc".source = ./dotfiles/dot-config/wget/wgetrc;
    "zed/settings.json".source = ./dotfiles/dot-config/zed/settings.json;
    "zed/keymap.json".source = ./dotfiles/dot-config/zed/keymap.json;
    "mimeapps.list".source = ./dotfiles/dot-config/mimeapps.list;
  };

  # Environment variables for config files
  home.sessionVariables = {
    INPUTRC = "${config.xdg.configHome}/readline/inputrc";
    RIPGREP_CONFIG_PATH = "${config.xdg.configHome}/ripgrep/ripgreprc";
    WGETRC = "${config.xdg.configHome}/wget/wgetrc";
  };
}
