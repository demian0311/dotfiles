// eagle-zoom: Hyprland plugin. Ctrl + two-finger scroll on the touchpad zooms
// the screen around the pointer, as macOS Accessibility Zoom does.
//
// Why a plugin: Hyprland only matches mouse_down/mouse_up binds on wheel-source
// axis events (src/keybinds/Manager.cpp, still true on main); a touchpad scroll
// arrives with WL_POINTER_AXIS_SOURCE_FINGER and no bind can see it. The Lua
// config has no pointer event either. Dotfiles issue #10.
//
// Also exposes hl.plugin.zoom.{get,set,by,toggle} so keyboard binds share the
// same zoom state as the scroll and the pinch gesture (monitor m_cursorZoom),
// instead of the cursor.zoom_factor config value.

#include <src/plugins/PluginAPI.hpp>
#include <src/managers/input/InputManager.hpp>
#include <src/output/Monitor.hpp>
#include <src/state/MonitorState.hpp>
#include <src/state/MonitorQuery.hpp>
#include <src/devices/IKeyboard.hpp>
#include <src/config/ConfigValue.hpp>
#include <src/debug/log/Logger.hpp>

// Lua headers are C; without extern "C" the references mangle to C++ names
// nobody provides, and lazy binding hides that until first use, which kills
// the compositor (dotfiles #12, 2026-10-17).
extern "C" {
#include <lua.h>
#include <lauxlib.h>
}

#include <algorithm>
#include <cmath>
#include <stdexcept>
#include <string_view>

namespace {
    HANDLE              g_handle = nullptr;
    CHyprSignalListener g_axisListener;
    float               g_zoomLast = 2.F; // what toggle returns to

    constexpr float ZOOM_MIN      = 1.F;
    constexpr float ZOOM_MAX      = 10.F;
    constexpr float ZOOM_SNAP     = 1.05F; // below this, snap to 1
    constexpr float SCROLL_RATE   = 0.015F; // zoom = exp(rate * scroll units)
    constexpr uint32_t LOCK_MODS  = HL_MODIFIER_CAPS | HL_MODIFIER_MOD2 | HL_MODIFIER_MOD3 | HL_MODIFIER_MOD5;

    PHLMONITOR monitorUnderCursor() {
        return State::monitorState()->query().vec(g_pInputManager->getMouseCoordsInternal()).run();
    }

    float currentZoom() {
        const auto mon = monitorUnderCursor();
        return mon ? mon->m_cursorZoom->goal() : 1.F;
    }

    // warp: jump straight to the value (continuous input); otherwise animate.
    void setZoom(float zoom, bool warp) {
        zoom = std::clamp(zoom, ZOOM_MIN, ZOOM_MAX);
        if (zoom < ZOOM_SNAP)
            zoom = 1.F;
        if (zoom > 1.F)
            g_zoomLast = zoom;

        for (const auto& mon : State::monitorState()->monitors()) {
            if (warp)
                mon->m_cursorZoom->setValueAndWarp(zoom);
            else
                *mon->m_cursorZoom = zoom;
        }
    }

    void onAxis(const IPointer::SAxisEvent& e, Event::SCallbackInfo& info) {
        if (e.source != WL_POINTER_AXIS_SOURCE_FINGER || e.axis != WL_POINTER_AXIS_VERTICAL_SCROLL)
            return;

        const uint32_t mods = g_pInputManager->getModsFromAllKBs() & ~LOCK_MODS;
        if (mods != HL_MODIFIER_CTRL)
            return;

        // Consume the scroll so the window under the pointer does not scroll too.
        info.cancelled = true;

        if (e.delta == 0.0) // axis stop frame at the end of the gesture
            return;

        static auto PNATURAL = CConfigValue<Config::INTEGER>("input:touchpad:natural_scroll");
        // libinput inverts the axis sign under natural scrolling; recover finger direction.
        const bool fingersUp = *PNATURAL ? e.delta > 0.0 : e.delta < 0.0;
        const float ratio    = std::exp((fingersUp ? 1.F : -1.F) * static_cast<float>(std::abs(e.delta)) * SCROLL_RATE);

        setZoom(currentZoom() * ratio, true);
    }

    int luaGet(lua_State* L) {
        lua_pushnumber(L, currentZoom());
        return 1;
    }

    int luaSet(lua_State* L) {
        setZoom(static_cast<float>(luaL_checknumber(L, 1)), false);
        return 0;
    }

    int luaBy(lua_State* L) {
        setZoom(currentZoom() * static_cast<float>(luaL_checknumber(L, 1)), false);
        return 0;
    }

    int luaToggle(lua_State* L) {
        setZoom(currentZoom() > 1.F ? 1.F : g_zoomLast, false);
        return 0;
    }
}

APICALL EXPORT std::string PLUGIN_API_VERSION() {
    return HYPRLAND_API_VERSION;
}

APICALL EXPORT PLUGIN_DESCRIPTION_INFO PLUGIN_INIT(HANDLE handle) {
    g_handle = handle;

    if (std::string_view{__hyprland_api_get_hash()} != std::string_view{__hyprland_api_get_client_hash()}) {
        HyprlandAPI::addNotification(g_handle, "[eagle-zoom] built for another Hyprland commit; rebuild with eagle/zoom/install.sh",
                                     CHyprColor{1.0, 0.2, 0.2, 1.0}, 8000);
        throw std::runtime_error("[eagle-zoom] version mismatch");
    }

    g_axisListener = Event::bus()->m_events.input.mouse.axis.listen(onAxis);

    const auto addLuaFn = [](const std::string& name, PLUGIN_LUA_FN fn) {
        if (!HyprlandAPI::addLuaFunction(g_handle, "zoom", name, fn))
            Log::logger->log(Log::ERR, "eagle-zoom: failed to register hl.plugin.zoom.{}", name);
    };
    addLuaFn("get", luaGet);
    addLuaFn("set", luaSet);
    addLuaFn("by", luaBy);
    addLuaFn("toggle", luaToggle);

    return {"eagle-zoom", "Ctrl + two-finger scroll zooms the screen (macOS-style)", "demian", "1.0"};
}

APICALL EXPORT void PLUGIN_EXIT() {
    g_axisListener.reset();
}
