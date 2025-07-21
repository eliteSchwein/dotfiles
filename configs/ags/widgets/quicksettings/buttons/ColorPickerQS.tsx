import { execAsync } from "astal";
import { App } from "astal/gtk4";
import { notifySend } from "../../../utils";
import { WINDOW_NAME } from "../QSWindow";
import QSButton from "../QSButton";
import { timeout } from "astal";

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
    const wlCopy = (color: string) =>
        execAsync(["wl-copy", color]).catch(console.error);

    execAsync("hyprpicker")
        .then((color) => {
            if (!color) return;

            wlCopy(color);
            notifySend({
                appName: "Hyprpicker",
                summary: "Color Picker",
                body: `${color} copied to clipboard`,
            });
        })
        .catch(console.error);
}