/**
 * Pi Notify Extension
 *
 * Sends a native terminal notification when Pi agent is done and waiting for input.
 * Supports multiple terminal protocols:
 * - OSC 777: Ghostty, iTerm2, WezTerm, rxvt-unicode
 * - OSC 99: Kitty
 * - Windows toast: Windows Terminal (WSL)
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

function windowsToastScript(title: string, body: string): string {
	const type = "Windows.UI.Notifications";
	const mgr = `[${type}.ToastNotificationManager, ${type}, ContentType = WindowsRuntime]`;
	const template = `[${type}.ToastTemplateType]::ToastText01`;
	const toast = `[${type}.ToastNotification]::new($xml)`;
	return [
		`${mgr} > $null`,
		`$xml = [${type}.ToastNotificationManager]::GetTemplateContent(${template})`,
		`$xml.GetElementsByTagName('text')[0].AppendChild($xml.CreateTextNode('${body}')) > $null`,
		`[${type}.ToastNotificationManager]::CreateToastNotifier('${title}').Show(${toast})`,
	].join("; ");
}

function notifyOSC777(title: string, body: string): void {
	process.stdout.write(`\x1b]777;notify;${title};${body}\x07`);
}

function notifyOSC99(title: string, body: string): void {
	// Kitty OSC 99: i=notification id, d=0 means not done yet, p=body for second part
	process.stdout.write(`\x1b]99;i=1:d=0;${title}\x1b\\`);
	process.stdout.write(`\x1b]99;i=1:p=body;${body}\x1b\\`);
}

function notifyWindows(title: string, body: string): void {
	const { execFile } = require("child_process");
	execFile("powershell.exe", ["-NoProfile", "-Command", windowsToastScript(title, body)]);
}

function notifyMacOSToast(title: string, body: string): void {
	const { execFile } = require("child_process");
	execFile("osascript", ["-e", `display notification "${body}" with title "${title}"`]);
}

function notify(title: string, body: string): void {
	if (process.env.WT_SESSION) {
		notifyWindows(title, body);
	} else if (process.env.KITTY_WINDOW_ID) {
		notifyOSC99(title, body);
	} else if (process.platform === "darwin" && !/iTerm|ghostty|wezterm/i.test(process.env.TERM_PROGRAM || "")) {
		// Terminal.app et al. don't render OSC 777; use a native macOS notification.
		notifyMacOSToast(title, body);
	} else {
		notifyOSC777(title, body);
	}
}

export default function (pi: ExtensionAPI) {
	// Notify only when the user is NOT looking at the terminal.
	// undefined = no focus signal yet (terminal without DECSET 1004 support,
	// or tmux without focus-events) → fall back to the old always-notify behavior.
	let focused: boolean | undefined;
	let hooked = false;

	pi.on("session_start", (_event, ctx) => {
		if (ctx.mode !== "tui" || hooked) return;
		hooked = true;
		ctx.ui.setWidget("notify-focus-watch", (tui) => {
			process.stdout.write("\x1b[?1004h"); // enable terminal focus reporting
			tui.addInputListener((data: string) => {
				if (data === "\x1b[I") {
					focused = true;
					return { consume: true };
				}
				if (data === "\x1b[O") {
					focused = false;
					return { consume: true };
				}
				return undefined;
			});
			// zero-height widget: we only wanted the TUI instance
			return { render: () => [], invalidate: () => {} };
		});
	});

	pi.on("session_shutdown", () => {
		if (hooked) process.stdout.write("\x1b[?1004l");
	});

	// `agent_end` fires after each low-level run; Pi may still retry, compact,
	// or continue with queued follow-ups. Notify only after the full run settles.
	pi.on("agent_settled", async () => {
		if (focused === false) return; // user is watching the terminal
		notify("Pi", "Ready for input");
	});
}
