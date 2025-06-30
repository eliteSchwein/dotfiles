import { createBinding } from "ags";
import Hyprland from "gi://AstalHyprland";
import app from "ags/gtk4/app"

export default function Workspaces() {
    const hypr = Hyprland.get_default();

    return (
        <box class="Workspaces font-victor-medium">
            {createBinding(app, "monitors").as(monitors => {
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
                                    class={createBinding(hypr, "focusedWorkspace").as(fw => {
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
