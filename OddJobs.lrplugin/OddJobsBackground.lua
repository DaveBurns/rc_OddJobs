--[[
        ExtendedBackground.lua
--]]

local ExtendedBackground, dbg, dbgf = Background:newClass{ className = 'ExtendedBackground' }



--- Constructor for extending class.
--
--  @usage      Although theoretically possible to have more than one background task,
--              <br>its never been tested, and its recommended to just use different intervals
--              <br>for different background activities if need be.
--
function ExtendedBackground:newClass( t )
    return Background.newClass( self, t )
end



--- Constructor for new instance.
--
--  @usage      Although theoretically possible to have more than one background task,
--              <br>its never been tested, and its recommended to just use different intervals
--              <br>for different background activities if need be.
--
function ExtendedBackground:new( t )
    local interval
    local minInitTime
    local idleThreshold
    if app:getUserName() == '_RobCole_' and app:isAdvDbgEna() then
        minInitTime = 3
    -- else default min-init-time is 10-15 seconds or so.
    end
    interval = .2 -- default is .2-fixed (could be .3 without a problem, but any higher and there would be perceptible lag; likewise, could be .1, but any lower wouldn't really buy anything).
    idleThreshold = 1 -- not used
    local o = Background.new( self, { interval=interval, minInitTime=minInitTime, idleThreshold=idleThreshold } )
    return o
end



local init
--- Initialize background task.
--
--  @param      call object - usually not needed, but its got the name, and context... just in case.
--
function ExtendedBackground:init( call )
    if app:getPref( 'background' ) then -- check preference that determines if background task should start.
        local s, m = pcall( init )
        if s then    
            self.initStatus = true
            -- this pref name is not assured nor sacred - modify at will.
            --    self:quit() -- indicate to base class that background processing should not continue past init.
            --end
        else
            self.initStatus = false
            app:logError( "Unable to initialize due to error: " .. str:to( m ) )
            app:show( { error="Unable to initialize - check log file for details." } )
        end
    else
        self.initStatus = true
    end
end


local scriptName = app:getAppName()
local scriptId = _PLUGIN.id

--[[ repo:

        context:addCleanupHandler( presentFinalDialogBox )
        checkScriptPrereqs( minLrVersion, osRequired ) -- abort if pre-requisites not met.
        local running = getSharedGlobal( scriptId )
        if running then
            infoMessage( "Already running.." )
            return
        else
            setSharedGlobal( scriptId, true )
        end

        context:addCleanupHandler( function()
            quit = true -- do-quit
            local shutdown, message = waitForShutdown()
            if not shutdown then
                warningMessage( message )
            else
                infoMessage( "'^1' is closed.", scriptName )
            end
            setSharedGlobal( scriptId, nil ) -- clear for restarting..
        end )
        
        local prefs = LrPrefs.prefsForPlugin( scriptId ) or error( "no prefs" )
        --prefs.prompt = "Info:"
        prefs.info = ""

        LrFunctionContext.postAsyncTaskWithContext( "Target Photo Change Watcher", function( context )
            context:addFailureHandler( function( _f, msg )
                if close then
                    close()
                    close = nil
                end
                showWarning( "'^1' has terminated due to error, message: ^2 - restart script or Lightroom, and if problem persists, notify script author. ", scriptName, msg )
            end )
            infoMessage( "'^1' background task has started.", scriptName )
            local started, message = waitForStartup()
            if started then -- to-front exists.
                infoMessage( "'^1' is running.", scriptName )
            else
                if message then -- timed out (as opposed to quit before it started).
                    warnMessage( message )
                -- else quit qlready: keep quiet.
                end
                return
            end
            assert( type( toFront ) == 'function', "no to-front function" ) -- no need to call it, just checking..
            repeat
                local testTarget = catalog:getTargetPhoto()
                if testTarget ~= prevTarget then
                    targetPhotoChange( testTarget )
                    prevTarget = testTarget
                else
                    LrTasks.sleep( .2 ) -- this task does very little very fast, so no need to minimize frequency - .2 seconds should be responsive enough.
                    if quit then break end                
                end
            until false
            quit = nil -- acknowledge.
            infoMessage( "'^1' background task has terminated.", scriptName )
        end )
--]]


local lookup = {}
local toFront
local close
local prevTarget
local quit = false


local function infoMessage( fmt, ... )
    app:displayInfo( fmt, ... )
end
local function warningMessage( fmt, ... )
    app:displayInfo( fmt, ... )
end
local function debugPause( ... )
    Debug.pause( ... )
end
local function waitForStartup()
    local c = 0
    while not toFront do
        LrTasks.sleep( .01 )
        if quit then return end
        c = c + 1
        if c >= 100 then
            return false, "Not starting up quickly enough.."
        end
    end
    return true
end
local function waitForShutdown()
    local c = 0
    while quit ~= nil do
        LrTasks.sleep( .01 )
        c = c + 1
        if c >= 100 then -- at least 10 seconds.
            return false, "Won't shutdown promptly enough.."
        end
    end
    if close then
        close() -- if not already
        close = nil
    end
    return true
end

local function getMainView()
    local vi = {}
    vi[#vi + 1] = vf:row {
        vf:static_text {
            title = "Working.. (click red 'x' to close)."
        },
    }
    return vf:view( vi )
end
-- get key based on sources, if only 1, then it's the src object itself (a unique pointer, under the hood).
-- if multiple, then a digest of all local identifiers (collections), or paths (folders), or ... ###1
local function getKeyAndName( srcs )
    if #srcs == 1 then
        local src = srcs[1]
        return src, cat:getSourceName( src )
    else -- it's a *new* array of sources.
        local b = {}
        for i, src in ipairs( srcs ) do
            local id = cat:getSourceId( src )
            assert( id ~= nil, "no source ID" )
            b[#b + 1] = id
        end
        return LrMD5.digest( table.concat( b ) ), "Multiple sources"
    end
end
local function save( srcs, tp, tpp )
    if tp and tpp then
        local key, name = getKeyAndName( srcs )
        local photoTable = lookup[key]
        debugPause{ fmt="Recording ^1 for ^2: ^3", #tpp, name, tp:getFormattedMetadata( 'fileName' ) }
        if photoTable then
            photoTable.targetPhoto = tp
            photoTable.selectedPhotos = tpp
            infoMessage( "Photo selections updated, source name: ^1, most-del: ^2, #sel: ^3", name, photoTable.targetPhoto:getFormattedMetadata( 'fileName' ), #photoTable.selectedPhotos )
        else
            lookup[key] = { targetPhoto = tp, selectedPhotos = tpp }
            photoTable = lookup[key]
            infoMessage( "Photo selections recorded, source name: ^1, most-del: ^2, #sel: ^3", name, photoTable.targetPhoto:getFormattedMetadata( 'fileName' ), #photoTable.selectedPhotos )
        end
    end
end
local function restore( srcs )
    local key, name = getKeyAndName( srcs )
    local rec = lookup[key]
    if rec then
        local s, m = cat:selectPhotos( rec.targetPhoto, rec.selectedPhotos ) -- , true, true ) -- dont resort to special collection, nor altering source (folder) selection.
        if s then
            debugPause( "recorded photo selections restored - source name: ^1", name )
        else
            warningMessage( "unable to restore recorded photo selections for ^1", name )
        end
    else
        infoMessage( "No recorded photo selections for source: ^1", name )
    end
end
local function targetPhotoChange( targetPhoto )
    LrFunctionContext.postAsyncTaskWithContext( "Target Photo Change", function( context )
        LrDialogs.attachErrorDialogToFunctionContext( context )
        if targetPhoto then
            local srcs = catalog:getActiveSources()
            local tpp = cat:getSelectedPhotos()
            save( srcs, targetPhoto, tpp )
        else
            infoMessage( "No target photo." )
        end
    end )
end
local function targetPhotosChange()
    LrFunctionContext.postAsyncTaskWithContext( "Target Photos Change", function( context )
        LrDialogs.attachErrorDialogToFunctionContext( context )
        local srcs = catalog:getActiveSources()
        local tp = catalog:getTargetPhoto()
        local tpp = cat:getSelectedPhotos()
        local srcs = catalog:getActiveSources()
        save( srcs, tp, tpp )
    end )
end
local function activeSourceChange()
    LrFunctionContext.postAsyncTaskWithContext( "Active Source Change", function( context )
        LrDialogs.attachErrorDialogToFunctionContext( context )
        local srcs = catalog:getActiveSources()
        restore( srcs )
    end )
end




-- note: file-types only matters in run boxes if not allowing folders, i.e. files only.
-- local fileTypes = getFileTypes() -- nil => all file types, could also pass param: 'photo', 'raw', 'rgb', or 'video'.


function init()
    LrFunctionContext.postAsyncTaskWithContext( scriptName, function( context )
    
        LrDialogs.presentFloatingDialog(
            _PLUGIN,
            {
                title = app:getAppName(),
                contents = getMainView(),
                blockTask = true,
                save_frame = _PLUGIN.id,
                resizable = true,
                onShow = function( funcs )
                    toFront = funcs.toFront
                    close = funcs.close
                end,
                sourceChangeObserver = activeSourceChange,
                selectionChangeObserver = targetPhotosChange,
            }
        )
        
        -- that's it for main (task) function, but note: cleanup-handler will still run..
        
    end ) -- end of task function.
    return true -- usually ignored, but if run under a debug, indicates module successfully started processing task.
end



-- ###1 code not being used


--- Background processing method.
--
--  @param      call object - usually not needed, but its got the name, and context... just in case.
--
function ExtendedBackground:process( call )

    local testTarget = catalog:getTargetPhoto()
    if testTarget ~= self.prevTarget then
        targetPhotoChange( testTarget )
        self.prevTarget = testTarget
    -- else do nothing.
    end

end
    


return ExtendedBackground
