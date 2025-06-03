QBCore = exports['qb-core']:GetCoreObject()
Config = {}

Config.EnablePedAnimation = true -- If the ped should do a animation before opening the stash
Config.PedCarryProp = "prop_cs_heist_bag_01" -- Change the prop til the one you'd like.

Config.UseStashPin = true -- Actvate pin codes.

Config.ShowOnlineStatus = false -- Show 🔴/🟢-icons in the employees menu

Config.UseMultiJob = true -- true = uses ps-multijob, false = don't use
Config.EnablePedSpeech = true -- Enable if the ped should say something or not.
Config.PedSpeechPhrases = {"GENERIC_HI", "GENERIC_THANKS", "GENERIC_HOWS_IT_GOING"} -- Phrases the ped should say

Config.EnablePedAnimation = true
Config.PropAnimation = true
Config.PedCarryProp = "prop_ld_suitcase_01"


Config.Stashes = {
    ["police"] = { -- job name
        job = "police",
        coords = vector4(231.66, -807.45, 30.45, 249.24), --Loc of the ped/prop.
        type = "prop", -- ped or prop
        model = "p_v_43_safe_s", -- Ped or prop model
        MaxWeight = 600000, -- Max weight of the stash
        MaxSlots = 40, -- Max slots
        BossGrade = 11, -- From what grade should the boss start at?
        stashType = "personal" -- shared / personal / secure
    },
    ["ambulance"] = { 
        job = "ambulance",
        coords = vector4(219.93, -803.20, 30.72, 249.78), 
        type = "ped", 
        model = "ig_djsolmanager",
        MaxWeight = 40000,
        MaxSlots = 40,
        BossGrade = 2, 
        stashType = "personal"
    },
    ["mechanic"] = { 
        job = "mechanic",
        coords = vector4(78.76, -1741.08, 29.61, 322.95), 
        type = "ped", 
        model = "mp_m_weapexp_01",
        MaxWeight = 40000,
        MaxSlots = 40,
        BossGrade = 2, 
        stashType = "personal"    
    },
    ["cardealer"] = { 
        job = "cardealer",
        coords = vector4(-797.76, -201.53, 37.25, 165.14), 
        type = "ped", 
        model = "s_m_y_cop_01",
        MaxWeight = 40000,
        MaxSlots = 40,
        BossGrade = 2, 
        stashType = "personal" 
    },
    ["realestate"] = { 
        job = "realestate",
        coords = vector4(-586.81, -343.01, 35.15, 288.46), 
        type = "ped", 
        model = "g_m_m_armboss_01",
        MaxWeight = 40000,
        MaxSlots = 40,
        BossGrade = 2, 
        stashType = "personal"
    }
}
