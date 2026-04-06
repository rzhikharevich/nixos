-- Randomly adjusts yabai padding and gap at random intervals to slightly reduce OLED burn-in risks.

local padding_min = 0
local padding_max = 10
local interval_min = 3 * 60
local interval_max = 5 * 60
local yabai_path = "@yabai@/bin/yabai"
local padding_debug = true

local pending_timer = nil

local function log(msg)
    if padding_debug then
        print("[yabai padding] " .. msg)
    end
end

local function yabai(args)
    local cmd = yabai_path .. " -m " .. args
    log("Running: " .. cmd)
    local output, status = hs.execute(cmd)
    if not status then
        log("WARNING: command failed: " .. cmd)
    end
    return output, status
end

local function set_padding(val)
    yabai("config top_padding " .. val)
    yabai("config bottom_padding " .. val)
    yabai("config left_padding " .. val)
    yabai("config right_padding " .. val)
    yabai("config window_gap " .. val)
end

local function randomize_padding()
    local val = math.random(padding_min, padding_max)
    log("Setting padding and gap to " .. val)
    set_padding(val)
end

local function schedule_next()
    local delay = math.random(interval_min, interval_max)
    log(string.format("Next padding change in %d seconds.", delay))
    pending_timer = hs.timer.doAfter(delay, function()
        randomize_padding()
        schedule_next()
    end)
end

function yabai_padding_start()
    math.randomseed(os.time())
    log("Starting.")
    randomize_padding()
    schedule_next()
end

function yabai_padding_stop()
    if pending_timer then
        pending_timer:stop()
        pending_timer = nil
    end
    set_padding(0)
    log("Stopped.")
end

return {
    start = yabai_padding_start,
    stop = yabai_padding_stop,
}
