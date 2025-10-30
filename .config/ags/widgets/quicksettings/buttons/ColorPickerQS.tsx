import {execAsync} from "astal";
import {App} from "astal/gtk4";
import {notifySend} from "../../../utils";
import {WINDOW_NAME} from "../QSWindow";
import QSButton from "../QSButton";
import {timeout} from "astal";

export default function ColorPickerQS() {
    return (
        <QSButton
            onClicked={() => {
                App.toggle_window(WINDOW_NAME);
                timeout(200, () => {
                    void launchPicker()
                });
            }}
            iconName={"color-select-symbolic"}
            label={"Color Picker"}
        />
    );
}

export async function launchPicker() {
    execAsync("hyprpicker -a -n")
        .catch(console.error);
}