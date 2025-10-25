const fs = require('fs');
const { lua, lauxlib, lualib } = require('fengari');

const code = fs.readFileSync('./1.lua', 'utf8');

const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);

// Ejecutar código Lua
if (lauxlib.luaL_loadstring(L, fengari.to_luastring(code)) === 0) {
    lua.lua_pcall(L, 0, lua.LUA_MULTRET, 0);
}