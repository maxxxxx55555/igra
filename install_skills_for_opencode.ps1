# install_skills_for_opencode.ps1
# Скачивает skills для Claude Code и адаптирует их в knowledge.md для OpenCode

$projectPath = Get-Location
$skillsDir = "$projectPath\docs\external_skills"
$knowledgeFile = "$projectPath\knowledge.md"

Write-Host "🔧 Установка skills для OpenCode..." -ForegroundColor Cyan

# Создаём папки
New-Item -ItemType Directory -Force -Path $skillsDir | Out-Null

# Список полезных репозиториев
$repos = @(
    @{ Name="andrej-karpathy-skills"; Url="https://raw.githubusercontent.com/forrestchang/andrej-karpathy-skills/main/CLAUDE.md"; Target="karpathy-behavior.md" },
    @{ Name="caveman"; Url="https://raw.githubusercontent.com/JuliusBrussee/caveman/main/SKILL.md"; Target="caveman-style.md" },
    @{ Name="superpowers-brainstorm"; Url="https://raw.githubusercontent.com/obra/superpowers/main/skills/brainstorm/SKILL.md"; Target="superpowers-brainstorm.md" },
    @{ Name="superpowers-plan"; Url="https://raw.githubusercontent.com/obra/superpowers/main/skills/write-plan/SKILL.md"; Target="superpowers-plan.md" },
    @{ Name="superpowers-execute"; Url="https://raw.githubusercontent.com/obra/superpowers/main/skills/execute-plan/SKILL.md"; Target="superpowers-execute.md" }
)

# Скачиваем каждый skill
foreach ($repo in $repos) {
    $targetPath = "$skillsDir\$($repo.Target)"
    try {
        Invoke-WebRequest -Uri $repo.Url -OutFile $targetPath -ErrorAction Stop
        Write-Host "  ✅ $($repo.Name)" -ForegroundColor Green
    } catch {
        Write-Host "  ⚠️ $($repo.Name) — не удалось скачать" -ForegroundColor Yellow
    }
}

# Создаём knowledge.md для OpenCode
$knowledgeContent = @"
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
- Example: Instead of ""The reason your component is re-rendering is likely because..."", say ""New object ref each render. Wrap in `useMemo`.""

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
- Use `@rpc`, `@export`, `@onready` correctly.
- For UI strings, use existing i18n keys from localization/.
- Do NOT modify 3D test files without explicit command.
- Multiplayer authority: server = logic, clients = interpolation only.

## 🔒 Security (from Trail of Bits methodology)
- Validate all network inputs (multiplayer).
- Check for hardcoded secrets before commit.
- Review authentication flows if modified.
"@

$knowledgeContent | Set-Content $knowledgeFile -Encoding UTF8

Write-Host "`n✅ Готово!" -ForegroundColor Green
Write-Host "   Skills сохранены в: $skillsDir" -ForegroundColor Gray
Write-Host "   Knowledge для OpenCode: $knowledgeFile" -ForegroundColor Gray
Write-Host "`n📋 Что дальше:" -ForegroundColor Cyan
Write-Host "   1. Открой OpenCode" -ForegroundColor White
Write-Host "   2. Начни новую сессию — knowledge.md подхватится автоматически" -ForegroundColor White
Write-Host "   3. Пиши запросы — агент будет следовать правилам из knowledge.md" -ForegroundColor White