/**
 * ssh-tools.ts — SSH teleport mode for pi
 *
 * Fork of @ogulcancelik/pi-ssh-tools (MIT), redesigned:
 * - Overrides the built-in read/write/edit/bash tools (state-aware passthrough)
 *   instead of adding ssh_* prefixed tools. /ssh on  = all four tools run on
 *   the remote host; /ssh off = identical to stock pi.
 * - Connection history in <agentDir>/ssh-tools-history.json
 * - Remote directory picker with typing/autocompletion: /ssh <host> or /ssh cd (no arg)
 *
 * Commands:
 *   /ssh                     pick from history + ~/.ssh/config hosts
 *   /ssh <host>              connect, then browse directories level by level
 *   /ssh <host>:/abs/path    connect directly to a full remote path
 *   /ssh cd [path]           change remote working dir while connected
 *   /ssh off | status
 */

import { spawn } from "node:child_process";
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import {
	getAgentDir,
	type BashOperations,
	createBashToolDefinition,
	createEditToolDefinition,
	createReadToolDefinition,
	createWriteToolDefinition,
	type EditOperations,
	type ExtensionAPI,
	type ExtensionCommandContext,
	type ExtensionContext,
	type ReadOperations,
	type WriteOperations,
} from "@earendil-works/pi-coding-agent";
import { DynamicBorder } from "@earendil-works/pi-coding-agent";
import { Container, Key, Text, type SelectItem, SelectList, decodeKittyPrintable, matchesKey } from "@earendil-works/pi-tui";
import { extname, join } from "node:path";

const SSH_STATUS_KEY = "ssh-tools";
const SSH_CONFIG_PATH = join(homedir(), ".ssh", "config");
const HISTORY_PATH = join(getAgentDir(), "ssh-tools-history.json");
const HISTORY_LIMIT = 50;
const CONTROL_TIMEOUT_S = 15;

type SshProfile = {
	name: string;
	remote: string;
	cwd?: string;
};

type ActiveSshTarget = {
	name: string;
	remote: string;
	remoteCwd: string;
};

type SshExecOptions = {
	stdin?: string | Buffer;
	signal?: AbortSignal;
	onStdoutData?: (data: Buffer) => void;
	onStderrData?: (data: Buffer) => void;
	timeoutSeconds?: number;
};

function shellQuote(value: string): string {
	return `'${value.replaceAll("'", `'"'"'`)}'`;
}

function normalizeRemoteDir(path: string): string {
	return path.length > 1 ? path.replace(/\/+$/, "") : path;
}

async function resolveRemoteDir(remote: string, dir: string): Promise<string> {
	const out = await sshOk(remote, `cd ${cdExprFor(dir)} && pwd`, { timeoutSeconds: CONTROL_TIMEOUT_S });
	return out.toString("utf8").trim();
}

function sshExec(remote: string, command: string, options: SshExecOptions = {}) {
	return new Promise<{ stdout: Buffer; stderr: Buffer; exitCode: number | null }>((resolve, reject) => {
		const child = spawn("ssh", [remote, command], { stdio: ["pipe", "pipe", "pipe"] });
		const stdoutChunks: Buffer[] = [];
		const stderrChunks: Buffer[] = [];
		let timedOut = false;
		const timer =
			typeof options.timeoutSeconds === "number" && options.timeoutSeconds > 0
				? setTimeout(() => {
						timedOut = true;
						child.kill();
					}, options.timeoutSeconds * 1000)
				: undefined;

		const cleanup = () => {
			if (timer) clearTimeout(timer);
			if (options.signal) options.signal.removeEventListener("abort", onAbort);
		};

		const onAbort = () => {
			child.kill();
		};

		child.stdout.on("data", (data: Buffer) => {
			stdoutChunks.push(data);
			options.onStdoutData?.(data);
		});
		child.stderr.on("data", (data: Buffer) => {
			stderrChunks.push(data);
			options.onStderrData?.(data);
		});
		child.on("error", (error) => {
			cleanup();
			reject(error);
		});
		child.on("close", (exitCode) => {
			cleanup();
			if (options.signal?.aborted) {
				reject(new Error("aborted"));
				return;
			}
			if (timedOut) {
				reject(new Error(`timeout:${options.timeoutSeconds}`));
				return;
			}
			resolve({
				stdout: Buffer.concat(stdoutChunks),
				stderr: Buffer.concat(stderrChunks),
				exitCode,
			});
		});

		if (options.signal) {
			if (options.signal.aborted) {
				onAbort();
			} else {
				options.signal.addEventListener("abort", onAbort, { once: true });
			}
		}

		if (options.stdin !== undefined) {
			child.stdin.write(options.stdin);
		}
		child.stdin.end();
	});
}

async function sshOk(remote: string, command: string, options: SshExecOptions = {}): Promise<Buffer> {
	const { stdout, stderr, exitCode } = await sshExec(remote, command, options);
	if (exitCode !== 0) {
		const errorText = stderr.toString("utf8").trim() || stdout.toString("utf8").trim() || "unknown ssh error";
		throw new Error(`SSH failed (${exitCode}): ${errorText}`);
	}
	return stdout;
}

// ── remote tool operations ────────────────────────────────────────────────

function inferImageMimeType(path: string): string | null {
	switch (extname(path).toLowerCase()) {
		case ".jpg":
		case ".jpeg":
			return "image/jpeg";
		case ".png":
			return "image/png";
		case ".gif":
			return "image/gif";
		case ".webp":
			return "image/webp";
		default:
			return null;
	}
}

function createRemoteReadOps(target: ActiveSshTarget): ReadOperations {
	return {
		readFile: (absolutePath) => sshOk(target.remote, `cat ${shellQuote(absolutePath)}`),
		access: (absolutePath) => sshOk(target.remote, `test -r ${shellQuote(absolutePath)}`).then(() => {}),
		detectImageMimeType: async (absolutePath) => inferImageMimeType(absolutePath),
	};
}

function createRemoteWriteOps(target: ActiveSshTarget): WriteOperations {
	return {
		writeFile: async (absolutePath, content) => {
			await sshOk(target.remote, `cat > ${shellQuote(absolutePath)}`, { stdin: content });
		},
		mkdir: (dir) => sshOk(target.remote, `mkdir -p ${shellQuote(dir)}`).then(() => {}),
	};
}

function createRemoteEditOps(target: ActiveSshTarget): EditOperations {
	const inside = (absolutePath: string) => {
		const base = normalizeRemoteDir(target.remoteCwd);
		if (absolutePath === base || absolutePath.startsWith(`${base}/`)) {
			return absolutePath;
		}
		throw new Error(`Path ${absolutePath} is outside the active SSH working directory ${target.remoteCwd}.`);
	};
	return {
		readFile: (absolutePath) => sshOk(target.remote, `cat ${shellQuote(inside(absolutePath))}`),
		writeFile: async (absolutePath, content) => {
			await sshOk(target.remote, `cat > ${shellQuote(inside(absolutePath))}`, { stdin: content });
		},
		access: (absolutePath) => {
			return sshOk(target.remote, `test -r ${shellQuote(inside(absolutePath))} && test -w ${shellQuote(inside(absolutePath))}`).then(() => {});
		},
	};
}

function createRemoteBashOps(target: ActiveSshTarget): BashOperations {
	return {
		exec: async (command, cwd, { onData, signal, timeout }) => {
			const script = `cd ${shellQuote(cwd)}\n${command}\n`;
			const { exitCode } = await sshExec(target.remote, "exec bash -se", {
				stdin: script,
				signal,
				timeoutSeconds: timeout,
				onStdoutData: onData,
				onStderrData: onData,
			});
			return { exitCode };
		},
	};
}

// ── history ───────────────────────────────────────────────────────────────

type HistoryEntry = { host: string; cwd: string; ts: number };

function loadHistory(): HistoryEntry[] {
	try {
		const arr: unknown = JSON.parse(readFileSync(HISTORY_PATH, "utf8"));
		return Array.isArray(arr)
			? arr.filter((e): e is HistoryEntry => !!e && typeof e.host === "string" && typeof e.cwd === "string")
			: [];
	} catch {
		return [];
	}
}

function remember(host: string, cwd: string): void {
	const entries = loadHistory().filter((e) => !(e.host === host && e.cwd === cwd));
	entries.unshift({ host, cwd, ts: Date.now() });
	try {
		writeFileSync(HISTORY_PATH, JSON.stringify(entries.slice(0, HISTORY_LIMIT), null, 1) + "\n");
	} catch {
		// history is best-effort
	}
}

function recentDir(host: string): string | undefined {
	return loadHistory().find((e) => e.host === host)?.cwd;
}

// ── remote directory picker ─────────────────────────────────────────────

function joinRemote(base: string, name: string): string {
	return base === "/" ? `/${name}` : `${base}/${name}`;
}

/** Shell expression for a user-typed path: unquoted ~ so the remote expands $HOME. */
function cdExprFor(path: string): string {
	if (path === "~") return "$HOME";
	if (path.startsWith("~/")) return `"$HOME/${path.slice(2)}"`;
	return shellQuote(path);
}

async function listRemoteDirs(remote: string, dir: string): Promise<string[]> {
	const out = await sshOk(remote, `cd ${shellQuote(dir)} && find . -mindepth 1 -maxdepth 1 -type d -print 2>/dev/null`, { timeoutSeconds: CONTROL_TIMEOUT_S });
	return out
		.toString("utf8")
		.split("\n")
		.map((l) => l.trim().replace(/^\.\//, ""))
		.filter(Boolean);
}

/**
 * Probe a path remotely in one ssh call.
 * isDir=true when it resolves to a directory; otherwise matches are the
 * directories whose names start with the typed path (relative to base, or
 * absolute when the typed path was absolute / ~).
 */
async function probeRemoteDir(remote: string, base: string, typed: string): Promise<{ isDir: boolean; matches: string[] }> {
	const expr = typed.startsWith("/") || typed.startsWith("~") ? cdExprFor(typed) : shellQuote(typed);
	// bash -se via stdin: the remote login shell is zsh, whose NOMATCH aborts unmatched globs.
	const script = `cd ${shellQuote(base)}
p=${expr}
if [ -d "$p" ]; then echo __DIR__; else ls -d "$p"*/ 2>/dev/null | head -50; fi
`;
	const out = await sshOk(remote, "bash -se", { stdin: script, timeoutSeconds: CONTROL_TIMEOUT_S });
	const lines = out.toString("utf8").split("\n").map((l) => l.trim()).filter(Boolean);
	if (lines[0] === "__DIR__") return { isDir: true, matches: [] };
	return { isDir: false, matches: lines.map((l) => l.replace(/\/+$/, "")) };
}

async function chooseRemoteDir(remote: string, startDir: string, ctx: ExtensionCommandContext): Promise<string | null> {
	if (ctx.mode === "tui") {
		return remoteDirPicker(remote, startDir, ctx);
	}
	return chooseRemoteDirInput(remote, startDir, ctx);
}

/**
 * fzf-style picker: one persistent custom TUI screen. Listing the current
 * level costs one ssh; typing filters locally (SelectList prefix match).
 * Enter with no local match resolves the typed text as a remote path.
 */
async function remoteDirPicker(remote: string, startDir: string, ctx: ExtensionCommandContext): Promise<string | null> {
	return ctx.ui.custom<string | null>((tui, theme, _keybindings, done) => {
		let dir = startDir;
		let filter = "";
		let loading = false;
		let finished = false;
		let items: SelectItem[] = [];
		const dirCache = new Map<string, string[]>();

		const selectList = new SelectList([], 10, {
			selectedPrefix: (t) => theme.fg("accent", t),
			selectedText: (t) => theme.fg("accent", t),
			description: (t) => theme.fg("muted", t),
			scrollInfo: (t) => theme.fg("dim", t),
			noMatch: (t) => theme.fg("warning", t),
		});
		const header = new Text(theme.fg("accent", theme.bold(`SSH ${remote}`)));
		const cwdLine = new Text("");
		const stateLine = new Text("");
		const hint = new Text(theme.fg("dim", "↑↓ move · enter descend/confirm · esc cancel · type to filter · no match: enter = try as path"));
		const container = new Container();
		container.addChild(new DynamicBorder((s) => theme.fg("accent", s)));
		container.addChild(header);
		container.addChild(cwdLine);
		container.addChild(selectList);
		container.addChild(stateLine);
		container.addChild(hint);
		container.addChild(new DynamicBorder((s) => theme.fg("accent", s)));

		const setState = (text: string, color?: "muted" | "warning" | "error" | "dim") => {
			stateLine.setText(color ? theme.fg(color, text) : text);
			tui.requestRender();
		};

		const applyFilter = () => {
			(selectList as unknown as { items: SelectItem[] }).items = items;
			selectList.setFilter(filter);
			tui.requestRender();
		};

		const matchesCount = () => items.filter((i) => i.value.toLowerCase().startsWith(filter.toLowerCase())).length;

		const refreshList = async () => {
			loading = true;
			cwdLine.setText(theme.fg("muted", `cwd: ${dir}`));
			setState("listing…", "dim");
			tui.requestRender();
			try {
				let dirs = dirCache.get(dir);
				if (!dirs) {
					dirs = await listRemoteDirs(remote, dir);
					dirCache.set(dir, dirs);
				}
				items = [
					{ value: ".", label: "✓ use this directory" },
					...(dir === "/" ? [] : [{ value: "..", label: ".." }]),
					...[...dirs].sort((a, b) => a.localeCompare(b)).map((d) => ({ value: d, label: d })),
				];
				filter = "";
				setState("");
			} catch (error) {
				items = [];
				setState((error as Error).message, "error");
			}
			loading = false;
			applyFilter();
		};

		const probeAndJump = async () => {
			const value = filter;
			loading = true;
			setState(`resolving ${value} …`, "dim");
			tui.requestRender();
			try {
				const probeBase = value.startsWith("/") || value.startsWith("~") ? "/" : dir;
				const { isDir, matches } = await probeRemoteDir(remote, probeBase, value);
				if (isDir) {
					dir = await resolveRemoteDir(remote, value.startsWith("/") || value.startsWith("~") ? value : joinRemote(dir, value));
				} else if (matches.length === 1) {
					dir = matches[0].startsWith("/") ? matches[0] : joinRemote(probeBase, matches[0]);
				} else if (matches.length === 0) {
					loading = false;
					setState(`no match for "${value}"`, "warning");
					return;
				} else {
					loading = false;
					setState(`${matches.length} matches — type more to narrow`, "warning");
					return;
				}
				filter = "";
				await refreshList();
			} catch (error) {
				loading = false;
				setState((error as Error).message, "error");
			}
		};

		selectList.onSelect = (item) => {
			if (finished || loading) return;
			if (item.value === ".") {
				finished = true;
				done(dir);
				return;
			}
			if (item.value === "..") {
				dir = dir.length > 1 ? dir.slice(0, dir.lastIndexOf("/")) || "/" : "/";
				void refreshList();
				return;
			}
			dir = joinRemote(dir, item.value);
			void refreshList();
		};
		selectList.onCancel = () => {
			if (!finished) {
				finished = true;
				done(null);
			}
		};

		void refreshList();

		return {
			render(width: number) {
				return container.render(width);
			},
			invalidate() {
				container.invalidate();
			},
			handleInput(data: string) {
				if (finished) return;
				if (data.includes("\x1b[200~")) {
					// bracketed paste: strip markers, append payload to filter
					filter += data.replace("\x1b[200~", "").replace(/\x1b\[201~.*$/, "");
					applyFilter();
					return;
				}
				if (matchesKey(data, Key.backspace)) {
					filter = filter.slice(0, -1);
					applyFilter();
					return;
				}
				const ch = data.length === 1 && data.charCodeAt(0) >= 32 ? data : decodeKittyPrintable(data) ?? undefined;
				if (ch) {
					filter += ch;
					applyFilter();
					return;
				}
				if (matchesKey(data, Key.enter) && filter.length > 0 && matchesCount() === 0) {
					void probeAndJump();
					return;
				}
				selectList.handleInput(data);
				tui.requestRender();
			},
		};
	});
}

/** Fallback for non-TUI modes (print/rpc): dialog loop. */
async function chooseRemoteDirInput(remote: string, startDir: string, ctx: ExtensionCommandContext): Promise<string | null> {
	let dir = startDir;
	while (true) {
		const typed = await ctx.ui.input(`SSH dir on ${remote} — type a path (empty = use current, .. = up)`, dir);
		if (typed === undefined) return null;
		const value = typed.trim();
		if (value === "" || value === ".") return dir;
		if (value === "..") {
			dir = dir.length > 1 ? dir.slice(0, dir.lastIndexOf("/")) || "/" : "/";
			ctx.ui.notify(`SSH dir: ${dir}`, "info");
			continue;
		}
		const probeBase = value.startsWith("/") || value.startsWith("~") ? "/" : dir;
		const { isDir, matches } = await probeRemoteDir(remote, probeBase, value);
		if (isDir) {
			dir = await resolveRemoteDir(remote, value.startsWith("/") || value.startsWith("~") ? value : joinRemote(dir, value));
			return dir;
		}
		const resolveMatch = (m: string) => (m.startsWith("/") ? m : joinRemote(probeBase, m));
		if (matches.length === 0) {
			ctx.ui.notify(`No directory matching "${value}" under ${probeBase}`, "warning");
			continue;
		}
		if (matches.length === 1) {
			dir = resolveMatch(matches[0]);
			ctx.ui.notify(`Auto-completed → ${dir}`, "info");
			continue;
		}
		const picked = await ctx.ui.select(`${remote}:${probeBase} — matches for "${value}"`, matches.map(resolveMatch).sort((a, b) => a.localeCompare(b)));
		if (!picked) continue;
		dir = picked;
	}
}

// ── ~/.ssh/config profiles ────────────────────────────────────────────────

function parseSshConfigProfiles(): SshProfile[] {
	if (!existsSync(SSH_CONFIG_PATH)) {
		return [];
	}

	const text = readFileSync(SSH_CONFIG_PATH, "utf8");
	const profiles = new Map<string, SshProfile>();

	for (const rawLine of text.split("\n")) {
		const withoutComment = rawLine.replace(/\s+#.*$/, "").trim();
		if (!withoutComment) continue;

		const match = withoutComment.match(/^Host\s+(.+)$/i);
		if (!match) continue;

		const aliases = match[1]
			.split(/\s+/)
			.map((alias) => alias.trim())
			.filter(Boolean)
			.filter((alias) => !alias.includes("*") && !alias.includes("?") && !alias.startsWith("!"));

		for (const alias of aliases) {
			if (!profiles.has(alias)) {
				profiles.set(alias, { name: alias, remote: alias });
			}
		}
	}

	return Array.from(profiles.values()).sort((a, b) => a.name.localeCompare(b.name));
}

// ── extension ─────────────────────────────────────────────────────────────

export default function sshToolsExtension(pi: ExtensionAPI) {
	let activeTarget: ActiveSshTarget | null = null;

	const withCwd = <T>(ctx: T, cwd: string): T => {
		if (ctx === undefined || ctx === null || typeof ctx !== "object") {
			return ctx;
		}
		const copy = Object.defineProperties({}, Object.getOwnPropertyDescriptors(ctx));
		delete (copy as Record<string, unknown>).cwd;
		Object.defineProperty(copy, "cwd", { value: cwd, enumerable: true, configurable: true, writable: true });
		return copy;
	};

	const updateStatus = (ctx: ExtensionContext) => {
		if (!activeTarget) {
			ctx.ui.setStatus(SSH_STATUS_KEY, undefined);
			return;
		}
		ctx.ui.setStatus(
			SSH_STATUS_KEY,
			ctx.ui.theme.fg("accent", `SSH ${activeTarget.name}:${activeTarget.remoteCwd}`),
		);
	};

	const deactivate = (ctx: ExtensionCommandContext) => {
		if (!activeTarget) {
			ctx.ui.notify("SSH mode is already off", "info");
			return;
		}
		activeTarget = null;
		updateStatus(ctx);
		ctx.ui.notify("SSH off — read/write/edit/bash back on the local machine", "info");
	};

	const activate = async (profile: SshProfile, ctx: ExtensionCommandContext) => {
		let dir: string;
		if (profile.cwd?.trim()) {
			dir = await resolveRemoteDir(profile.remote, profile.cwd.trim());
		} else {
			const start = (await recentDir(profile.remote)) ?? (await sshOk(profile.remote, "pwd", { timeoutSeconds: CONTROL_TIMEOUT_S })).toString("utf8").trim();
			const picked = await chooseRemoteDir(profile.remote, start, ctx);
			if (!picked) {
				ctx.ui.notify("SSH connect cancelled", "info");
				return;
			}
			dir = picked;
		}
		activeTarget = { name: profile.name, remote: profile.remote, remoteCwd: dir };
		remember(profile.remote, dir);
		updateStatus(ctx);
		ctx.ui.notify(`SSH on: ${activeTarget.name} (${dir}) — read/write/edit/bash now run remotely`, "info");
	};

	const handleTarget = async (input: string, ctx: ExtensionCommandContext) => {
		if (input === "off") {
			deactivate(ctx);
			return;
		}
		const separatorIndex = input.indexOf(":");
		let profile: SshProfile;
		if (separatorIndex > 0 && input.slice(separatorIndex + 1).startsWith("/")) {
			profile = { name: input.slice(0, separatorIndex), remote: input.slice(0, separatorIndex), cwd: input.slice(separatorIndex + 1) };
		} else {
			profile = { name: input, remote: input };
		}
		await activate(profile, ctx);
	};

	const handleCd = async (arg: string, ctx: ExtensionCommandContext) => {
		if (!activeTarget) {
			ctx.ui.notify("SSH mode is off. Use /ssh <host> first.", "warning");
			return;
		}
		let dir: string;
		if (arg) {
			dir = arg.startsWith("/") ? arg : `${normalizeRemoteDir(activeTarget.remoteCwd)}/${arg}`;
		} else {
			const picked = await chooseRemoteDir(activeTarget.remote, activeTarget.remoteCwd, ctx);
			if (!picked) {
				ctx.ui.notify("cd cancelled", "info");
				return;
			}
			dir = picked;
		}
		dir = await resolveRemoteDir(activeTarget.remote, dir);
		activeTarget = { ...activeTarget, remoteCwd: dir };
		remember(activeTarget.remote, dir);
		updateStatus(ctx);
		ctx.ui.notify(`SSH cwd: ${dir}`, "info");
	};

	pi.registerCommand("ssh", {
		description: "Teleport pi to a remote host: /ssh, /ssh <host>[:/path], /ssh cd [path], /ssh off, /ssh status",
		getArgumentCompletions: (prefix) => {
			const options = ["off", "status", "cd", ...loadHistory().map((h) => `${h.host}:${h.cwd}`), ...parseSshConfigProfiles().map((p) => p.name)];
			const filtered = options.filter((option) => option.startsWith(prefix));
			return filtered.length > 0 ? filtered.map((value) => ({ value, label: value })) : null;
		},
		handler: async (args, ctx) => {
			const input = args.trim();
			try {
				if (input === "status") {
					if (!activeTarget) {
						ctx.ui.notify("SSH mode is off", "info");
						return;
					}
					ctx.ui.notify(`SSH mode: ${activeTarget.name} (${activeTarget.remote}:${activeTarget.remoteCwd})`, "info");
					return;
				}
				if (input === "off") {
					deactivate(ctx);
					return;
				}
				if (input === "" ) {
					const items = [
						...(activeTarget ? ["off"] : []),
						...loadHistory().map((h) => `${h.host}:${h.cwd}`),
						...parseSshConfigProfiles().map((p) => p.name),
					];
					if (items.length === 0) {
						ctx.ui.notify("No SSH hosts in history or ~/.ssh/config. Use /ssh <host>[:/path]", "warning");
						return;
					}
					const picked = await ctx.ui.select("SSH target (history first, then ~/.ssh/config)", items);
					if (!picked) return;
					await handleTarget(picked, ctx);
					return;
				}
				if (input === "cd" || input.startsWith("cd ")) {
					await handleCd(input.startsWith("cd ") ? input.slice(3).trim() : "", ctx);
					return;
				}
				await handleTarget(input, ctx);
			} catch (error) {
				ctx.ui.notify(`SSH: ${(error as Error).message}`, "error");
			}
		},
	});

	// State-aware passthrough overrides of the built-in file/shell tools.
	// Off: delegates to the stock definitions (identical behavior to stock pi).
	// On:  re-resolves the same definitions against the remote host per call.
	const passthrough = (base: any, makeRemote: (t: ActiveSshTarget) => any): any => ({
		...base,
		execute: async (toolCallId: string, params: any, signal: any, onUpdate: any, ctx: ExtensionContext) => {
			const target = activeTarget;
			if (!target) {
				return base.execute(toolCallId, params, signal, onUpdate, ctx);
			}
			const tool = makeRemote(target);
			return tool.execute(toolCallId, params, signal, onUpdate, withCwd(ctx, target.remoteCwd));
		},
	});

	const localCwd = process.cwd();
	pi.registerTool(passthrough(createReadToolDefinition(localCwd), (t) => createReadToolDefinition(t.remoteCwd, { operations: createRemoteReadOps(t) })));
	pi.registerTool(passthrough(createWriteToolDefinition(localCwd), (t) => createWriteToolDefinition(t.remoteCwd, { operations: createRemoteWriteOps(t) })));
	pi.registerTool(passthrough(createEditToolDefinition(localCwd), (t) => createEditToolDefinition(t.remoteCwd, { operations: createRemoteEditOps(t) })));
	pi.registerTool(passthrough(createBashToolDefinition(localCwd), (t) => createBashToolDefinition(t.remoteCwd, { operations: createRemoteBashOps(t) })));

	pi.on("session_start", async (_event, ctx) => {
		activeTarget = null;
		updateStatus(ctx);
	});

	pi.on("before_agent_start", async (event) => {
		if (!activeTarget) {
			return;
		}
		return {
			systemPrompt:
				event.systemPrompt +
				`\n\nSSH mode is active for this run. The session working directory is REMOTE: host ${activeTarget.remote}, directory ${activeTarget.remoteCwd}.\n` +
				`read, write, edit, and bash all execute on that remote host; relative paths resolve against ${activeTarget.remoteCwd}.\n` +
				`Use bash for remote listing and search (ls, rg, find). MCP and web tools still run locally.`,
		};
	});
}
