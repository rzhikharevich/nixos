-- LG C2 power management.

local tv_input = "HDMI_2"
local switch_input_on_wake = true
local prevent_sleep_when_using_other_input = true
local debug = true

local tv_name = "'LG C2'"
local connected_tv_identifiers = { "LG TV", "LG TV SSCR2" }
local screen_off_command = "off"
local lgtv_path = "@lgtv_remote@/bin/lgtv"
local lgtv_cmd = lgtv_path .. " " .. tv_name
local app_id = "com.webos.app." .. tv_input:lower():gsub("_", "")
local lgtv_ssl = true

local function log(msg)
    if debug then
        print("[lgtv] " .. msg)
    end
end

local function exec_command(command)
    if lgtv_ssl then
        local space_loc = command:find(" ")
        if space_loc then
            command = command:sub(1, space_loc) .. "ssl " .. command:sub(space_loc + 1)
        else
            command = command .. " ssl"
        end
    end

    command = lgtv_cmd .. " " .. command
    log("Executing: " .. command)
    return hs.execute(command)
end

local function current_app_id()
    local info = exec_command("getForegroundAppInfo")
    for w in info:gmatch('%b{}') do
        if w:match('"response"') then
            local match = w:match('"appId"%s*:%s*"([^"]+)"')
            if match then
                return match
            end
        end
    end
end

local function tv_is_connected()
    for _, v in ipairs(connected_tv_identifiers) do
        if hs.screen.find(v) ~= nil then
            return true
        end
    end
    return false
end

watcher = hs.caffeinate.watcher.new(function(eventType)
    log("Received event: " .. (eventType or ""))

    if not tv_is_connected() then
        log("TV not connected, skipping.")
        return
    end

    if eventType == hs.caffeinate.watcher.screensDidWake or
        eventType == hs.caffeinate.watcher.systemDidWake or
        eventType == hs.caffeinate.watcher.screensDidUnlock then
        exec_command("on")
        exec_command("screenOn")
        log("TV turned on.")

        if current_app_id() ~= app_id and switch_input_on_wake then
            exec_command("startApp " .. app_id)
            log("Input switched to " .. app_id)
        end
    end

    if eventType == hs.caffeinate.watcher.screensDidSleep or
        eventType == hs.caffeinate.watcher.systemWillPowerOff then
        if current_app_id() ~= app_id and prevent_sleep_when_using_other_input then
            log("TV on another input (" .. (current_app_id() or "unknown") .. "), skipping power off.")
            return
        end

        exec_command(screen_off_command)
        log("TV screen off (" .. screen_off_command .. ").")
    end
end)
watcher:start()
