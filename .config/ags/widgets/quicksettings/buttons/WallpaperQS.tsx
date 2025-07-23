import {execAsync} from "astal";
import {App} from "astal/gtk4";
import {bash, notifySend} from "../../../utils";
import {WINDOW_NAME} from "../QSWindow";
import QSButton from "../QSButton";
import {timeout} from "astal";

export default function WallpaperQS() {
    return (
        <QSButton
            onClicked={() => {
                App.toggle_window(WINDOW_NAME);
                bash("bash $HOME/.config/hypr/scripts/wallpaper.sh")
            }}
            iconName={"preferences-desktop-wallpaper-symbolic"}
            label={"Change Wallpaper"}
        />
    );
}