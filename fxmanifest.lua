fx_version 'cerulean'
games { 'gta5' }
lua54 'yes'

author 'cruz28001'
description 'MysticBoomBox'

shared_scripts{
    'shared/config.lua',
    '@ox_lib/init.lua',
}

client_scripts {
    'client/language_cl.lua',
    'client/main.lua'
}

server_script 'server/main.lua'

files {
    'blacklist.json'
}

dependency 'ox_lib'
dependency 'xsound'