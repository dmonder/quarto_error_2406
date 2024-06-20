-- From https://github.com/pandoc/lua-filters/blob/master/scholarly-metadata/scholarly-metadata.lua
local List = require 'pandoc.List'

local yaml_tagname = "accreditation"
local debug = "warning" -- can be blank or "error"

local sources_style = "Sources"
local sources_path = "../documents"

local standards_path = "requirements"

local link_to_artifact_style = "Link to Artifact"
local link_standard_style = "Link to Standard"

local link_to_artifact_resume_prefix = "Resume"
local link_to_artifact_resume_sep = " - "
local link_to_artifact_resume_suffix = ""

local raw_type = "html"
local trace_options = { "link_to_artifact_style",
                        "link_standard_style", 
                        "make_link",
                     }

function contains(tbl, str)
    for _, value in pairs(tbl) do
        if value == str then
        return true
        end
    end
    return false
end
                      
local function qldebug(opt, msg)
    if contains(trace_options, opt) and debug == "warning" then
        quarto.log.debug(yaml_tagname .. ": [" .. opt .. "]: " .. msg)
    end
end

-- From https://github.com/pandoc/lua-filters/blob/master/scholarly-metadata/scholarly-metadata.lua
--- Returns the type of a metadata value.
--
-- @param v a metadata value
-- @treturn string one of `Blocks`, `Inlines`, `List`, `Map`, `string`, `boolean`
local function metatype (v)
    if PANDOC_VERSION <= '2.16.2' then
        local metatag = type(v) == 'table' and v.t and v.t:gsub('^Meta', '')
        return metatag and metatag ~= 'Map' and metatag or type(v)
    end
    return pandoc.utils.type(v)
end

-- From https://github.com/pandoc/lua-filters/blob/master/scholarly-metadata/scholarly-metadata.lua
local type = pandoc.utils.type or metatype


-- From https://github.com/nmfs-opensci/quarto_titlepages
local function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k,v in pairs(o) do
            if type(k) ~= 'number' then k = '"'..k..'"' end
            s = s .. '['..k..'] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

-- Based on code from https://github.com/nmfs-opensci/quarto_titlepages
local function has_attr (tab, attr)
    for index, value in pairs(tab) do
        if index == attr then
            return true
        end
    end

    return false
end

function make_link(path, evidence, evidence_pg, evidence_txt)
    qldebug("make_link", "    ...parms: [" .. path .. "] - [" .. evidence .. "] - [" .. evidence_pg .. "] - [" .. evidence_txt .. "]")
    local rtn_str = ""

    evidence_txt = evidence_txt:gsub("%%20", " ")

    rtn_str = "<a href=\"" .. path .. evidence .. evidence_pg .. "\" " .. " >" .. evidence_txt .. "</a>"

    qldebug("make_link", "    ...rtn_str: " .. rtn_str)
    return rtn_str
    
end

function link_to_artifact(el, artifact_type)
    qldebug("link_to_artifact_style", "Check Span: ")
    qldebug("link_to_artifact_style", "    ...content: " .. dump(el.content))
    qldebug("link_to_artifact_style", "    ...attributes: " .. dump(el.attr))

    local evidence_txt = ""
    local evidence = ""
    local evidence_pg = ""
    local rtn_str = ""
    local pref = ""
    local suf = ""
    local dir_str = ""

    local extension = ".pdf"

    if artifact_type == "resume" then
        evidence_txt = pandoc.utils.stringify(el.content)
        evidence_txt = evidence_txt:gsub("[ÂÄì]", " ")
        qldebug("link_to_artifact_style", "    [R]...evidence_txt: " .. evidence_txt)
        if link_to_artifact_resume_prefix ~= "" then
            pref = link_to_artifact_resume_prefix .. link_to_artifact_resume_sep
        else
            pref = ""
        end
        if link_to_artifact_resume_suffix ~= "" then
            suf = link_to_artifact_resume_sep .. link_to_artifact_resume_suffix
        else
            suf = ""
        end
        evidence = pref .. evidence_txt .. suf .. extension
        sources_txt = evidence_txt
    else
        qldebug("link_to_artifact_style", "ERROR: Unknown artifact type (" .. artifact_type .. ")")
        return el
    end
    
    evidence_pg = ""

    qldebug("link_to_artifact_style", "    ...evidence: " .. evidence_txt .. " - " .. evidence .. "  -  " .. evidence_pg)

    qldebug("link_to_artifact_style", "    ...dir_str: " .. quarto.project.offset .. "    -    " .. quarto.project.directory .. "    -    " .. quarto.doc.input_file) -- sources_path .. "/" .. sources_path_sub
    dir_str = pandoc.path.make_relative(pandoc.utils.stringify(sources_path), quarto.doc.input_file)
    qldebug("link_to_artifact_style", "    ...dir_str: " .. dir_str)

    qldebug("link_to_artifact_style", "    ...evidence: " .. evidence_txt .. " - " .. evidence .. "  -  " .. evidence_pg)
    rtn_str = make_link(sources_path .. "/", evidence, evidence_pg, evidence_txt)
    qldebug("link_to_artifact_style", "    ...rtn_str: " .. rtn_str)

    -- Now return the new link
    return pandoc.Span(pandoc.RawInline(raw_type,rtn_str))
    --return pandoc.Span(rtn_str)
end

function link_to_standard(el)
    local loc_standards_path = standards_path:gsub("\\","/")

    local evidence_txt_orig = pandoc.utils.stringify(el.content)
    local evidence_txt = ""
    local evidence = ""
    local evidence_pg = ""
    local rtn_str = ""
    local qpd = ""
    local qdi = ""
    local idx = nil
    local pat = ""

    -- If quarto.doc.input_file contains standards_path, then set loc_standards_path to ""
    -- Convert the path to contain only /. 
    qpd = quarto.project.directory:gsub("\\","/")
    qldebug("link_standard_style", "    ...quarto.project.directory: " .. qpd )
    qdi = pandoc.path.directory(quarto.doc.input_file:gsub("\\","/"))
    qldebug("link_standard_style", "    ...quarto.doc.input_file: " .. qdi ) 
    if string.find(qdi, loc_standards_path, 1, true) then
        loc_standards_path = ""
    end
    -- Now add a trailing / if loc_standards_path is not empty
    if loc_standards_path ~= "" then
        loc_standards_path = loc_standards_path .. "/"
    end
    
    qldebug("link_standard_style", "    ...loc_standards_path: [" .. loc_standards_path .."]" )

    qldebug("link_standard_style", "    ...evidence_txt_orig: [" .. evidence_txt_orig .."]" )

    -- Insert leading zeros for the standard number when needed
    if evidence_txt_orig == "Standard 5.4" then
        evidence_txt = "Standard 05.4"
    else 
        evidence_txt = evidence_txt_orig
    end
    evidence_txt = string.gsub(evidence_txt_orig, "–", "-")
    evidence = evidence_txt

    qldebug("link_standard_style", "    ...evidence_txt: " .. evidence .. " - " .. evidence_pg .. "  -  " .. evidence_txt)

    evidence = evidence .. ".html"

    rtn_str = make_link(loc_standards_path, evidence, evidence_pg, evidence_txt)
    qldebug("link_standard_style", "    ...rtn_str: " .. rtn_str)
    return pandoc.RawInline(raw_type, rtn_str)

end

local filter = {
    traverse = 'topdown',

    Span = function(el)

        local custom_style = ""
        local el_attr = el.attributes 

        -- The tables that pandoc generates from the Docx to Md conversion use the data-custom-style attribute
        --    instead of the custom-style attribute. This is a workaround to handle that.
        if has_attr(el_attr, "custom-style") or has_attr(el_attr, "data-custom-style") then

            if has_attr(el_attr, "custom-style") then
                custom_style = pandoc.utils.stringify(el_attr["custom-style"])
            else
                custom_style = pandoc.utils.stringify(el_attr["data-custom-style"])
            end

            --- Handle LINKs to artifacts
            if custom_style == (link_to_artifact_style .. " - " .. link_to_artifact_resume_prefix) then
                qldebug("link_to_artifact_style", " [R] -  " .. pandoc.utils.stringify(el.content))
                return link_to_artifact(el, "resume")

                --- Handle LINKs to standards
            elseif custom_style == link_standard_style then
                qldebug("link_standard_style", "Link to Standards")
                return link_to_standard(el)

            end    
        end

        return el
    end

}

return {filter}
