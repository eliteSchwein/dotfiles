import { Variable, GLib, createBinding } from "ags"
import Tray from "gi://AstalTray"

export default function SysTray() {
    const tray = Tray.get_default()

    return <box class="SysTray">
        {createBinding(tray, "items").as(items => items.map(item => (
            <menubutton
                tooltipMarkup={createBinding(item, "tooltipMarkup")}
                usePopover={false}
                actionGroup={createBinding(item, "actionGroup").as(ag => ["dbusmenu", ag])}
                menuModel={createBinding(item, "menuModel")}>
                <icon gicon={createBinding(item, "gicon")}  />
            </menubutton>
        )))}
    </box>
}