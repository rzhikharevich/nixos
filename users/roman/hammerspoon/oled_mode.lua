-- Activates when a monitor with a given name is connected:
--   - Sets the wallpaper on that screen to solid black
--   - Enables auto-hiding of the menu bar
--   - Enables dark mode
--   - Starts random yabai padding to alleviate the OLED burn-in risks a bit.
-- Reverts changes when the monitor is disconnected.

local yabai_padding = require("yabai_padding")

local oled_monitor_name = "LG TV"
local black_wallpaper_path = os.getenv("HOME") .. "/.config/hammerspoon/black.png"
local oled_debug = true

local oled_mode_active = false
local saved_wallpaper = nil
local saved_menubar_autohide = false

local function log(msg)
    if oled_debug then
        print("[OLED mode] " .. msg)
    end
end

local function create_black_wallpaper()
    if hs.fs.attributes(black_wallpaper_path) then
        log("Black wallpaper already exists at " .. black_wallpaper_path)
        return
    end

    log("Creating black wallpaper at " .. black_wallpaper_path)
    local canvas = hs.canvas.new({ x = 0, y = 0, w = 16, h = 16 })
    canvas:appendElements({
        type = "rectangle",
        fillColor = { red = 0, green = 0, blue = 0, alpha = 1 },
        action = "fill",
    })
    local img = canvas:imageFromCanvas()
    canvas:delete()

    if img then
        img:saveToFile(black_wallpaper_path)
        log("Black wallpaper created.")
    else
        log("ERROR: Failed to create black wallpaper image.")
    end
end

local function find_oled_screen()
    return hs.screen.find(oled_monitor_name)
end

local function get_menubar_autohide()
    local ok, result = hs.osascript.applescript(
        'tell application "System Events" to tell dock preferences to get autohide menu bar'
    )
    if ok then
        return result == true
    end
    log("WARNING: Failed to read menu bar auto-hide via osascript")
    return false
end

local function set_menubar_autohide(enabled)
    local val = enabled and "true" or "false"
    log("Setting menu bar auto-hide to " .. val)
    hs.osascript.applescript(
        'tell application "System Events" to tell dock preferences to set autohide menu bar to ' .. val
    )
end

local function set_dark_mode(enabled)
    local arg = enabled and "on" or "off"
    local bin = "@darwin_darkmode@/bin/darwin_darkmode"
    hs.task.new(bin, function(code, stdout, stderr)
        if code == 0 then
            print("darwin_darkmode " .. arg .. ": ok")
        else
            print("darwin_darkmode " .. arg .. ": exited " .. code .. " — " .. (stderr or ""))
        end
    end, { arg }):start()
end

local function enable_oled_mode(screen)
    if oled_mode_active then
        log("Already active, skipping enable.")
        return
    end

    log("Enabling OLED mode for screen: " .. screen:name())

    yabai_padding.start()

    saved_wallpaper = screen:desktopImageURL()
    log("Saved wallpaper: " .. (saved_wallpaper or "<nil>"))

    saved_menubar_autohide = get_menubar_autohide()
    log("Saved menu bar auto-hide: " .. tostring(saved_menubar_autohide))

    local black_url = "file://" .. black_wallpaper_path
    screen:desktopImageURL(black_url)
    log("Wallpaper set to black.")

    if not saved_menubar_autohide then
        set_menubar_autohide(true)
    else
        log("Menu bar auto-hide was already enabled.")
    end

    set_dark_mode(true)

    oled_mode_active = true
    log("OLED mode enabled.")
end

local function disable_oled_mode()
    if not oled_mode_active then
        log("Already inactive, skipping disable.")
        return
    end

    log("Disabling OLED mode.")

    yabai_padding.stop()

    set_menubar_autohide(false)
    set_dark_mode(false)

    local screen = find_oled_screen()
    if screen and saved_wallpaper then
        log("OLED screen still present — restoring wallpaper: " .. saved_wallpaper)
        screen:desktopImageURL(saved_wallpaper)
    else
        log("OLED screen disconnected; wallpaper will be restored by macOS next time.")
    end

    saved_wallpaper = nil
    oled_mode_active = false
    log("OLED mode disabled.")
end

local function on_screen_change()
    local screen = find_oled_screen()

    if screen and not oled_mode_active then
        log("OLED monitor detected.")
        enable_oled_mode(screen)
    elseif not screen and oled_mode_active then
        log("OLED monitor disconnected.")
        disable_oled_mode()
    end
end

create_black_wallpaper()

oled_screen_watcher = hs.screen.watcher.new(on_screen_change)
oled_screen_watcher:start()

on_screen_change()

hs.caffeinate.watcher.new(function(event_type)
    if event_type == hs.caffeinate.watcher.systemDidWake then
        on_screen_change()
    end
end)

return {
    enable = enable_oled_mode,
    disable = disable_oled_mode,
    set_dark_mode = set_dark_mode,
}
