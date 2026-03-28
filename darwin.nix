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

  environment = {
    pathsToLink = [ "/Applications" ];
    systemPackages = import ./packages.nix {
      inherit pkgs config;
      isLinux = false;
    };
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
