QBCore = exports['qb-core']:GetCoreObject()
Config = {}

Config.Stashes = {
    ["police"] = { -- job name
        coords = vector4(219.20, -805.18, 30.73, 248.82), --Loc of the ped/prop.
        type = "ped", -- ped or prop
        model = "s_m_y_cop_01", -- Ped or prop model
        MaxWeight = 600000, -- Max weight of the stash
        MaxSlots = 40, -- Max slots
        BossGrade = 11 -- From what grade should the boss start at?
    },
    ["ambulance"] = { 
        coords = vector4(219.93, -803.20, 30.72, 249.78), 
        type = "ped", 
        model = "ig_djsolmanager",
        MaxWeight = 40000,
        MaxSlots = 40,
        BossGrade = 2
    },
    ["mechanic"] = { 
        coords = vector4(78.76, -1741.08, 29.61, 322.95), 
        type = "ped", 
        model = "mp_m_weapexp_01",
        MaxWeight = 40000,
        MaxSlots = 40,
        BossGrade = 2    
    },
    ["cardealer"] = { 
        coords = vector4(-797.76, -201.53, 37.25, 165.14), 
        type = "ped", 
        model = "csb_customer",
        MaxWeight = 40000,
        MaxSlots = 40,
        BossGrade = 2 
    },
    ["realestate"] = { 
        coords = vector4(-586.81, -343.01, 35.15, 288.46), 
        type = "ped", 
        model = "g_m_m_armboss_01",
        MaxWeight = 40000,
        MaxSlots = 40,
        BossGrade = 2
    }
}
