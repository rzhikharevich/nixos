{
  self,
  config,
  pkgs,
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
      };

      dock = {
        autohide = true;
        orientation = "left";
        static-only = true;
        persistent-apps = [ ];
      };

      finder = {
        AppleShowAllFiles = true;
        AppleShowAllExtensions = true;
        FXPreferredViewStyle = "Nlsv";
        ShowPathbar = true;
        ShowStatusBar = true;
      };

      trackpad = {
        Clicking = true;
        TrackpadThreeFingerDrag = true;
      };
    };
  };

  fonts.packages = with pkgs; [
    jetbrains-mono
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
    cores = 4;
    memory = 4096;
    onDemand = {
      enable = true;
      ttl = 30;
    };
  };

  nix.settings = {
    extra-substituters = [ "https://virby-nix-darwin.cachix.org" ];
    extra-trusted-public-keys = [
      "virby-nix-darwin.cachix.org-1:z9GiEZeBU5bEeoDQjyfHPMGPBaIQJOOvYOOjGMKIlLo="
    ];
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
    };
    brews = [
      "batt"
      "sleepwatcher"
    ];
    casks = [
      "ungoogled-chromium"
      "halloy"
      "hammerspoon"
      "iina"
      "obsidian"
      "secretive"
      "transmission"
    ];
  };
}
