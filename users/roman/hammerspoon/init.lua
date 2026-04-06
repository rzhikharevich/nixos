require "lgtv_init"
require "oled_mode"

my_watcher = hs.caffeinate.watcher.new(function(eventType)
    if hs.application.find("md.obsidian", true, true) == nil then
        print "Obsidian is not running, skipping."
    else
        if
            eventType == hs.caffeinate.watcher.screensDidWake or
            eventType == hs.caffeinate.watcher.systemDidWake
        then
            print "Pulling the vault."
            hs.execute("cd ~/Documents/main && GIT_SSH_COMMAND=~/.local/bin/obsidian-git-ssh git pull")
        elseif
            eventType == hs.caffeinate.watcher.screensDidSleep or
            eventType == hs.caffeinate.watcher.systemWillPowerOff
        then
            print "Pushing the vault."
            hs.execute("~/.local/bin/push-obsidian-vault")
        end
    end
end)
my_watcher:start()
