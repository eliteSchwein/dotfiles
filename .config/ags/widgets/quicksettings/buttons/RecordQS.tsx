import {App} from "astal/gtk4";
import {timeout} from "astal";
import ScreenRecord from "../../../utils/screenrecord";
import QSButton from "../QSButton";
import {WINDOW_NAME} from "../QSWindow";

export default function RecordQS() {
    const screenRecord = ScreenRecord.get_default();

    return (
        <QSButton
            connection={[screenRecord, "recording"]}
            onClicked={() => {
                if (screenRecord.recording) {
                    screenRecord.stop();
                } else {
                    App.toggle_window(WINDOW_NAME);
                    timeout(200, () => {
                        screenRecord.start();
                    });
                }
            }}
            iconName={"screenshooter-symbolic"}
            label={"Screen Record"}
        />
    );
}
