import { bind } from "astal";
import AstalNetwork from "gi://AstalNetwork";

// Dummy fallback
const dummyDevice = {
    iconName: "network-offline-symbolic",
    state: 0,
    get_enabled: () => false,
    set_enabled: () => {},
};

export default function Network() {
    const network = AstalNetwork.get_default();

    const wifiDevice = network.wifi ?? dummyDevice;
    const wiredDevice = network.wired ?? dummyDevice;

    const wifiIcon = bind(wifiDevice, "iconName");
    const wiredIcon = bind(wiredDevice, "iconName");
    const wiredState = bind(wiredDevice, "state");

    function setWifiState() {
        if (network.wifi) {
            network.wifi.set_enabled(!network.wifi.get_enabled());
        }
    }

    return (
        <box className="Workspaces">
            {wiredState?.as((state) => {
                const isWiredConnected = state === 100;

                return (
                    <button onClicked={setWifiState}>
                        <icon
                            className="icon"
                            icon={isWiredConnected ? wiredIcon : wifiIcon}
                        />
                    </button>
                );
            }) ?? <label>No network</label>}
        </box>
    );
}
