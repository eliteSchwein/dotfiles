import { App } from "astal/gtk4";
import windows from "./windows";
import request from "./request";
import initStyles from "./utils/styles";
import initHyprland from "./utils/hyprland";
import Bar from "../agsbck/widget/Bar";
import NotificationPopups from "../agsbck/widget/NotificationPopups";
import {execAsync} from "astal";

initStyles();

App.start({
  requestHandler(req, res) {
    request(req, res);
  },
  main() {
    windows.map((win) => App.get_monitors().map(win));

    initHyprland();

    App.connect('monitor-added', (app: App, monitor: Gdk.Monitor) => {
      hypr.dispatch("vdeskreset", ``);

      restartAgs()
    });

    App.connect("monitor-removed", () => {
      hypr.dispatch("vdeskreset", ``);

      restartAgs()
    });
  },
});

export function restartAgs() {
  execAsync([
    "bash", "-c",
    "ags quit && ags run --gtk4 -d $HOME/dotfiles/configs/ags"
  ])
}

App.apply_css('/tmp/theme.css')