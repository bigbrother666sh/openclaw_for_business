#!/bin/bash
# Apply rebrowser-patches to playwright-core in node_modules.
# Must be run from the project root (openclaw_for_business/).
# Safe to run multiple times — checks if already patched before applying.

set -e

OPENCLAW_DIR="$(cd "$(dirname "$0")/.." && pwd)/openclaw"
PW_DIR="$OPENCLAW_DIR/node_modules/playwright-core/lib/server"

if [ ! -d "$PW_DIR" ]; then
  echo "❌ playwright-core not found at $PW_DIR"
  exit 1
fi

echo "🔧 Checking/applying rebrowser-patches to playwright-core 1.58.2..."

node - "$PW_DIR" <<'NODEEOF'
const fs = require('fs');
const path = require('path');
const dir = process.argv[2]; // argv[0]=node, argv[1]="-", argv[2]=PW_DIR

function patch(file, oldStr, newStr) {
  const fullPath = path.join(dir, file);
  let content = fs.readFileSync(fullPath, 'utf8');
  // idempotency: if old string is gone and new string is present, already patched
  const alreadyApplied = !content.includes(oldStr) && content.includes(newStr);
  if (alreadyApplied) {
    console.log(`  ⏭  Already patched: ${file}`);
    return;
  }
  if (!content.includes(oldStr)) {
    throw new Error(`Marker not found in ${file}: ${oldStr.slice(0, 60)}`);
  }
  content = content.replace(oldStr, newStr);
  fs.writeFileSync(fullPath, content);
  console.log(`  ✓ Patched: ${file}`);
}

// ── crConnection.js: add __re__ helper methods ──────────────────────────────
patch(
  'chromium/crConnection.js',
  `    this._callbacks.clear();
  }
}
class CDPSession extends`,
  `    this._callbacks.clear();
  }
  async __re__emitExecutionContext({
    world,
    targetId,
    frame = null,
    utilityWorldNameOverride = null
  }) {
    const fixMode = process.env["REBROWSER_PATCHES_RUNTIME_FIX_MODE"] || "addBinding";
    const utilityWorldName = utilityWorldNameOverride || (process.env["REBROWSER_PATCHES_UTILITY_WORLD_NAME"] !== "0" ? process.env["REBROWSER_PATCHES_UTILITY_WORLD_NAME"] || "util" : "__playwright_utility_world__");
    process.env["REBROWSER_PATCHES_DEBUG"] && console.log(\`[rebrowser-patches][crSession] targetId = \${targetId}, world = \${world}, frame = \${frame ? "Y" : "N"}, fixMode = \${fixMode}\`);
    let getWorldPromise;
    if (fixMode === "addBinding") {
      if (world === "utility") {
        getWorldPromise = this.__re__getIsolatedWorld({
          client: this,
          frameId: targetId,
          worldName: utilityWorldName
        }).then((contextId) => {
          return {
            id: contextId,
            name: utilityWorldName,
            auxData: {
              frameId: targetId,
              isDefault: false
            }
          };
        });
      } else if (world === "main") {
        getWorldPromise = this.__re__getMainWorld({
          client: this,
          frameId: targetId,
          isWorker: frame === null
        }).then((contextId) => {
          return {
            id: contextId,
            name: "",
            auxData: {
              frameId: targetId,
              isDefault: true
            }
          };
        });
      }
    } else if (fixMode === "alwaysIsolated") {
      getWorldPromise = this.__re__getIsolatedWorld({
        client: this,
        frameId: targetId,
        worldName: utilityWorldName
      }).then((contextId) => {
        return {
          id: contextId,
          name: "",
          auxData: {
            frameId: targetId,
            isDefault: true
          }
        };
      });
    }
    const contextPayload = await getWorldPromise;
    this.emit("Runtime.executionContextCreated", {
      context: contextPayload
    });
  }
  async __re__getMainWorld({ client, frameId, isWorker = false }) {
    let contextId;
    const randomName = [...Array(Math.floor(Math.random() * (10 + 1)) + 10)].map(() => Math.random().toString(36)[2]).join("");
    process.env["REBROWSER_PATCHES_DEBUG"] && console.log(\`[rebrowser-patches][getMainWorld] binding name = \${randomName}\`);
    await client.send("Runtime.addBinding", {
      name: randomName
    });
    const bindingCalledHandler = ({ name, payload, executionContextId }) => {
      process.env["REBROWSER_PATCHES_DEBUG"] && console.log("[rebrowser-patches][bindingCalledHandler]", {
        name,
        payload,
        executionContextId
      });
      if (contextId > 0) {
        return;
      }
      if (name !== randomName) {
        return;
      }
      if (payload !== frameId) {
        return;
      }
      contextId = executionContextId;
      client.off("Runtime.bindingCalled", bindingCalledHandler);
    };
    client.on("Runtime.bindingCalled", bindingCalledHandler);
    if (isWorker) {
      await client.send("Runtime.evaluate", {
        expression: \`this['\${randomName}']('\${frameId}')\`
      });
    } else {
      await client.send("Page.addScriptToEvaluateOnNewDocument", {
        source: \`document.addEventListener('\${randomName}', (e) => self['\${randomName}'](e.detail.frameId))\`,
        runImmediately: true
      });
      const createIsolatedWorldResult = await client.send("Page.createIsolatedWorld", {
        frameId,
        worldName: randomName,
        grantUniveralAccess: true
      });
      await client.send("Runtime.evaluate", {
        expression: \`document.dispatchEvent(new CustomEvent('\${randomName}', { detail: { frameId: '\${frameId}' } }))\`,
        contextId: createIsolatedWorldResult.executionContextId
      });
    }
    process.env["REBROWSER_PATCHES_DEBUG"] && console.log(\`[rebrowser-patches][getMainWorld] result:\`, { contextId });
    return contextId;
  }
  async __re__getIsolatedWorld({ client, frameId, worldName }) {
    const createIsolatedWorldResult = await client.send("Page.createIsolatedWorld", {
      frameId,
      worldName,
      grantUniveralAccess: true
    });
    process.env["REBROWSER_PATCHES_DEBUG"] && console.log(\`[rebrowser-patches][getIsolatedWorld] result:\`, createIsolatedWorldResult);
    return createIsolatedWorldResult.executionContextId;
  }
}
class CDPSession extends`
);

// ── crDevTools.js: conditional Runtime.enable ───────────────────────────────
patch(
  'chromium/crDevTools.js',
  `    Promise.all([
      session.send("Runtime.enable"),
      session.send("Runtime.addBinding", { name: kBindingName }),`,
  `    Promise.all([
      (() => {
        if (process.env["REBROWSER_PATCHES_RUNTIME_FIX_MODE"] === "0") {
          return session.send("Runtime.enable", {});
        }
      })(),
      session.send("Runtime.addBinding", { name: kBindingName }),`
);

// ── crPage.js: conditional Runtime.enable ───────────────────────────────────
patch(
  'chromium/crPage.js',
  `      this._client.send("Runtime.enable", {}),
      this._client.send("Page.addScriptToEvaluateOnNewDocument", {
        source: "",
        worldName: this._crPage.utilityWorldName
      }),`,
  `      (() => {
        if (process.env["REBROWSER_PATCHES_RUNTIME_FIX_MODE"] === "0") {
          return this._client.send("Runtime.enable", {});
        }
      })(),
      this._client.send("Page.addScriptToEvaluateOnNewDocument", {
        source: "",
        worldName: this._crPage.utilityWorldName
      }),`
);

// ── crPage.js: pass targetId+session to Worker constructor ──────────────────
patch(
  'chromium/crPage.js',
  `    const worker = new import_page.Worker(this._page, url);
    this._page.addWorker(event.sessionId, worker);
    this._workerSessions.set(event.sessionId, session);
    session.once("Runtime.executionContextCreated", async (event2) => {
      worker.createExecutionContext(new import_crExecutionContext.CRExecutionContext(session, event2.context));
    });
    if (this._crPage._browserContext._browser.majorVersion() >= 143)
      session.on("Inspector.workerScriptLoaded", () => worker.workerScriptLoaded());
    else
      worker.workerScriptLoaded();
    session._sendMayFail("Runtime.enable");`,
  `    const worker = new import_page.Worker(this._page, url, event.targetInfo.targetId, session);
    this._page.addWorker(event.sessionId, worker);
    this._workerSessions.set(event.sessionId, session);
    session.once("Runtime.executionContextCreated", async (event2) => {
      worker.createExecutionContext(new import_crExecutionContext.CRExecutionContext(session, event2.context));
    });
    if (this._crPage._browserContext._browser.majorVersion() >= 143)
      session.on("Inspector.workerScriptLoaded", () => worker.workerScriptLoaded());
    else
      worker.workerScriptLoaded();
    if (process.env["REBROWSER_PATCHES_RUNTIME_FIX_MODE"] === "0") {
      session._sendMayFail("Runtime.enable");
    }`
);

// ── crServiceWorker.js: conditional Runtime.enable ──────────────────────────
patch(
  'chromium/crServiceWorker.js',
  `    session.send("Runtime.enable", {}).catch((e) => {
    });
    session.send("Runtime.runIfWaitingForDebugger").catch((e) => {
    });`,
  `    if (process.env["REBROWSER_PATCHES_RUNTIME_FIX_MODE"] === "0") {
      session.send("Runtime.enable", {}).catch((e) => {
      });
    }
    session.send("Runtime.runIfWaitingForDebugger").catch((e) => {
    });`
);

// ── frames.js: emit context cleared on navigation ────────────────────────────
patch(
  'frames.js',
  `    this._page.mainFrame()._recalculateNetworkIdle(this);
    this._onLifecycleEvent("commit");
  }
  setPendingDocument(documentInfo) {`,
  `    this._page.mainFrame()._recalculateNetworkIdle(this);
    this._onLifecycleEvent("commit");
    const crSession = (this._page._delegate._sessions.get(this._id) || this._page._delegate._mainFrameSession)._client;
    crSession.emit("Runtime.executionContextsCleared");
  }
  setPendingDocument(documentInfo) {`
);

// ── frames.js: on-demand context via __re__emitExecutionContext ──────────────
patch(
  'frames.js',
  `  _context(world) {
    return this._contextData.get(world).contextPromise.then((contextOrDestroyedReason) => {
      if (contextOrDestroyedReason instanceof js.ExecutionContext)
        return contextOrDestroyedReason;
      throw new Error(contextOrDestroyedReason.destroyedReason);
    });
  }`,
  `  _context(world, useContextPromise = false) {
    if (process.env["REBROWSER_PATCHES_RUNTIME_FIX_MODE"] === "0" || this._contextData.get(world).context || useContextPromise) {
      return this._contextData.get(world).contextPromise.then((contextOrDestroyedReason) => {
        if (contextOrDestroyedReason instanceof js.ExecutionContext)
          return contextOrDestroyedReason;
        throw new Error(contextOrDestroyedReason.destroyedReason);
      });
    }
    const crSession = (this._page._delegate._sessions.get(this._id) || this._page._delegate._mainFrameSession)._client;
    return crSession.__re__emitExecutionContext({
      world,
      targetId: this._id,
      frame: this,
      utilityWorldNameOverride: world === "utility" ? this._page._delegate.utilityWorldName : null
    }).then(() => {
      return this._context(world, true);
    }).catch((error) => {
      if (error.message.includes("No frame for given id found")) {
        return {
          destroyedReason: "Frame was detached"
        };
      }
      const { debugLogger } = require("./utils/debugLogger");
      debugLogger.log("error", error);
      console.error("[rebrowser-patches][frames._context] cannot get world, error:", error);
    });
  }`
);

// ── page.js: Worker class — add targetId/session, getExecutionContext ─────────
patch(
  'page.js',
  `class Worker extends import_instrumentation.SdkObject {
  constructor(parent, url) {
    super(parent, "worker");
    this._executionContextPromise = new import_manualPromise.ManualPromise();
    this._workerScriptLoaded = false;
    this.existingExecutionContext = null;
    this.openScope = new import_utils.LongStandingScope();
    this.url = url;
  }`,
  `class Worker extends import_instrumentation.SdkObject {
  constructor(parent, url, targetId, session) {
    super(parent, "worker");
    this._executionContextPromise = new import_manualPromise.ManualPromise();
    this._workerScriptLoaded = false;
    this.existingExecutionContext = null;
    this.openScope = new import_utils.LongStandingScope();
    this.url = url;
    this._targetId = targetId;
    this._session = session;
  }`
);

patch(
  'page.js',
  `  async evaluateExpression(expression, isFunction, arg) {
    return js.evaluateExpression(await this._executionContextPromise, expression, { returnByValue: true, isFunction }, arg);
  }
  async evaluateExpressionHandle(expression, isFunction, arg) {
    return js.evaluateExpression(await this._executionContextPromise, expression, { returnByValue: false, isFunction }, arg);
  }
}
class PageBinding {`,
  `  async getExecutionContext() {
    if (process.env["REBROWSER_PATCHES_RUNTIME_FIX_MODE"] !== "0" && !this.existingExecutionContext) {
      await this._session.__re__emitExecutionContext({
        world: "main",
        targetId: this._targetId
      });
    }
    return this._executionContextPromise;
  }
  async evaluateExpression(expression, isFunction, arg) {
    return js.evaluateExpression(await this.getExecutionContext(), expression, { returnByValue: true, isFunction }, arg);
  }
  async evaluateExpressionHandle(expression, isFunction, arg) {
    return js.evaluateExpression(await this.getExecutionContext(), expression, { returnByValue: false, isFunction }, arg);
  }
}
class PageBinding {`
);

// ── page.js: PageBinding.dispatch guard ─────────────────────────────────────
patch(
  'page.js',
  `  static async dispatch(page, payload, context) {
    const { name, seq, serializedArgs } = JSON.parse(payload);`,
  `  static async dispatch(page, payload, context) {
    if (process.env["REBROWSER_PATCHES_RUNTIME_FIX_MODE"] !== "0" && !payload.includes("{")) {
      return;
    }
    const { name, seq, serializedArgs } = JSON.parse(payload);`
);

console.log('✅ All rebrowser-patches applied successfully');
NODEEOF

echo "✅ rebrowser-patches applied to playwright-core"
