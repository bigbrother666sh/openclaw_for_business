# HRBP Skill — Remove (解雇 / 停用实例)

## Trigger
User requests to delete/remove an existing agent instance, or Main Agent spawns HRBP for removal.

## Important
**This entire procedure is L3 — every step that modifies the system requires explicit user confirmation.**

## Procedure

### Step 1: Identify Target Instance (L1)
- Check the team roster in Main Agent's `MEMORY.md`
- Confirm which instance the user wants to remove
- If ambiguous, list available instances and ask for clarification

### Step 2: Safety Check (L1)
- **Protected agents** (`main`, `hrbp`, `it-engineer`) **cannot be deleted** — inform the user and abort
- Check if the instance has active channel bindings
- Review the instance's current workspace and configuration

### Step 3: Present Removal Plan (L3 — requires confirmation)
Show the user:
- Instance ID, name, and current responsibilities
- Source template (the template itself will NOT be deleted)
- Current channel bindings (if any) that will be removed
- Workspace location that will be archived
- **Explicitly state**: workspace will be archived (not permanently deleted) and can be recovered
- Ask for explicit confirmation to proceed

### Step 4: Execute Removal (L3)
After user confirms:

1. Run: `bash ./skills/hrbp-remove/scripts/remove-agent.sh <instance-id>`
2. This will:
   - Remove instance from `agents.list` in openclaw.json
   - Remove from Main Agent's `subagents.allowAgents`
   - Remove all related `bindings` entries
   - Archive workspace to `~/.openclaw/archived/workspace-<instance-id>-<timestamp>/`
   - Update Main Agent's `MEMORY.md` roster

### Step 5: Update HRBP Memory
- Remove entry from Instance Registry in MEMORY.md
- Note in Operation History

### Step 6: Closeout
Report to the user:
- Instance removed successfully
- Source template still available for future instantiation
- Workspace archived location (for recovery if needed)
- Bindings removed (if any)
- Remind: restart Gateway to apply changes (`./scripts/dev.sh gateway`)

## Notes
- **Never delete `main`, `hrbp`, or `it-engineer`** — these are protected system agents
- Removing an instance does NOT delete the template — template remains available for future use
- Workspace is archived, not permanently deleted — user can recover it
- All steps that modify the system require explicit user confirmation
- If the user asks to "undo" a removal, the workspace can be restored from the archive
