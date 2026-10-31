fx_version "cerulean"
lua54 "yes"
game "gta5"
use_experimental_fxv2_oal "yes"

author "DevDaddyJacob"
description "A FiveM script to add bait car equipment to your vehicles"
version "0.1.2"

dependencies {
	"ddj_lib", -- version >= 1.2.0
}

ui_page "nui/index.html"

files {
	"nui/index.html",
	"nui/style.css",
	"nui/index.js",
}

shared_scripts {
	"@ddj_lib/shared/logging.lua",
	"@ddj_lib/imports/rpc.lua",
	"config.lua",
}

client_scripts {
	"client/hooks/actions.lua",
	"client/utils.lua",
	"client/nui.lua",
	"client/main.lua",
}

server_scripts {
	"server/main.lua",
}
