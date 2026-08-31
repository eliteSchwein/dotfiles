-- Converted from misc.conf to Hyprland Lua config style.

hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = 1,
})

hl.config({
	render = {
  		direct_scanout = 0,
  		cm_enabled = 0,
  		send_content_type = 0,
  		cm_auto_hdr = 0,
 		non_shader_cm = 0,
	},

    misc = {
        font_family = "VictorMono",
        disable_splash_rendering = true,
        force_default_wallpaper = -1,
        disable_hyprland_logo = true,
        allow_session_lock_restore = true,
        initial_workspace_tracking = 0,
        anr_missed_pings = 10,
        vrr = 0
    },

    debug = {
        disable_logs = true,
    },

    ecosystem = {
        no_update_news = true,
        no_donation_nag = true,
    },

    binds = {
        allow_workspace_cycles = true,
        scroll_event_delay = 0,
        hide_special_on_workspace_change = true,
    },
})
