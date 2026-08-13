#!/usr/bin/env bash
# Синтаксическая проверка всех GDScript-файлов через gdparse.
#
# gdtoolkit не поддерживает многострочные лямбды — сопровождающий заявил, что
# и не будет: для этого нужен свой лексер, иначе на уровне парсера возникает
# неоднозначность. Для Godot 4 такой синтаксис корректен, поэтому файлы из
# списка ниже проверяются только движком, а здесь пропускаются.
#
# Список намеренно ЗАКРЫТЫЙ: если ложное срабатывание появится в новом файле,
# проверка упадёт, и решение придётся принять осознанно — либо переписать
# лямбду отдельной функцией, либо добавить файл сюда с обоснованием.
#
# Запуск: ./tools/gdparse_check.sh
set -uo pipefail
cd "$(dirname "$0")/.."

# Файлы с многострочными лямбдами (корректный Godot 4, не по зубам gdtoolkit).
ALLOWLIST=(
	"scripts/systems/loot_drop.gd"
	"scripts/ui/character_screen.gd"
	"scripts/ui/screens.gd"
)

if ! command -v gdparse >/dev/null 2>&1; then
	echo "  пропуск: gdparse не установлен (pip install gdtoolkit==4.*)"
	exit 0
fi

fails=0
skipped=0
checked=0

is_allowed() {
	local f="$1"
	for a in "${ALLOWLIST[@]}"; do
		[[ "$f" == "$a" ]] && return 0
	done
	return 1
}

while IFS= read -r f; do
	[[ -f "$f" ]] || continue
	if gdparse "$f" >/dev/null 2>&1; then
		checked=$((checked + 1))
		# Файл разбирается — значит, в списке исключений он больше не нужен.
		if is_allowed "$f"; then
			echo "  УСТАРЕЛО: $f разбирается, уберите его из ALLOWLIST"
			fails=$((fails + 1))
		fi
	else
		if is_allowed "$f"; then
			skipped=$((skipped + 1))
		else
			echo "  FAIL $f"
			gdparse "$f" 2>&1 | grep -E "Unexpected|line [0-9]+" | head -3 | sed 's/^/        /'
			fails=$((fails + 1))
		fi
	fi
done < <(git ls-files '*.gd')

if [[ $fails -eq 0 ]]; then
	echo "  OK   синтаксис: $checked файлов разобрано, $skipped с многострочными лямбдами пропущено"
else
	echo "  Провалено файлов: $fails"
fi
exit $fails
