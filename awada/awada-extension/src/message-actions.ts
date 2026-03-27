import { randomUUID } from "crypto";
import { jsonResult, readStringParam } from "openclaw/plugin-sdk/agent-runtime";
import type { ChannelMessageActionAdapter } from "openclaw/plugin-sdk/channel-contract";
import { resolveAwadaAccount } from "./accounts.js";
import { buildMediaContentFromName, sendMediaToAwada } from "./send.js";
import { getCachedOutboundTarget } from "./target-cache.js";

export const awadaMessageActions: ChannelMessageActionAdapter = {
  describeMessageTool: ({ cfg }) => {
    const account = resolveAwadaAccount({ cfg });
    if (!account.configured) return null;
    return { actions: ["sendAttachment"] };
  },

  supportsAction: ({ action }) => action === "sendAttachment",

  handleAction: async (ctx) => {
    if (ctx.action !== "sendAttachment") {
      throw new Error(`Unsupported awada action: ${ctx.action}`);
    }

    const fileName = readStringParam(ctx.params, "file_name", {
      required: true,
      label: "file_name (pre-stored WeChat cloud file)",
    });

    const account = resolveAwadaAccount({ cfg: ctx.cfg, accountId: ctx.accountId });
    if (!account.redisUrl) {
      throw new Error("[awada] redisUrl not configured");
    }

    const userIdExternal = ctx.requesterSenderId;
    if (!userIdExternal) {
      throw new Error("[awada] No sender context — cannot resolve recipient");
    }

    const target = getCachedOutboundTarget(userIdExternal);
    if (!target) {
      throw new Error(
        `[awada] No cached outbound target for sender "${userIdExternal}". ` +
          "The customer must have sent a message before you can send attachments.",
      );
    }

    const media = buildMediaContentFromName({ file_name: fileName });
    const streamId = await sendMediaToAwada({
      redisUrl: account.redisUrl,
      target,
      media,
      replyToEventId: randomUUID(),
      correlationId: randomUUID(),
      traceId: randomUUID(),
    });

    return jsonResult({ ok: true, type: media.type, file_name: fileName, streamId });
  },
};
