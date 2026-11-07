extends GutTest

const ICON := "res://assets/branding/icon.png"
const WINDOWS_ICON := "res://assets/branding/icon.ico"
const SPLASH := "res://assets/branding/splash.png"
const EXPORT_PRESETS := "res://export_presets.cfg"

func test_the_game_uses_its_own_icon() -> void:
	assert_eq(ProjectSettings.get_setting("application/config/icon"), ICON)
	assert_eq(ProjectSettings.get_setting("application/config/windows_native_icon"), WINDOWS_ICON)
	assert_true(FileAccess.file_exists(ICON))
	assert_true(FileAccess.file_exists(WINDOWS_ICON))

func test_the_windows_build_carries_the_icon() -> void:
	var presets := ConfigFile.new()
	assert_eq(presets.load(EXPORT_PRESETS), OK)
	var windows := ""
	for section: String in presets.get_sections():
		if presets.get_value(section, "platform", "") == "Windows Desktop":
			windows = section + ".options"
	assert_eq(presets.get_value(windows, "application/icon", ""), WINDOWS_ICON)

func test_the_splash_shows_the_title_in_crisp_pixels() -> void:
	assert_eq(ProjectSettings.get_setting("application/boot_splash/image"), SPLASH)
	assert_true(FileAccess.file_exists(SPLASH))
	assert_false(ProjectSettings.get_setting("application/boot_splash/use_filter"), "pixel art sem borrar")
	var splash: Texture2D = load(SPLASH)
	assert_eq(splash.get_size(), Vector2(1280, 720))
