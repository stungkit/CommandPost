local test 		= require("cp.test")

local _test = _G._test

return test.suite("*"):with {
    _test "cp.app",
    -- _test "cp.apple.finalcutpro",
    -- _test "cp.apple.finalcutpro.plugins",
    _test "cp.i18n.languageID",
    _test "cp.i18n.localeID",
    _test "cp.ids",
    _test "cp.is",
    _test "cp.just",
    _test "cp.localized",
    _test "cp.prop",
    _test "cp.rx",
    _test "cp.rx.go",
    _test "cp.strings",
    _test "cp.strings.source.plist",
    _test "cp.strings.source.table",
    _test "cp.text",
    _test "cp.text.matcher",
    _test "cp.ui.notifier",
    _test "cp.utf16",
    _test "cp.web.html",
    _test "cp.web.xml",
}