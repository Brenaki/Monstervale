extends GutTest

const CSV_PATH := "res://data/i18n/strings.csv"

func _rows() -> Array:
	var file := FileAccess.open(CSV_PATH, FileAccess.READ)
	var rows := []
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() > 1:
			rows.append(row)
	return rows

func test_header_lists_both_languages() -> void:
	assert_eq(Array(_rows()[0]), ["keys", "pt_BR", "en"])

func test_every_key_has_both_translations() -> void:
	for row: PackedStringArray in _rows():
		assert_eq(row.size(), 3, row[0])
		assert_ne(row[1], "", "%s sem pt_BR" % row[0])
		assert_ne(row[2], "", "%s sem en" % row[0])

func test_keys_are_unique() -> void:
	var seen := {}
	for row: PackedStringArray in _rows():
		assert_false(seen.has(row[0]), "chave repetida %s" % row[0])
		seen[row[0]] = true

func test_every_unit_and_monster_has_a_name() -> void:
	var keys := {}
	for row: PackedStringArray in _rows():
		keys[row[0]] = true
	var catalog: Dictionary = preload("res://src/core/game_data.gd").load_catalog()
	for kind: String in catalog.units:
		assert_true(keys.has("UNIT_%s" % kind.to_upper()), kind)
	for kind: String in catalog.monsters:
		assert_true(keys.has("MONSTER_%s" % kind.to_upper()), kind)
