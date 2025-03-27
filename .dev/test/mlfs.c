#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <dirent.h>
#include <time.h>
#include <utime.h>
#ifdef _WIN32
#include <windows.h>
#include <direct.h>
#define EXPORT __declspec(dllexport)
#define getcwd _getcwd
#define chdir _chdir
#else
#include <unistd.h>
#define EXPORT
#endif

/* Estrutura para iterador do lfs.dir (renomeada para evitar conflito) */
typedef struct {
    DIR* dir;
} l_dir_ud;

/* Função __gc para liberar o diretório */
static int l_dir_gc(lua_State* L) {
    l_dir_ud* d = (l_dir_ud*)lua_touserdata(L, 1);
    if (d && d->dir) {
        closedir(d->dir);
        d->dir = NULL;
    }
    return 0;
}

/* Função iteradora para lfs.dir */
static int l_dir_iter(lua_State* L) {
    l_dir_ud* d = (l_dir_ud*)lua_touserdata(L, lua_upvalueindex(1));
    if (!d || !d->dir) {
        lua_pushnil(L);
        return 1;
    }
    struct dirent* entry = readdir(d->dir);
    if (entry) {
        lua_pushstring(L, entry->d_name);
        return 1;
    }
    else {
        closedir(d->dir);
        d->dir = NULL;
        lua_pushnil(L);
        return 1;
    }
}

/* Função: lfs.dir
   Retorna um iterador para percorrer os nomes dos arquivos/diretórios de um diretório.
*/
static int l_dir(lua_State* L) {
    const char* path = luaL_checkstring(L, 1);
    DIR* d = opendir(path);
    if (!d) {
        lua_pushnil(L);
        lua_pushfstring(L, "cannot open directory %s", path);
        return 2;
    }
    /* Cria o userdata que guardará o DIR* */
    l_dir_ud* dir_ud = (l_dir_ud*)lua_newuserdata(L, sizeof(l_dir_ud));
    dir_ud->dir = d;
    /* Cria metatable com __gc para fechar o diretório se necessário */
    lua_newtable(L);
    lua_pushcfunction(L, l_dir_gc);
    lua_setfield(L, -2, "__gc");
    lua_setmetatable(L, -2);
    /* Cria e retorna a closure iteradora, capturando o userdata */
    lua_pushcclosure(L, l_dir_iter, 1);
    return 1;
}

/* Função: lfs.attributes */
static int l_attributes(lua_State* L) {
    const char* path = luaL_checkstring(L, 1);
    struct stat st;
    if (stat(path, &st) != 0) {
        lua_pushnil(L);
        lua_pushfstring(L, "cannot access %s", path);
        return 2;
    }
    if (lua_gettop(L) == 2) {
        const char* attr = luaL_checkstring(L, 2);
        if (strcmp(attr, "mode") == 0) {
            if (S_ISREG(st.st_mode))
                lua_pushstring(L, "file");
            else if (S_ISDIR(st.st_mode))
                lua_pushstring(L, "directory");
            else
                lua_pushstring(L, "other");
        }
        else if (strcmp(attr, "size") == 0) {
            lua_pushinteger(L, st.st_size);
        }
        else if (strcmp(attr, "access") == 0) {
            lua_pushinteger(L, st.st_atime);
        }
        else if (strcmp(attr, "modification") == 0) {
            lua_pushinteger(L, st.st_mtime);
        }
        else if (strcmp(attr, "change") == 0) {
            lua_pushinteger(L, st.st_ctime);
        }
        else {
            lua_pushnil(L);
        }
        return 1;
    }
    lua_newtable(L);
    if (S_ISREG(st.st_mode))
        lua_pushstring(L, "file");
    else if (S_ISDIR(st.st_mode))
        lua_pushstring(L, "directory");
    else
        lua_pushstring(L, "other");
    lua_setfield(L, -2, "mode");

    lua_pushinteger(L, st.st_size);
    lua_setfield(L, -2, "size");

    lua_pushinteger(L, st.st_atime);
    lua_setfield(L, -2, "access");

    lua_pushinteger(L, st.st_mtime);
    lua_setfield(L, -2, "modification");

    lua_pushinteger(L, st.st_ctime);
    lua_setfield(L, -2, "change");
    return 1;
}

/* Função: lfs.chdir */
static int l_chdir(lua_State* L) {
    const char* path = luaL_checkstring(L, 1);
    if (chdir(path) != 0) {
        lua_pushnil(L);
        lua_pushfstring(L, "cannot change directory to %s", path);
        return 2;
    }
    lua_pushboolean(L, 1);
    return 1;
}

/* Função: lfs.currentdir */
static int l_currentdir(lua_State* L) {
    char buffer[1024];
    if (getcwd(buffer, sizeof(buffer)) == NULL)
        return luaL_error(L, "cannot get current directory");
    lua_pushstring(L, buffer);
    return 1;
}

/* Função: lfs.touch */
static int l_touch(lua_State* L) {
    const char* path = luaL_checkstring(L, 1);
    time_t current = time(NULL);
    struct utimbuf times;
    times.actime = current;
    times.modtime = current;
    if (utime(path, &times) != 0) {
        FILE* fp = fopen(path, "ab");
        if (!fp) {
            lua_pushnil(L);
            lua_pushfstring(L, "cannot touch %s", path);
            return 2;
        }
        fclose(fp);
        if (utime(path, &times) != 0) {
            lua_pushnil(L);
            lua_pushfstring(L, "cannot update time for %s", path);
            return 2;
        }
    }
    lua_pushboolean(L, 1);
    return 1;
}

/* Função: lfs.lock (stub) */
static int l_lock(lua_State* L) {
    lua_pushnil(L);
    lua_pushstring(L, "lock not implemented");
    return 2;
}

/* Funções auxiliares extras */
static int l_isdir(lua_State* L) {
    const char* path = luaL_checkstring(L, 1);
    struct stat st;
    if (stat(path, &st) == 0 && S_ISDIR(st.st_mode))
        lua_pushboolean(L, 1);
    else
        lua_pushboolean(L, 0);
    return 1;
}

static int l_isfile(lua_State* L) {
    const char* path = luaL_checkstring(L, 1);
    struct stat st;
    if (stat(path, &st) == 0 && S_ISREG(st.st_mode))
        lua_pushboolean(L, 1);
    else
        lua_pushboolean(L, 0);
    return 1;
}

static int l_listdir(lua_State* L) {
    const char* path = luaL_checkstring(L, 1);
    DIR* dir = opendir(path);
    if (!dir) {
        lua_pushnil(L);
        return 1;
    }
    struct dirent* entry;
    lua_newtable(L);
    int i = 1;
    while ((entry = readdir(dir)) != NULL) {
        lua_pushstring(L, entry->d_name);
        lua_rawseti(L, -2, i++);
    }
    closedir(dir);
    return 1;
}

static int l_filesize(lua_State* L) {
    const char* path = luaL_checkstring(L, 1);
    struct stat st;
    if (stat(path, &st) == 0)
        lua_pushinteger(L, st.st_size);
    else
        lua_pushnil(L);
    return 1;
}

/* Mapeamento das funções para o módulo lfs */
static const struct luaL_Reg luafs[] = {
    {"attributes", l_attributes},
    {"chdir", l_chdir},
    {"currentdir", l_currentdir},
    {"dir", l_dir},
    {"touch", l_touch},
    {"lock", l_lock},
    {"isdir", l_isdir},
    {"isfile", l_isfile},
    {"listdir", l_listdir},
    {"filesize", l_filesize},
    {NULL, NULL}
};

/* Função de inicialização da biblioteca */
EXPORT int luaopen_luafs(lua_State* L) {
#if LUA_VERSION_NUM >= 502
    luaL_newlib(L, luafs);
#else
    luaL_register(L, "luafs", luafs);
#endif
    return 1;
}
