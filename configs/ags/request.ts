import ScreenRecord from "./utils/screenrecord";
import {App} from "astal/gtk4";

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
    case "screen-record":
      res("ok");
      screenRecord.start();
      break;
    case "screenshot":
      res("ok");
      screenRecord.screenshot(true);
      break;
    case "screenshot-select":
      res("ok");
      screenRecord.screenshot();
      break;
    default:
      res("not ok");
      break;
  }
}
