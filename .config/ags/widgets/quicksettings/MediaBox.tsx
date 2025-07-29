import {timeout, Variable} from "astal";
import {bind} from "astal";
import {App, Gtk} from "astal/gtk4";
import AstalApps from "gi://AstalApps";
import AstalHyprland from "gi://AstalHyprland";
import AstalMpris from "gi://AstalMpris";
import Pango from "gi://Pango";

export default function MediaBox() {
    const mpris = AstalMpris.get_default();
    return (
        <>
            {bind(mpris, "players").as((players) => (
                <>
                    {players.map((player) => (
                        <MediaPlayer player={player} />
                    ))}
                </>
            ))}
        </>
    )
}

function MediaPlayer({player}) {
    if (!player) {
        return <box/>;
    }
    const title = bind(player, "title").as((t) => t || "Unknown Track");
    const artist = bind(player, "artist").as((a) => a || "Unknown Artist");
    const coverArt = bind(player, "coverArt");

    const playIcon = bind(player, "playbackStatus").as((s) =>
        s === AstalMpris.PlaybackStatus.PLAYING
            ? "media-playback-pause-symbolic"
            : "media-playback-start-symbolic",
    );

    return (
        <box cssClasses={["media-player"]} hexpand>
            {/* Cover image */}
            <image
                overflow={Gtk.Overflow.HIDDEN}
                pixelSize={35}
                cssClasses={["cover"]}
                file={coverArt}
            />

            {/* Main content column */}
            <box vertical hexpand>
                <label
                    ellipsize={Pango.EllipsizeMode.END}
                    halign={Gtk.Align.START}
                    label={title}
                    maxWidthChars={15}
                />
                <label halign={Gtk.Align.START} label={artist}/>
            </box>

            {/* Playback buttons */}
            <button
                halign={Gtk.Align.END}
                valign={Gtk.Align.CENTER}
                onClicked={() => player.previous()}
                visible={bind(player, "canGoPrevious")}
            >
                <image iconName="media-skip-backward-symbolic" pixelSize={24}/>
            </button>
            <button
                halign={Gtk.Align.END}
                valign={Gtk.Align.CENTER}
                onClicked={() => player.play_pause()}
                visible={bind(player, "canControl")}
            >
                <image iconName={playIcon} pixelSize={18}/>
            </button>
            <button
                halign={Gtk.Align.END}
                valign={Gtk.Align.CENTER}
                onClicked={() => player.next()}
                visible={bind(player, "canGoNext")}
            >
                <image iconName="media-skip-forward-symbolic" pixelSize={24}/>
            </button>

            {/* App icon placed last to visually float in corner */}
            <image
                cssClasses={["media-app-icon"]}
                pixelSize={15}
                iconName={player.entry}
            />
        </box>
    );
}