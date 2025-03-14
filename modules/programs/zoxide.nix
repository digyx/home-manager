{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.zoxide;

  cfgOptions = concatStringsSep " " cfg.options;

in {
  meta.maintainers = [ ];

  options.programs.zoxide = {
    enable = mkEnableOption "zoxide";

    package = mkOption {
      type = types.package;
      default = pkgs.zoxide;
      defaultText = literalExpression "pkgs.zoxide";
      description = ''
        Zoxide package to install.
      '';
    };

    options = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--no-cmd" ];
      description = ''
        List of options to pass to zoxide init.
      '';
    };

    enableBashIntegration =
      lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableFishIntegration =
      lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableNushellIntegration =
      lib.hm.shell.mkNushellIntegrationOption { inherit config; };

    enableZshIntegration =
      lib.hm.shell.mkZshIntegrationOption { inherit config; };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs.bash.initExtra = mkIf cfg.enableBashIntegration (mkOrder 2000 ''
      eval "$(${cfg.package}/bin/zoxide init bash ${cfgOptions})"
    '');

    programs.zsh.initExtra = mkIf cfg.enableZshIntegration ''
      eval "$(${cfg.package}/bin/zoxide init zsh ${cfgOptions})"
    '';

    programs.fish.interactiveShellInit = mkIf cfg.enableFishIntegration ''
      ${cfg.package}/bin/zoxide init fish ${cfgOptions} | source
    '';

    programs.nushell = mkIf cfg.enableNushellIntegration {
      extraEnv = ''
        let zoxide_cache = "${config.xdg.cacheHome}/zoxide"
        if not ($zoxide_cache | path exists) {
          mkdir $zoxide_cache
        }
        ${cfg.package}/bin/zoxide init nushell ${cfgOptions} |
          save --force ${config.xdg.cacheHome}/zoxide/init.nu
      '';
      extraConfig = ''
        source ${config.xdg.cacheHome}/zoxide/init.nu
      '';
    };
  };
}
