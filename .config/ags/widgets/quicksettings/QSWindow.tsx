import PopupWindow from "../common/PopupWindow";
import ColorPickerQS from "./buttons/ColorPickerQS";
import DontDisturbQS from "./buttons/DontDisturbQS";
import RecordQS from "./buttons/RecordQS";
import BrightnessBox from "./BrightnessBox";
import VolumeBox from "./VolumeBox";
import {FlowBox} from "../common/FlowBox";
import {Gtk, App, Gdk} from "astal/gtk4";
import {WINDOW_NAME as POWERMENU_WINDOW} from "../powermenu/PowerMenu";
import {bind, Binding, GObject, Variable} from "astal";
import options from "../../options";
import AstalBattery from "gi://AstalBattery";
import AstalNetwork from "gi://AstalNetwork";
import AstalBluetooth from "gi://AstalBluetooth";
import BatteryPage from "./pages/BatteryPage";
import SpeakerPage from "./pages/SpeakerPage";
import WifiPage, {currentActiveWifiInput, currentWifiPassword} from "./pages/WifiPage";
import MicPage from "./pages/MicPage";
import BluetoothPage, {scanBluetoothDevices} from "./pages/BluetoothPage";
import AstalPowerProfiles from "gi://AstalPowerProfiles";
import WallpaperQS from "./buttons/WallpaperQS";
import RestartQS from "./buttons/RestartQS";
import MediaBox from "./MediaBox";

export const WINDOW_NAME = "quicksettings";
export const qsPage = Variable("main");
const {bar} = options;

const layout = Variable.derive(
    [bar.position, bar.start, bar.center, bar.end],
    (pos, start, center, end) => {
        if (start.includes("quicksetting")) return `${pos}_left`;
        if (center.includes("quicksetting")) return `${pos}_center`;
        if (end.includes("quicksetting")) return `${pos}_right`;

        return `${pos}_center`;
    },
);

function QSButtons() {
    return (
        <FlowBox
            maxChildrenPerLine={3}
            activateOnSingleClick={false}
            homogeneous
            rowSpacing={6}
            columnSpacing={6}
        >
            <ColorPickerQS/>
            <DontDisturbQS/>
            <RecordQS/>
            <WallpaperQS/>
            <RestartQS/>
        </FlowBox>
    );
}

function Header() {
    const battery = AstalBattery.get_default();
    const powerprofile = AstalPowerProfiles.get_default();

    return (
        <box hexpand={false} cssClasses={["header"]} spacing={6}>
            <label label={"Quick Setting"} hexpand xalign={0}/>
            <button
                cssClasses={["battery"]}
                onClicked={() => {
                    qsPage.set("battery");
                }}
            >

                {bind(battery, "batteryIconName").as((icon) => {
                    if (icon === "battery-missing-symbolic") {
                        return (
                            <box spacing={2}>
                                <image
                                    iconName={bind(powerprofile, "activeProfile").as(
                                        (p) => {
                                            switch (p) {
                                                case "power-saver":
                                                    return "battery-profile-powersave-symbolic"
                                                case "performance":
                                                    return "power-symbolic"
                                                default:
                                                    return "power-profile-balanced-symbolic"
                                            }
                                        },
                                    )}
                                    iconSize={Gtk.IconSize.NORMAL}
                                    cssClasses={["icon"]}
                                />
                            </box>
                        )
                    }

                    return (
                        <box spacing={2}>
                            <image
                                iconName={bind(battery, "batteryIconName")}
                                iconSize={Gtk.IconSize.NORMAL}
                                cssClasses={["icon"]}
                            />
                            <label
                                label={bind(battery, "percentage").as(
                                    (p) => `${Math.floor(p * 100)}%`,
                                )}
                            />
                        </box>
                    )
                })}
            </button>
            <button
                cssClasses={["powermenu"]}
                onClicked={() => {
                    App.toggle_window(WINDOW_NAME);
                    App.toggle_window(POWERMENU_WINDOW);
                }}
            >
                <image
                    iconName={"system-shutdown-symbolic"}
                    iconSize={Gtk.IconSize.NORMAL}
                />
            </button>
        </box>
    );
}

function ArrowButton<T extends GObject.Object>({
                                                   icon,
                                                   title,
                                                   subtitle,
                                                   onClicked,
                                                   onArrowClicked,
                                                   connection: [gobject, property],
                                               }: {
    icon: string | Binding<string>;
    title: string;
    subtitle: string | Binding<string>;
    onClicked: () => void;
    onArrowClicked: () => void;
    connection: [T, keyof T];
}) {
    return (
        <box
            cssClasses={bind(gobject, property).as((p) => {
                const classes = ["arrow-button"];
                p && classes.push("active");
                return classes;
            })}
        >
            <button onClicked={onClicked}>
                <box halign={Gtk.Align.START} spacing={6}>
                    <image iconName={icon} iconSize={Gtk.IconSize.LARGE}/>
                    <box vertical hexpand>
                        <label xalign={0} label={title} cssClasses={["title"]}/>
                        <label xalign={0} label={subtitle} cssClasses={["subtitle"]}/>
                    </box>
                </box>
            </button>
            <button iconName={"go-next-symbolic"} onClicked={onArrowClicked}/>
        </box>
    );
}

function WifiArrowButton() {
    const wifi = AstalNetwork.get_default().wifi;
    const wifiSsid = Variable.derive(
        [bind(wifi, "state"), bind(wifi, "ssid")],
        (state, ssid) => {
            return state == AstalNetwork.DeviceState.ACTIVATED
                ? ssid
                : AstalNetwork.device_state_to_string();
        },
    );

    return (
        <ArrowButton
            icon={bind(wifi, "iconName")}
            title="Wi-Fi"
            subtitle={wifiSsid()}
            onClicked={() => wifi.set_enabled(!wifi.get_enabled())}
            onArrowClicked={() => {
                currentWifiPassword.set("")
                currentActiveWifiInput.set("")
                wifi.scan();
                qsPage.set("wifi");
            }}
            connection={[wifi, "enabled"]}
        />
    );
}

function WifiBluetooth() {
    const bluetooth = AstalBluetooth.get_default();
    const btAdapter = bluetooth.adapter;

    const deviceConnected = Variable.derive(
        [bind(bluetooth, "devices"), bind(bluetooth, "isConnected")],
        (d, _) => {
            for (const device of d) {
                if (device.connected) return device.name;
            }
            return "No device";
        },
    );
    const wifi = AstalNetwork.get_default().wifi;

    return (
        <box
            homogeneous
            spacing={6}
            onDestroy={() => {
                deviceConnected.drop();
            }}
        >
            {!!wifi && <WifiArrowButton/>}
            <ArrowButton
                icon={bind(btAdapter, "powered").as(
                    (p) => `bluetooth-${p ? "" : "disabled-"}symbolic`,
                )}
                title="Bluetooth"
                subtitle={deviceConnected()}
                onClicked={() => bluetooth.toggle()}
                onArrowClicked={() => {
                    scanBluetoothDevices()
                    qsPage.set("bluetooth");
                }}
                connection={[btAdapter, "powered"]}
            />
        </box>
    );
}

function MainPage() {
    return (
        <box cssClasses={["qs-page"]} name={"main"} vertical spacing={6}>
            <Header/>
            <Gtk.Separator/>
            <WifiBluetooth/>
            <QSButtons/>
            <BrightnessBox/>
            <VolumeBox/>
            <MediaBox/>
        </box>
    );
}

function QSWindow(_gdkmonitor: Gdk.Monitor) {
    return (
        <PopupWindow
            name={WINDOW_NAME}
            layout={layout.get()}
            animation="slide top"
            onDestroy={() => layout.drop()}
        >
            <box
                cssClasses={["window-content", "qs-container"]}
                hexpand={false}
                vexpand={false}
                vertical
            >
                <stack
                    visibleChildName={qsPage()}
                    transitionType={Gtk.StackTransitionType.SLIDE_LEFT_RIGHT}
                >
                    <MainPage/>
                    <BatteryPage/>
                    <SpeakerPage/>
                    <WifiPage/>
                    <MicPage/>
                    <BluetoothPage/>
                </stack>
            </box>
        </PopupWindow>
    );
}

export default function (gdkmonitor: Gdk.Monitor) {
    QSWindow(gdkmonitor);

    App.connect("window-toggled", (_, win) => {
        if (win.name == WINDOW_NAME && !win.visible) {
            qsPage.set("main");
        }
    });

    layout.subscribe(() => {
        App.remove_window(App.get_window(WINDOW_NAME)!);
        QSWindow(gdkmonitor);
    });
}
