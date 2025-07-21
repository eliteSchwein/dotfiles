import networkSpeed from "../../utils/networkspeed";
import PanelButton from "../common/PanelButton";

export default function NetworkSpeedPanelButton() {
  return (
    <PanelButton window="">
      <box cssClasses={["network-speed"]}>
        <label
          cssClasses={["label"]}
          label={networkSpeed((value) => {
              const downloadSpeed = value.download; // in KB/s
              const uploadSpeed = value.upload;     // in KB/s
              const higherSpeed = Math.max(downloadSpeed, uploadSpeed); // KB/s

              const kbitSpeed = higherSpeed * 8; // Convert KB/s to kbit/s
              const mbitSpeed = kbitSpeed / 1000; // Convert kbit/s to Mbit/s

              if (mbitSpeed >= 0.5) {
                  return `${mbitSpeed.toFixed(2)} Mbit/s`;
              } else {
                  return `${kbitSpeed.toFixed(2)} kbit/s`;
              }
          })}

        />
          <image
              cssClasses={["ml-1"]}
              iconName={networkSpeed((value) => {
              const downloadSpeed = value.download;
              const uploadSpeed = value.upload;

              return downloadSpeed >= uploadSpeed ? "network-receive-symbolic" : "network-transmit-symbolic";
          })} />
      </box>
    </PanelButton>
  );
}
