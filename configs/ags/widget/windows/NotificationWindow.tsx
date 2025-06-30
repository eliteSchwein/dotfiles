import Notifd from "gi://AstalNotifd";
import { bind } from "ags";
import { App, Astal, Gtk } from "ags/gtk4";
import icons from "../../lib/icons";
import Notification from "../Notification";

const Items = ({ notis }: { notis: Notifd.Notification[] }) => {
    const { ALWAYS, NEVER } = Gtk.PolicyType;

    return (
        <scrollable
            class="notifications-scrollable"
            hscroll={NEVER}
            vscroll={ALWAYS}
            vexpand
        >
            <box vertical>
                {notis.map((n) => (
                    <Notification noti={n} width={10} />
                ))}
            </box>
        </scrollable>
    );
};

const Header = ({ notifd }: { notifd: Notifd.Notifd }) => {
    const dndToggleBtn = (
        <button
            class={bind(notifd, "dontDisturb").as((dnd) =>
                dnd ? "notifications-disabled" : "notifications-default",
            )}
            onClick={() => {
                notifd.set_dont_disturb(!notifd.dontDisturb);
            }}
        >
            <icon
                icon={
                    notifd.dontDisturb
                        ? icons.notification.disabled
                        : icons.notification.default
                }
            />
        </button>
    );

    const clearAllBtn = (
        <button
            onClick={() => {
                for (const noti of notifd.notifications) {
                    noti.dismiss();
                }
            }}
        >
            <icon
                icon={
                    notifd.notifications.length > 0 ? icons.trash.full : icons.trash.empty
                }
            />
        </button>
    );

    return (
        <box class="notifications-header">
            <box>
                <box halign={Gtk.Align.END} spacing={8} hexpand>
                    {dndToggleBtn}
                    {clearAllBtn}
                </box>
            </box>
        </box>
    );
};

const Main = () => {
    const notifd = Notifd.get_default();

    return (
        <box
            css="min-width: 20rem; min-height: 30rem; padding: 10px;"
            vertical
            spacing={8}
        >
            <Header notifd={notifd} />
            {bind(notifd, "notifications").as((notis) =>
                notis.length > 0 ? (
                    <Items notis={notis} />
                ) : (
                    <box>
                        AAA
                    </box>
                ),
            )}
        </box>
    );
};

export function NotificationCenter() {
    const { RIGHT, TOP } = Astal.WindowAnchor;

    return (
        <window
            visible={true}
            name="notification-center"
            anchor={RIGHT | TOP}
            margin={6}
            application={App}
        >
            <Main />
        </window>
    );
}