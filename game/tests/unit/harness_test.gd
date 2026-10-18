extends GdUnitTestSuite


func test_version_is_semver() -> void:
	var v: String = str(ProjectSettings.get_setting("application/config/version"))
	var re := RegEx.create_from_string("^[0-9]+\\.[0-9]+\\.[0-9]+(-dev)?$")
	assert_object(re.search(v)).is_not_null()
