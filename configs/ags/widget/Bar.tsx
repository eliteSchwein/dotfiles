import { createBinding } from "ags"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import Hyprland from "gi://AstalHyprland"
import Mpris from "gi://AstalMpris"
import Battery from "gi://AstalBattery"
import Wp from "gi://AstalWp"
import AstalNetwork from "gi://AstalNetwork";
import Popover from "./Popover"
import Network from "../components/Network";
import SysTray from "../components/SysTray";
import Workspaces from "../components/Workspaces";
import BatteryLevel from "../components/BatteryLevel";
import { GLib, Variable } from "/usr/share/astal/gjs"

function AudioSlider() {
    const speaker = Wp.get_default()?.audio.defaultSpeaker!

    return <box class="AudioSlider" css="min-width: 140px">
        <icon icon={createBinding(speaker, "volumeIcon")} />
        <slider
            hexpand
            onDragged={({ value }) => speaker.volume = value}
            value={createBinding(speaker, "volume")}
        />
    </box>
}

function Media() {
    const mpris = Mpris.get_default()

    return <box class="Media">
        {createBinding(mpris, "players").as(ps => ps[0] ? (
            <box>
                <box
                    class="Cover"
                    valign={Gtk.Align.CENTER}
                    css={createBinding(ps[0], "coverArt").as(cover =>
                        `background-image: url('${cover}');`
                    )}
                />
                <label
                    label={createBinding(ps[0], "metadata").as(() =>
                        `${ps[0].title} - ${ps[0].artist}`
                    )}
                />
            </box>
        ) : (
            <label label="Nothing Playing" />
        ))}
    </box>
}

function FocusedClient() {
    const hypr = Hyprland.get_default()
    const focused = createBinding(hypr, "focusedClient")

    return <box
        class="Focused"
        visible={focused.as(Boolean)}>
        {focused.as(client => (
            client && <label label={createBinding(client, "title").as(String)} />
        ))}
    </box>
}

function Time({ format = "%H:%M:%S - %A %e." }) {
    const time = Variable<string>("").poll(1000, () =>
        GLib.DateTime.new_now_local().format(format)!)

    return <label
        class="Time"
        onDestroy={() => time.drop()}
        label={time()}
    />
}

export default function Bar(monitor: Gdk.Monitor) {
    const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

    return <window
        class="Bar font-victor"
        gdkmonitor={monitor}
        exclusivity={Astal.Exclusivity.EXCLUSIVE}
        anchor={TOP | LEFT | RIGHT}>
        <centerbox>
            <box class="bar-box left-box font-turretroad" hexpand halign={Gtk.Align.START}>
                <Workspaces />
            </box>
            <box class="bar-box center-box font-victor">
                <Time />
            </box>
            <box class="bar-box right-box" hexpand halign={Gtk.Align.END} >
                <SysTray />
                <Network />
                <AudioSlider />
                <BatteryLevel />
            </box>
        </centerbox>
    </window>
}