# EllesmereUI

## [v9.3.4](https://github.com/EllesmereGaming/EllesmereUI/tree/v9.3.4) (2026-09-30)
[Full Changelog](https://github.com/EllesmereGaming/EllesmereUI/compare/v9.3.3...v9.3.4) [Previous Releases](https://github.com/EllesmereGaming/EllesmereUI/releases)

- Release v9.3.4  
- Merge pull request #2345 from JuJuFX-dev/refactor/core-panel-split  
- Merge pull request #2344 from JuJuFX-dev/refactor/core-visibility-split  
- Merge pull request #2340 from JuJuFX-dev/refactor/core-pixelperfect-split  
- Merge pull request #2339 from JuJuFX-dev/refactor/core-profilesync-split  
- Merge pull request #2338 from JuJuFX-dev/refactor/core-fonts-colors-split  
- Merge pull request #2337 from JuJuFX-dev/refactor/core-popups-split  
- Merge remote-tracking branch 'origin/main'  
- Load EllesmereUI\_Panel.lua right after EllesmereUI.lua  
    Adds the file header and re-imports, exports STYLE, THEME\_BG\_FILES and IS\_STANDALONE for it, and reads the main frame and the active page through EllesmereUI in the two remaining core call sites.  
- Move the options panel shell out of EllesmereUI.lua  
- Merge pull request #2343 from Barbiero/locale/ptbr-since-932  
    ptBR: translate v9.3.2 options (Mythic+ Timer, Glows, Gamepad, portrait dragon, end caps, WoW Forever)  
- ptBR: translate Mythic+ Timer bar options, Glows page, Gamepad page, portrait dragon, cast icon border, action bar end caps and WoW Forever druid/flight timer options  
- Load the visibility rules and shared helpers right after EllesmereUI.lua  
    Adds the file headers and the .toc entries. Both files load directly after EllesmereUI.lua, where the moved code ran before, so the load order is unchanged. The two banners that point at the 200-local cap now name EllesmereUI.lua.  
- Move the visibility rules and shared helpers out of EllesmereUI.lua  
    Verbatim move of the tail of EllesmereUI.lua: the shared visibility system into EllesmereUI\_VisibilityRules.lua, the frame data store, skin registry, cast bar ownership and the remaining shared helpers into EllesmereUI\_SharedHelpers.lua. File headers and the .toc entries follow in the next commit.  
- Load EllesmereUI\_PixelPerfect.lua before EllesmereUI.lua  
- Move the pixel perfect and border blocks out of EllesmereUI.lua  
- Load EllesmereUI\_ProfileSync.lua after the fonts  
- Move the profile sync blocks out of EllesmereUI.lua  
- Load EllesmereUI\_Colors.lua and EllesmereUI\_Fonts.lua after the popups  
    Adds the file headers and loads both files right after  
    EllesmereUI\_Popups.lua. Colors re-imports CLASS\_COLOR\_MAP and Fonts  
    re-imports MEDIA\_PATH. ResolveFontName now reads  
    EllesmereUI.LOCALE\_FONT\_FALLBACK instead of the file-local copy, because  
    RefreshLocaleFontFallback reassigns it at runtime and always updates the  
    field together with the local.  
- Move the font and colour blocks out of EllesmereUI.lua  
    Moves the global colour system, Dark Mode, the class colour getters and  
    the power/resource colour block verbatim into the new  
    EllesmereUI\_Colors.lua, and the global font system with its resolution  
    cache into the new EllesmereUI\_Fonts.lua. The crit/haste helpers and  
    UnitEffectiveRole, which sat between the colour blocks, stay in  
    EllesmereUI.lua. Nothing else changes in this commit; the next one adds  
    the file headers and the .toc entries, so this commit alone does not load.  
- Load EllesmereUI\_Popups.lua right after EllesmereUI.lua  
    Adds the client gate, a file header and the re-imports of the nine  
    EllesmereUI.lua locals the popup code uses; all of them are already  
    exported and none is reassigned after load. The file loads directly  
    after EllesmereUI.lua, which only calls the popups from function bodies.  
- Move the popup block out of EllesmereUI.lua  
    Moves the popup scale helper, the announcement shell and buttons, the  
    reload helpers, and the confirm, info and input popups verbatim into the  
    new EllesmereUI\_Popups.lua. Nothing else changes in this commit; the next  
    one adds the file header and the .toc entry, so this commit alone does  
    not load.  
