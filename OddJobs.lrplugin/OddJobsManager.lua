--[[
        OddJobsManager.lua
--]]


local OddJobsManager, dbg, dbgf = Manager:newClass{ className='OddJobsManager' }



--[[
        Constructor for extending class.
--]]
function OddJobsManager:newClass( t )
    return Manager.newClass( self, t )
end



--[[
        Constructor for new instance object.
--]]
function OddJobsManager:new( t )
    return Manager.new( self, t )
end



--- Initialize global preferences.
--
function OddJobsManager:_initGlobalPrefs()
    -- Instructions: delete the following line (or set property to nil) if this isn't an export plugin.
    --fprops:setPropertyForPlugin( _PLUGIN, 'exportMgmtVer', "2" ) -- a little add-on here to support export management. '1' is legacy (rc-common-modules) mgmt.
    -- Instructions: uncomment to support these external apps in global prefs, otherwise delete:
    -- app:initGlobalPref( 'exifToolApp', "" )
    -- app:initGlobalPref( 'mogrifyApp', "" )
    -- app:initGlobalPref( 'sqliteApp', "" )
    -- app:registerPreset( "My Preset", 2 )
    Manager._initGlobalPrefs( self )
end



--- Initialize local preferences for preset.
--
--  @usage **** Prefs defined here will overwrite like-named prefs if defined via system-settings.
--
function OddJobsManager:_initPrefs( presetName )
    -- Instructions: uncomment to support these external apps in local (preset) prefs, otherwise delete:
    -- app:initPref( 'imageMagickDir', "", presetName ) -- for Image Magick support.
    -- app:initPref( 'exifToolApp', "", presetName )
    -- app:initPref( 'mogrifyApp', "", presetName ) - deprecated.
    -- app:initPref( 'sqliteApp', "", presetName )
    -- *** Instructions: delete this line if no async init or continued background processing:
    app:initPref( 'autoStartMaintainPhotoSelections', false, presetName ) -- true to support on-going background processing, after async init (auto-update most-sel photo).
    -- *** Instructions: delete these 3 if not using them:
    --app:initPref( 'processSelectedPhotosInBackground', false, presetName )
    --app:initPref( 'processVisiblePhotosInBackground', false, presetName )
    --app:initPref( 'processAllPhotosInBackground', false, presetName )
    --app:initPref( 'backgroundPeriod', .1, presetName ) -- hard-wired to base background class.
    Manager._initPrefs( self, presetName )
end



--- Start of plugin manager dialog.
-- 
function OddJobsManager:startDialogMethod( props )
    -- *** Instructions: uncomment if you use these apps and their exe is bound to ordinary property table (not prefs).
    Manager.startDialogMethod( self, props ) -- adds observer to all props.

    -- ###0 delete this if not using general help.
    app:call( Call:new{ name="Welcome", async=true, guard=App.guardSilent, main=function( call )
        app:show{ info="Welcome to ^1.\n \nFor general plugin help - see \"Help (menu) -> Plugin Extras -> ^2 -> General Help\".\n \nTo quit showing this and other suppressible dialog boxes, check the 'Don't show again' box. To show this and other suppressed dialog boxes again, click the 'Reset Prompt Dialogs' button in top section of plugin manager.",
            subs = { app:getAppName(), app:getPluginName() },
            actionPrefKey = "Welcome - general help...",
        }
    end } )
    
end



--- Preference change handler.
--
--  @usage      Handles preference changes.
--              <br>Preferences not handled are forwarded to base class handler.
--  @usage      Handles changes that occur for any reason, one of which is user entered value when property bound to preference,
--              <br>another is preference set programmatically - recursion guarding is essential.
--
function OddJobsManager:prefChangeHandlerMethod( _id, _prefs, key, value )
    Manager.prefChangeHandlerMethod( self, _id, _prefs, key, value )
end



--- Property change handler.
--
--  @usage      Properties handled by this method, are either temporary, or
--              should be tied to named setting preferences.
--
function OddJobsManager:propChangeHandlerMethod( props, name, value, call )
    if app.prefMgr and (app:getPref( name ) == value) then -- eliminate redundent calls.
        -- Note: in managed cased, raw-pref-key is always different than name.
        -- Note: if preferences are not managed, then depending on binding,
        -- app-get-pref may equal value immediately even before calling this method, in which case
        -- we must fall through to process changes.
        return
    end
    -- *** Instructions: strip this if not using background processing:
    if name == 'autoStartMaintainPhotoSelections' then
        app:setPref( 'autoStartMaintainPhotoSelections', value )
        if value then
            app:show{ info="Reload plugin to start 'Maintain Photo Selections' as it would be when Lightroom starts up, if not already running.", actionPrefKey="Reload for startup action" }
        else
            app:show{ info="Close 'Maintain Photo Selections' window to kill it, if running.", actionPrefKey="Close to kill" }
        end
    -- *** and strip this if not using Image Magick.
    elseif name == 'imageMagickDir' then
        if gbl:getValue( 'imageMagick' ) then 
            imageMagick:processDirChange( value )
        else
            app:showBezel( { dur=1, holdoff=0 }, "Image Magick global variable not defined." )
        end
    else
        -- Note: preference key is different than name.
        Manager.propChangeHandlerMethod( self, props, name, value, call )
        -- Note: properties are same for all plugin-manager presets, but the prefs were they get saved changes with the preset.
    end
end



--- Sections for bottom of plugin manager dialog.
-- 
function OddJobsManager:sectionsForBottomOfDialogMethod( vf, props)

    local appSection = {}
    if app.prefMgr then
        appSection.bind_to_object = props
    else
        appSection.bind_to_object = prefs
    end
    
	appSection.title = app:getAppName() .. " Settings"
	appSection.synopsis = bind{ key='presetName', object=prefs }

	appSection.spacing = vf:label_spacing()

	appSection[#appSection + 1] = vf:row {
	    vf:static_text { -- ###1: consider replacing with something more appropriate..
	        --title = "There is nothing to configure here, but consider perusing the \"advanced settings\" in 'Preset Manager' section.\n \nReminder: visit Help (Lr menu) -> Plugin Extras for more info..."
	        title = "There is not much to configure here - just check the 'Maintain Photo Selections' box below.\n \nReminder: visit Help (Lr menu) -> Plugin Extras for more info..."
	    }
	}
	
    appSection[#appSection + 1] = vf:spacer{ height=10 }
    appSection[#appSection + 1] =
        vf:row {
            vf:checkbox {
                title = "Start 'Maintain Photo Selections' with Lightroom",
                value = bind( 'autoStartMaintainPhotoSelections' ),
                tooltip = "If this box is checked, 'Maintain Photo Selections' will be started when Lightroom starts, or when the plugin is reloaded (see plugin author section here in plugin manager); if unchecked, it will not be started with Lightroom - you'll still have to kill it by closing the window, if it's open and you want it dead..",
            },
        }


    --  A D D I T I O N A L   S E T T I N G S
    local addlSection = {
        bind_to_object = nil, -- addl-binding is hard-coded to prefs.
        title = app:getAppName() .. " Additional Settings",
        -- no synopsis, yet ###0
    }
    local addlSection = appSection -- ###0
    if false then -- "uncomment" this to have additional view items inline, if there are any defined in "Settings" file.
        app:pcall { name = "Additional View Items for Bottom of Plugin Manager Dialog", main= function( call )
            local viewItems, viewLookup, errm = systemSettings:getViewItemsAndLookup( call )
    
            if tab:isNotEmpty( viewItems ) then
                if addlSection == appSection then
                    addlSection[#addlSection + 1] = vf:spacer{ height=10 }
                    addlSection[#addlSection + 1] = vf:separator{ fill_horizontal=.9 }
                    addlSection[#addlSection + 1] = vf:row {
                        --vf:spacer{ width=share'label_width' }, -- used in 'Settings' class.
                        vf:static_text {
                            title = "Additional Settings",
                            width = share'addl_sets_lbl_wid',
                        },
                    }
                    addlSection[#addlSection + 1] = vf:row {
                        --vf:spacer{ width=share'label_width' }, -- used in 'Settings' class.
                        vf:separator {
                            width = share'addl_sets_lbl_wid',
                        },
                    }
                    addlSection[#addlSection + 1] = vf:spacer{ height=10 }
                end
                for i, v in ipairs( viewItems ) do
                    addlSection[#addlSection + 1] = v
                end
            else
                Debug.pause( "Thee are no settings view items." )
            end
        end }
    end

    --[[
    if false then -- "uncomment" this to have additional settings as a button.
        appSection[#appSection + 1] = vf:spacer{ height=10 }
        appSection[#appSection + 1] = vf:row {
            vf:push_button {
                title = "View/Edit Additional Settings",
                action = function( button )
    			    app:call( Call:new{ name=button.title, async=true, guard=App.guardVocal, main=function( call )
    
                        local viewItems, viewLookup, errm = systemSettings:getViewItemsAndLookup( call ) -- note: this tosses error since it's the "root" items, if none.
                
                        if tab:isNotEmpty( viewItems ) then
                        
                            --Debug.lognpp( viewItems, viewLookup )
                        
                            local button = app:show{ info="Additional Settings",
                                viewItems = viewItems,
                            }
                
                            if button == 'ok' then
                                -- ok
                            else
                                call:cancel()
                                return
                            end
                            
                        else
                            app:show{ warning="no view items" }
                            call:cancel()
                            return
                        end
                        
                    end, finale=function( call )
                        if not call:isCanceled() then
                            --Debug.showLogFile()
                        end
                    end } )
                
                end,
            },
            vf:static_text {
                title = "Miscellaneous settings, defined initially by me, can be refined by you...",
            },
        }
    end
    --]]
    
    --[[
    if not app:isRelease() or app:isAdvDbgEna() then
    	appSection[#appSection + 1] = vf:push_button {
    	    title = "Evaluate Additional Settings",
    	    action = function( button )
    	        app:service{ name=button.title, async=true, guard=App.guardVocal, main=function( call )
    	            app:log()
    	            app:log( "Evaluating prefs/settings:" )
    	            call:initStats{ 'eval', 'keys' }
    	            call:setStat( 'keys', tab:countItems( systemSettings.lookup ) )
    	            local evaluated = {}
    	            local function eval( key, spec )
        	            local v1, v2
        	            if spec.dataType ~= 'array' then
            	            v1 = app:getPref( spec.id )
            	            v2 = systemSettings:getValue( key )
            	            -- [ [ works for simple test functions, but otherwise may not be such a good idea:
            	            if type( v1 ) == 'function' then
            	                v1 = v2{ paramOne="ValueOne", paramTwo="ValueTwo\netc..." }
            	            else -- assertion holds true if proxied function, but not on-the-fly compilation of text function.
            	                app:assert( v1==v2, "pref/setting value mismatch for '^1' (^2), pref: ^3, setting: ^4", spec.id, key, v1, v2 )
            	            end
            	            -- ] ]
        	                call:incrStat( 'eval' )
            	            app:log( "^1: ^2", spec.id, str:to( v1 ) )
            	        else
            	            v1 = app:getPref( arrName )
            	            Debug.pause( spec.id, arrName, v1 )
            	        end
    	            end
    	            local function evalArray( key, spec )
    	                app:log()
            	        local va1 = app:getPref( spec.id ) -- selected array item only, unless 'whole' is specified in spec itself.
            	        Debug.pauseIf( type( va1 ) ~= 'table' )
            	        local va2
            	        if not spec.whole then
    	                    app:log( "Evaluating array (selection) setting" )
            	            local va = systemSettings:getValue( spec.id ) -- not whole
            	            app:assert( tab:isEquivalent( va1, va ), "va1(sel) ~= va2(sel)" )
                	        for i, x in ipairs{ va } do
            	                Debug.pauseIf( type( x ) ~= 'table', type( x ) )
                    	        for k, v in pairs( x ) do
                    	            app:log( "^1: ^2", k, v )
                    	        end
                    	    end
                	        va2 = systemSettings:getValue( spec.id, nil, { whole=true } )
            	        else
    	                    app:log( "Evaluating array (whole) setting" )
                	        va2 = systemSettings:getValue( spec.id, nil, { whole=true } )
                	        app:assert( tab:isEquivalent( va1, va2 ), "va1(whole) ~= va2(whole)" )
          	                Debug.pauseIf( type( va2 ) ~= 'table', type( va2 ) )
                	        for i, x in ipairs( va2 ) do
            	                Debug.pauseIf( type( x ) ~= 'table', type( x ) )
                    	        for k, v in pairs( x ) do
                    	            app:log( "^1: ^2", k, v )
                    	        end
                    	    end
            	        end
       	                Debug.pauseIf( type( va2 ) ~= 'table', type( va2 ) )
              	        for i, x in ipairs( va2 ) do
            	            if type( x ) == 'table' then
                    	        for k, v in pairs( x ) do
                    	            evaluated[k] = true
            	                    call:incrStat( 'eval' )
                    	        end
                        	else
                        	    app:logV( "Array value not table: ^1, spec-id: ^1, assuming valid..", type( x ), spec.id )
                    	    end
                            call:incrStat( 'eval' )
                    	end
    	                app:log()
    	            end
    	            for key, spec in pairs( systemSettings.lookup ) do
    	                if spec.dataType == 'array' then
        	                local s, m = LrTasks.pcall( evalArray, key, spec )
        	                if not s then
        	                    app:logE( "Problem evaluating array, key: ^1, spec.id: ^2 - ^3", key, spec.id, m )
        	                end
        	            end
        	        end
    	            for key, spec in pairs( systemSettings.lookup ) do
    	                if spec.dataType ~= 'array' and not evaluated[spec.id] then
        	                local s, m = LrTasks.pcall( eval, key, spec )
        	                if not s then
        	                    app:logE( "Problem evaluating (non-array) setting, key: ^1, spec.id: ^2 - ^3", key, spec.id, m )
        	                end
        	            end
        	        end
    	        end, finale=function( call )
    	            app:log()
      	            app:log( "^1.", str:nItems( call:getStat( 'keys' ), "high-level setting keys" ) )
      	            app:log( "^1 evaluated.", str:nItems( call:getStat( 'eval' ), "setting elements" ) )
    	            app:log()
    	        end }
    	    end,
    	}
    end
    --]]
        
    if not app:isRelease() then
    	appSection[#appSection + 1] = vf:spacer{ height = 20 }
    	appSection[#appSection + 1] = vf:static_text{ title = 'For plugin author only below this line:' }
    	appSection[#appSection + 1] = vf:separator{ fill_horizontal = 1 }
    	appSection[#appSection + 1] = 
    		vf:row {
    			vf:edit_field {
    				value = bind( "testData" ),
    			},
    			vf:static_text {
    				title = str:format( "Test data" ),
    			},
    		}
    	appSection[#appSection + 1] = 
    		vf:row {
    			vf:push_button {
    				title = "Test",
    				action = function( button )
    				    app:service{ name=button.title, async=true, guard=App.guardVocal, main=function( call )
                            app:show( { info="^1: ^2" }, str:to( app:getGlobalPref( 'presetName' ) or 'Default' ), app:getPref( 'testData' ) )
                        end }
    				end
    			},
    			vf:static_text {
    				title = str:format( "Perform tests." ),
    			},
    		}
    end

    local sections = Manager.sectionsForBottomOfDialogMethod ( self, vf, props ) -- fetch base manager sections.
    if #appSection > 0 then
        local otherSection = addlSection and addlSection ~= appSection and addlSection or nil -- in other words, other section is nill unless defined and distinct from app section.
        tab:appendArray( sections, { appSection, otherSection } ) -- put app-specific prefs after.
    end
    return sections
end



return OddJobsManager
-- the end.