import { corsHeaders, empty, errorResponse, json } from "../_shared/cors.ts";
import { ollamaChat, ollamaModels } from "../_shared/ollama.ts";
import { adminClient, HttpError, requireUser } from "../_shared/supabaseAdmin.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const user = await requireUser(req);
    const route = extractRoute(req);
    const method = req.method.toUpperCase();

    if (route === "/v1/profile" && method === "GET") {
      return json({ profile: await buildProfileResponse(user.id, user.user_metadata ?? {}) });
    }

    if (route === "/v1/profile" && method === "PATCH") {
      const payload = await req.json();
      await ensureProfile(user.id, user.user_metadata ?? {});

      const updates = {
        display_name: readString(payload, "display_name", "displayName"),
        preferred_name: readString(payload, "preferred_name", "preferredName"),
        assistant_tone: readString(payload, "assistant_tone", "assistantTone"),
        support_style: readString(payload, "support_style", "supportStyle"),
        life_focuses: readArray(payload, "life_focuses", "lifeFocuses"),
        likes: readArray(payload, "likes"),
        dislikes: readArray(payload, "dislikes"),
        boundaries: readArray(payload, "boundaries"),
        onboarding_answers: readObject(payload, "onboarding_answers", "onboardingAnswers"),
        summary: readString(payload, "summary"),
        is_onboarding_complete: readBoolean(payload, "is_onboarding_complete", "isOnboardingComplete"),
      };

      const sanitized = Object.fromEntries(
        Object.entries(updates).filter(([, value]) => value !== undefined),
      );

      const { error } = await adminClient
        .from("profiles")
        .update(sanitized)
        .eq("user_id", user.id);

      if (error) {
        throw new HttpError(400, error.message);
      }

      return json({ profile: await buildProfileResponse(user.id, user.user_metadata ?? {}) });
    }

    if (route === "/v1/memories" && method === "GET") {
      const memories = await listMemories(user.id);
      return json({ memories });
    }

    if (route === "/v1/conversations" && method === "GET") {
      const url = new URL(req.url);
      const limit = Math.max(1, Math.min(20, Number(url.searchParams.get("limit") ?? "1")));
      const { data, error } = await adminClient
        .from("conversations")
        .select("id, title, last_message_at, created_at")
        .eq("user_id", user.id)
        .order("last_message_at", { ascending: false })
        .limit(limit);

      if (error) {
        throw new HttpError(400, error.message);
      }

      return json({
        conversations: (data ?? []).map((row) => ({
          id: row.id,
          title: row.title,
          lastMessageAt: row.last_message_at,
          createdAt: row.created_at,
        })),
      });
    }

    if (route.startsWith("/v1/conversations/") && method === "GET") {
      const conversationId = route.replace("/v1/conversations/", "");
      return json({ conversation: await buildConversationResponse(conversationId, user.id) });
    }

    if (route.startsWith("/v1/memories/") && route.endsWith("/feedback") && method === "POST") {
      const memoryId = route.replace("/v1/memories/", "").replace("/feedback", "");
      const payload = await req.json();
      const feedback = readString(payload, "feedback");

      if (!feedback || !["accepted", "rejected", "reinforced"].includes(feedback)) {
        throw new HttpError(400, "Feedback must be accepted, rejected, or reinforced.");
      }

      const { data: memory, error: memoryError } = await adminClient
        .from("memory_entries")
        .select("*")
        .eq("id", memoryId)
        .eq("user_id", user.id)
        .single();

      if (memoryError || !memory) {
        throw new HttpError(404, "Memory not found.");
      }

      const status = feedback === "rejected" ? "rejected" : "active";
      const { data: updated, error: updateError } = await adminClient
        .from("memory_entries")
        .update({
          status,
          last_reinforced_at: new Date().toISOString(),
        })
        .eq("id", memoryId)
        .eq("user_id", user.id)
        .select("*")
        .single();

      if (updateError || !updated) {
        throw new HttpError(400, updateError?.message ?? "Unable to update memory.");
      }

      const { error: feedbackError } = await adminClient
        .from("memory_feedback_events")
        .insert({
          memory_id: memoryId,
          user_id: user.id,
          feedback,
          note: readString(payload, "note"),
        });

      if (feedbackError) {
        throw new HttpError(400, feedbackError.message);
      }

      return json(toMemoryResponse(updated));
    }

    if (route.startsWith("/v1/memories/") && method === "PATCH") {
      const memoryId = route.replace("/v1/memories/", "");
      const payload = await req.json();

      const { data: updated, error } = await adminClient
        .from("memory_entries")
        .update({
          kind: readString(payload, "kind"),
          title: readString(payload, "title"),
          summary: readString(payload, "summary"),
          status: readString(payload, "status"),
        })
        .eq("id", memoryId)
        .eq("user_id", user.id)
        .select("*")
        .single();

      if (error || !updated) {
        throw new HttpError(400, error?.message ?? "Unable to update memory.");
      }

      return json(toMemoryResponse(updated));
    }

    if (route.startsWith("/v1/memories/") && method === "DELETE") {
      const memoryId = route.replace("/v1/memories/", "");
      const { error } = await adminClient
        .from("memory_entries")
        .delete()
        .eq("id", memoryId)
        .eq("user_id", user.id);

      if (error) {
        throw new HttpError(400, error.message);
      }

      return empty();
    }

    if (route === "/v1/media/analyze" && method === "POST") {
      const payload = await req.json();
      const conversationId = readString(payload, "conversation_id", "conversationId");
      const imageBase64 = readString(payload, "image_base64", "imageBase64");
      const contentType = readString(payload, "content_type", "contentType");
      const prompt = readString(payload, "prompt") ?? "Describe the useful context in this image for future conversation.";

      if (!imageBase64 || !contentType) {
        throw new HttpError(400, "image_base64 and content_type are required.");
      }

      if (!["image/jpeg", "image/png"].includes(contentType)) {
        throw new HttpError(400, "Only JPEG and PNG uploads are supported in v1.");
      }

      if (conversationId) {
        await ensureConversationOwnership(conversationId, user.id);
      }

      const bytes = decodeBase64(imageBase64);
      const ext = contentType === "image/png" ? "png" : "jpg";
      const storagePath = `${user.id}/${new Date().toISOString().slice(0, 10)}/${crypto.randomUUID()}.${ext}`;

      const { error: uploadError } = await adminClient
        .storage
        .from("media-assets")
        .upload(storagePath, bytes, {
          contentType,
          upsert: false,
        });

      if (uploadError) {
        throw new HttpError(400, uploadError.message);
      }

      let summary = "Image attached for context.";
      let analysisPayload: Record<string, unknown> = {};

      try {
        const analysis = await ollamaChat({
          model: ollamaModels.vision,
          messages: [
            {
              role: "user",
              content: prompt,
              images: [imageBase64],
            },
          ],
        });
        summary = analysis?.message?.content?.trim() || summary;
        analysisPayload = analysis;
      } catch (error) {
        console.error("Vision analysis failed", error);
      }

      const { data: asset, error: assetError } = await adminClient
        .from("media_assets")
        .insert({
          user_id: user.id,
          conversation_id: conversationId,
          storage_path: storagePath,
          content_type: contentType,
          byte_size: bytes.byteLength,
          prompt,
          analysis_summary: summary,
          analysis_payload: analysisPayload,
        })
        .select("*")
        .single();

      if (assetError || !asset) {
        throw new HttpError(400, assetError?.message ?? "Unable to persist media asset.");
      }

      return json({
        asset: toMediaAssetResponse(asset),
        summary,
      });
    }

    if (route === "/v1/chat" && method === "POST") {
      const payload = await req.json();
      const conversationId = readString(payload, "conversation_id", "conversationId");
      const message = (readString(payload, "message") ?? "").trim();
      const mediaAssetIds = readArray(payload, "media_asset_ids", "mediaAssetIds");

      if (!message && mediaAssetIds.length === 0) {
        throw new HttpError(400, "A message or at least one media asset is required.");
      }

      const profile = await ensureProfile(user.id, user.user_metadata ?? {});
      const memories = await listMemories(user.id, "active", 8);
      const conversation = await getOrCreateConversation(user.id, conversationId, message);
      const recentMessages = await fetchRecentMessages(conversation.id, user.id);
      const attachedAssets = await loadMediaAssets(user.id, mediaAssetIds);
      const imagePayloads = await Promise.all(attachedAssets.map(downloadStorageAssetAsBase64));

      const userMessageContent = message || "Use the attached image context in your response.";
      const { data: userMessageRow, error: userMessageError } = await adminClient
        .from("messages")
        .insert({
          conversation_id: conversation.id,
          user_id: user.id,
          role: "user",
          content: userMessageContent,
          meta: {
            media_asset_ids: attachedAssets.map((asset) => asset.id),
          },
        })
        .select("*")
        .single();

      if (userMessageError || !userMessageRow) {
        throw new HttpError(400, userMessageError?.message ?? "Unable to store the user message.");
      }

      if (attachedAssets.length > 0) {
        const { error: linkError } = await adminClient
          .from("media_assets")
          .update({
            conversation_id: conversation.id,
            message_id: userMessageRow.id,
          })
          .in("id", attachedAssets.map((asset) => asset.id))
          .eq("user_id", user.id);

        if (linkError) {
          throw new HttpError(400, linkError.message);
        }
      }

      const promptMessages = [
        { role: "system", content: buildSystemPrompt(profile, memories) },
        ...recentMessages.map((entry) => ({
          role: entry.role,
          content: entry.content,
        })),
        {
          role: "user",
          content: userMessageContent,
          ...(imagePayloads.length > 0 ? { images: imagePayloads } : {}),
        },
      ];

      const model = imagePayloads.length > 0 ? ollamaModels.vision : ollamaModels.chat;
      const generation = await ollamaChat({
        model,
        messages: promptMessages,
        think: "low",
      });

      const assistantContent = generation?.message?.content?.trim();
      if (!assistantContent) {
        throw new HttpError(502, "Ollama returned an empty completion.");
      }

      const { data: assistantMessageRow, error: assistantMessageError } = await adminClient
        .from("messages")
        .insert({
          conversation_id: conversation.id,
          user_id: user.id,
          role: "assistant",
          content: assistantContent,
          reasoning: typeof generation?.message?.thinking === "string" ? generation.message.thinking : null,
          meta: {
            model,
            done_reason: generation?.done_reason ?? null,
          },
        })
        .select("*")
        .single();

      if (assistantMessageError || !assistantMessageRow) {
        throw new HttpError(400, assistantMessageError?.message ?? "Unable to store the assistant reply.");
      }

      const title = conversation.title?.trim()
        ? conversation.title
        : inferConversationTitle(message || attachedAssets[0]?.analysis_summary || "New conversation");

      const { error: conversationUpdateError } = await adminClient
        .from("conversations")
        .update({
          title,
          last_message_at: new Date().toISOString(),
        })
        .eq("id", conversation.id)
        .eq("user_id", user.id);

      if (conversationUpdateError) {
        throw new HttpError(400, conversationUpdateError.message);
      }

      const suggestedMemories = await extractAndStoreMemories({
        userId: user.id,
        conversationId: conversation.id,
        profile,
        userMessage: userMessageContent,
        assistantMessage: assistantContent,
      });

      return json({
        conversation: await buildConversationResponse(conversation.id, user.id),
        profile: await buildProfileResponse(user.id, user.user_metadata ?? {}),
        suggestedMemories,
      });
    }

    return errorResponse(404, "Route not found.");
  } catch (error) {
    if (error instanceof HttpError) {
      return errorResponse(error.status, error.message);
    }

    console.error(error);
    return errorResponse(500, error instanceof Error ? error.message : "Unexpected server error.");
  }
});

function extractRoute(req: Request): string {
  const pathname = new URL(req.url).pathname;
  const marker = pathname.lastIndexOf("/v1/");
  return marker >= 0 ? pathname.slice(marker) : pathname;
}

function readString(payload: Record<string, unknown>, ...keys: string[]): string | undefined {
  for (const key of keys) {
    const value = payload[key];
    if (typeof value === "string") {
      return value;
    }
  }
  return undefined;
}

function readArray(payload: Record<string, unknown>, ...keys: string[]): string[] {
  for (const key of keys) {
    const value = payload[key];
    if (Array.isArray(value)) {
      return value.filter((entry): entry is string => typeof entry === "string");
    }
  }
  return [];
}

function readObject(payload: Record<string, unknown>, ...keys: string[]): Record<string, string> | undefined {
  for (const key of keys) {
    const value = payload[key];
    if (value && typeof value === "object" && !Array.isArray(value)) {
      return Object.fromEntries(
        Object.entries(value).filter(([, entry]) => typeof entry === "string"),
      ) as Record<string, string>;
    }
  }
  return undefined;
}

function readBoolean(payload: Record<string, unknown>, ...keys: string[]): boolean | undefined {
  for (const key of keys) {
    const value = payload[key];
    if (typeof value === "boolean") {
      return value;
    }
  }
  return undefined;
}

async function ensureProfile(userId: string, userMetadata: Record<string, unknown>) {
  const { data: existingProfile } = await adminClient
    .from("profiles")
    .select("*")
    .eq("user_id", userId)
    .maybeSingle();

  if (existingProfile) {
    return existingProfile;
  }

  const displayName = typeof userMetadata.full_name === "string" ? userMetadata.full_name : "";
  const { data: household, error: householdError } = await adminClient
    .from("households")
    .insert({
      name: displayName ? `${displayName}'s Household` : "My Household",
      created_by: userId,
    })
    .select("id")
    .single();

  if (householdError || !household) {
    throw new HttpError(400, householdError?.message ?? "Unable to create household.");
  }

  await adminClient
    .from("household_memberships")
    .upsert({
      household_id: household.id,
      user_id: userId,
      role: "owner",
    }, { onConflict: "user_id" });

  const { data: created, error: profileError } = await adminClient
    .from("profiles")
    .upsert({
      user_id: userId,
      household_id: household.id,
      display_name: displayName,
      preferred_name: displayName,
    }, { onConflict: "user_id" })
    .select("*")
    .single();

  if (profileError || !created) {
    throw new HttpError(400, profileError?.message ?? "Unable to create profile.");
  }

  return created;
}

async function buildProfileResponse(userId: string, userMetadata: Record<string, unknown>) {
  const profile = await ensureProfile(userId, userMetadata);
  const { data: membership } = await adminClient
    .from("household_memberships")
    .select("role, households(name)")
    .eq("user_id", userId)
    .maybeSingle();

  const householdName = Array.isArray(membership?.households)
    ? membership.households[0]?.name
    : membership?.households?.name;

  return {
    userId: profile.user_id,
    householdId: profile.household_id,
    householdName: householdName ?? null,
    householdRole: membership?.role ?? null,
    displayName: profile.display_name,
    preferredName: profile.preferred_name,
    assistantTone: profile.assistant_tone,
    supportStyle: profile.support_style,
    lifeFocuses: profile.life_focuses ?? [],
    likes: profile.likes ?? [],
    dislikes: profile.dislikes ?? [],
    boundaries: profile.boundaries ?? [],
    onboardingAnswers: profile.onboarding_answers ?? {},
    summary: profile.summary,
    isOnboardingComplete: profile.is_onboarding_complete,
    createdAt: profile.created_at,
    updatedAt: profile.updated_at,
  };
}

async function listMemories(userId: string, status?: string, limit = 50) {
  let query = adminClient
    .from("memory_entries")
    .select("*")
    .eq("user_id", userId)
    .order("updated_at", { ascending: false })
    .limit(limit);

  if (status) {
    query = query.eq("status", status);
  }

  const { data, error } = await query;
  if (error) {
    throw new HttpError(400, error.message);
  }

  return (data ?? []).map(toMemoryResponse);
}

function toMemoryResponse(row: Record<string, unknown>) {
  return {
    id: row.id,
    kind: row.kind,
    title: row.title,
    summary: row.summary,
    status: row.status,
    confidence: row.confidence,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    lastReinforcedAt: row.last_reinforced_at,
  };
}

function toMediaAssetResponse(row: Record<string, unknown>) {
  return {
    id: row.id,
    contentType: row.content_type,
    analysisSummary: row.analysis_summary,
    storagePath: row.storage_path,
    createdAt: row.created_at,
  };
}

async function ensureConversationOwnership(conversationId: string, userId: string) {
  const { data, error } = await adminClient
    .from("conversations")
    .select("id")
    .eq("id", conversationId)
    .eq("user_id", userId)
    .maybeSingle();

  if (error || !data) {
    throw new HttpError(404, "Conversation not found.");
  }
}

async function getOrCreateConversation(userId: string, conversationId: string | undefined, firstMessage: string) {
  if (conversationId) {
    const { data, error } = await adminClient
      .from("conversations")
      .select("*")
      .eq("id", conversationId)
      .eq("user_id", userId)
      .single();

    if (error || !data) {
      throw new HttpError(404, "Conversation not found.");
    }

    return data;
  }

  const { data, error } = await adminClient
    .from("conversations")
    .insert({
      user_id: userId,
      title: inferConversationTitle(firstMessage || "New conversation"),
    })
    .select("*")
    .single();

  if (error || !data) {
    throw new HttpError(400, error?.message ?? "Unable to create conversation.");
  }

  return data;
}

async function buildConversationResponse(conversationId: string, userId: string) {
  await ensureConversationOwnership(conversationId, userId);

  const { data: conversation, error: conversationError } = await adminClient
    .from("conversations")
    .select("id, title")
    .eq("id", conversationId)
    .eq("user_id", userId)
    .single();

  if (conversationError || !conversation) {
    throw new HttpError(404, "Conversation not found.");
  }

  const { data: messages, error: messagesError } = await adminClient
    .from("messages")
    .select("*")
    .eq("conversation_id", conversationId)
    .eq("user_id", userId)
    .order("created_at", { ascending: true });

  if (messagesError) {
    throw new HttpError(400, messagesError.message);
  }

  const { data: assets, error: assetsError } = await adminClient
    .from("media_assets")
    .select("*")
    .eq("conversation_id", conversationId)
    .eq("user_id", userId);

  if (assetsError) {
    throw new HttpError(400, assetsError.message);
  }

  const attachmentsByMessageId = new Map<string, Record<string, unknown>[]>();
  for (const asset of assets ?? []) {
    if (!asset.message_id) continue;
    const collection = attachmentsByMessageId.get(asset.message_id) ?? [];
    collection.push(asset);
    attachmentsByMessageId.set(asset.message_id, collection);
  }

  return {
    id: conversation.id,
    title: conversation.title,
    messages: (messages ?? []).map((message) => ({
      id: message.id,
      role: message.role,
      content: message.content,
      reasoning: message.reasoning,
      createdAt: message.created_at,
      attachments: (attachmentsByMessageId.get(message.id) ?? []).map(toMediaAssetResponse),
    })),
  };
}

async function fetchRecentMessages(conversationId: string, userId: string) {
  const { data, error } = await adminClient
    .from("messages")
    .select("role, content")
    .eq("conversation_id", conversationId)
    .eq("user_id", userId)
    .order("created_at", { ascending: false })
    .limit(16);

  if (error) {
    throw new HttpError(400, error.message);
  }

  return (data ?? []).reverse();
}

async function loadMediaAssets(userId: string, assetIds: string[]) {
  if (assetIds.length === 0) {
    return [];
  }

  const { data, error } = await adminClient
    .from("media_assets")
    .select("*")
    .eq("user_id", userId)
    .in("id", assetIds);

  if (error) {
    throw new HttpError(400, error.message);
  }

  if ((data ?? []).length != assetIds.length) {
    throw new HttpError(400, "One or more media assets were not found.");
  }

  return data ?? [];
}

async function downloadStorageAssetAsBase64(asset: Record<string, unknown>) {
  const bucket = String(asset.bucket);
  const storagePath = String(asset.storage_path);
  const { data, error } = await adminClient.storage.from(bucket).download(storagePath);

  if (error || !data) {
    throw new HttpError(400, error?.message ?? `Unable to download ${storagePath}.`);
  }

  const bytes = new Uint8Array(await data.arrayBuffer());
  return encodeBase64(bytes);
}

function decodeBase64(input: string): Uint8Array {
  const normalized = input.includes(",") ? input.split(",").pop() ?? input : input;
  const binary = atob(normalized);
  return Uint8Array.from(binary, (char) => char.charCodeAt(0));
}

function encodeBase64(input: Uint8Array): string {
  let binary = "";
  input.forEach((byte) => {
    binary += String.fromCharCode(byte);
  });
  return btoa(binary);
}

function inferConversationTitle(source: string): string {
  const cleaned = source.trim().replace(/\s+/g, " ");
  return cleaned.slice(0, 72) || "New conversation";
}

function buildSystemPrompt(profile: Record<string, unknown>, memories: ReturnType<typeof toMemoryResponse>[]) {
  const answers = Object.entries((profile.onboarding_answers ?? {}) as Record<string, string>)
    .map(([question, answer]) => `- ${question}: ${answer}`)
    .join("\n");
  const memoryLines = memories
    .map((memory) => `- [${memory.kind}] ${memory.title}: ${memory.summary}`)
    .join("\n");

  return [
    "You are NestMind, a hyper-personal assistant for one specific signed-in user.",
    "Do not assume you know any other household member. Household membership does not imply shared memory.",
    `Preferred name: ${profile.preferred_name || profile.display_name || "User"}`,
    `Assistant tone: ${profile.assistant_tone}`,
    `Support style: ${profile.support_style}`,
    `Life focuses: ${(profile.life_focuses ?? []).join(", ") || "None recorded yet."}`,
    `Likes: ${(profile.likes ?? []).join(", ") || "None recorded yet."}`,
    `Dislikes: ${(profile.dislikes ?? []).join(", ") || "None recorded yet."}`,
    `Boundaries: ${(profile.boundaries ?? []).join(", ") || "None recorded yet."}`,
    answers ? `Onboarding answers:\n${answers}` : "Onboarding answers: none yet.",
    memoryLines ? `Accepted memories:\n${memoryLines}` : "Accepted memories: none yet.",
    "Be concise, specific, and action-oriented. Ask one clarifying question only when it materially improves the advice.",
  ].join("\n\n");
}

async function extractAndStoreMemories(input: {
  userId: string;
  conversationId: string;
  profile: Record<string, unknown>;
  userMessage: string;
  assistantMessage: string;
}) {
  const schema = {
    type: "object",
    properties: {
      memories: {
        type: "array",
        maxItems: 3,
        items: {
          type: "object",
          properties: {
            kind: {
              type: "string",
              enum: ["identity", "preference", "goal", "routine", "context"],
            },
            title: { type: "string" },
            summary: { type: "string" },
            confidence: { type: "number" },
          },
          required: ["kind", "title", "summary", "confidence"],
        },
      },
    },
    required: ["memories"],
  };

  try {
    const extraction = await ollamaChat({
      model: ollamaModels.memory,
      format: schema,
      messages: [
        {
          role: "system",
          content: "Extract only durable, user-specific memory candidates. Return JSON only. Ignore transient mood unless it is likely to matter again.",
        },
        {
          role: "user",
          content: [
            `Profile summary: ${input.profile.summary || "No summary saved yet."}`,
            `User message: ${input.userMessage}`,
            `Assistant response: ${input.assistantMessage}`,
          ].join("\n\n"),
        },
      ],
    });

    const parsed = JSON.parse(extraction?.message?.content ?? "{\"memories\":[]}");
    const candidates = Array.isArray(parsed.memories) ? parsed.memories.slice(0, 3) : [];
    const persisted = [];

    for (const candidate of candidates) {
      if (
        typeof candidate?.kind !== "string" ||
        typeof candidate?.title !== "string" ||
        typeof candidate?.summary !== "string"
      ) {
        continue;
      }

      const confidence = typeof candidate?.confidence === "number"
        ? Math.max(0.1, Math.min(0.99, candidate.confidence))
        : 0.5;

      const { data: existing } = await adminClient
        .from("memory_entries")
        .select("*")
        .eq("user_id", input.userId)
        .eq("title", candidate.title.trim())
        .maybeSingle();

      if (existing) {
        const { data: updated } = await adminClient
          .from("memory_entries")
          .update({
            kind: candidate.kind,
            summary: candidate.summary.trim(),
            confidence,
            status: "active",
            source_conversation_id: input.conversationId,
            last_reinforced_at: new Date().toISOString(),
            evidence: {
              source: "conversation",
              conversation_id: input.conversationId,
            },
          })
          .eq("id", existing.id)
          .select("*")
          .single();

        if (updated) {
          persisted.push(toMemoryResponse(updated));
        }
      } else {
        const { data: created } = await adminClient
          .from("memory_entries")
          .insert({
            user_id: input.userId,
            source_conversation_id: input.conversationId,
            kind: candidate.kind,
            title: candidate.title.trim(),
            summary: candidate.summary.trim(),
            confidence,
            evidence: {
              source: "conversation",
              conversation_id: input.conversationId,
            },
          })
          .select("*")
          .single();

        if (created) {
          persisted.push(toMemoryResponse(created));
        }
      }
    }

    return persisted;
  } catch (error) {
    console.error("Memory extraction failed", error);
    return [];
  }
}
