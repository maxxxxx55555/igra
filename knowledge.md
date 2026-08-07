# Knowledge Base — THE_LAST_STREETLIGHT

# Сгенерировано автоматически из Claude Code skills

# OpenCode читает этот файл и применяет инструкции

## 🧠 Behavioral Rules (from Karpathy Skills)

- **Think Before Coding**: State assumptions explicitly. If multiple interpretations exist, present them.
- **Simplicity First**: Minimum code that solves the problem. No features beyond what was asked.
- **Surgical Changes**: Touch only what you must. Match existing style.
- **Goal-Driven Execution**: Define success criteria and loop until verified.

## 🗣️ Communication Style (from Caveman)

- Be concise. Strip narration, filler, and pleasantries.
- Keep every technical fact and code block byte-for-byte intact.
- Example: Instead of ""The reason your component is re-rendering is likely because..."", say ""New object ref each render. Wrap in useMemo.""

## 🔄 Development Workflow (from Superpowers)

### Phase 1: Brainstorm

- Refine ideas through structured questions.
- Save design doc before coding.

### Phase 2: Plan

- Break designs into 2-5 minute tasks.
- Each task: exact file paths + verification steps.

### Phase 3: Execute

- One task at a time.
- Create .bak before modifying files.
- Verify after each change.

### Phase 4: Review

- Check spec compliance.
- Check code quality.
- Clean up branches.

## 🎮 Godot-Specific Rules

- Use @rpc, @export, @onready correctly.
- For UI strings, use existing i18n keys from localization/.
- Do NOT modify 3D test files without explicit command.
- Multiplayer authority: server = logic, clients = interpolation only.

## 🔒 Security (from Trail of Bits methodology)

- Validate all network inputs (multiplayer).
- Check for hardcoded secrets before commit.
- Review authentication flows if modified.

## 🗣️ Communication Style (Caveman Protocol)

- Be EXTREMELY concise. Strip ALL narration, filler, and pleasantries.
- Keep every technical fact and code block byte-for-byte intact.
- Never say "It seems that", "Likely", "Probably". State facts or ask.
- Example BAD: "The reason your component is re-rendering is likely because you're creating a new object reference on each render. You should wrap it in useMemo."
- Example GOOD: "New object ref each render. Wrap in `useMemo`."
- When giving code, output ONLY the code block with 1-line comment what changed.

## 🔄 Development Workflow (Superpowers Protocol)

### Phase 1: Brainstorm

- Ask clarifying questions before coding.
- Save design decisions to a .md file before implementation.

### Phase 2: Plan

- Break work into 2-5 minute tasks.
- Each task must include: exact file path, expected change, verification step.

### Phase 3: Execute

- One task at a time.
- Create .bak before modifying any file.
- Verify syntax/logic after each change.

### Phase 4: Review

- Check against original request.
- Check code quality and consistency.
- Clean up temporary files.
