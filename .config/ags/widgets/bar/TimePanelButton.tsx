import {App, Astal, Gtk, Gdk} from "astal/gtk4";
import {time} from "../../utils";
import PanelButton from "../common/PanelButton";
import {WINDOW_NAME} from "../datemenu/DateMenu";

export default function TimePanelButton({format = "%H:%M:%S - %A %e."}) {
    return (
        <PanelButton
            window={WINDOW_NAME}
            onClicked={() => App.toggle_window(WINDOW_NAME)}
        >
            <label cssClasses={["font-digital7", "time-container"]} label={time((t) => t.format(format)!)}/>
        </PanelButton>
    );
}