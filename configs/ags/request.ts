import ScreenRecord from "./utils/screenrecord";
import {App} from "astal/gtk4";
import {launchPicker} from "./widgets/quicksettings/buttons/ColorPickerQS";
import styles, {loadThemeColor} from "./utils/styles";

export default function requestHandler(
  request: string,
  res: (response: any) => void,
): void {
  const screenRecord = ScreenRecord.get_default();
  const params = request.split(" ")
  switch (params[0]) {
    case "changeThemeColor":
      res("ok");
      loadThemeColor(params[1])
      break;
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