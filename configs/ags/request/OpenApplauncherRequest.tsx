import BaseRequest from "./BaseRequest";
import Applauncher from "../widget/Applauncher";

export default class OpenApplauncherRequest extends BaseRequest {
    command = "openAppLauncher"

    async handleCommand(params: string[], res: (response: any) => void) {
        Applauncher()
        return res("ok");
    }
}