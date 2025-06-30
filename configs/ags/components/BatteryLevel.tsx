import { Variable, GLib, createBinding } from "ags"
import Battery from "gi://AstalBattery"

export default function BatteryLevel() {
    const bat = Battery.get_default()

    return <box class="Battery"
                visible={createBinding(bat, "isPresent")}>
        <icon icon={createBinding(bat, "batteryIconName")} />
        <label label={createBinding(bat, "percentage").as(p =>
            `${Math.floor(p * 100)} %`
        )} />
    </box>
}