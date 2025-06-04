fx_version 'cerulean'
game 'gta5'
use_experimental_fxv2_oal 'yes'
lua54 'yes'

author 'Skap'
description ''
repository ''

shared_script {'config.lua', '@ox_lib/init.lua'}

client_scripts {'client.lua', 'camdebug.lua'}

server_scripts {'server.lua', '@oxmysql/lib/MySQL.lua'}
