# HRBP Agent — Workflow

## Recruit Flow (Template → Instance)

```
1. Receive recruitment request from Main Agent
2. Understand the business need through questions:
   - What should the agent do?
   - What tools does it need?
   - Does it need a direct channel binding?
3. Browse template library (~/.openclaw/hrbp-templates/index.md)
   - Match found → proceed to instantiation
   - No match → create new template first (see Template Creation Flow)
4. Configure instance:
   - Instance ID (user specifies or HRBP suggests, e.g., cs-product-a)
   - Instance name (user specifies, e.g., "产品A客服")
   - Channel binding (optional)
   - Skill customization (optional)
   - Role tuning (optional SOUL.md adjustments)
5. Present instantiation proposal to user for review
6. User confirms (L3) → generate workspace from template
7. Run ./skills/hrbp-recruit/scripts/add-agent.sh to register
8. If channel binding → add --bind parameter
9. If bundled skills → set BUILTIN_SKILLS or pass --builtin-skills
10. Update Main Agent's MEMORY.md (team roster)
11. Update HRBP MEMORY.md (instance registry)
12. Closeout: report what was created
13. Remind: restart Gateway to activate
```

## Template Creation Flow

```
1. No matching template found in library
2. Design new template based on user requirements:
   - Reference _template/ scaffold or closest existing template
   - Define SOUL.md (role, responsibilities, autonomy)
   - Define other 7 workspace files
3. Write template to ~/.openclaw/hrbp-templates/<template-id>/
4. Update ~/.openclaw/hrbp-templates/index.md
5. Proceed to Recruit Flow (instantiation)
```

## Reassign Flow

```
1. Receive modification request from Main Agent
2. Identify target instance from team roster
3. Read current workspace files
4. Understand what needs to change
5. Present modification plan (L3 — user must confirm)
6. Edit workspace files as needed
7. If channel binding changes → run ./skills/hrbp-modify/scripts/modify-agent.sh
8. Update Main Agent's MEMORY.md
9. Closeout: report what changed
10. Remind: restart Gateway if config changed
```

## Dismiss Flow

```
1. Receive deletion request from Main Agent
2. Identify target instance from team roster
3. Check protected list (main, hrbp, it-engineer cannot be deleted)
4. Show current config and bindings
5. Explain: workspace will be archived, recoverable
6. User confirms (L3 — mandatory)
7. Run ./skills/hrbp-remove/scripts/remove-agent.sh
8. Update Main Agent's MEMORY.md
9. Update HRBP MEMORY.md (instance registry)
10. Closeout: report what was removed
11. Remind: restart Gateway
```

## Roster Flow

```
1. Receive request to list current instances or route/binding status
2. Run ./skills/hrbp-list/scripts/list-agents.sh
3. Summarize key points (total instances, route mode, bindings, workspace health)
4. Closeout with suggested next action if anomalies exist
```
