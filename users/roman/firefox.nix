{ config, ... }:
{
  programs.firefox = {
    enable = true;
    configPath = "${config.xdg.configHome}/mozilla/firefox";

    profiles.default = {
      settings = {
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        "browser.newtabpage.activity-stream.feeds.topsites" = false;
        "browser.newtabpage.activity-stream.feeds.section.highlights" = false;
        "browser.newtabpage.activity-stream.feeds.snippets" = false;
        "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
        "browser.newtabpage.activity-stream.showWeather" = false;

        "widget.use-xdg-desktop-portal.file-picker" = 1;

        "dom.min_background_timeout_value" = 10000;
        "beacon.enabled" = false;
        "privacy.resistFingerprinting" = true;

        "extensions.pocket.enabled" = false;
        "extensions.htmlaboutaddons.recommendations.enabled" = false;
        "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false;
        "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false;
        "browser.urlbar.suggest.linkpreview" = false;
        "browser.urlbar.suggest.quicksuggest.sponsored" = false;
        "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
        "browser.urlbar.quicksuggest.enabled" = false;
        "browser.urlbar.quicksuggest.dataCollection.enabled" = false;
        "browser.tabs.groups.smart.enabled" = false;
        "browser.ml.enable" = false;
      };

      extensions.force = true;

      search = {
        force = true;
        default = "ddg";
        privateDefault = "ddg";
      };
    };

    policies = {
      DisableTelemetry = true;
      DisableFirefoxAccounts = true;

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
          [
            "showIconBadge"
            "false"
          ]
        ];
      };
    };
  };

  stylix.targets.firefox = {
    profileNames = [ "default" ];
    colorTheme.enable = true;
  };
}
