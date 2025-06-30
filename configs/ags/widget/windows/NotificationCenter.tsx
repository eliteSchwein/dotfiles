import Apps from "gi://AstalApps"
import { App, Astal, Gdk, Gtk } from "ags/gtk3"
import { Variable } from "ags"

export function NotificationCenter() {
    const { CENTER } = Gtk.Align

    const width = Variable(1000)

    return <window
        name="notificationCenter"
        anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.BOTTOM}
        exclusivity={Astal.Exclusivity.IGNORE}
        application={App}
        onShow={(self) => {
            width.set(self.get_current_monitor().workarea.width)
        }}
    >
        <box></box>
    </window>
}