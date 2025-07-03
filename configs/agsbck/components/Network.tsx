import { bind } from "astal";
import AstalNetwork from "gi://AstalNetwork";
import { GObject } from "/usr/share/astal/gjs";

const DummyDevice = GObject.registerClass({
    Properties: {
        'iconName': GObject.ParamSpec.string(
            'iconName', '', '',
            GObject.ParamFlags.READWRITE,
            'network-wired-symbolic'
        ),
        'state': GObject.ParamSpec.int(
            'state', '', '',
            GObject.ParamFlags.READWRITE,
            0, 999, 0 // default state = 0 (disconnected)
        ),
        'enabled': GObject.ParamSpec.boolean(
            'enabled', '', '',
            GObject.ParamFlags.READWRITE,
            false // default: disabled
        ),
    },
}, class DummyDevice extends GObject.Object {
    get_enabled() {
        return this.enabled;
    }

    set_enabled(value) {
        this.enabled = value;
    }
});

export default function Network() {
    const network = AstalNetwork.get_default();


    const wiredDevice = network.wired ?? new DummyDevice();
    const wifiDevice = network.wifi ?? new DummyDevice();

    const wifi = bind(network, "wifi");
    const wifiIcon = bind(wifiDevice, "iconName");

    const wiredIcon = bind(wiredDevice, "iconName");
    const wiredState = bind(wiredDevice, "state");


    function setWifiState() {
        wifi.get().set_enabled(!wifi.get().get_enabled());
    }

    return (
        <box className="">
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
