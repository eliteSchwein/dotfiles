import { bind } from "astal";
import AstalNetwork from "gi://AstalNetwork";

export default function Network() {
    const network = AstalNetwork.get_default();

    const wifi = bind(network, "wifi");
    const wifiIcon = bind(network.wifi, "iconName");
    const wiredIcon = bind(network.wired, "iconName");
    const wiredState = bind(network.wired, "state");

    function setWifiState() {
        wifi.get().set_enabled(!wifi.get().get_enabled());
    }

    return (
        <box className="Workspaces">
            {wiredState.as((state) => {
                const isWiredConnected = state === 100; // NM.DeviceState.ACTIVATED

                return (
                    <button onClicked={setWifiState}>
                        <icon className="icon" icon={isWiredConnected ? wiredIcon : wifiIcon} />
                    </button>
                );
            })}
        </box>
    );
}
