import AstalNetwork from "gi://AstalNetwork";
import AstalBluetooth from "gi://AstalBluetooth";
import { qsPage } from "../QSWindow";
import { Gtk } from "astal/gtk4";
import { bind } from "astal";
import { bash } from "../../../utils";

export default function BluetoothPage() {
  const bluetooth = AstalBluetooth.get_default();
  const btAdapter = bluetooth.adapter;

  return (
    <box
      name={"bluetooth"}
      cssClasses={["bluetooth-page", "qs-page"]}
      vertical
      spacing={6}
    >
      <box hexpand={false} cssClasses={["header"]} spacing={6}>
        <button
          onClicked={() => {
            qsPage.set("main");

            if(btAdapter.get_discovering()) {
              btAdapter.stop_discovery();
            }
          }}
          iconName={"go-previous-symbolic"}
        />
        <label label={"Bluetooth"} hexpand xalign={0} />
      </box>
      <Gtk.Separator />
      <Gtk.ScrolledWindow vexpand>
        <box vertical spacing={6}>
          {bind(bluetooth, "devices").as((devices) => {
            const pairedDevices = devices
                .map((device) => ({
                  label: device.get_name() || device.get_address(),
                  data: device,
                }))
                .filter((d) => d.data.get_paired());

            const discoveredDevices = devices
                .map((device) => ({
                  label: device.get_name() || device.get_address(),
                  data: device,
                }))
                .filter((d) => !d.data.get_paired());

            return (
                <>
                  <Gtk.Separator />

                  <Gtk.ScrolledWindow vexpand>
                    <box vertical spacing={6}>
                      {pairedDevices.map((device, index) => (

                          <button
                              cssClasses={device.data.get_connected() ? ["button", "bt-button", "active"] : ["button", "bt-button"]}

                          >
                            <box>
                              <image iconName={device.data.get_icon()} />
                              <label label={device.label} />
                              <Gtk.Separator />
                              <box>
                                <button
                                    iconName={device.data.get_connected() ? "bluetooth-active-symbolic" : "bluetooth-disconnected-symbolic"}
                                    halign={Gtk.Align.CENTER}
                                    valign={Gtk.Align.CENTER}
                                    onClicked={() => {
                                      bash(`bluetoothctl connect ${device.data.get_address()}`);
                                    }}
                                >
                                </button>
                              </box>
                            </box>
                          </button>
                      ))}
                      <Gtk.Separator />
                      {discoveredDevices.map((device, index) => (

                          <button
                              cssClasses={device.data.get_connected() ? ["button", "bt-button", "active"] : ["button", "bt-button"]}

                          >
                            <box>
                              <image iconName={device.data.get_icon()} />
                              <label label={device.label} />
                              <Gtk.Separator />
                              <box>
                                <button
                                    iconName={device.data.get_connected() ? "bluetooth-active-symbolic" : "bluetooth-disconnected-symbolic"}
                                    halign={Gtk.Align.CENTER}
                                    valign={Gtk.Align.CENTER}
                                    onClicked={() => {
                                      bash(`bluetoothctl connect ${device.data.get_address()}`);
                                    }}
                                >
                                </button>
                              </box>
                            </box>
                          </button>
                      ))}
                    </box>
                  </Gtk.ScrolledWindow>
                </>
            );
          })}
        </box>
      </Gtk.ScrolledWindow>
    </box>
  );
}
