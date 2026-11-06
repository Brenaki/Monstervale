#!/usr/bin/env bash
# Roda os testes do GUT sem janela. GODOT aponta para o binário do Godot 4.7.2.
set -uo pipefail
cd "$(dirname "$0")/.."
: "${GODOT:=/data/nvme/SteamLibrary/steamapps/common/Godot Engine/godot.x11.opt.tools.64}"
"$GODOT" --headless --path . --import > /dev/null 2>&1
output=$("$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd -gconfig=.gutconfig.json 2>&1)
status=$?
printf '%s\n' "$output"
# O GUT termina com 0 quando nenhum teste roda, por exemplo com erro de parse.
if grep -q "Nothing was run" <<< "$output" || grep -q "Failed to load script" <<< "$output"; then
	exit 1
fi
exit "$status"
