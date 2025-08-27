import AstalBluetooth from "gi://AstalBluetooth";
import {qsPage} from "../QSWindow";
import {Gtk} from "astal/gtk4";
import {bind, GLib} from "astal";
import {bash, notifySend} from "../../../utils";

export function scanBluetoothDevices() {
    const bluetooth = AstalBluetooth.get_default();
    const btAdapter = bluetooth.adapter;

    if (btAdapter.get_discovering()) return;

    btAdapter.start_discovery();

    setTimeout(() => {
        btAdapter.stop_discovery();
    }, 20_000)
}

export function createBluetoothDevice(device: any) {
    return {
        label: device.get_name() || device.get_address(),
        icon: (device.get_icon()) ? `${device.get_icon()}-symbolic` : null,
        connected: device.get_connected(),
        data: device,
    }
}

export function pairBluetoothDevice(device: any) {
    const bluetooth = AstalBluetooth.get_default();
    const btAdapter = bluetooth.adapter;

    if (btAdapter.get_discovering()) {
        btAdapter.stop_discovery();
    }
    if (!btAdapter.get_discoverable()) {
        btAdapter.set_discoverable(true);
    }
    if (!btAdapter.get_pairable()) {
        btAdapter.set_pairable(true);
    }

    device.data.pair()

    btAdapter.set_discoverable(false);
    btAdapter.set_pairable(false);
}

export function connectBluetoothDevice(device: any) {
    const bluetooth = AstalBluetooth.get_default();
    const btAdapter = bluetooth.adapter;

    if (device.data.get_connected()) {
        device.data.disconnect_device(
            (result: boolean, error: Error | null) => {
                btAdapter.set_discoverable(false);
                btAdapter.set_pairable(false);
                if (error && error.message) {
                    notifySend({
                        urgency: "critical",
                        appIcon: "bluetooth-active-symbolic",
                        appName: "Bluetooth",
                        summary: `Disconnecting ${device.label} failed`,
                        body: error.message,
                    });
                }
            });
        return;
    }

    if (btAdapter.get_discovering()) {
        btAdapter.stop_discovery();
    }
    if (!btAdapter.get_discoverable()) {
        btAdapter.set_discoverable(true);
    }
    if (!btAdapter.get_pairable()) {
        btAdapter.set_pairable(true);
    }

    device.data.connect_device(
        (result: boolean, error: Error | null) => {
            btAdapter.set_discoverable(false);
            btAdapter.set_pairable(false);
            if (error && error.message) {
                notifySend({
                    urgency: "critical",
                    appIcon: "bluetooth-active-symbolic",
                    appName: "Bluetooth",
                    summary: `Connection ${device.label} failed`,
                    body: error.message,
                });
            }
        }
    );
}

function BluetoothButton(device: any) {
    device = device.device
    return <centerbox
        cssClasses={device.data.get_connected() ? ["button", "bt-button", "active"] : ["button", "bt-button"]}>
        <box halign={Gtk.Align.START}>
            <image iconName={device.icon}/>
            <label label={device.label}/>
        </box>
        <box></box>
        <box halign={Gtk.Align.END}>
            <Gtk.Separator/>
            {
                device.data.get_paired()
                    ? <>
                        <button
                            iconName={device.data.get_connected() ? "bluetooth-disconnected-symbolic" : "bluetooth-active-symbolic"}
                            halign={Gtk.Align.CENTER}
                            valign={Gtk.Align.CENTER}
                            onClicked={() => {
                                connectBluetoothDevice(device);
                            }}
                        >
                        </button>
                        <button
                            iconName="trash-symbolic"
                            halign={Gtk.Align.CENTER}
                            valign={Gtk.Align.CENTER}
                            onClicked={() => {
                                bash(`bluetoothctl remove ${device.data.get_address()}`);
                            }}
                        >
                        </button>
                    </>
                    : <>
                        <button
                            iconName="link-symbolic"
                            halign={Gtk.Align.CENTER}
                            valign={Gtk.Align.CENTER}
                            onClicked={() => {
                                pairBluetoothDevice(device);
                            }}
                        >
                        </button>
                        <button
                            iconName="action-unavailable-symbolic"
                            halign={Gtk.Align.CENTER}
                            valign={Gtk.Align.CENTER}
                            onClicked={() => {
                                device.data.set_blocked(true);
                            }}
                        >
                        </button>
                    </>
            }
        </box>
    </centerbox>
}

export default function BluetoothPage() {
    const bluetooth = AstalBluetooth.get_default();
    const btAdapter = bluetooth.adapter;

    return (
        <box
            name={"bluetooth"}
            cssClasses={["bluetooth-page", "qs-page"]}
            vertical
            spacing={6}
        >
            <box hexpand={false} cssClasses={["header"]} spacing={6}>
                <button
                    onClicked={() => {
                        qsPage.set("main");

                        if (btAdapter.get_discovering()) {
                            btAdapter.stop_discovery();
                        }
                    }}
                    iconName={"go-previous-symbolic"}
                />
                <label label={"Bluetooth"} hexpand xalign={0}/>

                {bind(btAdapter, "discovering").as((state) => {
                    return (
                        <button
                            onClicked={() => {
                                state ? btAdapter.stop_discovery() : scanBluetoothDevices()
                            }}
                        >
                            <box>
                                <image cssClasses={["mr-1"]}
                                       iconName={state ? "media-playback-stopped-symbolic" : "file-search-symbolic"}/>
                                <label label={state ? "Scanning" : "Scan"}/>
                            </box>
                        </button>)
                })}

                {bind(btAdapter, "discoverable").as((state) => {
                    return (
                        <button
                            onClicked={() => {
                                btAdapter.set_discoverable(!state)
                                btAdapter.set_pairable(!state)
                            }}
                        >
                            <box>
                                <image cssClasses={["mr-1"]}
                                       iconName={state ? "feather-eye-symbolic" : "feather-eye-off-symbolic"}/>
                                <label label={state ? "Visible" : "Invisible"}/>
                            </box>
                        </button>)
                })}
            </box>
            <Gtk.Separator/>
            <Gtk.ScrolledWindow vexpand>
                <box vertical spacing={6}>
                    {bind(bluetooth, "devices").as((devices) => {
                        const pairedDevices = devices
                            .map((device) => (createBluetoothDevice(device)))
                            .filter((d) => d.data.get_paired());

                        const discoveredDevices = devices
                            .map((device) => (createBluetoothDevice(device)))
                            .filter((d) => !d.data.get_paired() && !d.data.get_blocked());

                        return (
                            <>
                                <Gtk.ScrolledWindow vexpand>
                                    <box vertical spacing={6}>
                                        {pairedDevices.length > 0 ? (
                                            <>
                                                {pairedDevices.map((device, index) => (
                                                    <BluetoothButton key={index} device={device}/>
                                                ))}
                                                <Gtk.Separator/>
                                            </>
                                        ) : null}
                                        {discoveredDevices.length > 0 ? (
                                            <>
                                                {discoveredDevices.map((device, index) => (
                                                    <BluetoothButton key={index} device={device}/>
                                                ))}
                                            </>
                                        ) : null}
                                    </box>
                                </Gtk.ScrolledWindow>
                            </>
                        );
                    })}
                </box>
            </Gtk.ScrolledWindow>
        </box>
    );
}
