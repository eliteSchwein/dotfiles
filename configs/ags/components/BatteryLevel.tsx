import { Variable, GLib, bind } from "astal"
import Battery from "gi://AstalBattery"

export default function BatteryLevel() {
    const bat = Battery.get_default()

    return <box className="Battery"
                visible={bind(bat, "isPresent")}>
        <icon icon={bind(bat, "batteryIconName")} />
        <label label={bind(bat, "percentage").as(p =>
            `${Math.floor(p * 100)} %`
        )} />
    </box>
}