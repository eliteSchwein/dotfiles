import PanelButton from "../common/PanelButton";
import {showAppLauncher, WINDOW_NAME} from "../applauncher/Applauncher";

export default function LauncherPanelButton() {
    return (
        <PanelButton
            window={WINDOW_NAME}
            onClicked={() => showAppLauncher()}
        >
            <image iconName="preferences-desktop-apps-symbolic"/>
        </PanelButton>
    );
}
