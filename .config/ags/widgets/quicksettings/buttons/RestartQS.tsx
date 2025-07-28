import {execAsync} from "astal";
import {App} from "astal/gtk4";
import {bash, notifySend} from "../../../utils";
import {WINDOW_NAME} from "../QSWindow";
import QSButton from "../QSButton";
import {timeout} from "astal";
import {restartAgs} from "../../../app";

export default function RestartQS() {
    return (
        <QSButton
            onClicked={() => {
                restartAgs()
            }}
            iconName={"system-restart-symbolic"}
            label={"Restart AGS"}
        />
    );
}