import AstalWp from "gi://AstalWp?version=0.1";
import { qsPage } from "../QSWindow";
import { Gtk } from "astal/gtk4";
import { bind } from "astal";

export default function MicPage() {
  const audio = AstalWp.get_default()!.audio;
  return (
    <box
      name={"mic"}
      cssClasses={["mic-page", "qs-page"]}
      vertical
      spacing={6}
    >
      <box hexpand={false} cssClasses={["header"]} spacing={6}>
        <button
          onClicked={() => {
            qsPage.set("main");
          }}
          iconName={"go-previous-symbolic"}
        />
        <label label={"Microphone"} hexpand xalign={0} />
      </box>
      <Gtk.Separator />
      {bind(audio, "microphones").as((d) =>
        d.map((mic) => (
          <button
            cssClasses={bind(mic, "isDefault").as((isD) => {
              const classes = ["button"];
              isD && classes.push("active");
              return classes;
            })}
            onClicked={() => {
              mic.set_is_default(true);
              qsPage.set("main");
            }}
          >
            <box>
              <image iconName={mic.volumeIcon} />
              <label label={mic.description} />
            </box>
          </button>
        )),
      )}
    </box>
  );
}
