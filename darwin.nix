{
  self,
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./users/roman/darwin.nix
  ];

  system = {
    primaryUser = "roman";
    configurationRevision = self.rev or self.dirtyRev or null;

    defaults = {
      NSGlobalDomain = {
        AppleICUForce24HourTime = true;
        AppleMeasurementUnits = "Centimeters";
        AppleMetricUnits = 1;
        AppleTemperatureUnit = "Celsius";
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
        NSDocumentSaveNewDocumentsToCloud = false;
        NSNavPanelExpandedStateForSaveMode = true;
      };

      dock = {
        autohide = true;
        orientation = "left";
        scroll-to-open = true;
        static-only = true;
        persistent-apps = [ ];
        persistent-others = [
          {
            folder = {
              arrangement = "date-added";
              displayas = "folder";
              path = "${config.users.users.${config.system.primaryUser}.home}/Downloads";
              showas = "grid";
            };
          }
        ];
      };

      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = false;
        FXDefaultSearchScope = "SCcf";
        FXEnableExtensionChangeWarning = false;
        FXPreferredViewStyle = "Nlsv";
        ShowPathbar = true;
        ShowStatusBar = true;
        _FXShowPosixPathInTitle = true;
      };

      CustomUserPreferences."org.hammerspoon.Hammerspoon".MJConfigFile = "~/.config/hammerspoon/init.lua";

      trackpad = {
        Clicking = true;
        TrackpadFourFingerVertSwipeGesture = 2;
        TrackpadRightClick = true;
        TrackpadThreeFingerDrag = true;
      };
    };
  };

  fonts.packages = with pkgs; [
    jetbrains-mono
    merriweather-sans
    nerd-fonts.meslo-lg
  ];

  environment = {
    pathsToLink = [ "/Applications" ];
    systemPackages = import ./packages.nix {
      inherit pkgs config;
      isLinux = false;
    };
  };

  services.virby = {
    enable = true;
    onDemand = {
      enable = true;
      ttl = 30;
    };
  }
  // lib.rzMatch config.networking.hostName [
    [
      "secretive"
      {
        cores = 8;
        memory = 8192;
      }
    ]
    [
      "tenserise"
      {
        cores = 12;
        memory = 32768;
      }
    ]
  ];

  nix.settings = {
    #    extra-substituters = [ "https://virby-nix-darwin.cachix.org" ];
    #    extra-trusted-public-keys = [
    #      "virby-nix-darwin.cachix.org-1:z9GiEZeBU5bEeoDQjyfHPMGPBaIQJOOvYOOjGMKIlLo="
    #    ];
  };

  nix.gc = {
    automatic = true;
    interval = {
      Weekday = 0;
      Hour = 0;
      Minute = 0;
    };
  };
  nix.optimise.automatic = true;

  security.pam.services.sudo_local.touchIdAuth = true;
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "zap";
      extraFlags = [ "--force-cleanup" ];
    };
    taps = [
      {
        name = "xykong/tap";
        trusted = true;
      }
    ];
    brews = [
      "lume"
      "sleepwatcher"
    ];
    casks = [
      "discord"
      "google-chrome"
      "flux-markdown"
      "ungoogled-chromium"
      "halloy"
      "hammerspoon"
      "iina"
      "iterm2"
      "linearmouse"
      "lm-studio"
      "microsoft-teams"
      "obsidian"
      "openzfs"
      "secretive"
      "tailscale-app"
      "transmission"
      "visual-studio-code"
      "zoom"
    ];
  };
}
