import { Variable, GLib, bind } from "astal"
import Hyprland from "gi://AstalHyprland"

export default function Workspaces() {
    const hypr = Hyprland.get_default();

    return <box className="Workspaces">
        {bind(hypr, "monitors").as(monitors => (
            <>
                {[...Array(5)].map((_, i) => {
                    const workspaceId = i + 1;
                    const monitorCount = monitors.length;

                    return (
                        <button
                            key={workspaceId}
                            className={bind(hypr, "focusedWorkspace").as(fw => {
                                if(!fw) {
                                    return ""
                                }

                                const minWorkspace = (workspaceId - 1) * monitorCount + 1;
                                const maxWorkspace = minWorkspace + monitorCount - 1;

                                const allMonitorsInRange =
                                    fw.id >= minWorkspace &&
                                    fw.id <= maxWorkspace

                                return allMonitorsInRange ? "focused" : "";
                            })}
                            onClicked={() => {
                                hypr.dispatch("vdesk", `${workspaceId}`)
                            }}
                        >
                            {workspaceId}
                        </button>
                    );
                })}
            </>
        ))}
    </box>
}