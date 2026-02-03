local function inject_globals(t)
    if type(t) ~= "table" then return end
    for k,v in pairs(t) do
        if not _G[k] then _G[k] = v end
        if k:sub(1,6) ~= "cairo_" and not _G["cairo_" .. k] then
            _G["cairo_" .. k] = v
        end
    end
end

local ok, ret = pcall(require, "cairo")
if ok then
    if type(ret) == "table" then
        inject_globals(ret)
    elseif type(ret) == "string" then
        local loader = package.loadlib(ret, "luaopen_cairo")
        if loader then 
            local res = loader()
            if type(res) == "function" then res = res() end
            inject_globals(res)
        end
    end
end

if not cairo_xlib_surface_create then
    local paths = {
        "/usr/lib/conky/libcairo_xlib.so",
        "/usr/local/lib/conky/libcairo_xlib.so"
    }
    
    for _, path in ipairs(paths) do
        local loader = package.loadlib(path, "luaopen_cairo_xlib")
        if not loader then loader = package.loadlib(path, "luaopen_cairo") end
        
        if loader then
            local res = loader()
            if type(res) == "function" then res = res() end
            inject_globals(res)
        end
        if cairo_xlib_surface_create then break end
    end
end

if not cairo_create then
    print("Warning: cairo_create is still nil. Lua graphics will fail.")
end

local config_dir = conky_config:gsub("conky.conf$", "")
package.path = config_dir .. "?.lua;" .. package.path

local settings = require("settings")

local function get_asset_path(type, name)
    local theme = settings.theme_mode:lower()
    local path = config_dir .. "assets/images/"

    if type == "common" then
        return path .. "common/" .. name
    elseif type == "theme" then
        return path .. theme .. "/" .. name
    end
    return path .. name
end

function set_color(cr, alpha)
    if settings.theme_mode == "WHITE" then
        cairo_set_source_rgba(cr, 1, 1, 1, alpha)
    else 
        cairo_set_source_rgba(cr, 0, 0, 0, alpha)
    end
end

function draw_image(display, xc, yc, radius, path)
    if not path then return end
    
    local image = cairo_image_surface_create_from_png(path)
    if cairo_surface_status(image) ~= CAIRO_STATUS_SUCCESS then
        return
    end

    local w = cairo_image_surface_get_width(image)
    local h = cairo_image_surface_get_height(image)

    cairo_save(display)
    
    cairo_arc(display, xc, yc, radius, 0, 2 * math.pi)
    cairo_clip(display)
    cairo_new_path(display)

    cairo_translate(display, xc, yc)
    cairo_scale(display, (2 * radius) / w, (2 * radius) / h)
    cairo_translate(display, -w / 2, -h / 2)
    
    cairo_set_source_surface(display, image, 0, 0)
    cairo_paint(display)
    
    cairo_restore(display)
    cairo_surface_destroy(image)
end

function conky_setup()
end

function conky_main()
    if conky_window == nil then return end

    local updates = tonumber(conky_parse("${updates}"))
    if updates < 3 then return end

    local cs = cairo_xlib_surface_create(conky_window.display, conky_window.drawable, conky_window.visual, conky_window.width, conky_window.height)
    local cr = cairo_create(cs)
    
    local extents = cairo_text_extents_t:create()
    
    local width = settings.width
    local height = settings.height
    local interface = settings.network_interface
    local centerx = width / 2
    local centery = height / 2

    local face_radius = 50
    draw_image(cr, centerx, centery, face_radius, get_asset_path("theme", "solus.png"))

    set_color(cr, 0.9)
    cairo_set_line_width(cr, 3)
    cairo_set_line_cap(cr, CAIRO_LINE_CAP_ROUND)
    cairo_set_line_join(cr, CAIRO_LINE_JOIN_ROUND)
    cairo_arc(cr, centerx, centery, face_radius, 0, 2 * math.pi)
    cairo_stroke(cr)

    local function draw_section(angle_deg, label, value_text, icon_name, is_gauge, gauge_val)
        local angle = angle_deg * math.pi / 180
        local item_startx = centerx + math.cos(angle) * face_radius
        local item_starty = centery + math.sin(angle) * face_radius
        local item_endx = centerx + math.cos(angle) * width / 6
        local item_endy = centery + math.sin(angle) * height / 6
        local item_curvex = centerx + math.cos(angle) * width / 12
        local item_curvey = centery + math.sin(angle) * height / 12
        local item_radius = 15
        local item_centerx = item_endx + math.cos(angle) * (item_radius + 5)
        local item_centery = item_endy + math.sin(angle) * (item_radius + 5)
        local item_font_size = height / 50

        local cp1x, cp1y = item_curvex, item_curvey
        local cp2x, cp2y = item_curvex, item_curvey - 100 
        
        if angle_deg == 50 then cp2y = item_curvey + 40 end 
        if angle_deg == 90 then cp2y = item_curvey + 100 end 
        if angle_deg == 130 then cp2y = item_curvey + 100 end 
        if angle_deg == 210 then cp2y = item_curvey - 70 end 
        if angle_deg == 170 then cp2y = item_curvey - 40 end 
        if angle_deg == 320 or angle_deg == 310 then cp2y = item_curvey - 70 end 

        cairo_move_to(cr, item_startx, item_starty)
        cairo_curve_to(cr, cp1x, cp1y, cp2x, cp2y, item_endx, item_endy)
        set_color(cr, 0.5)
        cairo_stroke(cr)

        cairo_arc(cr, item_centerx, item_centery, item_radius + 5, 0, 2 * math.pi)
        set_color(cr, 0.4)
        if is_gauge and tonumber(gauge_val or 0) > 85 then
             cairo_set_source_rgba(cr, 1, 0, 0, 0.4)
        end
        cairo_fill(cr)

        if icon_name then
            draw_image(cr, item_centerx, item_centery, item_radius, get_asset_path("theme", icon_name))
        end

        cairo_arc(cr, item_centerx, item_centery, item_radius + 5, 0, 2 * math.pi)
        set_color(cr, 1)
        if is_gauge and tonumber(gauge_val or 0) > 85 then
             cairo_set_source_rgba(cr, 1, 0, 0, 1)
        end
        cairo_stroke(cr)

        set_color(cr, 1)
        cairo_select_font_face(cr, "Roboto", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
        cairo_set_font_size(cr, item_font_size)
        
        cairo_text_extents(cr, label, extents)
        cairo_move_to(cr, item_centerx - extents.width / 2, item_centery - item_radius - 10)
        cairo_show_text(cr, label)

        if value_text then
             if type(value_text) == "table" then
                 for i, v in ipairs(value_text) do
                     cairo_text_extents(cr, v, extents)
                     cairo_move_to(cr, item_centerx - extents.width / 2, item_centery + item_radius + (item_font_size * i) + 5)
                     cairo_show_text(cr, v)
                 end
             else
                cairo_text_extents(cr, value_text, extents)
                cairo_move_to(cr, item_centerx - extents.width / 2, item_centery + item_radius + item_font_size + 8)
                cairo_show_text(cr, value_text)
             end
        end
        
        return item_endx, item_endy, item_font_size 
    end

    local cpu_val = conky_parse("${cpu}")
    local endx, endy, fsize = draw_section(10, "CPU", cpu_val .. "%", "cpu", true, cpu_val)

    local top_cpu_x = endx + 30 
    local top_cpu_y = endy + 20
    
    set_color(cr, 1)
    cairo_set_font_size(cr, fsize)
    cairo_text_extents(cr, "Top Processes", extents)
    cairo_move_to(cr, top_cpu_x, top_cpu_y)
    cairo_show_text(cr, "Top Processes")

    set_color(cr, 0.7)
    cairo_set_font_size(cr, fsize / 1.4)
    for i = 1, 5 do
        local name = conky_parse("${top name " .. i .. "}")
        local val = conky_parse("${top cpu " .. i .. "}")
        local txt = string.sub(name, 1, 10) .. " " .. val .. "%"
        cairo_move_to(cr, top_cpu_x, top_cpu_y + (fsize * i) + 5)
        cairo_show_text(cr, txt)
    end

    local swap_val = conky_parse("${swapperc}")
    if swap_val == "" then swap_val = "0" end
    draw_section(50, "SWAP", swap_val .. "%", "swap", true, swap_val)

    local uptime_val = conky_parse("${uptime_short}")
    draw_section(90, "UPTIME", uptime_val, "uptime", false)

    local free = "Free: " .. conky_parse("${fs_free /}")
    local total = "Total: " .. conky_parse("${fs_size /}")
    draw_section(130, "ROOT", {free, total}, "root", false)

    local ram_val = conky_parse("${memperc}")
    local rx, ry, rs = draw_section(210, "RAM", ram_val .. "%", "ram", true, ram_val)
    
    local top_mem_x = rx + 30
    local top_mem_y = ry + 20
    
    set_color(cr, 1)
    cairo_set_font_size(cr, rs)
    cairo_move_to(cr, top_mem_x, top_mem_y)
    cairo_show_text(cr, "Top Memory")
    
    set_color(cr, 0.7)
    cairo_set_font_size(cr, rs / 1.4)
    for i = 1, 5 do
        local name = conky_parse("${top_mem name " .. i .. "}")
        local val = conky_parse("${top_mem mem_res " .. i .. "}")
        local txt = string.sub(name, 1, 10) .. " " .. val
        cairo_move_to(cr, top_mem_x, top_mem_y + (rs * i) + 5)
        cairo_show_text(cr, txt)
    end

    draw_section(170, "DISK I/O", {conky_parse("${diskio_read}"), conky_parse("${diskio_write}")}, "root", false) 

    local ip_addr = conky_parse("${addr " .. interface .. "}")
    local nx, ny, ns = draw_section(320, "IP", ip_addr, "network", false)

    set_color(cr, 1)
    cairo_move_to(cr, nx + 20, ny + 20)
    cairo_show_text(cr, "Up: " .. conky_parse("${upspeed " .. interface .. "}"))
    cairo_move_to(cr, nx + 20, ny + 35)
    cairo_show_text(cr, "Down: " .. conky_parse("${downspeed " .. interface .. "}"))

    cairo_destroy(cr)
    cairo_surface_destroy(cs)
    tolua.takeownership(extents)
    extents:destroy()
end
