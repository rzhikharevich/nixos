{ ... }:
{
  programs.firefox = {
    enable = true;

    profiles.default.settings = {
      "browser.newtabpage.activity-stream.showSponsored" = false;
      "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
      "browser.newtabpage.activity-stream.feeds.topsites" = false;
      "browser.newtabpage.activity-stream.feeds.section.highlights" = false;
      "browser.newtabpage.activity-stream.feeds.snippets" = false;
      "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
      "browser.newtabpage.activity-stream.showWeather" = false;

      "dom.min_background_timeout_value" = 10000;
      "beacon.enabled" = false;
      "privacy.resistFingerprinting" = true;
    };

    profiles.default.search = {
      force = true;
      default = "ddg";
      privateDefault = "ddg";
    };

    policies = {
      DisableTelemetry = true;

      ExtensionSettings."uBlock0@raymondhill.net" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
        installation_mode = "force_installed";
        private_browsing = true;
      };
      "3rdparty".Extensions."uBlock0@raymondhill.net" = {
        toOverwrite.filterLists = [
          "user-filters"
          "ublock-filters"
          "ublock-badware"
          "ublock-privacy"
          "ublock-unbreak"
          "ublock-quick-fixes"
          "easylist"
          "easyprivacy"
          "urlhaus-1"
          "plowe-0"
          "fanboy-cookiemonster"
          "fanboy-social"
          "fanboy-thirdparty_social"
        ];
        userSettings = [
          [ "showIconBadge" "false" ]
        ];
      };
    };
  };

  stylix.targets.firefox.profileNames = [ "default" ];
}
