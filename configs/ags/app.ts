import { App } from "astal/gtk3"
import { exec } from "astal/process"
import Bar from "./widget/Bar"
import NotificationPopups from "./widget/NotificationPopups"
import OpenApplauncherRequest from "./request/OpenApplauncherRequest";
import ThemeColorRequest from "./request/ThemeColorRequest";
import {monitorFile, readFile} from "/usr/share/astal/gjs";

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

            App.reset_css()

            App.apply_css('/tmp/style.css')
            App.apply_css('/tmp/theme.css')
        }
    )
}

App.start({
    css: "/tmp/style.css",
    async requestHandler(request: string, res: (response: any) => void) {
        await (new OpenApplauncherRequest()).execute(request, res);
        await (new ThemeColorRequest()).execute(request, res);

        res('unkown command');
    },
    main() {
        //const config = JSON.parse(readFile("./local.config.json"))

        //const primaryMonitorIndex = (config.primary_monitor) ? config.primary_monitor : 0
        //const primaryMonitor = App.get_monitors()[primaryMonitorIndex]
        //Bar(primaryMonitor)
        //NotificationPopups(primaryMonitor)
        App.get_monitors().map(Bar)
        App.get_monitors().map(NotificationPopups)
    },
})


App.apply_css('/tmp/theme.css')
