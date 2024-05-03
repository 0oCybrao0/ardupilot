--[[
   example script to test lua socket API
--]]

PARAM_TABLE_KEY = 47
PARAM_TABLE_PREFIX = "WEB_"

-- add a parameter and bind it to a variable
function bind_add_param(name, idx, default_value)
    assert(param:add_param(PARAM_TABLE_KEY, idx, name, default_value), string.format('could not add param %s', name))
    return Parameter(PARAM_TABLE_PREFIX .. name)
end

-- Setup Parameters
assert(param:add_table(PARAM_TABLE_KEY, PARAM_TABLE_PREFIX, 6), 'net_test: could not add param table')

--[[
  // @Param: WEB_ENABLE
  // @DisplayName: enable web server
  // @Description: enable web server
  // @Values: 0:Disabled,1:Enabled
  // @User: Standard
--]]
local WEB_ENABLE = bind_add_param('ENABLE', 1, 1)

--[[
  // @Param: WEB_BIND_PORT
  // @DisplayName: web server TCP port
  // @Description: web server TCP port
  // @Range: 1 65535
  // @User: Standard
--]]
local WEB_BIND_PORT = bind_add_param('BIND_PORT', 2, 80)

--[[
  // @Param: WEB_DEBUG
  // @DisplayName: web server debugging
  // @Description: web server debugging
  // @Values: 0:Disabled,1:Enabled
  // @User: Advanced
--]]
local WEB_DEBUG = bind_add_param('DEBUG', 3, 0)

--[[
  // @Param: WEB_BLOCK_SIZE
  // @DisplayName: web server block size
  // @Description: web server block size for download
  // @Range: 1 65535
  // @User: Advanced
--]]
local WEB_BLOCK_SIZE = bind_add_param('BLOCK_SIZE', 4, 10240)

--[[
  // @Param: WEB_TIMEOUT
  // @DisplayName: web server timeout
  // @Description: timeout for inactive connections
  // @Units: s
  // @Range: 0.1 60
  // @User: Advanced
--]]
local WEB_TIMEOUT = bind_add_param('TIMEOUT', 5, 2.0)

--[[
  // @Param: WEB_SENDFILE_MIN
  // @DisplayName: web server minimum file size for sendfile
  // @Description: sendfile is an offloading mechanism for faster file download. If this is non-zero and the file is larger than this size then sendfile will be used for file download
  // @Range: 0 10000000
  // @User: Advanced
--]]
local WEB_SENDFILE_MIN = bind_add_param('SENDFILE_MIN', 6, 100000)

-- LED.lua
PARAM_TABLE_KEY = 68
clkpin = 1
datapin = 2

function add_params(key, prefix, tbl)
    assert(param:add_table(key, prefix, #tbl), string.format('Could not add %s param table.', prefix))
    for num = 1, #tbl do
        print(string.format('Adding %s%s.', prefix, tbl[num][1]))
        assert(param:add_param(key, num, tbl[num][1], tbl[num][2]),
            string.format('Could not add %s%s.', prefix, tbl[num][1]))
    end
end

add_params(PARAM_TABLE_KEY, 'LED_', {
    { 'LEN',        100 }, -- Number of LEDs
    { 'PATTERN',    1 },
    { 'HUE',        0.5 },
    { 'BRIGHTNESS', 100 },
    { 'SPEED',      1 },
    { 'REVERSE',    1 },
    { 'HMIN',       0.0 },
    { 'HMAX',       1.0 },
    { 'HSPEED',     1.2 },
    { 'SMIN',       0.6 },
    { 'SMAX',       1.0 },
    { 'SSPEED',     0.5 },
    { 'VMIN',       0.3 },
    { 'VMAX',       0.7 },
    { 'VSPEED',     0.8 },
})

LED_LEN = Parameter()
LED_PATTERN = Parameter()
LED_HUE = Parameter()
LED_BRIGHTNESS = Parameter()
LED_SPEED = Parameter()
LED_REVERSE = Parameter()
LED_HMIN = Parameter()
LED_HMAX = Parameter()
LED_HSPEED = Parameter()
LED_SMIN = Parameter()
LED_SMAX = Parameter()
LED_SSPEED = Parameter()
LED_VMIN = Parameter()
LED_VMAX = Parameter()
LED_VSPEED = Parameter()

LED_LEN:init('LED_LEN')
LED_PATTERN:init('LED_PATTERN')
LED_HUE:init('LED_HUE')
LED_BRIGHTNESS:init('LED_BRIGHTNESS')
LED_SPEED:init('LED_SPEED')
LED_REVERSE:init('LED_REVERSE')
LED_HMIN:init('LED_HMIN')
LED_HMAX:init('LED_HMAX')
LED_HSPEED:init('LED_HSPEED')
LED_SMIN:init('LED_SMIN')
LED_SMAX:init('LED_SMAX')
LED_SSPEED:init('LED_SSPEED')
LED_VMIN:init('LED_VMIN')
LED_VMAX:init('LED_VMAX')
LED_VSPEED:init('LED_VSPEED')
-- LED.lua end

if WEB_ENABLE:get() ~= 1 then
    periph:can_printf("WebServer: disabled")
    return
end

periph:can_printf(string.format("WebServer: starting on port %u", WEB_BIND_PORT:get()))

local sock_listen = Socket(0)
local clients = {}

local DOCTYPE = "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 3.2 Final//EN\">"
local SERVER_VERSION = "net_webserver 1.0"
local CONTENT_TEXT_HTML = "text/html;charset=UTF-8"
local CONTENT_OCTET_STREAM = "application/octet-stream"

local HIDDEN_FOLDERS = { "@SYS", "@ROMFS", "@MISSION", "@PARAM" }

local MNT_PREFIX = "/mnt"
local MNT_PREFIX2 = MNT_PREFIX .. "/"

local MIME_TYPES = {
    ["apj"] = CONTENT_OCTET_STREAM,
    ["dat"] = CONTENT_OCTET_STREAM,
    ["o"] = CONTENT_OCTET_STREAM,
    ["obj"] = CONTENT_OCTET_STREAM,
    ["lua"] = "text/x-lua",
    ["py"] = "text/x-python",
    ["shtml"] = CONTENT_TEXT_HTML,
    ["js"] = "text/javascript",
    -- thanks to https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types/Common_types
    ["aac"] = "audio/aac",
    ["abw"] = "application/x-abiword",
    ["arc"] = "application/x-freearc",
    ["avif"] = "image/avif",
    ["avi"] = "video/x-msvideo",
    ["azw"] = "application/vnd.amazon.ebook",
    ["bin"] = "application/octet-stream",
    ["bmp"] = "image/bmp",
    ["bz"] = "application/x-bzip",
    ["bz2"] = "application/x-bzip2",
    ["cda"] = "application/x-cdf",
    ["csh"] = "application/x-csh",
    ["css"] = "text/css",
    ["csv"] = "text/csv",
    ["doc"] = "application/msword",
    ["docx"] = "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    ["eot"] = "application/vnd.ms-fontobject",
    ["epub"] = "application/epub+zip",
    ["gz"] = "application/gzip",
    ["gif"] = "image/gif",
    ["htm"] = CONTENT_TEXT_HTML,
    ["html"] = CONTENT_TEXT_HTML,
    ["ico"] = "image/vnd.microsoft.icon",
    ["ics"] = "text/calendar",
    ["jar"] = "application/java-archive",
    ["jpeg"] = "image/jpeg",
    ["json"] = "application/json",
    ["jsonld"] = "application/ld+json",
    ["mid"] = "audio/x-midi",
    ["mjs"] = "text/javascript",
    ["mp3"] = "audio/mpeg",
    ["mp4"] = "video/mp4",
    ["mpeg"] = "video/mpeg",
    ["mpkg"] = "application/vnd.apple.installer+xml",
    ["odp"] = "application/vnd.oasis.opendocument.presentation",
    ["ods"] = "application/vnd.oasis.opendocument.spreadsheet",
    ["odt"] = "application/vnd.oasis.opendocument.text",
    ["oga"] = "audio/ogg",
    ["ogv"] = "video/ogg",
    ["ogx"] = "application/ogg",
    ["opus"] = "audio/opus",
    ["otf"] = "font/otf",
    ["png"] = "image/png",
    ["pdf"] = "application/pdf",
    ["php"] = "application/x-httpd-php",
    ["ppt"] = "application/vnd.ms-powerpoint",
    ["pptx"] = "application/vnd.openxmlformats-officedocument.presentationml.presentation",
    ["rar"] = "application/vnd.rar",
    ["rtf"] = "application/rtf",
    ["sh"] = "application/x-sh",
    ["svg"] = "image/svg+xml",
    ["tar"] = "application/x-tar",
    ["tif"] = "image/tiff",
    ["tiff"] = "image/tiff",
    ["ts"] = "video/mp2t",
    ["ttf"] = "font/ttf",
    ["txt"] = "text/plain",
    ["vsd"] = "application/vnd.visio",
    ["wav"] = "audio/wav",
    ["weba"] = "audio/webm",
    ["webm"] = "video/webm",
    ["webp"] = "image/webp",
    ["woff"] = "font/woff",
    ["woff2"] = "font/woff2",
    ["xhtml"] = "application/xhtml+xml",
    ["xls"] = "application/vnd.ms-excel",
    ["xlsx"] = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    ["xml"] = "default.",
    ["xul"] = "application/vnd.mozilla.xul+xml",
    ["zip"] = "application/zip",
    ["3gp"] = "video",
    ["3g2"] = "video",
    ["7z"] = "application/x-7z-compressed",
}

--[[
 builtin dynamic pages
--]]
local INDEX_PAGE = [[
    <!doctype html>
    <html lang="en">
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    
    <head>
        <meta charset="utf-8">
        <title>CubePilot LED Control</title>
        <script>
            function dynamic_load(div_id, uri, period_ms) {
                var xhr = new XMLHttpRequest();
                xhr.open('GET', uri);
    
                xhr.setRequestHeader("Cache-Control", "no-cache, no-store, max-age=0");
                xhr.setRequestHeader("Expires", "Tue, 01 Jan 1980 1:00:00 GMT");
                xhr.setRequestHeader("Pragma", "no-cache");
    
                xhr.onload = function () {
                    if (xhr.status === 200) {
                        var output = document.getElementById(div_id);
                        if (uri.endsWith('.shtml') || uri.endsWith('.html')) {
                            output.innerHTML = xhr.responseText;
                        } else if(uri.endsWith('.json')) {
                            var json = JSON.parse(xhr.responseText);
                            for (var key in json) {
                                if (document.querySelector('input[type=number][id=' + key + ']')) {
                                    document.querySelector('input[type=number][id=' + key + ']').value = json[key];
                                } 
                                if (document.querySelector('input[type=range][id=' + key + ']')) {
                                    document.querySelector('input[type=range][id=' + key + ']').value = json[key];
                                } 
                                if (document.querySelector('input[type=checkbox][id=' + key + ']')) {
                                    document.querySelector('input[type=hidden][id=' + key + ']').value = json[key];
                                    document.querySelector('input[type=checkbox][id=' + key + ']').checked = json[key] == -1;
                                } 
                                if (document.querySelector('select[id=' + key + ']')) {
                                    document.querySelector('select[id=' + key + ']').value = json[key];
                                    const value = +json[key];
                                    if(value <= 2){
                                        // show speed and brightness and reverse only
                                        document.querySelector('.hsv-full-usage').style.display = 'none';
                                        document.querySelector('.hsv-hue-usage').style.display = 'none';
                                        document.querySelector('.hsv-no-hue-usage').style.display = 'block';
                                    } else if(value <= 5){
                                        // show hue, sat, val and speed
                                        document.querySelector('.hsv-full-usage').style.display = 'none';
                                        document.querySelector('.hsv-hue-usage').style.display = 'block';
                                        document.querySelector('.hsv-no-hue-usage').style.display = 'block';
                                    } else {
                                        // show hue and speed
                                        document.querySelector('.hsv-full-usage').style.display = 'block';
                                        document.querySelector('.hsv-hue-usage').style.display = 'none';
                                        document.querySelector('.hsv-no-hue-usage').style.display = 'none';
                                    }
                                }
                            }
                            document.getElementById("led_control").style.display = "block";
                            draw();
                        } else {
                            output.textContent = xhr.responseText;
                        }
                    }
                    if (period_ms > 0) {
                        setTimeout(function() { dynamic_load(div_id,uri, period_ms); }, period_ms);
                    }
                }
                xhr.send();
            }
        </script>
        <style>
            html, body {
                height: 100%;
                transition: 0.5s;
            }
    
            .light-theme {
                background-color: white;
                color: #222;
            }
    
            .dark-theme {
                background-color: #222;
                color: #fff;
            }
    
            .dark-theme .main-control .led-control {
                background-color: #333;
                border-color: white;
            }
            
            .dark-theme input[type="range"]::-webkit-slider-thumb {
                background: white;
                border: 1px solid #333;
            }
    
            .dark-theme .normal {
                background: #aaa;
            }
    
            .update {
                text-align: right;
            }
    
            .theme-switch {
                position: absolute;
                top: 5px;
                left: 10px;
                font-size: 40px;
                cursor: pointer;
            }
    
            .invisible{
                padding: 5px;
                color: transparent;
            }
    
            .invisible:hover {
                color: blue;
            }
    
            br{
                -webkit-user-select: none; /* Safari */        
                -moz-user-select: none; /* Firefox */
                -ms-user-select: none; /* IE10+/Edge */
                user-select: none; /* Standard */
            }
    
            .main-control {
                width: calc(50% + 150px);
                height: calc(15% + 300px);
                margin: 10px auto; /* Center horizontally */
            }
    
            #colors {
                width: 100%;
                height: 100%;
            }
    
            .led-animation {
                position: absolute;
                width: 104%;
                height: 104%;
                z-index: -1;
                top: -2%;
                left: -2%;
                border-radius: 20px;
                /* background: linear-gradient(#14ffe9, #ffeb3b, #ff00e0);
                animation: rotate 2s linear infinite; */
            }
    
            .led-animation span {
                height: 100%;
                width: 100%;
                background: inherit;
            }
    
            .led-animation span:nth-child(1) {
                filter: blur(7px);
            }
    
            .led-animation span:nth-child(2) {
                filter: blur(14px);
            }
    
            .led-animation span{
                position: absolute;
                top: 50%;
                left: 50%;
                transform: translate(-50%, -50%);
            }
    
            @keyframes rotate {
                0%{
                    filter: hue-rotate(0deg);
                }
                100%{
                    filter: hue-rotate(360deg);
                }
            }
    
            .led-control{
                position: relative;
                height: 100%;
                background-color: white;
                border: 1px solid black;
                border-radius: 20px;
                padding: 10% 6% 8% 5%;
                margin: 10px;
            }
    
            h1 {
                text-align: center;
                padding-bottom: 20px;
            }
    
            input[type=number] {
                width: 3em;
                border: none;
                border:solid 1px #666;
                border-radius: 5px;
    
            }
    
            label {
                width: 85px;
                text-align: right;
                margin-right: 3px;
            }
            
            .select-container {
                display: flex;
                width: 100%;
            }
    
            select {
                width: 100%;
            }
    
            .speed-input-container{
                display: flex;
                align-items: center;
            }
            
            .color-input-container{
                display: flex;
                align-items: center;
                position: relative;
                width: 100%;
            }
            
            .normal-container, .input-container{
                width: 100%;
                display: flex;
                align-items: center;
            }
            
            .range-input {
                width: 100%;
                height: 10px;
                position: relative;
                border-radius: 5px;
                margin-top: 10px;
                margin-left: 3px;
                margin-right: 5px;
                -ms-transform: translateY(-50%);
                transform: translateY(-50%);
            }
    
            .hue {
                background: linear-gradient(to right, hsl(0, 100%, 50%), hsl(60, 100%, 50%), hsl(120, 100%, 50%), hsl(180, 100%, 50%), hsl(240, 100%, 50%), hsl(300, 100%, 50%), hsl(0, 100%, 50%));
            }
            
            .sat {
                background: linear-gradient(to right, hsl(0, 0%, 100%), hsl(0, 100%, 50%));
            }
            
            .val {
                background: linear-gradient(to right, hsl(0, 100%, 0%), hsl(0, 100%, 50%));
            }
    
            .normal {
                background: gray;
            }
    
            .range-input input{
                position: absolute;
                margin: 0;
                margin-top: 3px;
                width: 100%;
                height: 50%;
                background: none;
                pointer-events: none;
                cursor: pointer;
                appearance: none;
                -webkit-appearance: none;
            }
    
            .submit {
                position: absolute;
                bottom: 10%;
                width: 80%;
            }
            
            input[type="submit"] {
                width: 100%;
                background-color: #4CAF50;
                color: white;
                padding: 14px 20px;
                margin: 8px 5%;
                border-radius: 5px;
                border: none;
                cursor: pointer;
            }
            
            /* Styles for the range thumb in WebKit browsers */
            input[type="range"]::-webkit-slider-thumb {
                height: 16px;
                width: 16px;
                border-radius: 70%;
                background: black;
                pointer-events: auto;
                -webkit-appearance: none;
            }   
        </style>
    </head>
    
    <body class="light-theme">
        <div class="theme-switch">
            <a class="theme-switch">☀︎</a>
        </div>
        <div class="update">
            <!-- <li><a href="mnt/">Filesystem Access</a></li> -->
            <a class="invisible" href="?FWUPDATE">Reboot for Firmware Update</a>
        </div>
        <div class="main-control">
            <br>
            <h1>CubePilot LED Controller</h1>
            <div class="led-control">
                <div class="led-animation">
                    <span></span>
                    <span></span>
                    <canvas id="colors"></canvas>
                </div>
                <form id="led_control" target="_blank" action="/RGB" method="get" style="display: none;" >
                    <div class="select-container">
                        <label for="PATTERN" style="font-size: large;">Pattern: </label>
                        <select id="PATTERN" name="PATTERN">
                            <option value="1">1. RGB_H_circling</option>
                            <option value="2">2. RGB_H_rolling</option>
                            <option value="3">3. RGB_V_circling</option>
                            <option value="4">4. RGB_S_circling</option>
                            <option value="5">5. RGB_SV_circling</option>
                            <option value="6">6. RGB_HSV_circling</option>
                            <option value="7">7. RGB_HSV_rolling</option>
                        </select>
                    </div>
                    <br>
                    <br>
                    <div class="hsv-hue-usage">
                        <div class="input-container"> 
                            <label for="HUE">Hue: </label>
                            <div class="normal-container">
                                <input type="number" id="HUE" min="1" max="360" step="1">
                                <div class="hue range-input"> 
                                    <input type="range" id="HUE" name="HUE" min="1" max="360" step="1">
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="hsv-no-hue-usage">
                        <div class="input-container">
                            <label for="BRIGHTNESS">Value: </label>
                            <div class="normal-container">
                                <input type="number" id="BRIGHTNESS" min="0" max="100">
                                <div class="val range-input"> 
                                    <input type="range" id="BRIGHTNESS" name="BRIGHTNESS" min="0" max="100">
                                </div>
                            </div>
                        </div>
                        <div class="input-container">
                            <label for="SPEED">Speed: </label>
                            <div class="normal-container">
                                <input type="number" id="SPEED" min="1" max="255">
                                <div class="normal range-input">
                                    <input type="range" id="SPEED" name="SPEED" min="1" max="255">
                                </div>
                            </div>
                        </div>
                        <br>    
                    </div>
                    <div class="hsv-full-usage">
                        <div class="color-input-container"> 
                            <label for="HUE">Hue: </label>
                            <div class="input-container">
                                <input type="number" id="HMIN" class="min-input" min="1" max="360" step="1">
                                <div class="hue range-input"> 
                                    <input type="range" id="HMIN" name="HMIN" class="min-range" min="1" max="360" step="1">
                                    <input type="range" id="HMAX" name="HMAX" class="max-range" min="1" max="360" step="1">
                                </div>
                                <input type="number" id="HMAX" class="max-input" min="1" max="360" step="1">
                            </div>
                        </div>
                        <div class="input-container">
                            <label for="HSPEED">Speed: </label>
                            <div class="normal-container">
                                <input type="number" id="HSPEED" min="1" max="255" step="1">
                                <div class="normal range-input">
                                    <input type="range" id="HSPEED" name="HSPEED" min="1" max="255" step="1">
                                </div>
                            </div>
                        </div>
                        <br>
                        <div class="color-input-container"> 
                            <label for="SAT">Sat: </label>
                            <div class="input-container">
                                <input type="number" id="SMIN" class="min-input" min="0" max="1" step="0.01">
                                <div class="sat range-input"> 
                                    <input type="range" id="SMIN" name="SMIN" class="min-range" min="0" max="1" step="0.01">
                                    <input type="range" id="SMAX" name="SMAX" class="max-range" min="0" max="1" step="0.01">
                                </div>
                                <input type="number" id="SMAX" class="max-input" min="0" max="1" step="0.01">
                            </div>
                        </div>
                        <div class="input-container">
                            <label for="SSPEED">Speed: </label>
                            <div class="normal-container">
                                <input type="number" id="SSPEED" min="1" max="255" step="1">
                                <div class="normal range-input">
                                    <input type="range" id="SSPEED" name="SSPEED" min="1" max="255" step="1">
                                </div>
                            </div>
                        </div>
                        <br>
                        <div class="color-input-container"> 
                            <label for="VAL">Val: </label>
                            <div class="input-container">
                                <input type="number" id="VMIN" class="min-input" min="0" max="1" step="0.01">
                                <div class="val range-input"> 
                                    <input type="range" id="VMIN" name="VMIN" class="min-range" min="0" max="1" step="0.01">
                                    <input type="range" id="VMAX" name="VMAX" class="max-range" min="0" max="1" step="0.01">
                                </div>
                                <input type="number" id="VMAX" class="max-input" min="0" max="1" step="0.01">
                            </div>
                        </div>
                        <div class="input-container">
                            <label for="VSPEED">Speed: </label>
                            <div class="normal-container">
                                <input type="number" id="VSPEED" min="1" max="255" step="1">
                                <div class="normal range-input">
                                    <input type="range" id="VSPEED" name="VSPEED" min="1" max="255" step="1">
                                </div>
                            </div>
                        </div>
                        <br>
                    </div>
                    <div class="input-container">
                        <label for="REVERSE">Reverse: </label>
                        <input type="hidden" id="REVERSE" name="REVERSE">
                        <input type="checkbox" id="REVERSE">
                    </div>
                    <br>
                    <br>
                    <div class="submit">
                        <input type="submit" value="Submit">
                    </div>
                </form>
            </div>
        </div>
    
        <script>
            console.log("Script loading");
            if (dynamic_load("led_control", "/@DYNAMIC/led_status.json", 0)){
                console.log("Loaded");
            }
    
            const canvas = document.getElementById("colors");
            canvas.style.webkitFilter = "blur(7px)";
            const PI = Math.PI;
            var cnt = 0,
                CX = canvas.width / 2,
                CY = canvas.height/ 2,
                sx = CX,
                sy = CY;
            function radians(degrees) {
                return degrees * (PI / 180);
            }
            const SPEED = document.querySelector('input[name="SPEED"]');
            const BRIGHTNESS = document.querySelector('input[name="BRIGHTNESS"]');
            function draw(){
                const graphics = canvas.getContext("2d");
                for(var i = 0; i < 360; i+=0.1){
                    var rad = radians(i);
                    graphics.strokeStyle = "hsla("+(cnt + i)+", 100%, 70%, 1)";
                    if (rad < PI / 4) {
                        sx = CX;
                        sy = Math.tan(rad) * CX;
                    }
                    else if (rad < PI / 2) {
                        sx = Math.tan(PI / 2 - rad) * CY;
                        sy = CY;
                    }
                    else if (rad < 3 * PI / 4) {
                        sx = -Math.tan(rad - PI / 2) * CX;
                        sy = CY;
                    }
                    else if (rad < PI) {
                        sx = -CX;
                        sy = Math.tan(PI - rad) * CY;
                    }
                    else if (rad < 5 * PI / 4) {
                        sx = -CX;
                        sy = -Math.tan(rad - PI) * CX;
                    }
                    else if (rad < 3 * PI / 2) {
                        sx = -Math.tan(3 * PI / 2 - rad) * CY;
                        sy = -CY;
                    }
                    else if (rad < 7 * PI / 4) {
                        sx = Math.tan(rad - 3 * PI / 2) * CX;
                        sy = -CY;
                    }
                    else if (rad < 2 * PI) {
                        sx = CX;
                        sy = -Math.tan(2 * PI - rad) * CY;
                    }
                    else{
                        continue;
                    }
                    graphics.beginPath();
                    graphics.moveTo(CX, CY);
                    graphics.lineTo(CX + sx, CY + sy);
                    graphics.stroke();
                }
                cnt = (cnt < 360) ? (cnt + +SPEED.value) : 0;
                window.requestAnimationFrame(draw);
            }
    
            const themeSwitch = document.querySelector('.theme-switch');
            themeSwitch.addEventListener('click', () => {
                if (document.body.classList.contains('dark-theme')) {
                    themeSwitch.style.fontSize = '40px';
                    themeSwitch.textContent = '☀︎';
                } else {
                    themeSwitch.style.fontSize = '50px';
                    themeSwitch.style.top = '10px';
                    themeSwitch.style.left = '20px';
                    themeSwitch.textContent = '☾';
                }
                document.body.classList.toggle('dark-theme');
                document.body.classList.toggle('light-theme');
            });
    
            const patternSelect = document.querySelector('select');
            patternSelect.addEventListener('change', e => {
                if(e.target.value <= 2){
                    // show speed and brightness and reverse only
                    document.querySelector('.hsv-full-usage').style.display = 'none';
                    document.querySelector('.hsv-hue-usage').style.display = 'none';
                    document.querySelector('.hsv-no-hue-usage').style.display = 'block';
                } else if(e.target.value <= 5){
                    // show hue, sat, val and speed
                    document.querySelector('.hsv-full-usage').style.display = 'none';
                    document.querySelector('.hsv-hue-usage').style.display = 'block';
                    document.querySelector('.hsv-no-hue-usage').style.display = 'block';
                } else {
                    // show hue and speed
                    document.querySelector('.hsv-full-usage').style.display = 'block';
                    document.querySelector('.hsv-hue-usage').style.display = 'none';
                    document.querySelector('.hsv-no-hue-usage').style.display = 'none';
                }
            });
    
            const inputValue = document.querySelectorAll('.color-input-container .input-container input[type="number"');
            const rangeInputValue = document.querySelectorAll('.color-input-container .range-input input');
    
            // Adding event listeners to input elements 
            for (let i = 0; i < inputValue.length; i+=2){
                inputValue[i].addEventListener('input', e => {
                    let min = +e.target.value;
                    let max = +inputValue[i+1].value;
                    
                    // Validate the input values 
                    if (min > max - +e.target.getAttribute('step')) {
                        e.target.value = max - +e.target.getAttribute('step');
                    }
                    if (min < 0) {
                        e.target.value = 0;
                    }
                    rangeInputValue[i].value = +e.target.value;
                    rangeInputValue[i+1].value = max;
                }); 
            }
            for (let i = 1; i < inputValue.length; i+=2){
                inputValue[i].addEventListener('input', e => {
                    let max = +e.target.value;
                    let min = +inputValue[i-1].value;
                    
                    // Validate the input values 
                    if (max < min + +e.target.getAttribute('step')) {
                        e.target.value = min + +e.target.getAttribute('step');
                    }
                    if (max > +e.target.getAttribute('max')) {
                        e.target.value = +e.target.getAttribute('max');
                    }
                    rangeInputValue[i].value = +e.target.value;
                    rangeInputValue[i-1].value = min;
                }); 
            }
    
            // Adding event listeners to range elements
            for (let i = 0; i < rangeInputValue.length; i+=2){
                rangeInputValue[i].addEventListener('input', e => {
                    let min = +e.target.value;
                    let max = +rangeInputValue[i+1].value;
    
                    // Validate the input values
                    if (min > max - +e.target.getAttribute('step')) {
                        e.target.value = max - +e.target.getAttribute('step');
                    }
                    if (min < 0) {
                        e.target.value = 0;
                    }
                    inputValue[i].value = +e.target.value;
                    inputValue[i+1].value = max;
    
                }); 
            }
            for (let i = 1; i < rangeInputValue.length; i+=2){
                rangeInputValue[i].addEventListener('input', e => {
                    let max = +e.target.value;
                    let min = +rangeInputValue[i-1].value;
    
                    // Validate the input values
                    if (max < min + +e.target.getAttribute('step')) {
                        e.target.value = min + +e.target.getAttribute('step');
                    }
                    if (max > +e.target.getAttribute('max')) {
                        e.target.value = +e.target.getAttribute('max');
                    }
                    inputValue[i].value = +e.target.value;
                    inputValue[i-1].value = min;
                }); 
            }
    
            // Adding event listeners to normal input elements
            const normalInputValue = document.querySelectorAll('.normal-container input[type="number"');
            const normalRangeInputValue = document.querySelectorAll('.normal-container .range-input input');
    
            for (let i = 0; i < normalInputValue.length; i++){
                normalInputValue[i].addEventListener('input', e => {
                    let value = +e.target.value;
                    // Validate the input values
                    if (value < 0) {
                        e.target.value = 0;
                    }
                    if (value > +e.target.getAttribute('max')) {
                        e.target.value = +e.target.getAttribute('max');
                    }
                    normalRangeInputValue[i].value = +e.target.value;
                }); 
            }
    
            // Adding event listeners to normal range elements
            for (let i = 0; i < normalRangeInputValue.length; i++){
                normalRangeInputValue[i].addEventListener('input', e => {
                    let value = +e.target.value;
                    // Validate the input values
                    if (value < 0) {
                        e.target.value = 0;
                    }
                    if (value > +e.target.getAttribute('max')) {
                        e.target.value = +e.target.getAttribute('max');
                    }
                    normalInputValue[i].value = +e.target.value;
                }); 
            }
    
            const reverseCheckbox = document.querySelector('input[type="checkbox"]');
            reverseCheckbox.addEventListener('change', e => {
                if(e.target.checked){
                    document.querySelector('input[name="REVERSE"]').value = -1;
                } else {
                    document.querySelector('input[name="REVERSE"]').value = 1;
                }
            });
    
            document.getElementById("led_control").addEventListener("submit", function(event) {
                event.preventDefault();
                var form = event.target;
                var url = form.getAttribute("action");
                var params = new URLSearchParams(new FormData(form));
                fetch(url + "?" + params.toString())
                .then(function(response) {
                    if (response.redirected) {
                        window.location.href = response.url;
                    }
                })
                .catch(function(error) {
                    console.log(error);
                });
                alert("Submitted")
            });
    
            console.log("Script loaded");
        </script>
    </body>
    </html>
]]

DYNAMIC_PAGES = {
    ["@DYNAMIC/led_status.json"] = [[
        {
            "PATTERN" : <?lstr PATTERN ?>,
            "HUE" : <?lstr HUE ?>,
            "BRIGHTNESS" : <?lstr BRIGHTNESS ?>,
            "SPEED" : <?lstr SPEED ?>,
            "REVERSE" : <?lstr REVERSE ?>,
            "HMIN" : <?lstr HMIN ?>,
            "HMAX" : <?lstr HMAX ?>,
            "HSPEED" : <?lstr HSPEED ?>,
            "SMIN" : <?lstr SMIN ?>,
            "SMAX" : <?lstr SMAX ?>,
            "SSPEED" : <?lstr SSPEED ?>,
            "VMIN" : <?lstr VMIN ?>,
            "VMAX" : <?lstr VMAX ?>,
            "VSPEED" : <?lstr VSPEED ?>
        }
    ]],
    ["@DYNAMIC/board_status.shtml"] = [[
        <table>
        <tr><td>Firmware</td><td><?lstr FWVersion:string() ?></td></tr>
        <tr><td>GIT Hash</td><td><?lstr FWVersion:hash() ?></td></tr>
        <tr><td>Uptime</td><td><?lstr hms_uptime() ?></td></tr>
        <tr><td>IP</td><td><?lstr networking:address_to_str(networking:get_ip_active()) ?></td></tr>
        <tr><td>Netmask</td><td><?lstr networking:address_to_str(networking:get_netmask_active()) ?></td></tr>
        <tr><td>Gateway</td><td><?lstr networking:address_to_str(networking:get_gateway_active()) ?></td></tr>
        <tr><td>MCU Temperature</td><td><?lstr string.format("%.1fC", analog:mcu_temperature()) ?></td></tr>
        </table>
    ]],
}

reboot_counter = 0

local ACTION_PAGES = {
    ["/?FWUPDATE"] = function()
        periph:can_printf("Rebooting for firmware update")
        reboot_counter = 50
    end
}

--[[
 builtin javascript library functions
--]]
JS_LIBRARY = {
    ["dynamic_load"] = [[
        async function dynamic_load(div_id, uri, period_ms) {
            var xhr = new XMLHttpRequest();
            xhr.open('GET', uri);

            xhr.setRequestHeader("Cache-Control", "no-cache, no-store, max-age=0");
            xhr.setRequestHeader("Expires", "Tue, 01 Jan 1980 1:00:00 GMT");
            xhr.setRequestHeader("Pragma", "no-cache");

            xhr.onload = function () {
                if (xhr.status === 200) {
                    var output = document.getElementById(div_id);
                    if (uri.endsWith('.shtml') || uri.endsWith('.html')) {
                        output.innerHTML = xhr.responseText;
                    } else if(uri.endsWith('.json')) {
                        var json = JSON.parse(xhr.responseText);
                        for (var key in json) {
                            console.log(key);
                            if (document.querySelector('input[type=number][id=' + key + ']')) {
                                console.log("number" + ' '+ key);
                                document.querySelector('input[type=number][id=' + key + ']').value = json[key];
                            } else if (document.querySelector('input[type=range][id=' + key + ']')) {
                                console.log("range" + ' '+ key);
                                document.querySelector('input[type=range][id=' + key + ']').value = json[key];
                            } else if (document.querySelector('input[type=checkbox][id=' + key + ']')) {
                                console.log("checkbox" + ' '+ key);
                                document.querySelector('input[type=hidden][id=' + key + ']').value = json[key];
                                document.querySelector('input[type=checkbox][id=' + key + ']').checked = json[key] == -1;
                            } else if (document.querySelector('select[id=' + key + ']')) {
                                console.log("select" + ' '+ key);
                                document.querySelector('select[id=' + key + ']').value = json[key];
                            } else {
                                console.log("drop" + ' '+ key);
                            }
                        }
                    } else {
                        output.textContent = xhr.responseText;
                    }
                }
                if (period_ms > 0) {
                    setTimeout(function() { dynamic_load(div_id,uri, period_ms); }, period_ms);
                }
            }
            xhr.send();
        }
    ]]
}

if not sock_listen:bind("0.0.0.0", WEB_BIND_PORT:get()) then
    periph:can_printf(string.format("WebServer: failed to bind to TCP %u", WEB_BIND_PORT:get()))
    return
end

if not sock_listen:listen(20) then
    periph:can_printf("WebServer: failed to listen")
    return
end

function hms_uptime()
    local s = (millis() / 1000):toint()
    local min = math.floor(s / 60) % 60
    local hr = math.floor(s / 3600)
    return string.format("%u hours %u minutes %u seconds", hr, min, s % 60)
end

--[[
   split string by pattern
--]]
local function split(str, pattern)
    local ret = {}
    for s in string.gmatch(str, pattern) do
        table.insert(ret, s)
    end
    return ret
end

--[[
   return true if a string ends in the 2nd string
--]]
local function endswith(str, s)
    local len1 = #str
    local len2 = #s
    return string.sub(str, 1 + len1 - len2, len1) == s
end

--[[
   return true if a string starts with the 2nd string
--]]
local function startswith(str, s)
    return string.sub(str, 1, #s) == s
end

local debug_count = 0

function DEBUG(txt)
    if WEB_DEBUG:get() ~= 0 then
        periph:can_printf(txt .. string.format(" [%u]", debug_count))
        debug_count = debug_count + 1
    end
end

--[[
   return index of element in a table
--]]
function table_index(t, el)
    for i, v in ipairs(t) do
        if v == el then
            return i
        end
    end
    return nil
end

--[[
   return true if a table contains a given element
--]]
function table_contains(t, el)
    local i = table_index(t, el)
    return i ~= nil
end

function is_hidden_dir(path)
    return table_contains(HIDDEN_FOLDERS, path)
end

local DAYS = { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" }
local MONTHS = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }

function isdirectory(path)
    local s = fs:stat(path)
    return s and s:is_directory()
end

--[[
   time string for directory listings
--]]
function file_timestring(path)
    local s = fs:stat(path)
    if not s then
        return ""
    end
    local mtime = s:mtime()
    local year, month, day, hour, min, sec, _ = rtc:clock_s_to_date_fields(mtime)
    if not year then
        return ""
    end
    return string.format("%04u-%02u-%02u %02u:%02u", year, month + 1, day, hour, min, sec)
end

--[[
   time string for Last-Modified
--]]
function file_timestring_http(mtime)
    local year, month, day, hour, min, sec, wday = rtc:clock_s_to_date_fields(mtime)
    if not year then
        return ""
    end
    return string.format("%s, %02u %s %u %02u:%02u:%02u GMT",
        DAYS[wday + 1],
        day,
        MONTHS[month + 1],
        year,
        hour,
        min,
        sec)
end

--[[
   parse a http time string to a uint32_t seconds timestamp
--]]
function file_timestring_http_parse(tstring)
    local dayname, day, monthname, year, hour, min, sec =
        string.match(tstring,
            '(%w%w%w), (%d+) (%w%w%w) (%d%d%d%d) (%d%d):(%d%d):(%d%d) GMT')
    if not dayname then
        return nil
    end
    local mon = table_index(MONTHS, monthname)
    return rtc:date_fields_to_clock_s(year, mon - 1, day, hour, min, sec)
end

--[[
   return true if path exists and is not a directory
--]]
function file_exists(path)
    local s = fs:stat(path)
    if not s then
        return false
    end
    return not s:is_directory()
end

--[[
   substitute variables of form {xxx} from a table
   from http://lua-users.org/wiki/StringInterpolation
--]]
function substitute_vars(s, vars)
    s = (string.gsub(s, "({([^}]+)})",
        function(whole, i)
            return vars[i] or whole
        end))
    return s
end

--[[
  lat or lon as a string, working around limited type in ftoa_engine
--]]
function latlon_str(ll)
    local ipart = tonumber(string.match(tostring(ll * 1.0e-7), '(.*[.]).*'))
    local fpart = math.abs(ll - ipart * 10000000)
    return string.format("%d.%u", ipart, fpart, ipart * 10000000, ll)
end

--[[
 location string for home page
--]]
function location_string(loc)
    return substitute_vars(
        [[<a href="https://www.google.com/maps/search/?api=1&query={lat},{lon}" target="_blank">{lat} {lon}</a> {alt}]],
        {
            ["lat"] = latlon_str(loc:lat()),
            ["lon"] = latlon_str(loc:lng()),
            ["alt"] = string.format("%.1fm", loc:alt() * 1.0e-2)
        })
end

--[[
   client class for open connections
--]]
local function Client(_sock, _idx)
    local self = {}

    self.closed = false

    local sock = _sock
    local idx = _idx
    local have_header = false
    local header = ""
    local header_lines = {}
    local header_vars = {}
    local run = nil
    local protocol = nil
    local file = nil
    local start_time = millis()
    local offset = 0

    function self.read_header()
        local s = sock:recv(2048)
        if not s then
            local now = millis()
            if not sock:is_connected() or now - start_time > WEB_TIMEOUT:get() * 1000 then
                -- EOF while looking for header
                DEBUG(string.format("%u: EOF", idx))
                self.remove()
                return false
            end
            return false
        end
        if not s or #s == 0 then
            return false
        end
        header = header .. s
        local eoh = string.find(s, '\r\n\r\n')
        if eoh then
            DEBUG(string.format("%u: got header", idx))
            have_header = true
            header_lines = split(header, "[^\r\n]+")
            -- blocking for reply
            sock:set_blocking(true)
            return true
        end
        return false
    end

    function self.sendstring(s)
        sock:send(s, #s)
    end

    function self.sendline(s)
        self.sendstring(s .. "\r\n")
    end

    --[[
      send a string with variable substitution using {varname}
   --]]
    function self.sendstring_vars(s, vars)
        self.sendstring(substitute_vars(s, vars))
    end

    function self.send_header(code, codestr, vars)
        self.sendline(string.format("%s %u %s", protocol, code, codestr))
        self.sendline(string.format("Server: %s", SERVER_VERSION))
        for k, v in pairs(vars) do
            self.sendline(string.format("%s: %s", k, v))
        end
        self.sendline("Connection: close")
        self.sendline("")
    end

    -- get size of a file
    function self.file_size(fname)
        local s = fs:stat(fname)
        if not s then
            return 0
        end
        local ret = s:size():toint()
        DEBUG(string.format("%u: size of '%s' -> %u", idx, fname, ret))
        return ret
    end

    --[[
      return full path with .. resolution
   --]]
    function self.full_path(path, name)
        DEBUG(string.format("%u: full_path(%s,%s)", idx, path, name))
        local ret = path
        if path == "/" and startswith(name, "@") then
            return name
        end
        if name == ".." then
            if path == "/" then
                return "/"
            end
            if endswith(path, "/") then
                path = string.sub(path, 1, #path - 1)
            end
            local dir, _ = string.match(path, '(.*/)(.*)')
            if not dir then
                return path
            end
            return dir
        end
        if not endswith(ret, "/") then
            ret = ret .. "/"
        end
        ret = ret .. name
        DEBUG(string.format("%u: full_path(%s,%s) -> %s", idx, path, name, ret))
        return ret
    end

    function self.directory_list(path)
        sock:set_blocking(true)
        if startswith(path, "/@") then
            path = string.sub(path, 2, #path - 1)
        end
        DEBUG(string.format("%u: directory_list(%s)", idx, path))
        local dlist = dirlist(path)
        if not dlist then
            dlist = {}
        end
        if not table_contains(dlist, "..") then
            -- on ChibiOS we don't get ..
            table.insert(dlist, "..")
        end
        if path == "/" then
            for _, v in ipairs(HIDDEN_FOLDERS) do
                table.insert(dlist, v)
            end
        end

        table.sort(dlist)
        self.send_header(200, "OK", { ["Content-Type"] = CONTENT_TEXT_HTML })
        self.sendline(DOCTYPE)
        self.sendstring_vars([[
<html>
 <head>
  <title>Index of {path}</title>
 </head>
 <body>
<h1>Index of {path}</h1>
  <table>
   <tr><th align="left">Name</th><th align="left">Last modified</th><th align="left">Size</th></tr>
]], { path = path })
        for _, d in ipairs(dlist) do
            local skip = d == "."
            if not skip then
                local fullpath = self.full_path(path, d)
                local name = d
                local sizestr = "0"
                local stat = fs:stat(fullpath)
                local size = stat and stat:size() or 0
                if is_hidden_dir(fullpath) or (stat and stat:is_directory()) then
                    name = name .. "/"
                elseif size >= 100 * 1000 * 1000 then
                    sizestr = string.format("%uM", (size / (1000 * 1000)):toint())
                else
                    sizestr = tostring(size)
                end
                local modtime = file_timestring(fullpath)
                self.sendstring_vars(
                    [[<tr><td align="left"><a href="{name}">{name}</a></td><td align="left">{modtime}</td><td align="left">{size}</td></tr>
]], { name = name, size = sizestr, modtime = modtime })
            end
        end
        self.sendstring([[
</table>
</body>
</html>
]])
    end

    -- send file content
    function self.send_file()
        if not sock:pollout(0) then
            return
        end
        local chunk = WEB_BLOCK_SIZE:get()
        local b = file:read(chunk)
        sock:set_blocking(true)
        if b and #b > 0 then
            local sent = sock:send(b, #b)
            if sent == -1 then
                run = nil
                self.remove()
                return
            end
            if sent < #b then
                file:seek(offset + sent)
            end
            offset = offset + sent
        end
        if not b or #b < chunk then
            -- EOF
            DEBUG(string.format("%u: sent file", idx))
            run = nil
            self.remove()
            return
        end
    end

    --[[
      load whole file as a string
   --]]
    function self.load_file()
        local chunk = WEB_BLOCK_SIZE:get()
        local ret = ""
        while true do
            local b = file:read(chunk)
            if not b or #b == 0 then
                break
            end
            ret = ret .. b
        end
        return ret
    end

    --[[
      evaluate some lua code and return as a string
   --]]
    function self.evaluate(code)
        local eval_code = "function eval_func()\n" .. code .. "\nend\n"
        local f, errloc, err = load(eval_code, "eval_func", "t", _ENV)
        if not f then
            DEBUG(string.format("load failed: err=%s errloc=%s", err, errloc))
            return nil
        end
        local success, err2 = pcall(f)
        if not success then
            DEBUG(string.format("pcall failed: err=%s", err2))
            return nil
        end
        local ok, s2 = pcall(eval_func)
        eval_func = nil
        if ok then
            return s2
        end
        return nil
    end

    --[[
      process a file as a lua CGI
   --]]
    function self.send_cgi()
        sock:set_blocking(true)
        local contents = self.load_file()
        local s = self.evaluate(contents)
        if s then
            self.sendstring(s)
        end
        self.remove()
    end

    --[[
      send file content with server side processsing
      files ending in .shtml can have embedded lua lika this:
      <?lua return "foo" ?>
      <?lstr 2.6+7.2 ?>

      Using 'lstr' a return tostring(yourcode) is added to the code
      automatically
   --]]
    function self.send_processed_file(dynamic_page)
        sock:set_blocking(true)
        local contents
        if dynamic_page then
            contents = file
        else
            contents = self.load_file()
        end
        while #contents > 0 do
            local pat1 = "(.-)[<][?]lua[ \n](.-)[?][>](.*)"
            local pat2 = "(.-)[<][?]lstr[ \n](.-)[?][>](.*)"
            local p1, p2, p3 = string.match(contents, pat1)
            if not p1 then
                p1, p2, p3 = string.match(contents, pat2)
                if not p1 then
                    break
                end
                p2 = "return tostring(" .. p2 .. ")"
            end
            self.sendstring(p1)
            local s2 = self.evaluate(p2)
            if s2 then
                self.sendstring(s2)
            end
            contents = p3
        end
        self.sendstring(contents)
        self.remove()
    end

    -- return a content type
    function self.content_type(path)
        if path == "/" then
            return MIME_TYPES["html"]
        end
        local _, ext = string.match(path, '(.*[.])(.*)')
        ext = string.lower(ext)
        local ret = MIME_TYPES[ext]
        if not ret then
            return CONTENT_OCTET_STREAM
        end
        return ret
    end

    -- perform a file download
    function self.file_download(path)
        if startswith(path, "/@") then
            path = string.sub(path, 2, #path)
        end
        DEBUG(string.format("%u: file_download(%s)", idx, path))
        file = DYNAMIC_PAGES[path]
        dynamic_page = file ~= nil
        if not dynamic_page then
            file = io.open(path, "rb")
            if not file then
                DEBUG(string.format("%u: Failed to open '%s'", idx, path))
                return false
            end
        end
        local vars = { ["Content-Type"] = self.content_type(path) }
        local cgi_processing = startswith(path, "/cgi-bin/") and endswith(path, ".lua")
        local server_side_processing = endswith(path, ".shtml")
        local stat = fs:stat(path)
        if not startswith(path, "@") and
            not server_side_processing and
            not cgi_processing and stat and
            not dynamic_page then
            local fsize = stat:size()
            local mtime = stat:mtime()
            vars["Content-Length"] = tostring(fsize)
            local modtime = file_timestring_http(mtime)
            if modtime then
                vars["Last-Modified"] = modtime
            end
            local if_modified_since = header_vars['If-Modified-Since']
            if if_modified_since then
                local tsec = file_timestring_http_parse(if_modified_since)
                if tsec and tsec >= mtime then
                    DEBUG(string.format("%u: Not modified: %s %s", idx, modtime, if_modified_since))
                    self.send_header(304, "Not Modified", vars)
                    return true
                end
            end
        end
        self.send_header(200, "OK", vars)
        if server_side_processing or dynamic_page then
            DEBUG(string.format("%u: shtml processing %s", idx, path))
            run = self.send_processed_file(dynamic_page)
        elseif cgi_processing then
            DEBUG(string.format("%u: CGI processing %s", idx, path))
            run = self.send_cgi
        elseif stat and
            WEB_SENDFILE_MIN:get() > 0 and
            stat:size() >= WEB_SENDFILE_MIN:get() and
            sock:sendfile(file) then
            return true
        else
            run = self.send_file
        end
        return true
    end

    function self.not_found()
        self.send_header(404, "Not found", {})
    end

    function self.moved_permanently(relpath)
        if not startswith(relpath, "/") then
            relpath = "/" .. relpath
        end
        local location = string.format("http://%s%s", header_vars['Host'], relpath)
        DEBUG(string.format("%u: Redirect -> %s", idx, location))
        self.send_header(301, "Moved Permanently", { ["Location"] = location })
    end

    -- process a single request
    function self.process_request()
        local h1 = header_lines[1]
        if not h1 or #h1 == 0 then
            DEBUG(string.format("%u: empty request", idx))
            return
        end
        local cmd = split(header_lines[1], "%S+")
        if not cmd or #cmd < 3 then
            DEBUG(string.format("bad request: %s", header_lines[1]))
            return
        end
        if cmd[1] ~= "GET" then
            DEBUG(string.format("bad op: %s", cmd[1]))
            return
        end
        protocol = cmd[3]
        if protocol ~= "HTTP/1.0" and protocol ~= "HTTP/1.1" then
            DEBUG(string.format("bad protocol: %s", protocol))
            return
        end
        local path = cmd[2]
        DEBUG(string.format("%u: path='%s'", idx, path))

        if startswith(path, "/RGB") then
            -- extract param and value
            print("received RGB LED control request")
            PATTERN, HMIN, HMAX, HSPEED, SMIN, SMAX, SSPEED, VMIN, VMAX, VSPEED, HUE, BRIGHTNESS, SPEED, REVERSE = string.match(
            path,
                "/RGB%?PATTERN=(.*)&HMIN=(.*)&HMAX=(.*)&HSPEED=(.*)&SMIN=(.*)&SMAX=(.*)&SSPEED=(.*)&VMIN=(.*)&VMAX=(.*)&VSPEED=(.*)&HUE=(.*)&BRIGHTNESS=(.*)&SPEED=(.*)&REVERSE=(.*)")
            if PATTERN and HUE and BRIGHTNESS and SPEED and REVERSE and HMIN and HMAX and HSPEED and SMIN and SMAX and SSPEED and VMIN and VMAX and VSPEED and type(tonumber(PATTERN)) == "number" and type(tonumber(HUE)) == "number" and type(tonumber(BRIGHTNESS)) == "number" and type(tonumber(SPEED)) == "number" and type(tonumber(REVERSE)) == "number" and type(tonumber(HMIN)) == "number" and type(tonumber(HMAX)) == "number" and type(tonumber(HSPEED)) == "number" and type(tonumber(SMIN)) == "number" and type(tonumber(SMAX)) == "number" and type(tonumber(SSPEED)) == "number" and type(tonumber(VMIN)) == "number" and type(tonumber(VMAX)) == "number" and type(tonumber(VSPEED)) == "number" then
                LED_PATTERN:set_and_save(tonumber(PATTERN))
                LED_HUE:set_and_save(tonumber(HUE))
                LED_BRIGHTNESS:set_and_save(tonumber(BRIGHTNESS))
                LED_SPEED:set_and_save(tonumber(SPEED))
                LED_REVERSE:set_and_save(tonumber(REVERSE))
                LED_HMIN:set_and_save(tonumber(HMIN))
                LED_HMAX:set_and_save(tonumber(HMAX))
                LED_HSPEED:set_and_save(tonumber(HSPEED))
                LED_SMIN:set_and_save(tonumber(SMIN))
                LED_SMAX:set_and_save(tonumber(SMAX))
                LED_SSPEED:set_and_save(tonumber(SSPEED))
                LED_VMIN:set_and_save(tonumber(VMIN))
                LED_VMAX:set_and_save(tonumber(VMAX))
                LED_VSPEED:set_and_save(tonumber(VSPEED))
                print("RGB LED control request processed")
                self.send_header(200, "OK", { ["Content-Type"] = CONTENT_TEXT_HTML })
                return
            else
                print("Failed to set RGB LED")
                self.send_header(400, "Bad Request", { ["Content-Type"] = CONTENT_TEXT_HTML })
                return
            end
        end

        -- extract header variables
        for i = 2, #header_lines do
            local key, var = string.match(header_lines[i], '(.*): (.*)')
            if key then
                header_vars[key] = var
            end
        end

        if ACTION_PAGES[path] ~= nil then
            DEBUG(string.format("Running ACTION %s", path))
            local fn = ACTION_PAGES[path]
            self.send_header(200, "OK", { ["Content-Type"] = CONTENT_TEXT_HTML })
            self.sendstring([[
<html>
<head>
<meta http-equiv="refresh" content="2; url=/">
</head>
</html>
]])
            fn()
            return
        end

        if DYNAMIC_PAGES[path] ~= nil then
            self.file_download(path)
            return
        end

        if path == MNT_PREFIX then
            path = "/"
        end

        if path == "/" then
            self.sendstring(INDEX_PAGE)
            return
        end

        if startswith(path, MNT_PREFIX2) then
            path = string.sub(path, #MNT_PREFIX2, #path)
        end

        if isdirectory(path) and
            not endswith(path, "/") and
            header_vars['Host'] and
            not is_hidden_dir(path) then
            self.moved_permanently(path .. "/")
            return
        end

        if path ~= "/" and endswith(path, "/") then
            path = string.sub(path, 1, #path - 1)
        end

        if startswith(path, "/@") then
            path = string.sub(path, 2, #path)
        end

        -- see if we have an index file
        if isdirectory(path) and file_exists(path .. "/index.html") then
            DEBUG(string.format("%u: found index.html", idx))
            if self.file_download(path .. "/index.html") then
                return
            end
        end

        -- see if it is a directory
        if (path == "/" or
                DYNAMIC_PAGES[path] == nil) and
            (endswith(path, "/") or
                isdirectory(path) or
                is_hidden_dir(path)) then
            self.directory_list(path)
            return
        end

        -- or a file
        if self.file_download(path) then
            return
        end
        self.not_found(path)
    end

    -- update the client
    function self.update()
        if run then
            run()
            return
        end
        if not have_header then
            if not self.read_header() then
                return
            end
        end
        self.process_request()
        if not run then
            -- nothing more to do
            self.remove()
        end
    end

    function self.remove()
        DEBUG(string.format("%u: removing client OFFSET=%u", idx, offset))
        if self.closed then
            return
        end
        sock:close()
        self.closed = true
    end

    return self
end

--[[
   see if any new clients want to connect
--]]
local function check_new_clients()
    while sock_listen:pollin(0) do
        local sock = sock_listen:accept()
        if not sock then
            return
        end
        -- non-blocking for header read
        sock:set_blocking(false)
        -- find free client slot
        for i = 1, #clients + 1 do
            if clients[i] == nil then
                local idx = i
                local client = Client(sock, idx)
                DEBUG(string.format("%u: New client", idx))
                clients[idx] = client
            end
        end
    end
end

--[[
   check for client activity
--]]
local function check_clients()
    for idx, client in ipairs(clients) do
        if not client.closed then
            client.update()
        end
        if client.closed then
            table.remove(clients, idx)
        end
    end
end

local function RGB()
    local self = {}
    local tick = 0
    local htick = 0
    local stick = 0
    local vtick = 0

    local function get_LED_params()
        NUM_LEDS = LED_LEN:get()
        PATTERN = LED_PATTERN:get()
        HUE = LED_HUE:get()
        BRIGHTNESS = LED_BRIGHTNESS:get()
        SPEED = LED_SPEED:get()
        REVERSE = LED_REVERSE:get()
        HMIN = LED_HMIN:get()
        HMAX = LED_HMAX:get()
        HSPEED = LED_HSPEED:get()
        SMIN = LED_SMIN:get()
        SMAX = LED_SMAX:get()
        SSPEED = LED_SSPEED:get()
        VMIN = LED_VMIN:get()
        VMAX = LED_VMAX:get()
        VSPEED = LED_VSPEED:get()
    end
    get_LED_params()

    local RGB_LED_VALUES = {}
    for i = 1, NUM_LEDS do
        RGB_LED_VALUES[i] = { 0, 0, 0 }
    end

    -- equivalent to serialLED:set_RGB(CHAN, i, r, g, b)
    local function set_gpio_rgb_led(i, red, green, blue)
        RGB_LED_VALUES[i] = { red, green, blue }
    end

    -- equivalent to serialLED:send(CHAN)
    local function update_gpio_rgb_led()
        min_bits = NUM_LEDS * 25 + 50
        num_leading_zeros = 8 - min_bits % 8 + 50
        output_stream_byte_length = (min_bits + 7) / 8

        --use gpio:write to push all the bits to the LED
        for i = 0, output_stream_byte_length - 1 do
            for bit = 0, 7 do
                out_bit_idx = i * 8 + bit
                if out_bit_idx < num_leading_zeros then
                    bit_val = 0
                elseif (out_bit_idx - num_leading_zeros) % 25 == 0 then
                    bit_val = 1
                else
                    led_idx = math.floor((out_bit_idx - num_leading_zeros) / 25)
                    in_bit_idx = out_bit_idx - num_leading_zeros - (out_bit_idx - num_leading_zeros) / 25
                    in_bit_idx = math.floor(in_bit_idx)
                    byte_idx = math.floor((in_bit_idx % 24) / 8)
                    -- periph:can_printf(string.format("bytes_val[%u] bit_val[%u]: %u", byte_idx, in_bit_idx, bit_val))
                    --  bit_val = (byte_val[byte_idx+1] >> (8-in_bit_idx%8)) & 1
                    bit_val = RGB_LED_VALUES[led_idx + 1][byte_idx + 1] >> (8 - in_bit_idx % 8) & 1
                end
                gpio:write(clkpin, 0)
                gpio:write(datapin, bit_val)
                gpio:write(clkpin, 1)
            end
        end
    end

    local function print(...)
        local args = { ... }
        local str = ""
        for i = 1, #args do
            str = str .. tostring(args[i]) .. "\t"
        end
        -- gcs:send_text(6, str)
        periph:can_printf(str)
    end

    --[[
   * Converts an HSL color value to RGB. Conversion formula
   * adapted from http://en.wikipedia.org/wiki/HSL_color_space.
   * Assumes h, s, and l are contained in the set [0, 1] and
   * returns r, g, and b in the set [0, 255].
   *
   * @param   Number  h       The hue
   * @param   Number  s       The saturation
   * @param   Number  l       The lightness
   * @return  Array           The RGB representation
   ]]
    local function hsvToRgb(h, s, v)
        local r, g, b
        h = (h + 90) / 360

        local i = math.floor(h * 6);
        local f = h * 6 - i;
        local p = v * (1 - s);
        local q = v * (1 - f * s);
        local t = v * (1 - (1 - f) * s);

        i = i % 6

        if i == 0 then
            r, g, b = v, t, p
        elseif i == 1 then
            r, g, b = q, v, p
        elseif i == 2 then
            r, g, b = p, v, t
        elseif i == 3 then
            r, g, b = p, q, v
        elseif i == 4 then
            r, g, b = t, p, v
        elseif i == 5 then
            r, g, b = v, p, q
        end
        return math.floor(r * 255), math.floor(g * 255), math.floor(b * 255)
    end

    local function RGB_H_circling() -- Pattern 1
        tick = (tick + SPEED * REVERSE) % NUM_LEDS
        for i = 1, NUM_LEDS do
            local h, s, v = ((i + tick) % NUM_LEDS) * 360 / (NUM_LEDS), 1, BRIGHTNESS / 100
            local r, g, b = hsvToRgb(h, s, v)
            set_gpio_rgb_led(i, r, g, b)
        end
    end

    local function RGB_H_rolling() -- Pattern 2
        tick = (tick + SPEED * REVERSE) % (NUM_LEDS / 2)
        for i = 1, NUM_LEDS / 2 + 1 do
            local h, s, v = ((i + tick) % (NUM_LEDS / 2)) * 360/ (NUM_LEDS / 2), 1, BRIGHTNESS / 100
            local r, g, b = hsvToRgb(h, s, v)
            set_gpio_rgb_led(i, r, g, b)
            set_gpio_rgb_led(NUM_LEDS + 1 - i, r, g, b)
        end
    end

    local function RGB_V_circling() -- Pattern 3
        tick = (tick + SPEED * REVERSE) % 360
        for i = 1, NUM_LEDS do
            local phase = (i * 360) / NUM_LEDS
            local h, s, v = HUE, 1, 0.1 + 0.4 * math.abs(math.sin(math.rad((tick * SPEED) + phase)))
            local r, g, b = hsvToRgb(h, s, v)
            set_gpio_rgb_led(i, r, g, b)
        end
    end

    local function RGB_S_circling() -- Pattern 4
        tick = (tick + SPEED * REVERSE) % 360
        for i = 1, NUM_LEDS do
            local phase = (i * 360) / NUM_LEDS
            local h, s, v = HUE, 0.1 + 0.9 * math.abs(math.sin(math.rad((tick * SPEED) + phase))), BRIGHTNESS / 100
            local r, g, b = hsvToRgb(h, s, v)
            set_gpio_rgb_led(i, r, g, b)
        end
    end

    local function RGB_SV_circling() -- Pattern 5
        tick = (tick + SPEED * REVERSE) % 360
        for i = 1, NUM_LEDS do
            local phase = (i * 360) / NUM_LEDS
            local h, s, v = HUE, 0.1 + 0.6 * math.abs(math.sin(math.rad((tick * SPEED) + phase))),
                0.1 + 0.6 * math.abs(math.sin(math.rad((tick * SPEED) + phase)))
            local r, g, b = hsvToRgb(h, s, v)
            set_gpio_rgb_led(i, r, g, b)
        end
    end

    local function rng(min, max, ttick, phase)
        -- return ((min + max) / 2) + (((max - min) * math.sin(math.rad(ttick + phase))) / 2)
        return min + (max - min) * math.abs(math.sin(math.rad(ttick + phase)))
    end

    local function RGB_HSV_circling() -- Pattern 6
        htick = (htick + HSPEED * REVERSE) % 360
        stick = (stick + SSPEED * REVERSE) % 360
        vtick = (vtick + VSPEED * REVERSE) % 360
        for i = 1, NUM_LEDS do
            local phase = (i * 360) / NUM_LEDS
            local h, s, v = rng(HMIN, HMAX, htick, phase),
                rng(SMIN, SMAX, stick, phase),
                rng(VMIN, VMAX, vtick, phase)
            local r, g, b = hsvToRgb(h, s, v)
            set_gpio_rgb_led(i, r, g, b)
        end
    end

    local function RGB_HSV_rolling() -- Pattern 7
        htick = (htick + HSPEED * REVERSE) % 360
        stick = (stick + SSPEED * REVERSE) % 360
        vtick = (vtick + VSPEED * REVERSE) % 360
        for i = 1, NUM_LEDS / 2 + 1 do
            local phase = (i * 360) / NUM_LEDS / 2
            local h, s, v = rng(HMIN, HMAX, htick, phase),
                rng(SMIN, SMAX, stick, phase),
                rng(VMIN, VMAX, vtick, phase)
            local r, g, b = hsvToRgb(h, s, v)
            set_gpio_rgb_led(i, r, g, b)
            set_gpio_rgb_led(NUM_LEDS + 1 - i, r, g, b)
        end
    end

    local patterns = {
        RGB_H_circling,
        RGB_H_rolling,
        RGB_V_circling,
        RGB_S_circling,
        RGB_SV_circling,
        RGB_HSV_circling,
        RGB_HSV_rolling,
    }

    function self.update_LEDs()
        get_LED_params()
        local ok = pcall(patterns[PATTERN])
        if not ok then
            print("LEDs: pattern not found")
            return false
        end
        update_gpio_rgb_led()
    end

    return self
end

local RGB_ctr = RGB()
local update_led_ctr = 0

local function update()
    check_new_clients()
    check_clients()
    if reboot_counter then
        reboot_counter = reboot_counter - 1
        if reboot_counter == 0 then
            periph:can_printf("Rebooting")
            periph:reboot(true)
        end
    end
    -- LED.lua
    if update_led_ctr == 0 then
        RGB_ctr.update_LEDs()
        update_led_ctr = 4
    end
    update_led_ctr = update_led_ctr - 1
    return update, 5
end

return update, 100
