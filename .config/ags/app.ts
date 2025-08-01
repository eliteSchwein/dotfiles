import {App} from "astal/gtk4";
import windows from "./windows";
import request from "./request";
import initStyles from "./utils/styles";
import initHyprland from "./utils/hyprland";
import {execAsync} from "astal";

initStyles();

App.start({
    requestHandler(req, res) {
        request(req, res);
    },
    main() {
        windows.map((win) => App.get_monitors().map(win));

        initHyprland();
    },
});

export function restartAgs() {
    execAsync([
        "bash", "-c",
        "ags quit && ags run --gtk4 -d $HOME/.config/ags"
    ])
}

App.apply_css('/tmp/theme.css')