--[[
        mHelp.lua
--]]


local Help = {}


local dbg, dbgf = Object.getDebugFunction( 'Help' ) -- Usually not registered for conditional dbg support via plugin-manager, but can be (in Init.lua).



--[[
        Synopsis:           Provides help text as quick tips.
        
        Notes:              Accessed directly from plugin menu.
        
        Returns:            X
--]]        
function Help.general()

    app:call( Call:new{ name="General Help", main=function( call )
    
        local m = {}
        m[#m + 1] = str:fmtx( "This plugin has two kinds of help:\n1. In context (plugin UI, log file...).\n2. On the web (often comprehensive and current...)." )
        m[#m + 1] = str:fmtx( "Visit the 'Plugin Manager' for administration and configuration - it's on Lightroom's 'File' menu (the most important sections are at the top *and* bottom)." )
        
        -- ###0 delete if no advanced settings worth talking about:
        --m[#m + 1] = str:fmtx( "In addition to the settings in plugin manager, there may be \"advanced\" settings worth having a peek at, and maybe a tweak at. Such are accessed by first creating a new preset in the preset manager section, then editing a (lua) text configuration file." )
        
        -- ###0 consider re-wording if not quite accurate.
        m[#m + 1] = str:fmtx( "This plugin does not, yet, have any features which can be accessed from 'Plugin Extras' branch of the 'File' and/or 'Library' menu." )
        
        m[#m + 1] = str:fmtx( "Reminder: To show previously suppressed dialog boxes again (those with \"Don't show again\" checked), click the 'Reset Prompt Dialogs' button in top section of plugin manager." )
        
        dia:quickTips( m )
        
    end } )
end


Help.general()
    
    
