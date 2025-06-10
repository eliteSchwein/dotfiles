import { bind } from "astal";
import AstalNetwork from "gi://AstalNetwork";

// Dummy fallback device
const dummyDevice = {
    iconName: "network-offline-symbolic",
    state: 0,
    get_enabled: () => false,
    set_enabled: () => {},
};

// Safe bind helper
function safeBind(obj, prop, fallback = null) {
    try {
        return bind(obj ?? dummyDevice, prop);
    } catch (e) {
        print(`❌ Failed to bind "${prop}":`, e);
        return fallback;
    }
}

export default function Network() {
    const network = AstalNetwork.get_default();

    // Safe fallback devices
    const wifiDevice = network.wifi ?? dummyDevice;
    const wiredDevice = network.wired ?? dummyDevice;

    // Bindings
    const wifi = safeBind(network, "wifi");
    const wifiIcon = safeBind(wifiDevice, "iconName");
    const wiredIcon = safeBind(wiredDevice, "iconName");
    const wiredState = safeBind(wiredDevice, "state");

    function setWifiState() {
        try {
            const w = wifi.get();
            if (w) w.set_enabled(!w.get_enabled());
        } catch (e) {
            print("⚠️ Error toggling WiFi:", e);
        }
    }

    return (
        <box className="Workspaces">
            {wiredState?.as((state) => {
                const isWiredConnected = state === 100; // NM.DeviceState.ACTIVATED
                return (
                    <button onClicked={setWifiState}>
                        <icon className="icon" icon={isWiredConnected ? wiredIcon : wifiIcon ?? "network-offline-symbolic"} />
                    </button>
                );
            }) ?? <label>No network</label>}
        </box>
    );
}
