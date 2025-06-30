import { Gdk } from "ags/gtk3"
import app from "ags/gtk3/app"
import { exec } from "ags/process"
import Bar from "./widget/Bar"
import NotificationPopups from "./widget/NotificationPopups"
import OpenApplauncherRequest from "./request/OpenApplauncherRequest";
import ThemeColorRequest from "./request/ThemeColorRequest";
import {execAsync, GLib, monitorFile, readFile, Variable} from "/usr/share/astal/gjs";
import Hyprland from "gi://AstalHyprland";
import {NotificationCenter} from "./widget/windows/NotificationCenter";

exec("sass ./style.scss /tmp/style.css")

const monitorPaths = [
    "./style/",
    "./style.scss"
]

for(const monitorPath of monitorPaths) {
    monitorFile(
        monitorPath,
        async () => {
            exec("sass ./style.scss /tmp/style.css")

            app.reset_css()

            app.apply_css('/tmp/style.css')
            app.apply_css('/tmp/theme.css')
        }
    )
}

app.start({
    css: "/tmp/style.css",
    async requestHandler(request: string, res: (response: any) => void) {
        await (new OpenApplauncherRequest()).execute(request, res);
        await (new ThemeColorRequest()).execute(request, res);

        res('unknown command');
    },
    main() {
        const hypr = Hyprland.get_default();

        //NotificationCenter()

        app.get_monitors().map(registerMonitor)

        app.connect('monitor-added', (app: app, monitor: Gdk.Monitor) => {
            registerMonitor(monitor)

            hypr.dispatch("vdeskreset", ``);
        });

        app.connect("monitor-removed", () => {
            hypr.dispatch("vdeskreset", ``);

            restartAgs()
        });
    },
})

function registerMonitor(monitor: Gdk.Monitor) {
    Bar(monitor);
    NotificationPopups(monitor);
}

export function restartAgs() {
    execAsync([
        "bash", "-c",
        "ags quit && ags run $HOME/.config/ags/app.ts"
    ])
}

app.apply_css('/tmp/theme.css')
