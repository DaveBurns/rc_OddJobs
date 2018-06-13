--[[
        OddJobs.lua
--]]


local OddJobs, dbg, dbgf = Object:newClass{ className = "OddJobs", register = true }



--- Constructor for extending class.
--
function OddJobs:newClass( t )
    return Object.newClass( self, t )
end


--- Constructor for new instance.
--
function OddJobs:new( t )
    local this = Object.new( self, t )
    -- assign other members, if desired..
    return this
end



-- script emulations - this plugin started out being a true 'Script' (not a plugin).
-- note: app--display-info method's default options are: dur=3 and holdoff=1.2.
local function infoMessage( fmt, ... )
    -- display is same as show-bezel, except with app-name prefix.
    app:display( {dur=1.5, holdoff=0}, fmt, ... ) -- after debugging, all info is of the "not very important" / overwritable variety, thus short duration and no holdoff.
end



-- present UI as floating dialog box, and handle everything until closed..
function OddJobs:maintainPhotoSelections()
    -- variables accessible in finale method (could also be assigned to call object).
    app:service{ name="Maintain Photo Selections", async=true, guard=App.guardVocal, function( call )
        
        local props = LrBinding.makePropertyTable( call.context ) -- use temporary properties - no need for persistence.
        props.saving = "Working.."
        props.restoring = "(click red 'x' to close)."
        local lookup = {} -- indexed by source(s), contains saved photo selections for restoral.
        local toFront -- no need for window in front, but here is the function that would do it anyway..
        local close -- sometimes called redundently, but Lr seems to weather it OK.
        
        -- this function just assures we've gotten the obligatory callback before getting too happy..
        -- upon return, we are guaranteed to have to-front and close methods callable, whether we use them or not..
        local function waitForStartup()
            app:sleep( 15, .1, function()
                return toFront
            end )
            if toFront then
                return true
            else
                return false, "Not starting up quickly enough.."
            end
        end
        
        -- no need for function since main-view not presented in loop, still.. (doesn't hurt).
        local function getMainView()
            local vi = {}
            vi[#vi + 1] = vf:row {
                vf:static_text {
                    bind_to_object = props,
                    title = bind 'saving',
                    width_in_chars = 35, -- truncate long source names
                },
            }
            vi[#vi + 1] = vf:row {
                vf:static_text {
                    bind_to_object = props,
                    title = bind 'restoring',
                    width_in_chars = 35, -- truncate long source names
                },
            }
            return vf:view( vi )
        end
        
        -- get key based on sources, if only 1, then it's the src object itself (a unique pointer, under the hood).
        -- if multiple, then a digest of all local identifiers (collections), or paths (folders), or ... ###1
        local function getKeyAndName( srcs )
            if #srcs == 1 then
                local src = srcs[1]
                local name, id = cat:getSourceName( src )
                return src, name
            else -- it's a *new* array of sources.
                local b = {}
                for i, src in ipairs( srcs ) do
                    local name, id = cat:getSourceName( src )
                    app:assert( id ~= nil, "no source ID for ^1", name )
                    b[#b + 1] = id
                end
                return LrMD5.digest( table.concat( b ) ), "Multiple sources"
            end
        end

        local prevTarget -- used for computing most-sel target photo change.
        
        local saveIndic = ""
        local updIndic = ""
        -- save photo selections for specified sources.
        local function save( srcs, tp, tpp )
            if tp and tpp then
                local key, name = getKeyAndName( srcs )
                local photoTable = lookup[key]
                if photoTable then
                    photoTable.targetPhoto = tp
                    photoTable.selectedPhotos = tpp
                    --infoMessage( "Photo selections updated, source name: ^1, most-del: ^2, #sel: ^3", name, photoTable.targetPhoto:getFormattedMetadata( 'fileName' ), #photoTable.selectedPhotos )
                    props.saving = str:fmtx( "Updated: ^1 - ^2 selected^3", name, str:pluralize( #tpp, "photo" ), updIndic ) 
                    if updIndic == "" then
                        updIndic = "*"
                    else
                        updIndic = ""
                    end
                else
                    lookup[key] = { targetPhoto = tp, selectedPhotos = tpp }
                    photoTable = lookup[key]
                    --infoMessage( "Photo selections recorded, source name: ^1, most-del: ^2, #sel: ^3", name, photoTable.targetPhoto:getFormattedMetadata( 'fileName' ), #photoTable.selectedPhotos )
                    props.saving = str:fmtx( "Saved (first time): ^1 - ^2 selected^3", name, str:pluralize( #tpp, "photo" ), saveIndic ) 
                    if saveIndic == "" then
                        saveIndic = "*"
                    else
                        saveIndic = ""
                    end
                end
            end
            prevTarget = tp
        end
        
        local rstIndic = ""
        -- restore saved photo selections for specified sources.
        local function restore( srcs )
            local key, name = getKeyAndName( srcs )
            local rec = lookup[key]
            if rec then
                local s, _m -- reminder: if odd-jobs insists on having selection as was previous, then plugins which switch source then override previous selection don't work, on the other hand: OddJobs must make a concerted effort lest it be flaky, when there is no such interference - it's a balancing act..
                -- bottom-line: OddJobs is making a concerted effort, but if another plugin uses assure-sel method (after a delay), it will win out.
                --if app:getPref( 'okToClearViewFilter' ) then -- system-setting.
                    -- clear view filter if selected photos not selecting.
                --    s, _m = cat:assureSelectedPhotos( rec.selectedPhotos, rec.targetPhoto, true ) -- try, fairly hard, to select photos, but do NOT resort to changing photo sources to do it.
                --else
                    s, _m = cat:tryToSelectPhotos( rec.selectedPhotos, rec.targetPhoto ) -- as-of v1.2 it will no longer clear view filter to assure photo selection - you get what you get after a fair try (~150ms)..
                --end
                if s then
                    --infoMessage( "recorded photo selections restored - source name: ^1", name )
                    props.restoring = str:fmtx( "Photo selections restored: ^1^2", name or "unknown", rstIndic ) -- I think there will always be a name, but cheap insurance..
                else
                    props.restoring = str:fmtx( "Photo selections restored?: ^1^2", name or "unknown", rstIndic ) -- restoration not confirmed in timely enough fashion, but that does not mean they didn't eventually take..
                    app:log( "*** unable to confirm photo selection restoral for '^1' - ^2", name, _m ) -- user can always check the log to see if this has happened..
                    infoMessage( "unable to confirm photo selection restoral for '^1'", name ) -- this used to be a more severe warning, but it's seeming better to downplay - it's normal if user is yanking selections around wrecklessly..
                end
                if rstIndic == "" then
                    rstIndic = "*"
                else
                    rstIndic = ""
                end
                prevTarget = rec.targetPhoto
                return true -- lookup exists already, whether successful restoration or not.
            else
                --infoMessage( "No recorded photo selections for source: ^1", name )
                props.restoring = str:fmtx( "Source (nothing restored): ^1", name or "unknown" ) -- I think there will always be a name, but cheap insurance..
                -- note: will save upon return, which saves prev-target
            end
        end
        
        local srcChg   -- flags a source change needs to be processed (without queueing them up).
        local targsChg -- flags a target set change needs to be processed (without queueing them up).
        
        -- start a persistent task to detect and process changes to source, targets, or most-sel target.
        -- it terminates when outer context dies (i.e. user closes frame), or an uncaught error occurs.
        app:pcall{ name="Target Photo Change Watcher", async=true, function( icall )
            infoMessage( "'^1' background task has started.", call.name )
            local started, message = waitForStartup()
            if started then -- to-front exists.
                infoMessage( "'^1' is running.", call.name )
            else
                if message then -- timed out (as opposed to quit before it started).
                    app:alertLogW( message )
                -- else quit qlready: keep quiet.
                end
                return
            end
            assert( type( toFront ) == 'function', "no to-front function" ) -- no need to call it, just checking..
            repeat
                repeat
                    if srcChg then -- active source(s) changed..
                        srcChg = false -- do this first, so back-to-back source changes are not missed.
                        local srcs = catalog:getActiveSources()
                        local ok = restore( srcs )
                        if ok then -- restoration was attempted - may not have been successful, but bottom line: lookup record exists, so don't overwrite with another, due to a source change..
                            -- prev-target set to restored target.
                        else
                            save( srcs, catalog:getTargetPhoto(), catalog:getTargetPhotos() ) -- saves prev-target too.
                        end
                        targsChg = false -- ignore targets which changed as a result of source changing. Note: this shouldn't be necessary,
                        -- since what would happen is the same source (or restored source) would just be resaved, but also there would be no point.
                        -- there is possibly a very tiny window here where a race is possible - if targets change asynchronously after being read,
                        -- but before being saved - as long as save method does not yield, I dont think that possibility will ever happen.
                        break
                    end
                    -- no src-chg
                    if targsChg then -- different targets became selected - NOT asserted when only the most-selected photo changes.
                        targsChg = false -- do this first, so if targets change again whilst futzing, the change will not be lost.
                        save( catalog:getActiveSources(), catalog:getTargetPhoto(), catalog:getTargetPhotos() ) -- saves prev-target too.
                        break
                    end
                    -- no targs chg
                    local targ = catalog:getTargetPhoto()
                    if targ ~= prevTarget then -- most-selected photo changed.
                        save( catalog:getActiveSources(), targ, catalog:getTargetPhotos() ) -- saves prev-target too.
                        break
                    end
                    
                    LrTasks.sleep( .1 ) -- note: this task does *very* little when nothing is changing, so frequent re-checking is not a problem, and makes it very responsive.

                until true
                
                if call:isQuit() then break end    
                
            until false
        end, finale=function( icall )
            if icall.status then
                -- nuthing - there will be a finale message due to frame closure.
            else
                if close then
                    close()
                    close = nil
                end
                app:show{ warning="'^1' has terminated due to error, message: ^2 - reload plugin or restart Lightroom, and if problem persists, notify author. ", call.name, icall.message }
            end
        end }
        
        -- called by Lr when selection changes (not sensitive to most-sel changes).
        local function targetPhotosChange()
            targsChg = true
        end

        -- called by Lr when active source changes.        
        local function activeSourceChange()
            srcChg = true
        end
        
        dia:presentFloatingDialog{ name=call.name, guard=App.guardNot, args={
            title = call.name,
            save_frame = call.name,
            resizable = true,
            background_color=nil,
            contents = getMainView(),
            blockTask = true,
            windowWillClose = nil,
            onShow = function( funcs )
                toFront = funcs.toFront
                close = funcs.close
            end,
            sourceChangeObserver = activeSourceChange,       -- set src-chg flag - note: we don't want this to guard or gate, whatever is in play when processing, is it.
            selectionChangeObserver = targetPhotosChange,    -- set targs-chg flag. ditto..
        }}
        --Debug.pause( "floater returned.." )
    
    end, finale=function( call )
        if call.status then
            infoMessage( "'^1' is closed.", call.name )
        -- else no need for banner message, since log will be offered
        end
    end } -- end of service
end -- end of function


return OddJobs