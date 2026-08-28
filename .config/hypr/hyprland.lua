-- ~/.config/hypr/hyprland.lua
-- Перенос с hyprland.conf на Lua (Hyprland 0.55+).
-- Синтаксис диспетчеров/биндов взят из официального example/hyprland.lua.
-- Колоночная раскладка — из вики (Custom-Layouts), используется как "lua:columns".
-- ВАЖНО: если этот файл существует, Hyprland грузит ЕГО вместо hyprland.conf.

------------------ МОНИТОРЫ ------------------
-- position в логических координатах; ультравайд слева, ноут справа (центр по высоте).
-- hl.monitor({ output = "DP-1",  mode = "3440x1440@99.982", position = "0x0",     scale = 1 })
-- hl.monitor({ output = "eDP-1", mode = "2880x1800@120",    position = "3440x120", scale = 1.5 })
-- запасной для ноута без внешнего:
hl.monitor({ output = "eDP-1", mode = "2880x1800@120", position = "0x0", scale = 1.5, vrr = 3,
    bitdepth = 10,
    -- cm = "hdr"
    })
hl.monitor({
  output = "desc:LG Electronics LG TV SSCR2 0x01010101",
  mode = "3840x2160@60",
  position = "0x-1440",
  scale = 1.5,
  vrr = 3
})
-- всё прочее — авто:
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })


------------------ ПЕРЕМЕННЫЕ ОКРУЖЕНИЯ ------------------
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("GDK_SCALE", "1.25")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("HANDY_NO_GTK_LAYER_SHELL", "true")

------------------ КОЛОНОЧНАЯ РАСКЛАДКА (из вики) ------------------
-- Каждое окно занимает свою колонку, делятся поровну. Заменяет hy3.
hl.layout.register("columns", {
    recalculate = function(ctx)
        local n = #ctx.targets
        if n == 0 then return end
        for i, target in ipairs(ctx.targets) do
            target:place(ctx:column(i, n))
        end
    end,
})

------------------ ОБЩИЙ ВИД / ЭФФЕКТЫ ------------------
hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 10,
        border_size = 2,
        col = {
            active_border   = "rgba(cba6f7ff)",   -- Catppuccin mauve
            inactive_border = "rgba(6c7086ff)",   -- overlay0
        },
        
        layout = "hy3",
    },
    decoration = {
        rounding = 8,
        active_opacity = 1.0,
        inactive_opacity = 0.95,                   -- бывш. picom inactive-opacity
        shadow = { enabled = true, range = 8, render_power = 3, color = 0xee1a1a1a },
        blur   = { enabled = true, size = 5, passes = 2 },
    },
    animations = { enabled = true },
    misc = { disable_hyprland_logo = true },
    input = {
        kb_layout = "us,ru",
        kb_options = "grp:alt_shift_toggle",
        follow_mouse = 1,
        touchpad = { natural_scroll = true, disable_while_typing = true },
    },
    xwayland = {
        force_zero_scaling = true
    },
})

------------------ АНИМАЦИИ (с fade) ------------------
hl.curve("easeOutQuint",  { type = "bezier", points = { {0.23, 1}, {0.32, 1} } })
hl.curve("almostLinear",  { type = "bezier", points = { {0.5, 0.5}, {0.75, 1} } })
hl.curve("quick",         { type = "bezier", points = { {0.15, 0}, {0.1, 1} } })

hl.animation({ leaf = "windows",    enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",  enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2.0,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "fade",       enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "fadeIn",     enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",    enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "border",     enabled = true, speed = 5.39, bezier = "easeOutQuint" })
-- hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "easeOutQuint", style = "slide" })

------------------ АВТОЗАПУСК ------------------
hl.on("hyprland.start", function()
    -- uwsm сам прокидывает окружение и поднимает graphical-session.target + портал.
    -- finalize отдаёт переменные Hyprland в systemd/dbus.
    hl.exec_cmd("uwsm finalize")
    -- Приложения — через uwsm app, чтобы каждое жило в своём systemd-юните.
    hl.exec_cmd("uwsm app -- waybar")
    hl.exec_cmd("uwsm app -- awww-daemon")
    hl.exec_cmd("uwsm app -- nm-applet --indicator")
    hl.exec_cmd("uwsm app -- hypridle")
    hl.exec_cmd("hypridle")
    -- dex убран: uwsm сам обрабатывает XDG-autostart (.desktop в autostart)
    hl.exec_cmd("hyprpm reload -n")
end)

------------------ ПРАВИЛА ОКОН ------------------
hl.window_rule({ name = "handy-float", match = { class = "Handy" }, float = true })
-- hl.window_rule({
--     -- Ignore maximize requests from all apps. You'll probably like this.
--     name = "suppress-maximize-events",
--     match = { class = ".*" },

--     suppress_event = "maximize",
-- })
hl.window_rule({
    name = "move-hyprland-run",

    match = { class = "hyprland-run" },

    move = "20 monitor_h-120",
    float = true,
})
hl.window_rule({ name = "portal-picker-float", match = { class = "hyprland-share-picker" }, float = true })
hl.window_rule({ name = "portal-picker-center", match = { class = "hyprland-share-picker" }, float = true, move = "cursor -50% -50%" })
hl.on("window.title", function(w)
    if w.class == "zen" and w.title:match("^Extension:") then
        hl.dispatch(hl.dsp.window.float({
            action = "on",
            window = w,
        }))
    end
end)

------------------ БИНДЫ ------------------
local mainMod  = "SUPER"
local terminal = "alacritty"
local menu     = "wofi --show drun"

hl.bind(mainMod .. " + O", hl.dsp.exec_cmd("pkill -USR2 -x handy"))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + SPACE", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())        -- inferred dispatcher
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + SHIFT + I", hl.dsp.exec_cmd("pkill hypridle || hypridle &"))

-- Перезагрузка / выход
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprctl reload"))
-- ВАЖНО под uwsm: выходить через uwsm stop, НЕ нативным exit (иначе ломается
-- порядок остановки юнитов сессии)
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd("uwsm stop"))

-- Фокус (j=left k=down l=up ;=right) + стрелки
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + semicolon", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))

-- Перемещение окна (inferred: direction у window.move, по аналогии с focus)
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "down" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + semicolon", hl.dsp.window.move({ direction = "right" }))

-- Воркспейсы 1..10 + перенос окна (точь-в-точь как в official example)
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Мышь: перетаскивание / ресайз
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
-- hl.bind("mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Скриншоты
hl.bind("Print", hl.dsp.exec_cmd("grim - | wl-copy"))
hl.bind(mainMod .. " + SHIFT + S",
        hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | swappy -f -"))

-- Обои
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/wallpaper-picker.sh"))

-- Звук / медиа (pactl/playerctl; locked = работает на лок-экране, repeating = автоповтор)
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ +5%"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ -5%"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("pactl set-sink-mute @DEFAULT_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("pactl set-source-mute @DEFAULT_SOURCE@ toggle"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"), { locked = true })
