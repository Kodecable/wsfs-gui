rule("auto_qrc")
    on_config(function (target)
        local autogendir = path.join(target:autogendir(), "rules", "auto_qrc")
        local qrc_path = path.join(autogendir, "qml.qrc")

        local qrc_patterns = target:values("auto_qrc.files")
        if not qrc_patterns or #qrc_patterns == 0 then
            raise("auto_qrc: no files specified! Use set_values('auto_qrc.files', ...)")
        end

        local ts_patterns = target:values("auto_qrc.ts_files")
        local strip_prefix = target:values("auto_qrc.strip_prefix") or ""

        local qrc_content = {'<!DOCTYPE RCC>', '<RCC>', '  <qresource prefix="/">'}

        for _, pattern in ipairs(qrc_patterns) do
            local files = os.files(pattern)
            if not files or #files == 0 then
                raise("auto_qrc: no files matched pattern: " .. pattern)
            end

            for _, filepath in ipairs(files) do
                local abs_path = path.absolute(filepath)
                local projectdir = os.projectdir()
                local rel = path.relative(filepath, projectdir)

                if strip_prefix ~= "" then
                    local prefix = strip_prefix .. "/"
                    if rel:startswith(prefix) then
                        rel = rel:sub(#prefix + 1)
                    end
                end
                table.insert(qrc_content, '    <file alias="' .. rel .. '">' .. abs_path .. '</file>')
            end
        end

        if ts_patterns then
            for _, pattern in ipairs(ts_patterns) do
                local files = os.files(pattern)
                if files then
                    for _, filepath in ipairs(files) do
                        local qm_name = path.basename(filepath) .. ".qm"
                        local qm_path = path.join(autogendir, "i18n", qm_name)
                        local abs_qm_path = path.absolute(qm_path)
                        table.insert(qrc_content, '    <file alias="i18n/' .. qm_name .. '">' .. abs_qm_path .. '</file>')
                    end
                end
            end
        end

        table.insert(qrc_content, '  </qresource>')
        table.insert(qrc_content, '</RCC>')

        os.mkdir(autogendir)
        io.writefile(qrc_path, table.concat(qrc_content, "\n"))

        target:add("files", qrc_path)
        target:data_set("auto_qrc_autogendir", autogendir)
    end)

    before_build(function (target)
        import("lib.detect.find_file")

        local autogendir = target:data("auto_qrc_autogendir")
        if not autogendir then return end

        local ts_patterns = target:values("auto_qrc.ts_files")
        if not ts_patterns then return end

        local qt = target:data("qt")
        if not qt then return end

        local search_dirs = {}
        if qt.bindir_host then table.insert(search_dirs, qt.bindir_host) end
        if qt.bindir then table.insert(search_dirs, qt.bindir) end
        if qt.libexecdir_host then table.insert(search_dirs, qt.libexecdir_host) end
        if qt.libexecdir then table.insert(search_dirs, qt.libexecdir) end

        local lrelease = find_file(is_host("windows") and "lrelease.exe" or "lrelease", search_dirs)
        if not lrelease then
            raise("auto_qrc: lrelease not found!")
        end

        local i18n_dir = path.join(autogendir, "i18n")
        os.mkdir(i18n_dir)

        for _, pattern in ipairs(ts_patterns) do
            local files = os.files(pattern)
            if files then
                for _, tsfile in ipairs(files) do
                    local qm_name = path.basename(tsfile) .. ".qm"
                    local qm_path = path.join(i18n_dir, qm_name)
                    os.execv(lrelease, {tsfile, "-qm", qm_path})
                end
            end
        end
    end)
