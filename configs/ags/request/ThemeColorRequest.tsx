import BaseRequest from "./BaseRequest";
import { App } from "ags/gtk3";
import { exec } from "ags/process";

export default class ThemeColorRequest extends BaseRequest {
    command = "changeThemeColor"

    async handleCommand(params: string[], res: (response: any) => void) {
        if (params.length < 1) {
            return res("missing arguments");
        }

        try {
            exec(`cp ./style/Theme.scss /tmp/Theme.scss`);
            exec(`sed -i 's/#378DF7/#${params[0]}/g' /tmp/Theme.scss`);
            exec(`sass /tmp/Theme.scss /tmp/theme.css`);

            App.reset_css();

            App.apply_css('/tmp/style.css');
            App.apply_css('/tmp/theme.css');
            return res("ok");
        } catch (error) {
            console.error("Error updating theme color:", error);
            return res("failed");
        }
    }
}
