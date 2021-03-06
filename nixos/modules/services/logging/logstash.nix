{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.logstash;
  pluginPath = lib.concatStringsSep ":" cfg.plugins;
  havePluginPath = lib.length cfg.plugins > 0;
  ops = lib.optionalString;
  verbosityFlag = {
    debug = "--debug";
    info  = "--verbose";
    warn  = ""; # intentionally empty
    error = "--quiet";
    fatal = "--silent";
  }."${cfg.logLevel}";

in

{
  ###### interface

  options = {

    services.logstash = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable logstash.";
      };

      package = mkOption {
        type = types.package;
        default = pkgs.logstash;
        defaultText = "pkgs.logstash";
        example = literalExample "pkgs.logstash";
        description = "Logstash package to use.";
      };

      plugins = mkOption {
        type = types.listOf types.path;
        default = [ ];
        example = literalExample "[ pkgs.logstash-contrib ]";
        description = "The paths to find other logstash plugins in.";
      };

      logLevel = mkOption {
        type = types.enum [ "debug" "info" "warn" "error" "fatal" ];
        default = "warn";
        description = "Logging verbosity level.";
      };

      filterWorkers = mkOption {
        type = types.int;
        default = 1;
        description = "The quantity of filter workers to run.";
      };

      enableWeb = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the logstash web interface.";
      };

      listenAddress = mkOption {
        type = types.str;
        default = "0.0.0.0";
        description = "Address on which to start webserver.";
      };

      port = mkOption {
        type = types.str;
        default = "9292";
        description = "Port on which to start webserver.";
      };

      inputConfig = mkOption {
        type = types.lines;
        default = ''generator { }'';
        description = "Logstash input configuration.";
        example = ''
          # Read from journal
          pipe {
            command => "''${pkgs.systemd}/bin/journalctl -f -o json"
            type => "syslog" codec => json {}
          }
        '';
      };

      filterConfig = mkOption {
        type = types.lines;
        default = "";
        description = "logstash filter configuration.";
        example = ''
          if [type] == "syslog" {
            # Keep only relevant systemd fields
            # http://www.freedesktop.org/software/systemd/man/systemd.journal-fields.html
            prune {
              whitelist_names => [
                "type", "@timestamp", "@version",
                "MESSAGE", "PRIORITY", "SYSLOG_FACILITY"
              ]
            }
          }
        '';
      };

      outputConfig = mkOption {
        type = types.lines;
        default = ''stdout { codec => rubydebug }'';
        description = "Logstash output configuration.";
        example = ''
          redis { host => ["localhost"] data_type => "list" key => "logstash" codec => json }
          elasticsearch { }
        '';
      };

    };
  };


  ###### implementation

  config = mkIf cfg.enable {
    systemd.services.logstash = with pkgs; {
      description = "Logstash Daemon";
      wantedBy = [ "multi-user.target" ];
      environment = { JAVA_HOME = jre; };
      path = [ pkgs.bash ];
      serviceConfig = {
        ExecStart =
          "${cfg.package}/bin/logstash agent " +
          "-w ${toString cfg.filterWorkers} " +
          ops havePluginPath "--pluginpath ${pluginPath} " +
          "${verbosityFlag} " +
          "-f ${writeText "logstash.conf" ''
            input {
              ${cfg.inputConfig}
            }

            filter {
              ${cfg.filterConfig}
            }

            output {
              ${cfg.outputConfig}
            }
          ''} " +
          ops cfg.enableWeb "-- web -a ${cfg.listenAddress} -p ${cfg.port}";
      };
    };
  };
}
