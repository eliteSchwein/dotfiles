import { bind } from "astal";
import { App, Gdk } from "astal/gtk3"
import Hyprland from "gi://AstalHyprland";

export default function Workspaces() {
    const hypr = Hyprland.get_default();

    return (
        <box className="Workspaces font-victor-medium">
            {bind(App, "monitors").as(monitors => {
                if (!Array.isArray(monitors) || monitors.some(m => m == null)) {
                    return <label>Loading monitors…</label>;
                }

                const monitorCount = monitors.length;

                return (
                    <>
                        {[...Array(5)].map((_, i) => {
                            const workspaceId = i + 1;

                            return (
                                <button
                                    key={workspaceId}
                                    className={bind(hypr, "focusedWorkspace").as(fw => {
                                        if (!fw || fw.id === 0) return "";

                                        const minWorkspace = (workspaceId - 1) * monitorCount + 1;
                                        const maxWorkspace = minWorkspace + monitorCount - 1;

                                        const allMonitorsInRange =
                                            fw.id >= minWorkspace && fw.id <= maxWorkspace;

                                        return allMonitorsInRange ? "focused" : "d-none";
                                    })}
                                    onClicked={() => {
                                        hypr.dispatch("vdesk", `${workspaceId}`);
                                    }}
                                >
                                    {workspaceId}
                                </button>
                            );
                        })}
                    </>
                );
            })}
        </box>
    );
}
