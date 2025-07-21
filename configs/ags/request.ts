import ScreenRecord from "./utils/screenrecord";
import {App} from "astal/gtk4";
import {launchPicker} from "./widgets/quicksettings/buttons/ColorPickerQS";

export default function requestHandler(
  request: string,
  res: (response: any) => void,
): void {
  const screenRecord = ScreenRecord.get_default();
  switch (request) {
    case "openAppLauncher":
      res("ok");
      App.get_window("applauncher")?.set_visible(true);
      break;
    case "pickColor":
      res("ok");
      void launchPicker()
      break;
    case "screen-record":
      res("ok");
      screenRecord.start();
      break;
    default:
      res("not ok");
      break;
  }
}
