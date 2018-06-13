--[[
        Info.lua
--]]

return {
    appName = "Odd Jobs",
    author = "Rob Cole",
    authorsWebsite = "www.robcole.com",
    donateUrl = "http://www.robcole.com/Rob/Donate",
    platforms = { 'Windows', 'Mac' },
    pluginId = "com.robcole.lightroom.OddJobs",
    xmlRpcUrl = "http://www.robcole.com/Rob/_common/cfpages/XmlRpc.cfm",
    LrPluginName = "rc Odd Jobs",
    LrSdkMinimumVersion = 4.0,
    LrSdkVersion = 5.0,
    LrPluginInfoUrl = "http://www.robcole.com/Rob/ProductsAndServices/OddJobsLrPlugin",
    LrPluginInfoProvider = "OddJobsManager.lua",
    LrToolkitIdentifier = "com.robcole.OddJobs",
    LrInitPlugin = "Init.lua",
    LrShutdownPlugin = "Shutdown.lua",
    LrMetadataTagsetFactory = "Tagsets.lua",
    LrHelpMenuItems = {
        {
            title = "General Help",
            file = "mHelp.lua",
        },
    },
    VERSION = { display = "1.2.2    Build: 2015-01-08 14:07:53" },
}
