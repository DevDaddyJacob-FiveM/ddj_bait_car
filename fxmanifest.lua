fx_version "cerulean"
lua54 "yes"
game "gta5"
use_experimental_fxv2_oal "yes"

author "DevDaddyJacob"
description "A FiveM script to add bait car equipment to your vehicles"
version "1.0.0"

dependencies {
	"ddj_lib", -- version >= 1.2.0
}

ui_page "nui/index.html"

files {
	"nui/index.html",
}

shared_scripts {
	"config.lua",
}

client_scripts {
	"client/main.lua",
}

server_scripts {
	"server/main.lua",
}
