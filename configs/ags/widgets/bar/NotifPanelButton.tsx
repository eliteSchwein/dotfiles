import AstalNotifd from "gi://AstalNotifd";
import PanelButton from "../common/PanelButton";
import {App} from "astal/gtk4";
import {bind, Variable} from "astal";
import {WINDOW_NAME} from "../notification/NotificationWindow";
import {getFallback, getNotificationIcon, substitute} from "../notification/Notification";

const notifd = AstalNotifd.get_default();

function NotifIcon() {
    const getVisible = () =>
        notifd.dont_disturb ? true : notifd.notifications.length <= 0;

    const visibility = Variable(getVisible())
        .observe(notifd, "notify::dont-disturb", () => {
            return getVisible();
        })
        .observe(notifd, "notify::notifications", () => getVisible());

    return (
        <image
            onDestroy={() => visibility.drop()}
            visible={visibility()}
            cssClasses={["icon"]}
            iconName={bind(notifd, "dont_disturb").as(
                (dnd) => `notifications-${dnd ? "disabled-" : ""}symbolic`,
            )}
        />
    );
}

export default function NotifPanelButton() {
    return (
        <PanelButton
            window={WINDOW_NAME}
            onClicked={() => {
                App.toggle_window(WINDOW_NAME);
            }}
        >
            {bind(notifd, "dontDisturb").as((dnd) =>
                !dnd ? (
                    <box spacing={6}>
                        {bind(notifd, "notifications").as((n) => {
                            if (n.length > 0) {
                                return [
                                    ...n.slice(0, 3).map((e) => {
                                        const icon = getNotificationIcon(e);
                                        return <image iconName={icon}/>;
                                    }),
                                    <image
                                        visible={n.length > 3}
                                        cssClasses={["circle"]}
                                        iconName={"feather-more-horizontal-symbolic"}
                                    />,
                                ];
                            }
                            return <NotifIcon/>;
                        })}
                    </box>
                ) : (
                    <NotifIcon/>
                ),
            )}
        </PanelButton>
    );
}
