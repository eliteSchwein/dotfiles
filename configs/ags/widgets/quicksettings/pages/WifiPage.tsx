import AstalNetwork from "gi://AstalNetwork";
import { qsPage } from "../QSWindow";
import { Gtk } from "astal/gtk4";
import { bind, Variable } from "astal";
import { bash } from "../../../utils";
import { App, Gtk, hook, Gdk } from "astal/gtk4";

export const currentActiveWifiInput = Variable("");
export const currentWifiPassword = Variable("");

async function connectWifi(accessPoint) {
  const ssid = accessPoint.ssid
  const bssid = accessPoint.bssid;

  let request = ""

  if(currentWifiPassword.get() !== "") {
    await bash(`nmcli device wifi delete "${ssid}"`)
    request = await bash(`echo "${currentWifiPassword.get()}" | nmcli device wifi connect "${ssid}" --ask`)
  } else {
    request = await bash(`nmcli device wifi connect "${ssid}"`)
  }

  currentWifiPassword.set("")

  if(request.includes("successfully activated with")) {
    currentActiveWifiInput.set("")
    return
  }

  currentActiveWifiInput.set(bssid)
}

export default function WifiPage() {
  const wifi = AstalNetwork.get_default().wifi;

  wifi.visiblePasswordBox ??= null;

  return (
    <box
      name={"wifi"}
      cssClasses={["wifi-page", "qs-page"]}
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
        <label label={"Wi-Fi"} hexpand xalign={0} />

        {bind(wifi, "scanning").as((state) => {
          return (
              <button
                  onClicked={() => {
                    currentWifiPassword.set("")
                    currentActiveWifiInput.set("")
                    wifi.scan()
                  }}
              >
                <box>
                  <image cssClasses={["mr-1"]} iconName={state ? "media-playback-stopped-symbolic" : "file-search-symbolic"} />
                  <label label={state ? "Scanning" : "Scan"}/>
                </box>
              </button>)
        })}
      </box>
      <Gtk.Separator />
      <Gtk.ScrolledWindow vexpand>
        <box vertical spacing={6}>
          {bind(wifi, "accessPoints").as((aps) => {
            const seenSsids = new Set();
            return aps
              .filter((ap) => {
                if (seenSsids.has(ap.ssid)) {
                  return false;
                }
                seenSsids.add(ap.ssid);
                return !!ap.ssid;
              })
              .map((accessPoint) => {
                let icon = accessPoint.iconName

                if(accessPoint.get_requires_password()) {
                  icon = icon.replace("-symbolic", "-secure-symbolic");
                }

                return (
                  <box
                    cssClasses={bind(wifi, "ssid").as((ssid) => {
                      const classes = ["button", "wifi-button"];
                      ssid === accessPoint.ssid && classes.push("active");
                      return classes;
                    })}
                    hexpand
                  >
                    <box vertical spacing={6}>
                      <centerbox hexpand>
                        <box halign={Gtk.Align.START}>
                          <image iconName={icon} />
                          <label label={accessPoint.ssid} />
                        </box>
                        <box></box>
                        <box halign={Gtk.Align.END}>
                          {bind(wifi, "ssid").as((ssid) => {
                            if(ssid === accessPoint.ssid) {
                              return (
                                  <>
                                  </>
                              )
                            }
                            return (
                                <>
                                  <Gtk.Separator />
                                  <button
                                      iconName="link-symbolic"
                                      halign={Gtk.Align.CENTER}
                                      valign={Gtk.Align.CENTER}
                                      onClicked={() => {
                                        connectWifi(accessPoint);
                                      }}
                                  >
                                  </button>
                                </>
                            )
                          })}
                        </box>
                      </centerbox>
                      <box
                          vertical
                          spacing={6}
                          name={`wifi-input-${accessPoint.bssid}`}
                          visible={bind(currentActiveWifiInput).as((activeBssid) => {
                            return activeBssid === accessPoint.bssid;
                          })}

                      >
                        <Gtk.Separator />
                        <box>
                          <entry
                              type="overlay"
                              hexpand
                              primaryIconName={"blueman-pair-symbolic"}
                              placeholderText="Password..."
                              text={currentWifiPassword.get()}
                              onChanged={(entry) => {
                                currentWifiPassword.set(entry.text);
                              }}
                          >
                          </entry>
                        </box>
                      </box>
                    </box>
                  </box>
                );
              });
          })}
        </box>
      </Gtk.ScrolledWindow>
    </box>
  );
}
