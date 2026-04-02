function requireEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

const ollamaBaseURL = Deno.env.get("OLLAMA_BASE_URL") ?? "https://ollama.com";
const ollamaAPIKey = requireEnv("OLLAMA_API_KEY");
const timeoutMs = Number(Deno.env.get("OLLAMA_REQUEST_TIMEOUT_MS") ?? "60000");

export const ollamaModels = {
  chat: Deno.env.get("OLLAMA_DEFAULT_MODEL") ?? "gpt-oss:20b-cloud",
  vision: Deno.env.get("OLLAMA_VISION_MODEL") ?? "gemma3",
  memory: Deno.env.get("OLLAMA_MEMORY_MODEL") ?? (Deno.env.get("OLLAMA_DEFAULT_MODEL") ?? "gpt-oss:20b-cloud"),
};

export async function ollamaChat(body: Record<string, unknown>) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort("Ollama request timed out."), timeoutMs);

  try {
    const response = await fetch(new URL("/api/chat", ollamaBaseURL), {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${ollamaAPIKey}`,
      },
      body: JSON.stringify({
        stream: false,
        ...body,
      }),
      signal: controller.signal,
    });

    if (!response.ok) {
      const text = await response.text();
      throw new Error(`Ollama request failed: ${response.status} ${text}`);
    }

    return await response.json();
  } finally {
    clearTimeout(timeout);
  }
}

