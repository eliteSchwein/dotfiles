import { bind } from "astal";
import { Gtk } from "astal/gtk4";
import AstalWp from "gi://AstalWp";
import { qsPage } from "./QSWindow";

export default function VolumeBox() {
  const speaker = AstalWp.get_default()?.audio!.defaultSpeaker!;
  const mic = AstalWp.get_default()?.audio!.defaultMicrophone!;

  console.log(mic)

  return (
      <>
        <box
            cssClasses={["qs-box", "volume-box"]}
            valign={Gtk.Align.CENTER}
            spacing={10}
        >

          <button
              iconName={bind(speaker, "volumeIcon")}
              valign={Gtk.Align.CENTER}
              onButtonPressed={() => {speaker.mute = !speaker.mute}}
          >
          </button>
          <slider
              onChangeValue={(self) => {
                speaker.volume = self.value;
              }}
              value={bind(speaker, "volume")}
              hexpand
          />
          <button
              iconName={"go-next-symbolic"}
              onClicked={() => qsPage.set("speaker")}
          />
        </box>
        <box
            cssClasses={["qs-box", "volume-box"]}
            valign={Gtk.Align.CENTER}
            spacing={10}
        >

          <button
              iconName={bind(mic, "volumeIcon")}
              valign={Gtk.Align.CENTER}
              onButtonPressed={() => {mic.mute = !mic.mute}}
          >
          </button>
          <slider
              onChangeValue={(self) => {
                mic.volume = self.value;
              }}
              value={bind(mic, "volume")}
              hexpand
          />
          <button
              iconName={"go-next-symbolic"}
              onClicked={() => qsPage.set("mic")}
          />
        </box>
      </>
  );
}
