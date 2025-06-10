import { bind } from "astal";
import AstalNetwork from "gi://AstalNetwork";

export default function Network() {
    const network = AstalNetwork.get_default();

    const wifi = bind(network, "wifi");
    const wifiIcon = bind(network.wifi, "iconName");
    const dummyWired = {
        iconName: "network-wired-symbolic",
        state: 100, // NM.DeviceState.ACTIVATED
    };

    const wiredDevice = network.wired ?? dummyWired;
    const wiredIcon = bind(wiredDevice, "iconName");
    const wiredState = bind(wiredDevice, "state");


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
