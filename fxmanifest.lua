fx_version 'cerulean'
game 'gta5'

name 'ngJobphone'
description 'Share one phone number across all employees'

author 'Niklas Gschaider <niklas.gschaider@gschaider-systems.at>'

lua54 "yes"
  
client_scripts {
  '@NativeUI/NativeUI.lua',
  '@es_extended/locale.lua',
  "locales/*",
  'config.lua',
  'client/cl_main.lua',
}

server_scripts {
  '@mysql-async/lib/MySQL.lua',
  '@es_extended/locale.lua',
  "locales/*",
  'config.lua',
  'server/sv_main.lua',
}

escrow_ignore {
	"config.lua",
	"locales/*.lua",
}

dependencies {
	'es_extended'
}
