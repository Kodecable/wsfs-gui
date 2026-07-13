add_rules("mode.debug", "mode.release")

set_config("qt_sdkver", "6")

includes("xmake/auto_qrc.lua")

if is_plat("linux") then
    add_requires("pkgconfig::libsecret-1", {system = true})
end

set_version()

target("qtkeychain")
    set_kind("static")
    set_languages("cxx17")
    add_rules("qt.static")
    add_defines("QTKEYCHAIN_NO_EXPORT")
    add_includedirs("3rdparty/qtkeychain", "3rdparty/qtkeychain/qtkeychain", {public = true})
    add_headerfiles("3rdparty/qtkeychain/qtkeychain/keychain.h")
    add_headerfiles("3rdparty/qtkeychain/qtkeychain/keychain_p.h")
    add_files("3rdparty/qtkeychain/qtkeychain/keychain.h")
    add_files("3rdparty/qtkeychain/qtkeychain/keychain_p.h")
    add_files("3rdparty/qtkeychain/qtkeychain/keychain.cpp")
    add_frameworks("QtCore")

    if is_plat("linux") then
        on_config(function (target)
            import("lib.detect.find_file")

            local output_dir = "3rdparty/qtkeychain/generated"
            local output_prefix = path.join(output_dir, "kwallet_interface")
            local xml_file = path.absolute("3rdparty/qtkeychain/qtkeychain/org.kde.KWallet.xml")
            local header_file = output_prefix .. ".h"
            local source_file = output_prefix .. ".cpp"
            local source_data = os.isfile(source_file) and io.readfile(source_file) or ""

            if not os.isfile(header_file) or not os.isfile(source_file) or
               os.mtime(xml_file) > os.mtime(header_file) or
               os.mtime(xml_file) > os.mtime(source_file) or
               not source_data:find('#include "kwallet_interface.h"', 1, true) then
                local qt = assert(target:data("qt"), "Qt SDK not found!")
                local search_dirs = {}
                if qt.bindir_host then table.insert(search_dirs, qt.bindir_host) end
                if qt.bindir then table.insert(search_dirs, qt.bindir) end
                if qt.libexecdir_host then table.insert(search_dirs, qt.libexecdir_host) end
                if qt.libexecdir then table.insert(search_dirs, qt.libexecdir) end
                local qdbusxml2cpp = find_file(is_host("windows") and "qdbusxml2cpp.exe" or "qdbusxml2cpp", search_dirs)
                assert(qdbusxml2cpp,
                    "qdbusxml2cpp was not found in the configured Qt SDK")
                os.mkdir(output_dir)
                os.vrunv(qdbusxml2cpp, {"-p", "kwallet_interface", "-c", "KWalletInterface", xml_file}, {curdir = output_dir})
            end
        end)

        add_defines("KEYCHAIN_DBUS=1", "HAVE_LIBSECRET=1")
        add_frameworks("QtDBus")
        add_packages("pkgconfig::libsecret-1")
        add_includedirs("3rdparty/qtkeychain/generated", {public = true})
        add_headerfiles("3rdparty/qtkeychain/qtkeychain/gnomekeyring_p.h")
        add_headerfiles("3rdparty/qtkeychain/qtkeychain/libsecret_p.h")
        add_headerfiles("3rdparty/qtkeychain/qtkeychain/plaintextstore_p.h")
        add_headerfiles("3rdparty/qtkeychain/generated/kwallet_interface.h")
        add_files("3rdparty/qtkeychain/qtkeychain/gnomekeyring_p.h")
        add_files("3rdparty/qtkeychain/generated/kwallet_interface.h")
        add_files("3rdparty/qtkeychain/qtkeychain/keychain_unix.cpp")
        add_files("3rdparty/qtkeychain/qtkeychain/gnomekeyring.cpp")
        add_files("3rdparty/qtkeychain/qtkeychain/libsecret.cpp")
        add_files("3rdparty/qtkeychain/qtkeychain/plaintextstore.cpp")
        add_files("3rdparty/qtkeychain/generated/kwallet_interface.cpp")
    end

    if is_plat("windows") then
        add_defines("USE_CREDENTIAL_STORE=1", "UNICODE")
        add_files("3rdparty/qtkeychain/qtkeychain/keychain_win.cpp")
        add_files("3rdparty/qtkeychain/qtkeychain/libsecret.cpp")
        add_syslinks("advapi32", "crypt32")
    end

    if is_plat("macosx") then
        add_files("3rdparty/qtkeychain/qtkeychain/keychain_apple.mm")
        add_frameworks("Foundation", "Security")
    end

target("wsfs-gui")
    set_default(true)
    set_version("0.1.0")

    set_languages("cxx17")
    add_rules("auto_qrc", "qt.quickapp")
    add_frameworks("QtCore", "QtGui", "QtQml", "QtQuick", "QtQuickControls2", "QtWidgets")

    add_deps("qtkeychain")
    add_defines("QTKEYCHAIN_NO_EXPORT")
    if is_plat("linux") then
        add_frameworks("QtDBus")
    end

    set_configdir("src/")
    add_configfiles("src/config.h.in")

    add_headerfiles("src/*.hpp")
    add_files("src/*.hpp")
    add_files("src/*.cpp")

    set_values("auto_qrc.strip_prefix", "src")
    set_values("auto_qrc.ts_files", "src/i18n/*.ts")
    set_values("auto_qrc.files", "src/*.qml", "src/assets/**")
