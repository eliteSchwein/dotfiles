import { Gtk, Astal } from "ags/gtk3"
import { type EventBox } from "ags/gtk3/widget"
import Notifd from "gi://AstalNotifd"
import { GLib } from "/usr/share/astal/gjs"

const isIcon = (icon: string) =>
    !!Astal.Icon.lookup_icon(icon)

const fileExists = (path: string) =>
    GLib.file_test(path, GLib.FileTest.EXISTS)

const time = (time: number, format = "%H:%M") => GLib.DateTime
    .new_from_unix_local(time)
    .format(format)!

const urgency = (n: Notifd.Notification = undefined) => {
    if(!n) return
    const { LOW, NORMAL, CRITICAL } = Notifd.Urgency
    // match operator when?
    switch (n.urgency) {
        case LOW: return "low"
        case CRITICAL: return "critical"
        case NORMAL:
        default: return "normal"
    }
}

type Props = {
    setup(self: EventBox): void
    notification: Notifd.Notification
}

export default function Notification(props: Props) {
    const { notification: n, setup } = props
    const { START, CENTER, END } = Gtk.Align

    if (n.appName === "Hyprshot") {
        return <eventbox
            class={`Notification font-victor ${urgency(n)}`}
            setup={setup}>
            <box vertical>
                <box class="header">
                    {(n.desktopEntry) && <icon
                        class="app-icon"
                        visible={Boolean(n.desktopEntry)}
                        icon={n.desktopEntry}
                    />}
                    <label
                        class="app-name font-orbitron"
                        halign={START}
                        truncate
                        label={n.appName || "Unknown"}
                    />
                    <label
                        class="time"
                        hexpand
                        halign={END}
                        label={time(n.time)}
                    />
                    <button class="bg-transparent bx-none" onClicked={() => n.dismiss()}>
                        <icon icon="window-close-symbolic" />
                    </button>
                </box>
                <Gtk.Separator visible />
                <box class="content">
                    <box vertical>
                        <label
                            class="summary"
                            halign={START}
                            xalign={0}
                            label={n.summary}
                            truncate
                        />
                        {n.body && <label
                            class="body"
                            wrap
                            useMarkup
                            halign={START}
                            xalign={0}
                            justifyFill
                            label={n.body}
                        />}
                    </box>
                </box>
                <box class="content full-image">
                    {n.appIcon && fileExists(n.appIcon) && <box
                        valign={CENTER}
                        class="image"
                        css={`background-image: url('${n.appIcon}')`}
                    />}
                </box>
                {n.get_actions().length > 0 && <box class="actions">
                    {n.get_actions().map(({ label, id }) => (
                        <button
                            class="bx-none"
                            hexpand
                            onClicked={() => {n.invoke(id); n.dismiss();}}>
                            <label label={label} halign={CENTER} hexpand />
                        </button>
                    ))}
                </box>}
            </box>
        </eventbox>
    }

    return <eventbox
        class={`Notification font-victor ${urgency(n)}`}
        setup={setup}>
        <box vertical>
            <box class="header">
                {(n.appIcon || n.desktopEntry) && <icon
                    class="app-icon"
                    visible={Boolean(n.appIcon || n.desktopEntry)}
                    icon={n.appIcon || n.desktopEntry}
                />}
                <label
                    class="app-name font-orbitron"
                    halign={START}
                    truncate
                    label={n.appName || "Unknown"}
                />
                <label
                    class="time"
                    hexpand
                    halign={END}
                    label={time(n.time)}
                />
                <button class="bg-transparent bx-none" onClicked={() => n.dismiss()}>
                    <icon icon="window-close-symbolic" />
                </button>
            </box>
            <Gtk.Separator visible />
            <box class="content">
                {n.image && fileExists(n.image) && <box
                    valign={START}
                    class="image"
                    css={`background-image: url('${n.image}')`}
                />}
                {n.image && isIcon(n.image) && <box
                    expand={false}
                    valign={START}
                    class="icon-image">
                    <icon icon={n.image} expand halign={CENTER} valign={CENTER} />
                </box>}
                <box vertical>
                    <label
                        class="summary"
                        halign={START}
                        xalign={0}
                        label={n.summary}
                        truncate
                    />
                    {n.body && <label
                        class="body"
                        wrap
                        useMarkup
                        halign={START}
                        xalign={0}
                        justifyFill
                        label={n.body}
                    />}
                </box>
            </box>
            {n.get_actions().length > 0 && <box class="actions">
                {n.get_actions().map(({ label, id }) => (
                    <button
                        class="bx-none"
                        hexpand
                        onClicked={() => {n.invoke(id); n.dismiss();}}>
                        <label label={label} halign={CENTER} hexpand />
                    </button>
                ))}
            </box>}
        </box>
    </eventbox>
}
