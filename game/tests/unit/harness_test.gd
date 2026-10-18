extends GdUnitTestSuite


func test_version_is_dev() -> void:
	assert_str(ProjectSettings.get_setting("application/config/version")).is_equal("0.3.0-dev")
