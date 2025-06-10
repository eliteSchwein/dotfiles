import { bind } from "astal";
import AstalNetwork from "gi://AstalNetwork";

export default function Network() {
    const network = AstalNetwork.get_default();

    const wifi = bind(network, "wifi");

    const wifiDevice = wifi.get();
    const wiredDevice = network.wired;

    if (!wifiDevice && !wiredDevice) {
        return <box><label>⚠ No network device</label></box>;
    }

    const wifiIcon = wifiDevice ? bind(wifiDevice, "iconName") : null;
    const wiredIcon = wiredDevice ? bind(wiredDevice, "iconName") : null;
    const wiredState = wiredDevice ? bind(wiredDevice, "state") : null;

    function setWifiState() {
        const w = wifi.get();
        if (w) {
            w.set_enabled(!w.get_enabled());
        }
    }

    return (
        <box className="Workspaces">
            {wiredState?.as((state) => {
                const isWiredConnected = state === 100; // NM.DeviceState.ACTIVATED

                return (
                    <button onClicked={setWifiState}>
                        <icon className="icon" icon={isWiredConnected ? wiredIcon : wifiIcon} />
                    </button>
                );
            }) ?? <label>No connection</label>}
        </box>
    );
}
