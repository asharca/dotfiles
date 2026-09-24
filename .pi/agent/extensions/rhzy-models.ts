import { readFile } from "node:fs/promises";
import type { ExtensionAPI, ProviderModelConfig } from "@earendil-works/pi-coding-agent";
import type { RefreshModelsContext } from "@earendil-works/pi-ai";

const BASE_URL = "https://model.rhzy.ai/v1";
const COST = { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 };
const REASONING = ["low", "medium", "high"];

// Context windows researched from z.ai docs / zhipu pricing pages (2026-07).
type Meta = { ctx: number; out?: number; reasoning?: boolean; image?: boolean };

// GPT models from pi-ai openai.json (2026-07); codex-only entries from codex-models.json.
const GPT: Record<string, Meta> = {
  "codex-auto-review": { ctx: 272_000, reasoning: true },
  "gpt-4o-audio-preview": { ctx: 272_000 },
  "gpt-4o-realtime-preview": { ctx: 272_000 },
  "gpt-5.2": { ctx: 400_000, out: 128_000, reasoning: true, image: true },
  "gpt-5.2-2025-12-11": { ctx: 400_000, out: 128_000, reasoning: true, image: true },
  "gpt-5.2-chat-latest": { ctx: 128_000, out: 16_384, reasoning: true, image: true },
  "gpt-5.2-pro": { ctx: 400_000, out: 128_000, reasoning: true, image: true },
  "gpt-5.2-pro-2025-12-11": { ctx: 400_000, out: 128_000, reasoning: true, image: true },
  "gpt-5.3-codex-spark": { ctx: 128_000, out: 32_000, reasoning: true, image: true },
  "gpt-5.4": { ctx: 272_000, out: 128_000, reasoning: true, image: true },
  "gpt-5.4-2026-03-05": { ctx: 272_000, out: 128_000, reasoning: true, image: true },
  "gpt-5.4-mini": { ctx: 400_000, out: 128_000, reasoning: true, image: true },
  "gpt-5.5": { ctx: 272_000, out: 128_000, reasoning: true, image: true },
  "gpt-5.6": { ctx: 272_000, out: 128_000, reasoning: true, image: true },
  "gpt-5.6-luna": { ctx: 272_000, out: 128_000, reasoning: true, image: true },
  "gpt-5.6-sol": { ctx: 272_000, out: 128_000, reasoning: true, image: true },
  "gpt-5.6-terra": { ctx: 272_000, out: 128_000, reasoning: true, image: true },
  "gpt-6": { ctx: 272_000, out: 128_000, reasoning: true, image: true },
  "gpt-6-astra": { ctx: 272_000, out: 128_000, reasoning: true, image: true },
  "gpt-6-luna": { ctx: 272_000, out: 128_000, reasoning: true, image: true },
  "gpt-6-sol": { ctx: 272_000, out: 128_000, reasoning: true, image: true },
  "gpt-reserve": { ctx: 272_000 },
};

const GLM: Record<string, Meta> = {
  // legacy chatglm (2023-24)
  chatglm_lite: { ctx: 2_048 },
  chatglm_std: { ctx: 2_048 },
  chatglm_pro: { ctx: 2_048 },
  chatglm_turbo: { ctx: 4_096 },
  "glm-3-turbo": { ctx: 4_096 },
  "glm-4": { ctx: 4_096 },
  "glm-4-0520": { ctx: 4_096 },
  "glm-4-plus": { ctx: 128_000 },
  "glm-4-air": { ctx: 128_000 },
  "glm-4-airx": { ctx: 128_000 },
  "glm-4-flash": { ctx: 8_192 },
  "glm-4-long": { ctx: 1_000_000 },
  "glm-4-alltools": { ctx: 4_096 },
  "glm-4v": { ctx: 4_096, image: true },
  "glm-4v-plus": { ctx: 4_096, image: true },
  // current series (z.ai docs)
  "glm-4.5": { ctx: 128_000, reasoning: true },
  "glm-4.5-air": { ctx: 128_000, reasoning: true },
  "glm-4.5-flash": { ctx: 128_000, reasoning: true },
  "glm-4.5-x": { ctx: 128_000, reasoning: true },
  "glm-4.6": { ctx: 200_000, out: 131_072, reasoning: true },
  "glm-4.7": { ctx: 204_800, out: 131_072, reasoning: true },
  "glm-4.7-flash": { ctx: 200_000, reasoning: true },
  "glm-4.7-flashx": { ctx: 200_000, reasoning: true },
  "glm-5": { ctx: 200_000, out: 128_000, reasoning: true },
  "glm-5-turbo": { ctx: 200_000, reasoning: true },
  "glm-5.1": { ctx: 200_000, reasoning: true },
  "glm-5.2": { ctx: 1_000_000, reasoning: true },
  "glm-5.3": { ctx: 1_000_000, out: 131_072, reasoning: true },
  "glm-5.3-flash": { ctx: 1_000_000, reasoning: true, image: true },
};

// kimi-for-coding context from pi-ai kimi-coding.json; others from Moonshot official specs.
const KIMI: Record<string, Meta> = {
  "kimi-for-coding": { ctx: 1_048_576, out: 32_768, reasoning: true, image: true },
  // rolling alias, tracks the current 1M flagship
  "kimi-latest": { ctx: 1_048_576, out: 32_768, reasoning: true, image: true },
  "kimi-k2": { ctx: 131_072 },
  "moonshot-v1-8k": { ctx: 8_192 },
  "moonshot-v1-32k": { ctx: 32_768 },
  "moonshot-v1-128k": { ctx: 131_072 },
};

// M2.7/M3 from pi-ai minimax.json; M2/M2.1/M2.5/abab from MiniMax official docs.
const MINIMAX: Record<string, Meta> = {
  "MiniMax-M2": { ctx: 204_800, out: 131_072, reasoning: true },
  "MiniMax-M2.1": { ctx: 204_800, out: 131_072, reasoning: true },
  "MiniMax-M2.1-highspeed": { ctx: 204_800, out: 131_072, reasoning: true },
  "MiniMax-M2.5": { ctx: 204_800, out: 131_072, reasoning: true },
  "MiniMax-M2.5-highspeed": { ctx: 204_800, out: 131_072, reasoning: true },
  "MiniMax-M2.7": { ctx: 204_800, out: 131_072, reasoning: true },
  "MiniMax-M2.7-highspeed": { ctx: 204_800, out: 131_072, reasoning: true },
  "MiniMax-M3": { ctx: 1_048_576, out: 512_000, reasoning: true, image: true },
  "abab5.5-chat": { ctx: 8_192 },
  "abab5.5s-chat": { ctx: 8_192 },
  "abab6-chat": { ctx: 8_192 },
  "abab6.5-chat": { ctx: 245_760 },
  "abab6.5s-chat": { ctx: 245_760 },
  "abab6.5s-chat-pro": { ctx: 245_760 },
};

type RemoteModel = {
  id: string;
  display_name?: string;
  name?: string;
  context_window?: number;
  contextWindow?: number;
  max_context_length?: number;
  max_tokens?: number;
  maxTokens?: number;
  reasoning?: boolean;
  input?: ("text" | "image")[];
};

function positiveNumber(value: unknown): number | undefined {
  return typeof value === "number" && Number.isFinite(value) && value > 0 ? value : undefined;
}

async function fetchJson(url: string, signal: AbortSignal, apiKey?: string): Promise<unknown> {
  const response = await fetch(url, {
    signal,
    ...(apiKey ? { headers: { Authorization: `Bearer ${apiKey}` } } : {}),
  });
  if (!response.ok) throw new Error(`${response.status} ${response.statusText}`);
  return response.json();
}

async function modelConfig(
  model: RemoteModel,
  signal: AbortSignal,
  apiKey: string | undefined,
  meta: Record<string, Meta>,
): Promise<ProviderModelConfig> {
  let detail: RemoteModel = model;

  // The list endpoint currently omits context metadata; try the standard detail endpoint.
  try {
    const candidate = await fetchJson(`${BASE_URL}/models/${encodeURIComponent(model.id)}`, signal, apiKey);
    if (candidate && typeof candidate === "object") detail = { ...model, ...(candidate as RemoteModel) };
  } catch {
    // The list response remains usable when per-model metadata is unavailable.
  }

  const m = meta[detail.id];
  const contextWindow =
    positiveNumber(detail.context_window) ??
    positiveNumber(detail.contextWindow) ??
    positiveNumber(detail.max_context_length) ??
    m?.ctx ??
    (positiveNumber(Number(process.env.RHZY_CONTEXT_WINDOW)) ?? 128_000);
  const reasoning = (detail.reasoning ?? m?.reasoning) || /codex|reasoning/i.test(detail.id);

  return {
    id: detail.id,
    name: detail.display_name ?? detail.name ?? detail.id,
    reasoning,
    ...(reasoning ? { thinkingLevelMap: Object.fromEntries(REASONING.map((level) => [level, level])) } : {}),
    input: detail.input ?? (m?.image ? ["text", "image"] : ["text"]),
    cost: COST,
    contextWindow,
    maxTokens:
      positiveNumber(detail.max_tokens) ??
      positiveNumber(detail.maxTokens) ??
      m?.out ??
      Math.min(contextWindow, 32_768),
  };
}

async function refreshProviderModels(
  signal: AbortSignal,
  apiKey: string | undefined,
  meta: Record<string, Meta>,
): Promise<ProviderModelConfig[]> {
  const payload = (await fetchJson(`${BASE_URL}/models`, signal, apiKey)) as
    | { data?: RemoteModel[] }
    | RemoteModel[];
  const models = Array.isArray(payload) ? payload : payload.data;
  if (!models?.length) throw new Error("/v1/models returned no models");
  return Promise.all(
    models.filter((model) => model?.id).map((model) => modelConfig(model, signal, apiKey, meta)),
  );
}

async function configuredApiKey(provider: string): Promise<string | undefined> {
  try {
    const path = `${process.env.HOME}/.pi/agent/models.json`;
    const config = JSON.parse(await readFile(path, "utf8")) as {
      providers?: Record<string, { apiKey?: string }>;
    };
    return config.providers?.[provider]?.apiKey;
  } catch {
    return undefined;
  }
}

async function registerProviderAsync(
  pi: ExtensionAPI,
  id: string,
  api: "openai-responses" | "openai-completions",
  meta: Record<string, Meta>,
) {
  const apiKey = await configuredApiKey(id);
  let models: ProviderModelConfig[] | undefined;
  try {
    models = await refreshProviderModels(new AbortController().signal, apiKey, meta);
  } catch {
    // Keep models.json's last-known catalog when the endpoint is unavailable.
  }

  pi.registerProvider(id, {
    baseUrl: BASE_URL,
    api,
    apiKey,
    ...(models ? { models } : {}),
    refreshModels: async (context: RefreshModelsContext) => {
      const key = context.credential?.type === "api_key" ? context.credential.key : apiKey;
      return refreshProviderModels(context.signal, key, meta);
    },
  });
  pi.registerCommand(`refresh-${id}`, {
    description: `Refresh the ${id} model list and metadata`,
    handler: async (_args, ctx) => {
      await ctx.modelRegistry.refresh({ providers: [id], force: true });
      ctx.ui.notify(`${id} models refreshed`, "info");
    },
  });
}

export default async function (pi: ExtensionAPI) {
  await Promise.all([
    registerProviderAsync(pi, "rhzy-gpt", "openai-responses", GPT),
    registerProviderAsync(pi, "rhzy-glm", "openai-completions", GLM),
    registerProviderAsync(pi, "rhzy-kimi", "openai-completions", KIMI),
    registerProviderAsync(pi, "rhzy-minimax", "openai-completions", MINIMAX),
  ]);
}
