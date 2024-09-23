if getexecutorname():find("Wave") then
    local s, r = pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/incrimination/fvgfwe/main/bbb"))() end)
    if not s or not r then -- no this is not a mistake, im checking for 404 Not Found
        local s, r = pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/buhhhhg/homohack-backup/refs/heads/main/wave-drawinglib.lua"))() end)
        if not s or not r then
            warn("No drawinglib for Wave found!")
            return
        end
    end
end

--// ui

local repository = "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/"
local library = loadstring(game:HttpGet(repository .. "Library.lua"))()
local theme_manager = loadstring(game:HttpGet(repository .. "addons/ThemeManager.lua"))()
local save_manager = loadstring(game:HttpGet(repository .. "addons/SaveManager.lua"))()

library:Notify("make sure you're using a good executor. (solara and celery is NOT supported.)")
-- library:Notify("if you would like to support them, feel free to join their discord server: https://discord.gg/q2hwnnntSt", 5)

--// services

local run_service = game:GetService("RunService")
local players = game:GetService("Players")
local user_input_service = game:GetService("UserInputService")
local lighting = game:GetService("Lighting")
local replicated_storage = game:GetService("ReplicatedStorage")

--// variables

local weapon_db = replicated_storage.Content.ProductionContent.WeaponDatabase
local camera = workspace.CurrentCamera
local knives = {
    weapon_db["ONE HAND BLUNT"],
    weapon_db["TWO HAND BLADE"],
    weapon_db["ONE HAND BLADE"],
    weapon_db["TWO HAND BLUNT"]
}

--// tables

local ui_window = library:CreateWindow({
    Title = "homohack | made by @eldmonstret",
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

local features = {
    combat = {
        legit = {
            aim_assist = {
                enabled = false,
                speed = {x = 0, y = 0},
                hitpart = "Head",
            },
            bullet_redirection = {
                enabled = false,
            },
            prediction = {
                velocity = false,
                travel_time = false,
                bullet_drop = false
            }
        },
        ragebot = {
            enabled = false,
            silent_hit = true,
            hitpart = "Head"
        },
        knife_aura = {
            enabled = false,
            headshot = false,
            radius = 10
        }
    },
    visuals = {
        world = {
            bullet_tracers = {
                tracer = "beam",
                lifetime = 5,
                speed = 5,
                color = Color3.fromRGB(255, 255, 255)
            },
        },
        viewmodel = {
            viewmodel_offset = {
                enabled = false,
                offset = {
                    x = 0,
                    y = 0,
                    z = 0
                }
            }
        },
    },
    misc = {
        player = {
            anti_aim = {
                enabled = false,
                spin = false,
                spin_speed = 1,
                pitch = 0,
            },
            walkspeed = {
                enabled = false,
                speed = 45,
            },
            unlocks = {
                attachments = false,
            },
            bhop = false,
        },
        gun = {
            insta_reload = false,
            no_spread = false,
            no_recoil = false,
            no_sway = false,
        },
        hitsounds = {
            enabled = false,
            hitsound = "rust",
            volume = 1
        }
    }
}

local storage = {

    closest_player = nil,
    latest_hit = nil,
    old_latest_hit = nil,

    old_reload_state = false,
    reload_state = false,

    aa_rotation_angle = 0,

    shoot_time = os.clock(),

    esp_cache = {},
    kill_indexes = {},
    hitsounds = {
        pvz = 17685794320,
        rust = 5043539486,
        tf2 = 3455144981,
        quake = 4868633804,
        osu = 7768346480,
        bubble = 7322736504,
        mw2019 = 7644717397,
        neverlose = 8726881116
    },
    killsounds = {
        sit_nn_dog = 5902468562,
        csgo_headshot = 18315629371,
    },
    shoot_sounds = {
        csgo_scout = 2476571739,
    },
    bullet_tracers = {
        beam = {texture = 5864341017, width = 1},
    },
}

local tabs = {
    legit_tab = ui_window:AddTab("legit"),
    rage_tab = ui_window:AddTab("rage"),
    visual_tab = ui_window:AddTab("visuals"),
    misc_tab = ui_window:AddTab("misc"),
    ["settings"] = ui_window:AddTab("settings"),
}

local sections = {
    legit_tab = {
        aim_assist = tabs.legit_tab:AddLeftGroupbox("aim assistance"),
        bullet_redirection = tabs.legit_tab:AddRightGroupbox("bullet redirection"),
        config = tabs.legit_tab:AddRightGroupbox("config"),
        prediction = tabs.legit_tab:AddLeftGroupbox("prediction"),
    },
    rage_tab = {
        ragebot = tabs.rage_tab:AddLeftGroupbox("ragebot"),
        knife_aura = tabs.rage_tab:AddRightGroupbox("knife aura"),
    },
    visuals_tab = {
        players = tabs.visual_tab:AddLeftGroupbox("players"),
        world = tabs.visual_tab:AddRightGroupbox("world"),
        viewmodel = tabs.visual_tab:AddLeftGroupbox("viewmodel"),
        visuals = tabs.visual_tab:AddRightGroupbox("visuals"),
    },
    misc_tab = {
        misc = tabs.misc_tab:AddLeftGroupbox("misc"),
        unlocks = tabs.misc_tab:AddLeftGroupbox("unlocks"),
        local_player = tabs.misc_tab:AddRightGroupbox("local player"),
        onhit = tabs.misc_tab:AddRightGroupbox("onhit"),
        gun_mods = tabs.misc_tab:AddLeftGroupbox("gun mods"),
        anti_aim = tabs.misc_tab:AddLeftGroupbox("anti aim"),
    }
}

--// optimization variables

local homohack_require
local shared = getrenv().shared

if shared then
    homohack_require = shared.require
else
    for _, nil_instance in getnilinstances() do
        if tostring(nil_instance):find("ClientLoader") then
            homohack_require = getsenv(nil_instance).shared.require
        end
    end
end

--// instances

local homohack_storage = Instance.new("Folder", workspace)
homohack_storage.Name = "homohack"

local homohack_overlay = Instance.new("ScreenGui", players.LocalPlayer.PlayerGui)

--// drawing

local main_fov = Drawing.new("Circle")
main_fov.Visible = false

--// rest

do --// main 

    --// modules

    local network_module = homohack_require("NetworkClient")
    local replication_interface = homohack_require("ReplicationInterface")
    local weapon_controller = homohack_require("WeaponControllerInterface")
    local recoil_springs = homohack_require("RecoilSprings")
    local firearm_object = homohack_require("FirearmObject")
    local bullet_check = homohack_require("BulletCheck")
    local public_settings = homohack_require("PublicSettings")
    local player_data_utils = homohack_require("PlayerDataUtils")
    local third_person_obj = homohack_require("ThirdPersonObject")
    local physics = homohack_require("PhysicsLib")
    local clocktime = homohack_require("GameClock")
    local effects = homohack_require("Effects")
    local bullet_interface = homohack_require("BulletInterface")
    local hit_detection_interface = homohack_require("HitDetectionInterface")
    local player_settings_interface = homohack_require("PlayerSettingsInterface")
    local hud_crosshairs_interface = homohack_require("HudCrosshairsInterface")
    local camera_interface = homohack_require("CameraInterface")
    local main_camera_object = homohack_require("MainCameraObject")
    local action_bind_interface = homohack_require("ActionBindInterface")
    local hud_scope_interface = homohack_require("HudScopeInterface")
    local hud_screen_gui = homohack_require("HudScreenGui")
    local hud_spotting_interface = homohack_require("HudSpottingInterface")
    local hud_notification_config = homohack_require("HudNotificationConfig")
    local cframe_lib = homohack_require("CFrameLib")
    local character_interface = homohack_require("CharacterInterface")

    library:Notify("successfully loaded all modules")

    local game_hitmarker
    local game_crosshair
    local custom_crosshair

    do --// functions
    
        do --// weapon
        
            function get_weapon_by_index(index)
            
                local active_controller = weapon_controller.getActiveWeaponController()
                local weapon_registry = active_controller and active_controller._activeWeaponRegistry or nil
                local weapon = weapon_registry and weapon_registry[index]
            
                return weapon or nil, weapon and weapon:getWeaponStat("type")
                
            end
        
            function get_weapon()
            
                local active_controller = weapon_controller.getActiveWeaponController()
                local weapon_registry = active_controller and active_controller._activeWeaponRegistry or nil
                local weapon = weapon_registry and get_weapon_by_index(active_controller._activeWeaponIndex)
            
                return weapon or nil, weapon and weapon:getWeaponStat("type")
            
            end
        
            function get_weapon_model()
            
                local active_weapon, weapon_type, weapon_index = get_weapon()
                return weapon_type ~= "KNIFE" and (active_weapon and active_weapon._weaponModel or nil)
            
            end
            
        end
    
        function randomString()
            local length = math.random(10,20)
            local array = {}
            for i = 1, length do
                array[i] = string.char(math.random(32, 126))
            end
            return table.concat(array)
        end

        do --// players
        
            function get_players()
                local entity_list = {}
            
                for _, player in players:GetPlayers() do
                    local entry = replication_interface.getEntry(player)
                    if (entry and entry._alive) and player ~= players.LocalPlayer and player.Team ~= players.LocalPlayer.Team then
                        entity_list[#entity_list+1] = replication_interface.getEntry(player)
                    end
                end
            
                return entity_list
            end
        
            function get_character(player)
                local thirdPersonObject = player._thirdPersonObject
                if thirdPersonObject then
                    return thirdPersonObject._characterHash
                end
                return nil
            end
        
            function get_velocity(player)
                return player._velspring.t
            end
        
            function get_closest_player()
            
                local closest_entry = nil
                local closest_distance = math.huge
            
                for _, player_entry in get_players() do
                
                    local character = get_character(player_entry)
                
                    if character then
                    
                        local head = character.Head
                        local w2s, onscreen = camera:WorldToViewportPoint(head.Position)
                        local distance = (Vector2.new(w2s.X, w2s.Y) - user_input_service:GetMouseLocation()).Magnitude
                    
                        if onscreen and (distance < closest_distance) and main_fov.Radius > distance then
                        
                            closest_entry = player_entry
                            closest_distance = distance
                        
                        end
                    
                    end
                end
            
                return closest_entry, closest_distance
            
            end
            
        end
    
        do --// math
        
            function get_distance(origin_pos, end_pos)
                return (origin_pos - end_pos).Magnitude
            end
            
            function is_vis(origin_pos, end_pos, is_vis, ignore_list)
            
                local params = RaycastParams.new()
                params.FilterDescendantsInstances = ignore_list
                params.FilterType = Enum.RaycastFilterType.Exclude
            
                local ray = workspace:Raycast(origin_pos, (end_pos - origin_pos).Unit * 300, params)
                return (not ray and nil) or ray and ray.Instance:IsDescendantOf(is_vis), ray
                
            end
        
            function calculate_trajectory(origin_pos, acceleration, end_pos, speed)
                
                local negative_acceleration = -acceleration
                
                local direction = end_pos - origin_pos
                
                local neg_accel = Vector3.new().Dot(negative_acceleration, negative_acceleration)
                local directionDotDirection = 4 * Vector3.new().Dot(direction, direction)
                local speeddot = (4 * (Vector3.new().Dot(negative_acceleration, direction) + speed * speed)) / (2 * neg_accel)
                
                local discriminant = (speeddot * speeddot - directionDotDirection / neg_accel) ^ 0.5
                
                local time1 = speeddot - discriminant
                local time2 = speeddot + discriminant
                
                local time = time1 < 0 and time2 or time1
                time = time ^ 0.5
                
                return negative_acceleration * time / 2 + direction / time, time
            
            end
        
            function calculate_position(origin_pos, end_pos, end_velocity, data)
            
                local distance = get_distance(origin_pos, end_pos)
                local travel_time = distance / data.bulletspeed
            
                local prediction = features.combat.legit.prediction
                local travel_time = (prediction.travel_time and travel_time or 0)
            
                local predicted_pos = end_pos + (end_velocity * travel_time)
                local bullet_drop = 0.5 * data.gravity * travel_time^2
            
                local hitchance = data.hitchance
            
                if hitchance < 100 then
                
                    local miss_chance = (100 - hitchance) / 100
                    local x = math.random() * 3 - 1
                    local y = math.random() * 3 - 1
                    local z = math.random() * 3 - 1
                    predicted_pos = predicted_pos + Vector3.new(x, y, z) * miss_chance
                
                end
            
                return predicted_pos + (prediction.bullet_drop and Vector3.new(0, bullet_drop, 0) or Vector3.new(0, 0, 0))
                
            end
        
            function round_vec(...)
                local rounded = {}
                for _, value in {...} do
                    rounded[_] = math.round(value)
                end
                return unpack(rounded)
            end
            
        end
    
        do --// ragebot
        
            function can_shoot_object(object, weapon)
            
                if object and weapon then
                
                    local barrel = weapon._barrelPart
                    local bullet_speed = weapon:getWeaponStat("bulletspeed")
                    local penetration_depth = weapon:getWeaponStat("penetrationdepth")
                
                    local trajectory = calculate_trajectory(barrel.Position, public_settings.bulletAcceleration, object.Position, bullet_speed)
                    return bullet_check(barrel.Position, object.Position, trajectory, public_settings.bulletAcceleration, penetration_depth, 0.016666666666666666)
                
                end
            
                return false
                
            end
        
            function get_closest_shootable(weapon)
                
                if weapon:getWeaponStat("type") == "KNIFE" then
                    return
                end
            
                local closest_entry = nil
                local closest_distance = math.huge
                
                local get_distance = get_distance
                local can_penetrate = can_shoot_object
            
                local get_players = get_players()
            
                for _, player_entry in get_players do
                
                    if player_entry._receivedPosition then
                    
                        local character = get_character(player_entry)
                    
                        if character then
                        
                            local head = character.Head
                        
                            if head and can_penetrate(head, weapon) then
                            
                                local distance = get_distance(weapon._barrelPart.Position, head.Position)
                                
                                if distance < closest_distance then
                                
                                    closest_entry = player_entry
                                    closest_distance = distance
                                
                                end
                            
                            end
                        
                        end
                    
                    end
                end
            
                return closest_entry
            
            end
        
            function shoot(origin, hit, player) --// pasted from fireRound in firearmobject
                local weapon, type, weapon_index = get_weapon()
            
                if weapon and type ~= "KNIFE" then
                
                    if weapon._magCount == 0 then
                    
                        network_module:send("reload")
                        return weapon:applyReloadCount(weapon:getWeaponStat("magsize"))
                    
                    end
                
                    local barrelpart = weapon._barrelPart
                    local weapon_id = weapon.uniqueId
                    local bullet_speed = weapon:getWeaponStat("bulletspeed")
                    local bullet_acceleration = public_settings.bulletAcceleration
                
                    local trajectory = calculate_trajectory(origin, bullet_acceleration, hit, bullet_speed)
                    --local travel_time = physics.timehit(origin, trajectory, bullet_acceleration, hit)
                
                    local unit = trajectory.Unit
                    local firecount = weapon._fireCount or 1
                    local data = {
                        firepos = origin,
                        bullets = {{ unit, firecount }},
                        camerapos = camera.CFrame.Position
                    }
                
                    for i = 1, weapon._weaponData.pelletcount or 1 do
                        firecount += 1
                        data.bullets[i] = {
                            unit,
                            firecount
                        }
                    end
                
                    do --// bullet fired
                    
                        local dir = weapon._mainPart.CFrame.LookVector
                    
                        weapon._fireCount = firecount
                    
                        network_module:send("newbullets", weapon_id, data, clocktime.getTime())
                    
                        weapon:decrementMagCount(1)
                    
                        storage.shoot_time = os.clock()
                        bullet_interface.newBullet({
                            
                            position = barrelpart.Position, 
                            velocity = trajectory,
                            acceleration = (weapon:getWeaponStat("bulletaccel") or 0) * dir + public_settings.bulletAcceleration, 
                            color = weapon:getWeaponStat("bulletcolor") or Color3.fromRGB(255, 94, 94), 
                            size = 0.2,
                            bloom = 0.005,
                            brightness = weapon:getWeaponStat("bulletbrightness") or 400,
                            life = public_settings.bulletLifeTime,
                            visualorigin = barrelpart.Position,
                            physicsignore = {workspace.Players, workspace.Terrain, workspace.Ignore, workspace.CurrentCamera},
                            dt = clocktime.getTime() - weapon._nextShot,
                            penetrationdepth = weapon:getWeaponStat("penetrationdepth"),
                            tracerless = weapon:getWeaponStat("tracerless"),
                    
                            onplayerhit = function()
                            end,
                        
                            usingGlassHack = (((player_settings_interface.getValue("toggleglasshacktracers") and weapon:isAiming()) and not weapon:isBlackScoped()) and weapon:getActiveAimStat("sightObject")) and weapon:getActiveAimStat("sightObject"):isApertureVisible(), 
                            
                            extra = {
                                playersHit = {}, 
                                bulletTicket = weapon._fireCount, 
                                firstHits = {}, 
                                firearmObject = weapon, 
                                uniqueId = weapon.uniqueId
                            },
                        
                            ontouch = function(v22, obj, v24, v25, v26, v27)
                        
                                local hitpart = features.combat.ragebot.hitpart
                                hud_crosshairs_interface.fireHitmarker((hitpart == "Head" and true) or false)
                        
                                if obj.Anchored then
                                    if obj.Name == "Window" then
                                        effects.breakwindow(obj, v22.extra.bulletTicket);
                                    end
                                end
                            
                            end
                        })
                        
                        if not weapon:getWeaponStat("nomuzzleeffects") then
                            if player_settings_interface.getValue("firstpersonmuzzleffectsenabled") then
                                effects.muzzleflash(barrelpart, weapon:getWeaponStat("hideflash"), 0.9);
                            end;
                            if not weapon:getWeaponStat("hideflash") then
                                weapon._characterObject:fireMuzzleLight();
                            end
                        end
                    
                    end
                
                    if not features.combat.ragebot.silent_hit then
                    
                        local shoot_sound = Options.shoot_sound.Value
                        local is_original = shoot_sound == "original"
                    
                        local sound_id, volume, pitch
                    
                        if is_original then
                            sound_id = weapon:getWeaponStat("firesoundid")
                            volume = weapon:getWeaponStat("firevolume")
                            pitch = weapon:getWeaponStat("firepitch")
                        else
                            sound_id = `rbxassetid://{storage.shoot_sounds[shoot_sound]}`
                            volume = 1
                            pitch = 1
                        end
                    
                        play(sound_id, {
                            volume = volume,
                            pitch = pitch,
                            parent = barrelpart
                        })
                    
                    end
                
                    for i = 1, #data.bullets do
                        network_module:send("bullethit", weapon_id, player, hit, features.combat.ragebot.hitpart, data.bullets[i][2], clocktime.getTime())
                    end
                
                end
            
            end
            
        end
    
        do --// sounds
        
            function play(rbxassetid, data)
            
                local sound = Instance.new("Sound", data.parent or homohack_storage)
                sound.SoundId = rbxassetid
                sound.Volume = data.volume
                sound.Pitch = data.pitch
                sound.Looped = false
                sound.PlayOnRemove = true
                sound:Destroy()
            
            end
            
        end
    
        do --// esp
        
            function add(player)
                
                if not storage.esp_cache[player] then
                
                    local drawing = {
                
                        box_outline = Drawing.new("Square"),
                        box = Drawing.new("Square"),
                        
                        healthbar_outline = Drawing.new("Square"),
                        healthbar = Drawing.new("Square"),
                
                        name = Drawing.new("Text"),
                        weapon = Drawing.new("Text"),
                
                    }
                
                    local box = drawing.box
                    local box_outline = drawing.box_outline
                
                    local healthbar = drawing.healthbar
                    local healthbar_outline = drawing.healthbar_outline
                
                    local name = drawing.name
                    local weapon = drawing.weapon
                
                    name.Outline = true
                    name.Size = 16
                    name.OutlineColor = Color3.fromRGB(0, 0, 0)
                
                    weapon.Outline = true
                    weapon.Size = 16
                    weapon.OutlineColor = Color3.fromRGB(0, 0, 0)
                
                    box_outline.Color = Color3.fromRGB(0, 0, 0)
                    box_outline.Thickness = 3
                
                    healthbar.Filled = true
                    healthbar.Thickness = 1
                    
                    healthbar_outline.Color = Color3.fromRGB(0, 0, 0)
                    healthbar_outline.Thickness = 3
                    
                    storage.esp_cache[player] = drawing
                
                end
                
            end
        
            function remove(player)
            
                for _, drawing in storage.esp_cache[player] do
                    if drawing.Remove then
                        drawing:Remove()
                    end
                end
            
                storage.esp_cache[player] = nil
                
            end
            
        end
    
        do --// main
        
            function render_tracer(origin_pos, end_pos, data)
            
                local duration = 1
                local start = data.lifetime - duration
            
                local increment = 1 / (duration / 0.1)
                local current = 0
            
                local part1 = Instance.new("Part", workspace)
                part1.Name = 1
                part1.Transparency = 1
                part1.CanCollide = false
                part1.Anchored = true
                part1.Size = Vector3.new(1, 1, 1)
                part1.CFrame = CFrame.new(origin_pos)
            
                local part2 = Instance.new("Part", workspace)
                part2.Name = 2
                part2.Transparency = 1
                part2.CanCollide = false
                part2.Anchored = true
                part2.CFrame = CFrame.new(end_pos)
                part2.Size = Vector3.new(1, 1, 1)
            
                local attach1 = Instance.new("Attachment", part1)
                local attach2 = Instance.new("Attachment", part2)
            
                local beam = Instance.new("Beam", part1)
                beam.Texture = data.tracer
                beam.LightEmission = 0
                beam.LightInfluence = 3
                beam.TextureLength = 5
                beam.TextureMode = Enum.TextureMode.Wrap
                beam.TextureSpeed = data.speed
                beam.ZOffset = 0
                beam.Attachment0 = attach1
                beam.Attachment1 = attach2
                beam.CurveSize0 = 0
                beam.CurveSize1 = 0
                beam.Segments = 10
                beam.Width0 = 1.5
                beam.Width1 = 1.5
                beam.Color = ColorSequence.new(data.color)
            
                task.wait(start)
            
                repeat
                
                    current = current + increment
                    beam.Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, current),
                        NumberSequenceKeypoint.new(0.5, current),
                        NumberSequenceKeypoint.new(1, 1),
                    })
                    task.wait(0.05)
                
                until current > 1
            
                part1:Destroy()
                part2:Destroy()
                
            end
        
            function render_hitmarker(end_pos, color, lifetime)
            
                local _, on_screen = camera:WorldToViewportPoint(end_pos)
            
                if on_screen then
                
                    local new_hitmarker = game_hitmarker:Clone()
                    local billboard = nil
                    local end_pos_part = nil
                
                    end_pos_part = Instance.new("Part", homohack_storage)
                    end_pos_part.Anchored = true
                    end_pos_part.Transparency = 1
                    end_pos_part.CFrame = CFrame.new(end_pos)
                
                    billboard = Instance.new("BillboardGui", homohack_storage)
                    billboard.Size = new_hitmarker.Size
                    billboard.AlwaysOnTop = true
                    billboard.Adornee = end_pos_part
                    
                    new_hitmarker.Parent = billboard
                    new_hitmarker.Visible = true
                    new_hitmarker.ImageTransparency = 0
                    new_hitmarker.ImageColor3 = color
                
                    task.wait(lifetime)
                
                    local fade_out = game:GetService("TweenService"):Create(new_hitmarker, TweenInfo.new(lifetime / 2), { ImageTransparency = 1 })
                    fade_out:Play()
                
                    fade_out.Completed:Connect(function()
                        new_hitmarker:Destroy()
                
                        if billboard then
                            billboard:Destroy()
                        end
                        if end_pos_part then
                            end_pos_part:Destroy()
                        end
                    end)
                
                end
            end
        
            function set_killtext(text)
            
                for _, value in hud_notification_config.typeList do
                
                    local tostr = tostring(_)
                    if tostr:find("kill") and not tostr:find("assist") then
                        value[1] = text
                    end
                
                end
                
            end
        
            function create_crosshair()
                local crosshair = Instance.new("Frame", homohack_overlay)
                local left = Instance.new("Frame")
                local top = Instance.new("Frame")
                local bottom = Instance.new("Frame")
                local right = Instance.new("Frame")
            
                crosshair.Name = "crosshair"
                crosshair.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                crosshair.BackgroundTransparency = 1.000
                crosshair.BorderColor3 = Color3.fromRGB(0, 0, 0)
                crosshair.BorderSizePixel = 0
                crosshair.Position = UDim2.new(0.5, 0, 0.5, 0)
                crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
                crosshair.Size = UDim2.new(0, 125, 0, 125)
            
                local crosshair_size_x = UDim2.new(0, 10, 0, 2)
                local crosshair_size_y = UDim2.new(0, 2, 0, 10)
            
                left.Name = "left"
                left.Parent = crosshair
                left.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                left.BorderColor3 = Color3.fromRGB(0, 0, 0)
                left.Size = crosshair_size_x
                left.Position = UDim2.new(0.5, -10 - crosshair_size_x.X.Offset, 0.5, -crosshair_size_x.Y.Offset / 2)
            
                top.Name = "top"
                top.Parent = crosshair
                top.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                top.BorderColor3 = Color3.fromRGB(0, 0, 0)
                top.Size = crosshair_size_y
                top.Position = UDim2.new(0.5, -crosshair_size_y.X.Offset / 2, 0.5, -10 - crosshair_size_y.Y.Offset)
            
                bottom.Name = "bottom"
                bottom.Parent = crosshair
                bottom.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                bottom.BorderColor3 = Color3.fromRGB(0, 0, 0)
                bottom.Size = crosshair_size_y
                bottom.Position = UDim2.new(0.5, -crosshair_size_y.X.Offset / 2, 0.5, 10)
            
                right.Name = "right"
                right.Parent = crosshair
                right.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                right.BorderColor3 = Color3.fromRGB(0, 0, 0)
                right.Size = crosshair_size_x
                right.Position = UDim2.new(0.5, 10, 0.5, -crosshair_size_x.Y.Offset / 2)
            
                return {
                    crosshair = crosshair,
                    left = left,
                    top = top,
                    bottom = bottom,
                    right = right
                }
            end
            
        end
        
    end

    do --// on_script_load
    
        game_hitmarker = hud_screen_gui.getScreenGui().Main.ImageHitmarker
        custom_crosshair = create_crosshair()
    
        for _, value in hud_notification_config.typeList do
            local tostr = tostring(_)
            if tostr:find("kill") and not tostr:find("assist") then
                storage.kill_indexes[_] = value[1]
            end
        end
        
    end

    do --// loop
    
        run_service.RenderStepped:Connect(function()
    
            local weapon, weapon_type, weapon_index = get_weapon()
            local char_obj = character_interface.getCharacterObject()
            local localplayer = workspace.Ignore:FindFirstChildOfClass("Model")
            
            local closest_shootable = (weapon and weapon_type ~= "KNIFE" and get_closest_shootable(weapon)) or nil
            local closest = storage.closest_player
    
            --local arms = {
                --char_obj and char_obj._rightArmModel or nil,
                --char_obj and char_obj._leftArmModel or nil
            --}
    
            do --// features
            
                do --// legit
                
                    if features.combat.legit.aim_assist.enabled and user_input_service:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
                    
                        if closest and weapon and weapon_type ~= "KNIFE" then
                        
                            local character = get_character(closest)
                        
                            if character and character.Torso then
                            
                                local hitpart = character[Options.legitbot_hitpart.Value]
                                local w2s, onscreen = camera:WorldToScreenPoint(hitpart.Position)
                            
                                if onscreen then
                                
                                    local pos = Vector2.new(w2s.X, w2s.Y)
                                    local hit_pos = calculate_position(camera.CFrame.Position, hitpart.Position, get_velocity(closest), { bulletspeed = weapon:getWeaponStat("bulletspeed"), gravity = workspace.Gravity, hitchance = 100 })
                                
                                    if Options.aimassist_method.Value == "mouse" then
                                    
                                        local delta_x = (pos.X - camera.ViewportSize.X / 2) * features.combat.legit.aim_assist.speed.x
                                        local delta_y = (pos.Y - camera.ViewportSize.Y / 2) * features.combat.legit.aim_assist.speed.y
                                    
                                        mousemoverel(delta_x, delta_y)
                                    
                                    else
                                    
                                        local origin = camera.CFrame.Position
                                    
                                        local target_direction = (hit_pos - origin).Unit
                                        local current_direction = camera.CFrame.LookVector
                                    
                                        local smoothness = Options.camera_smoothness.Value
                                    
                                        local lerped = current_direction:Lerp(target_direction, smoothness ~= 0 and 0.04 * (1 / (smoothness / 10)) or 1)
                                    
                                        main_camera_object.setLookVector(camera_interface.getActiveCamera("MainCamera"), lerped)
                                    
                                    end
                                
                                end
                            
                            end
                        
                        end
                    
                    end
                    
                end
            
                do --// ragebot
                
                    task.spawn(function() --// so the other features actually work lol
                
                        if features.combat.ragebot.enabled and closest_shootable then
                                
                            local character = get_character(closest_shootable)
                        
                            if character then
                            
                                local shoot_tick = os.clock()
                                local firerate = weapon:getWeaponStat("firerate")
                                local current_firerate = typeof(firerate) == "number" and firerate or firerate[1]
                                
                                if not (shoot_tick - storage.shoot_time <= 60 / current_firerate) then
                                    shoot(weapon._barrelPart.Position, character[features.combat.ragebot.hitpart].Position, closest_shootable._player)
                                end
                            
                            end
                        
                        end
                    end)
                    
                end
            
                do --// knife aura
                
                    if features.combat.knife_aura.enabled and weapon and weapon._meleeState then
                        for _, player in get_players() do
                        
                            if player and player._alive then
                            
                                local character = get_character(player)
                            
                                if localplayer and character then
                                
                                    local head = character.Head
                                    local torso = character.Torso
                                
                                    if head and torso then
                                    
                                        local dist = get_distance(char_obj._rootPart.Position, torso.Position)
                                        local player_client = player._player
                                    
                                        if dist <= features.combat.knife_aura.radius then
                                        
                                            weapon._activeStabType = weapon.quick and "quickstab" or "stab1"
                                            weapon:fireInput("meleeStart", clocktime.getTime())
                                        
                                            network_module:send("stab")
                                            network_module:send("knifehit", player_client, ((features.combat.knife_aura.headshot and "Head") or "Torso"), head.Position, clocktime.getTime())
                                        
                                        end
                                    
                                    end
                                
                                end
                                
                            end
                        
                        end
                    end
                    
                end
                
            end
        
            --network_module:send("onboardingPromoted")
            
        end)
    
        run_service.Heartbeat:Connect(function()
    
            local weapon, weapon_type, weapon_index = get_weapon()
            local char_obj = character_interface.getCharacterObject()
            local localplayer = workspace.Ignore:FindFirstChildOfClass("Model")
    
            do --// visuals
            
                do --// players
                
                    for _, player in get_players() do
                        if player._alive then
                            task.spawn(add, player)
                        end
                    end
                
                    for player, data in storage.esp_cache do
                        if player and data then
                            local character = get_character(player)
                            if character and character.Torso then
                            
                                local camera_position = camera.CFrame.Position
                            
                                local box_obj = data.box
                                local box_outline_obj = data.box_outline
                                local healthbar_obj = data.healthbar
                                local healthbar_outline_obj = data.healthbar_outline
                            
                                local weapon_text_obj = data.weapon
                                local name_text_obj = data.name
                            
                                local torso_position = character.Torso.Position
                                local conversion, onscreen = camera:WorldToViewportPoint(torso_position)
                                local w2s = Vector2.new(conversion.X, conversion.Y)
                            
                                local scale = (1000) / (camera_position - torso_position).Magnitude * 80 / camera.FieldOfView
                            
                                if onscreen then
                                    local box_width, box_height = round_vec(3 * scale, 4 * scale)
                                    local box_position = Vector2.new(round_vec(w2s.X - (box_width / 2), w2s.Y - (box_height / 2)))
                                
                                    local is_visible, vis_ray_1 = is_vis(camera_position, torso_position, player._thirdPersonObject._character, {workspace.Terrain, workspace.Ignore, camera})
                                
                                    local ragebot_target_color = player == closest_shootable and Options.ragebot_target_color.Value
                                
                                    local box_color = ragebot_target_color or (not is_visible and Options.box_color_occluded.Value or Options.box_color_vis.Value)
                                    local name_color = ragebot_target_color or (not is_visible and Options.name_color_occluded.Value or Options.name_color_vis.Value)
                                    local weapon_color = ragebot_target_color or (not is_visible and Options.weapon_color_occluded.Value or Options.weapon_color_vis.Value)
                                
                                    local fill_cham_color = ragebot_target_color or (not is_visible and Options.cham_fill_color_occluded.Value or Options.cham_fill_color_vis.Value)
                                    local outline_cham_color = ragebot_target_color or (not is_visible and Options.cham_outline_color_occluded.Value or Options.cham_outline_color_vis.Value)
                                
                                    --// box
                                
                                    local box_enabled = Toggles.box_enabled.Value
                                    box_obj.Visible = box_enabled
                                    box_obj.Size = Vector2.new(box_width, box_height)
                                    box_obj.Position = box_position
                                    box_obj.Color = box_color
                                    box_obj.Thickness = 1
                                
                                    box_outline_obj.Visible = box_enabled
                                    box_outline_obj.Size = Vector2.new(box_width, box_height)
                                    box_outline_obj.Position = box_position
                                    box_outline_obj.Color = Color3.fromRGB(0, 0, 0)
                                    box_outline_obj.Thickness = 3
                                
                                    --// healthbar
                                
                                    local max_health = 100
                                    local health_val = player._healthstate.health0
                                    local current_health = health_val > 0 and health_val or max_health
                                
                                    local health_percentage = current_health / max_health
                                    local healthbar_height = box_height * health_percentage
                                    local healthbar_offset = box_height - healthbar_height
                                    local healthbar_thickness = Options.healthbar_thickness.Value
                                    local healthbar_position = Vector2.new(box_position.X - healthbar_thickness - 3, box_position.Y + healthbar_offset)
                                
                                    local healthbar_enabled = Toggles.healthbar_enabled.Value
                                    healthbar_obj.Size = Vector2.new(healthbar_thickness, healthbar_height)
                                    healthbar_obj.Position = healthbar_position
                                    healthbar_obj.Color = Color3.new(1 - health_percentage, health_percentage, 0)
                                    healthbar_obj.Visible = healthbar_enabled
                                
                                    healthbar_outline_obj.Visible = healthbar_enabled
                                    healthbar_outline_obj.Size = healthbar_obj.Size
                                    healthbar_outline_obj.Position = healthbar_obj.Position
                                
                                    --// name text
                                
                                    name_text_obj.Center = true
                                    name_text_obj.Visible = Toggles.name_enabled.Value
                                    name_text_obj.Text = player._player.Name or "unnamed (?)"
                                    name_text_obj.Color = name_color
                                    name_text_obj.Position = Vector2.new(box_obj.Position.X + (box_obj.Size.X / 2), box_obj.Position.Y - 15)
                                
                                    --// weapon text
                                
                                    weapon_text_obj.Center = true
                                    weapon_text_obj.Visible = Toggles.weapon_enabled.Value
                                    weapon_text_obj.Text = player._thirdPersonObject._weaponname or "nothing"
                                    weapon_text_obj.Color = weapon_color
                                    weapon_text_obj.Position = Vector2.new(box_obj.Position.X + (box_obj.Size.X / 2) - weapon_text_obj.Size / 2, box_obj.Position.Y + box_height + 5)
                                
                                    --// chams
                                
                                    local char = player._thirdPersonObject._character
                                    local highlight = char:FindFirstChildOfClass("Highlight")
                                
                                    if Toggles.chams_enabled.Value then
                                        if not highlight then
                                        
                                            highlight = Instance.new("Highlight", char)
                                            
                                        else
                                        
                                            if not player._alive then
                                                highlight:Destroy()
                                            end
                                        
                                        end
                                    
                                        highlight.FillColor = fill_cham_color
                                        highlight.OutlineColor = outline_cham_color
                                    
                                        highlight.FillTransparency = Options.cham_fill_color_vis.Transparency
                                        highlight.OutlineTransparency = Options.cham_outline_color_vis.Transparency
                                        highlight.DepthMode = Enum.HighlightDepthMode[Options.cham_method.Value]
                                    
                                    else
                                    
                                        if highlight then
                                            highlight:Destroy()
                                        end
                                    
                                    end
                                else
                                
                                    remove(player)
                                
                                end
                            else
                            
                                remove(player)
                            
                            end
                        end
                    end
                
                end
            
                do --// world
                
                    if Toggles.ambient_enabled.Value then
                        
                        lighting.Ambient = Options.ambient_color.Value
                        lighting.OutdoorAmbient = Options.ambient_color.Value
                    
                    else
                    
                        lighting.Ambient = lighting.MapLighting.Ambient.Value
                        lighting.OutdoorAmbient = lighting.MapLighting.OutdoorAmbient.Value
                    
                    end
                
                    if Toggles.override_clocktime.Value then
                    
                        lighting.ClockTime = Options.clock_time.Value
                        
                    end
                    
                end
            
                do --// hit notifications
                
                    if storage.latest_hit ~= storage.old_latest_hit then
                    
                        --table.foreach(storage.latest_hit, print)
                        if Toggles.hit_notifications_enabled.Value then
                            library:Notify(`hit {tostring(storage.latest_hit[3])} in the {tostring(storage.latest_hit[5])} ({math.floor(get_distance(camera.CFrame.Position, storage.latest_hit[4]))} studs)`)
                        end
                    
                        if Toggles["3d_hitmarker_enabled"].Value then
                            task.spawn(render_hitmarker, storage.latest_hit[4], Options["3d_hitmarker_color"].Value, Options["3d_hitmarker_lifetime"].Value)
                            --render_hitmarker(storage.latest_hit[4], Options["3d_hitmarker_color"].Value)
                        end
                    
                        storage.latest_hit = nil
                        storage.old_latest_hit = storage.latest_hit
                    
                    end
                    
                end
            
                do --// viewmodel
                
                    if weapon then
                    
                        if Toggles.override_viewmodel_offset.Value then
                        
                            local default_offset = weapon:getWeaponStat("mainoffset")
                            local set_offset = features.visuals.viewmodel.viewmodel_offset.offset
                        
                            local offset_vector = Vector3.new(-set_offset.x / 5, set_offset.y / 5, -set_offset.z / 5)
                            weapon._mainOffset = default_offset * CFrame.new(offset_vector)
                        
                        else
                        
                            weapon._mainOffset = weapon:getWeaponStat("mainoffset")
                        
                        end
                            
                    end
                    
                end
            
                do --// crosshair
                
                    if Toggles.crosshair_enabled.Value and weapon then
                    
                        local left = custom_crosshair.left
                        local top = custom_crosshair.top
                        local bottom = custom_crosshair.bottom
                        local right = custom_crosshair.right
                        
                        local crosshair_size_x = UDim2.new(0, 10, 0, 2)
                        local crosshair_size_y = UDim2.new(0, 2, 0, 10)
                    
                        local spacing_val = Options.crosshair_spacing.Value
                        local spacing = spacing_val
                        local color = Options.crosshair_color.Value
                        
                        left.BackgroundColor3 = color
                        left.Size = crosshair_size_x
                        left.Position = UDim2.new(0.5, -spacing - crosshair_size_x.X.Offset / 2, 0.5, -crosshair_size_x.Y.Offset / 2)
                        
                        top.BackgroundColor3 = color
                        top.Size = crosshair_size_y
                        top.Position = UDim2.new(0.5, -crosshair_size_y.X.Offset / 2, 0.5, -spacing - crosshair_size_y.Y.Offset / 2)
                        
                        bottom.BackgroundColor3 = color
                        bottom.Size = crosshair_size_y
                        bottom.Position = UDim2.new(0.5, -crosshair_size_y.X.Offset / 2, 0.5, spacing - crosshair_size_y.Y.Offset / 2)
                        
                        right.BackgroundColor3 = color
                        right.Size = crosshair_size_x
                        right.Position = UDim2.new(0.5, spacing - crosshair_size_x.X.Offset / 2, 0.5, -crosshair_size_x.Y.Offset / 2)
                        
                        local crosshair_position = UDim2.new(0, camera.ViewportSize.X / 2, 0, camera.ViewportSize.Y / 2) - UDim2.new(0, 0, 0, 37)
                        
                        custom_crosshair.crosshair.Visible = Toggles.crosshair_enabled.Value
                        custom_crosshair.crosshair.Position = crosshair_position
                    
                        if Toggles.crosshair_rotation_enabled.Value then
                            custom_crosshair.crosshair.Rotation += Options.crosshair_rotation_speed.Value
                        else
                            custom_crosshair.crosshair.Rotation = 0
                        end
                    
                    else
                    
                        custom_crosshair.crosshair.Visible = false
                    
                    end
                    
                end
            
            end
        
            do --// misc
            
                do --// gun mods
                
                    if weapon then
                    
                        if features.misc.gun.no_spread and weapon._spreadSpring then
                        
                            weapon._spreadSpring["_p0"] = Vector3.new(0, 0, 0)
                            weapon._spreadSpring["_v0"] = Vector3.new(0, 0, 0)
                            
                        end
                    
                        if features.misc.gun.insta_reload and weapon._characterObject then
                        
                            local char_obj = weapon._characterObject
                        
                            if char_obj.reloading ~= storage.old_reload_state and char_obj.reloading then
                                network_module:send("reload")
                                weapon:applyReloadCount(weapon:getWeaponStat("magsize") -1)
                                weapon:cancelAnimation()
                                weapon:fireInput("reloadFinish", (clocktime.getTime()))
                                --weapon:fireInput("reloadCancel", (clocktime.getTime()))
                            end
                        
                            storage.old_reload_state = char_obj.reloading
                            char_obj.animating = false
                        
                        end
                        
                    end
                    
                end
            
                do --// localplayer
                    
                    if char_obj then
                    
                        local humanoid = char_obj._humanoid
                        local humanoid_root = char_obj._rootPart
                        
                        if features.misc.player.walkspeed.enabled then
                        
                            humanoid_root.CFrame = humanoid_root.CFrame + (humanoid.MoveDirection * (features.misc.player.walkspeed.speed / (30*10)))
                        
                        end
                    
                        if Toggles["bhop_enabled"].Value then
                            humanoid.Jump = user_input_service:IsKeyDown(Enum.KeyCode.Space)
                        end
                    
                    end
                    
                end
                
            end
        
            do --// settings
            
                --// checking for visibility before setting position, not sure if this is better performance wise but seems like it
            
                if main_fov.Visible then
                
                    local fov_val = Options.fov_value.Value
                
                    main_fov.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
                    main_fov.Radius = (Toggles.dynamic_fov_enabled.Value and fov_val / math.tan(math.rad(camera.FieldOfView / 2))) or fov_val
                    
                end
                
                if (features.combat.legit.aim_assist.enabled or features.combat.legit.bullet_redirection.enabled) and not features.combat.ragebot.enabled then
                    storage.closest_player = get_closest_player()
                end
                
            end
            
        end)
        
    end

    do --// hooking
    
        local network_send = network_module.send
        local apply_impulse = recoil_springs.applyImpulse
        local compute_gun_sway = firearm_object.computeGunSway
        local compute_walk_sway = firearm_object.computeWalkSway
        local ownsWeapon = player_data_utils.ownsWeapon
        local ownsAttachment = player_data_utils.ownsAttachment
        local step = third_person_obj.step
        local getWeaponStat = firearm_object.getWeaponStat
        local isInputActionDown = action_bind_interface.isInputActionDown
        local __index = nil
        
        do --// gun mods
        
            do --// recoil springs
            
                recoil_springs.applyImpulse = function(self, ...)
                    -- return (features.misc.gun.no_recoil and "pwnd by mega hacker dementia") or apply_impulse(self, ...)
                    return (features.misc.gun.no_recoil and randomString()) or apply_impulse(self, ...)
                end
                
            end
        
            do --// firearmobject
            
                firearm_object.computeGunSway = function(self, ...)
                    return (features.misc.gun.no_sway and CFrame.new(0, 0, 0)) or compute_gun_sway(self, ...)
                end
            
                firearm_object.computeWalkSway = function(self, ...)
                    return (features.misc.gun.no_sway and CFrame.new(0, 0, 0)) or compute_walk_sway(self, ...)
                end
                
            end
        
            firearm_object.getWeaponStat = function(weapon, stat, ...)
                return getWeaponStat(weapon, stat, ...)
            end
        
            action_bind_interface.isInputActionDown = function(action, ...)
                return isInputActionDown(action, ...)
            end
            
        end
    
        do --// player data utils
        
            player_data_utils.ownsWeapon = function(self, ...)
                local args = {...}
        
                for i = 1, #knives do
                    for whitelisted, state in Options[`{knives[i].Name}_section`].Value do
                        if args[1] == whitelisted then
                            return state
                        end
                    end
                end
            
                return ownsWeapon(self, ...)
            end
        
            player_data_utils.ownsAttachment = function(self, ...)
                return (features.misc.player.unlocks.attachments and true) or ownsAttachment(self, ...)
            end
            
        end
    
        do --// third person object
        
            third_person_obj.step = function(arg1, _, arg3, arg4, arg5, arg6) --// cred for fake entry fix: mogger / @imtrolling
                step(arg1, true, arg3, arg4, arg5, arg6)
            end
            
        end
    
        do --// metamethod
        
            __index = hookmetamethod(game, "__index", function(self, key)
        
                if checkcaller() then
                    return __index(self, key)
                end
            
                if features.combat.legit.bullet_redirection.enabled then
                
                    local info = debug.info(3, "n")
                
                    if key == "CFrame" and info:find("fire") then
                    
                        local weapon, _, _ = get_weapon()
                        local closest = storage.closest_player
                    
                        if closest and weapon and weapon._barrelPart then
                            local character = get_character(closest)
                            local hitPart = character[Options.legitbot_hitpart.Value]
                        
                            if hitPart then
                            
                                local hit_pos = calculate_position(
                                    weapon._barrelPart.Position,
                                    hitPart.Position,
                                    get_velocity(closest),
                                    { bulletspeed = weapon:getWeaponStat("bulletspeed"), gravity = workspace.Gravity, hitchance = Options.hitchance_value.Value }
                                )
                            
                                return CFrame.lookAt(weapon._barrelPart.Position, hit_pos)
                            
                            end
                        end
                    
                    end
                end
            
                return __index(self, key)
            end)
            
        end
    
        do --// network
        
            network_module.send = function(self, ...)
                local args = {...}
                local network_name = args[1]
            
                task.spawn(function()
                    local weapon, _, _ = get_weapon()
            
                    if network_name == "newbullets" and Toggles.bullet_tracers_enabled.Value then
                        if weapon and weapon._barrelPart then
                            local firepos = weapon._barrelPart.Position
                            storage.shoot_time = os.clock()
                        
                            local bullets = args[3].bullets
                            local tracer_config = {
                                color = Options.bullet_tracers_color.Value,
                                lifetime = Options.bullet_tracer_lifetime.Value,
                                speed = Options.bullet_tracer_speed.Value * 2,
                                tracer = `rbxassetid://{storage.bullet_tracers.beam.texture}`
                            }
                        
                            for _, bullet in ipairs(bullets) do
                                render_tracer(firepos, firepos + bullet[1].Unit.Unit * 300, tracer_config)
                            end
                        end
                    elseif network_name == "bullethit" then
                        storage.latest_hit = args
                    
                        if features.misc.hitsounds.enabled then
                            play(`rbxassetid://{storage.hitsounds[features.misc.hitsounds.hitsound]}`, {
                                volume = features.misc.hitsounds.volume,
                                pitch = 1,
                            })
                        end
                    elseif network_name == "repupdate" then
                        if features.misc.player.anti_aim.enabled then
                            local spin_speed = features.misc.player.anti_aim.spin_speed / 10
                            storage.aa_rotation_angle = (storage.aa_rotation_angle + spin_speed) % 360
                        
                            args[3] = Vector3.new(
                                features.misc.player.anti_aim.pitch, 
                                features.misc.player.anti_aim.spin and storage.aa_rotation_angle or 0, 
                                0
                            )
                        end
                    end
                end)
            
                return network_send(self, unpack(args))
            end            
            
        end
        
    end

    do --// connections
    
        replicated_storage.RemoteEvent.OnClientEvent:Connect(function(self, ...)
            local args = {...}
            local name = args[1]
    
            if name == "kill" then
            
                if Toggles.kill_notifications_enabled.Value then
                
                    Library:Notify(`killed {tostring(args[2].Name)}`)
                
                end
            
                if Toggles.killsounds_enabled.Value then
                    
                    play(`rbxassetid://{storage.killsounds[Options.killsound_id.Value]}`, {
                        volume = Options.killsound_volume.Value * 1.15,
                        pitch = 1,
                    })
                
                end
            
            end
        
        end)
    
        workspace.Ignore.DeadBody.ChildAdded:Connect(function(body)
    
            if body:FindFirstChildOfClass("Highlight") then
                body:FindFirstChildOfClass("Highlight"):Destroy()
            end
            
        end)
        
    end

    do --// ui
    
        do --// sections
        
            do --// combat tab
            
                do --// aim assist
                
                    sections.legit_tab.aim_assist:AddToggle("aimassist_enabled", {
                        Text = "enabled",
                        Default = false,
                        Tooltip = nil,
                    
                        Callback = function(Value)
                            features.combat.legit.aim_assist.enabled = Value
                        end
                    })
                    
                    sections.legit_tab.aim_assist:AddSlider("aimassist_speed_x", {
                        Text = "mouse speed x",
                        Default = 0,
                        Min = 0,
                        Max = 10,
                        Rounding = 1,
                        Compact = false,
                    })
                    
                    sections.legit_tab.aim_assist:AddSlider("aimassist_speed_y", {
                        Text = "mouse speed y",
                        Default = 0,
                        Min = 0,
                        Max = 10,
                        Rounding = 1,
                        Compact = false,
                    })
                    
                    sections.legit_tab.aim_assist:AddSlider("camera_smoothness", {
                        Text = "camera smoothness",
                        Default = 0,
                        Min = 0,
                        Max = 10,
                        Rounding = 1,
                        Compact = false,
                    
                        Callback = function(Value)
                            features.combat.legit.aim_assist.speed.y = Value
                        end
                    })
                    
                    sections.legit_tab.aim_assist:AddDropdown('aimassist_method', {
                        Values = {"camera", "mouse"},
                        Default = 1,
                        Multi = false,
                    
                        Text = "aim assist method",
                        Tooltip = nil,
                    })
                    
                end
            
                do --// bullet redirection
                
                    sections.legit_tab.bullet_redirection:AddToggle("bullet_redirection_enabled", {
                        Text = "enabled",
                        Default = false,
                        Tooltip = nil,
                    
                        Callback = function(Value)
                            features.combat.legit.bullet_redirection.enabled = Value
                        end
                    })
                    
                end
            
                do --// ragebot
                
                    local shoot_sounds_packed = {"original"}
                
                    for index, id in storage.shoot_sounds do
                        shoot_sounds_packed[#shoot_sounds_packed+1] = index
                    end
                
                    sections.rage_tab.ragebot:AddToggle("ragebot_enabled", {
                        Text = "ragebot",
                        Default = false,
                        Tooltip = nil,
                
                        Callback = function(Value)
                            features.combat.ragebot.enabled = Value
                        end
                    }):AddColorPicker("ragebot_target_color", {
                        Default = Color3.fromRGB(255, 255, 255), 
                        Title = "ragebot target color",
                        Transparency = 0,
                    })
                    
                    sections.rage_tab.ragebot:AddToggle("silent_hit_enabled", {
                        Text = "silent hit",
                        Default = true,
                        Tooltip = nil,
                    
                        Callback = function(Value)
                            features.combat.ragebot.silent_hit = Value
                        end
                    })
                    
                    sections.rage_tab.ragebot:AddToggle("instahit_enabled", {
                        Text = "instant hit",
                        Default = false,
                        Tooltip = nil,
                    
                        Callback = function(Value)
                            features.combat.ragebot.insta_hit = Value
                        end
                    })
                    
                    sections.rage_tab.ragebot:AddDropdown('ragebot_hitpart', {
                        Values = {"Head", "Torso"},
                        Default = 1, 
                        Multi = false,
                    
                        Text = "ragebot hitpart",
                        Tooltip = nil,
                    
                        Callback = function(Value)
                            features.combat.ragebot.hitpart = Value
                        end
                    })
                    
                    sections.rage_tab.ragebot:AddDropdown('shoot_sound', {
                        Values = shoot_sounds_packed,
                        Default = 1, 
                        Multi = false,
                    
                        Text = "shoot sound",
                        Tooltip = nil,
                    })
                    
                    
                end
            
                do --// knife_aura
                
                    sections.rage_tab.knife_aura:AddToggle("knife_aura_enabled", {
                        Text = "enabled",
                        Default = false,
                        Tooltip = nil,
                
                        Callback = function(Value)
                            features.combat.knife_aura.enabled = Value
                        end
                    })
                    
                    sections.rage_tab.knife_aura:AddToggle("knife_aura_headshot_enabled", {
                        Text = "headshot",
                        Default = false,
                        Tooltip = nil,
                    
                        Callback = function(Value)
                            features.combat.knife_aura.headshot = Value
                        end
                    })
                    
                    sections.rage_tab.knife_aura:AddSlider("knife_aura_radius", {
                        Text = "radius",
                        Default = 0,
                        Min = 0,
                        Max = 15,
                        Rounding = 1,
                        Compact = false,
                    
                        Callback = function(Value)
                            features.combat.knife_aura.radius = Value
                        end
                    })
                    
                end
            
                do --// config section
                
                    sections.legit_tab.config:AddToggle("fov_enabled", {
                        Text = "fov",
                        Default = false,
                        Tooltip = nil,
                    
                        Callback = function(Value)
                            main_fov.Visible = Value
                        end
                    }):AddColorPicker("fov_color", {
                        Default = Color3.fromRGB(255, 255, 255), 
                        Title = "fov color",
                        Transparency = 0,
                    
                        Callback = function(Value)
                            main_fov.Color = Value
                        end
                    })
                    
                    sections.legit_tab.config:AddToggle("dynamic_fov_enabled", {
                        Text = "dynamic fov",
                        Default = false,
                        Tooltip = nil,
                    })
                    
                    sections.legit_tab.config:AddDropdown('legitbot_hitpart', {
                        Values = {"Head", "Torso"},
                        Default = 1, 
                        Multi = false,
                    
                        Text = "hitpart",
                        Tooltip = nil,
                    })
                    
                    sections.legit_tab.config:AddSlider("fov_value", {
                        Text = "fov value",
                        Default = 250,
                        Min = 0,
                        Max = 1000,
                        Rounding = 1,
                        Compact = false,
                    })
                    
                    sections.legit_tab.config:AddSlider("hitchance_value", {
                        Text = "hitchance",
                        Default = 100,
                        Min = 0,
                        Max = 100,
                        Rounding = 1,
                        Compact = false,
                    })
                    
                end
            
                do --// prediction section
                
                    sections.legit_tab.prediction:AddToggle("prediction_bulletdrop_enabled", {
                        Text = "bullet drop",
                        Default = false,
                        Tooltip = nil,
                    
                        Callback = function(Value)
                            features.combat.legit.prediction.bullet_drop = Value
                        end
                    })
                    
                    sections.legit_tab.prediction:AddToggle("prediction_velocity_enabled", {
                        Text = "velocity",
                        Default = false,
                        Tooltip = nil,
                    
                        Callback = function(Value)
                            features.combat.legit.prediction.velocity = Value
                        end
                    })
                    
                    sections.legit_tab.prediction:AddToggle("prediction_travel_time_enabled", {
                        Text = "travel time",
                        Default = false,
                        Tooltip = nil,
                    
                        Callback = function(Value)
                            features.combat.legit.prediction.travel_time = Value
                        end
                    })
                    
                end
                
            end
        
            do --// visuals tab
            
                do --// players
                
                    sections.visuals_tab.players:AddToggle("box_enabled", {
                        Text = "box",
                        Default = false,
                        Tooltip = nil,
                    }):AddColorPicker("box_color_vis", {
                        Default = Color3.fromRGB(255, 255, 255), 
                        Title = "box color visible",
                        Transparency = 0,
                    }):AddColorPicker("box_color_occluded", {
                        Default = Color3.fromRGB(255, 255, 255), 
                        Title = "box color occluded",
                        Transparency = 0,
                    })
                
                    sections.visuals_tab.players:AddToggle("healthbar_enabled", {
                        Text = "healthbar",
                        Default = false,
                        Tooltip = nil,
                    })
                
                    sections.visuals_tab.players:AddToggle("weapon_enabled", {
                        Text = "weapon",
                        Default = false,
                        Tooltip = nil,
                    }):AddColorPicker("weapon_color_vis", {
                        Default = Color3.fromRGB(255, 255, 255), 
                        Title = "weapon color visible",
                        Transparency = 0,
                    }):AddColorPicker("weapon_color_occluded", {
                        Default = Color3.fromRGB(255, 255, 255), 
                        Title = "weapon color occluded",
                        Transparency = 0,
                    })
                
                    sections.visuals_tab.players:AddToggle("name_enabled", {
                        Text = "name",
                        Default = false,
                        Tooltip = nil,
                    }):AddColorPicker("name_color_vis", {
                        Default = Color3.fromRGB(255, 255, 255), 
                        Title = "name color visible",
                        Transparency = 0,
                    }):AddColorPicker("name_color_occluded", {
                        Default = Color3.fromRGB(255, 255, 255), 
                        Title = "name color occluded",
                        Transparency = 0,
                    })
                
                    sections.visuals_tab.players:AddToggle("chams_enabled", {
                        Text = "chams",
                        Default = false,
                        Tooltip = nil,
                    }):AddColorPicker("cham_fill_color_vis", {
                        Default = Color3.fromRGB(255, 255, 255), 
                        Title = "cham fill color visible",
                        Transparency = 0,
                    }):AddColorPicker("cham_outline_color_vis", {
                        Default = Color3.fromRGB(255, 255, 255), 
                        Title = "cham outline color visible",
                        Transparency = 0,
                    }):AddColorPicker("cham_fill_color_occluded", {
                        Default = Color3.fromRGB(255, 255, 255), 
                        Title = "cham fill color occluded",
                        Transparency = 0,
                    }):AddColorPicker("cham_outline_color_occluded", {
                        Default = Color3.fromRGB(255, 255, 255), 
                        Title = "cham outline color occluded",
                        Transparency = 0,
                    })
                
                    sections.visuals_tab.players:AddSlider("healthbar_thickness", {
                        Text = "healthbar thickness",
                        Default = 2,
                        Min = 2,
                        Max = 10,
                        Rounding = 1,
                        Compact = false,
                    })
                
                    sections.visuals_tab.players:AddDropdown("cham_method", {
                        Values = {"AlwaysOnTop", "Occluded"},
                        Default = 1, 
                        Multi = false,
                    
                        Text = "cham method",
                        Tooltip = nil,
                    })
                    
                end
            
                do --// world
                
                    local bullet_tracers_packed = {}
                
                    for index, _ in storage.bullet_tracers do
                        bullet_tracers_packed[#bullet_tracers_packed+1] = index
                    end
                
                    sections.visuals_tab.world:AddToggle("bullet_tracers_enabled", {
                        Text = "bullet tracers",
                        Default = false,
                        Tooltip = nil,
                    }):AddColorPicker("bullet_tracers_color", {
                        Default = Color3.fromRGB(255, 255, 255), 
                        Title = "bullet tracer color",
                        Transparency = 0,
                    })
                
                    sections.visuals_tab.world:AddSlider("bullet_tracer_lifetime", {
                        Text = "bullet tracer lifetime",
                        Default = 5,
                        Min = 0,
                        Max = 20,
                        Rounding = 1,
                        Compact = false,
                    })
                    
                    sections.visuals_tab.world:AddSlider("bullet_tracer_speed", {
                        Text = "bullet tracer speed",
                        Default = 5,
                        Min = 0,
                        Max = 20,
                        Rounding = 1,
                        Compact = false,
                
                        Callback = function(Value)
                            features.visuals.world.bullet_tracers.speed = Value
                        end
                    })
                    
                    sections.visuals_tab.world:AddDivider()
                    
                    sections.visuals_tab.world:AddToggle("3d_hitmarker_enabled", {
                        Text = "3d hitmarker",
                        Default = false,
                        Tooltip = nil,
                    }):AddColorPicker("3d_hitmarker_color", {
                        Default = Color3.fromRGB(255, 255, 255), 
                        Title = "hitmarker color",
                        Transparency = 0,
                    })
                    
                    sections.visuals_tab.world:AddSlider("3d_hitmarker_lifetime", {
                        Text = "3d hitmarker lifetime",
                        Default = 0.5,
                        Min = 0.1,
                        Max = 5,
                        Rounding = 1,
                        Compact = false,
                    })
                    
                    sections.visuals_tab.world:AddDivider()
                    
                    sections.visuals_tab.world:AddToggle("ambient_enabled", {
                        Text = "ambient",
                        Default = false,
                        Tooltip = nil,
                    }):AddColorPicker("ambient_color", {
                        Default = Color3.fromRGB(255, 255, 255), 
                        Title = "ambient color",
                        Transparency = 0,
                    })
                    
                    sections.visuals_tab.world:AddToggle("override_clocktime", {
                        Text = "override clocktime",
                        Default = false,
                        Tooltip = nil,
                    })
                    
                    sections.visuals_tab.world:AddSlider("clock_time", {
                        Text = "clocktime",
                        Default = 0,
                        Min = 0,
                        Max = 24,
                        Rounding = 1,
                        Compact = false,
                    })
                    
                end
            
                do --// viewmodel
                
                    sections.visuals_tab.viewmodel:AddToggle("override_viewmodel_offset", {
                        Text = "override offset",
                        Default = false,
                        Tooltip = nil,
                    
                        Callback = function(Value)
                            features.visuals.viewmodel.viewmodel_offset.enabled = Value
                        end
                    })
                    
                    sections.visuals_tab.viewmodel:AddSlider("override_offset_x", {
                        Text = "offset x",
                        Default = 0,
                        Min = -10,
                        Max = 10,
                        Rounding = 1,
                        Compact = false,
                    
                        Callback = function(Value)
                            features.visuals.viewmodel.viewmodel_offset.offset.x = Value
                        end
                    })
                    
                    sections.visuals_tab.viewmodel:AddSlider("override_offset_y", {
                        Text = "offset y",
                        Default = 0,
                        Min = -10,
                        Max = 10,
                        Rounding = 1,
                        Compact = false,
                    
                        Callback = function(Value)
                            features.visuals.viewmodel.viewmodel_offset.offset.y = Value
                        end
                    })
                    
                    sections.visuals_tab.viewmodel:AddSlider("override_offset_z", {
                        Text = "offset z",
                        Default = 0,
                        Min = -10,
                        Max = 10,
                        Rounding = 1,
                        Compact = false,
                    
                        Callback = function(Value)
                            features.visuals.viewmodel.viewmodel_offset.offset.z = Value
                        end
                    })
                    
                end
            
                do --// visuals
                
                    sections.visuals_tab.visuals:AddToggle("crosshair_enabled", {
                        Text = "crosshair",
                        Default = false,
                        Tooltip = nil,
                    }):AddColorPicker("crosshair_color", {
                        Default = Color3.fromRGB(255, 255, 255), 
                        Title = "crosshair color",
                        --Transparency = 0,
                    })
                
                    sections.visuals_tab.visuals:AddToggle("crosshair_rotation_enabled", {
                        Text = "rotate",
                        Default = false,
                        Tooltip = nil,
                    })
                
                    sections.visuals_tab.visuals:AddSlider("crosshair_rotation_speed", {
                        Text = "rotation speed",
                        Default = 1,
                        Min = 1,
                        Max = 10,
                        Rounding = 1,
                        Compact = false,
                    })
                
                    sections.visuals_tab.visuals:AddSlider("crosshair_spacing", {
                        Text = "spacing",
                        Default = 1,
                        Min = 1,
                        Max = 20,
                        Rounding = 1,
                        Compact = false,
                    })
                
                end
                
            end
        
            do --// misc tab
            
                do --// misc
                
                    sections.misc_tab.misc:AddToggle("custom_kill_text_enabled", {
                        Text = "custom kill text",
                        Default = false,
                        Tooltip = nil,
                
                        Callback = function(Value)
                            if Value then
                                set_killtext(Options.custom_kill_text_value.Value)
                            else
                                for index, _ in hud_notification_config.typeList do
                                    set_killtext(storage.kill_indexes[index])
                                end
                            end
                        end
                    })
                    
                    sections.misc_tab.misc :AddInput("custom_kill_text_value", {
                        
                        Default = 'Raped Enemy!',
                        Numeric = false,
                        Finished = false,
                    
                        Text = 'custom kill text',
                        Tooltip = nil,
                    
                        Placeholder = 'text here',
                    
                        Callback = function(Value)
                    
                            if Toggles.custom_kill_text_enabled.Value then
                                set_killtext(Value)
                            end
                            
                        end
                    
                    })
                    
                end
            
                do --// anti aim
                    
                    sections.misc_tab.anti_aim:AddToggle("aa_enabled", {
                        Text = "anti aim",
                        Default = false,
                        Tooltip = nil,
                    
                        Callback = function(Value)
                            features.misc.player.anti_aim.enabled = Value
                        end
                    })
                    
                    sections.misc_tab.anti_aim:AddToggle("aa_spin_enabled", {
                        Text = "spin",
                        Default = false,
                        Tooltip = nil,
                    
                        Callback = function(Value)
                            features.misc.player.anti_aim.spin = Value
                        end
                    })
                    
                    sections.misc_tab.anti_aim:AddSlider("aa_spin_speed", {
                        Text = "spin speed",
                        Default = 1,
                        Min = 1,
                        Max = 10,
                        Rounding = 1,
                        Compact = false,
                    
                        Callback = function(Value)
                            features.misc.player.anti_aim.spin_speed = Value
                        end
                    })
                    
                    sections.misc_tab.anti_aim:AddSlider("aa_pitch", {
                        Text = "pitch",
                        Default = 0,
                        Min = -2,
                        Max = 2,
                        Rounding = 1,
                        Compact = false,
                    
                        Callback = function(Value)
                            features.misc.player.anti_aim.pitch = Value
                        end
                    })
                    
                end
            
                do --// unlocks
                
                    for _, knife_section in knives do
                    
                        local formatted_knives = {}
                    
                        for _, knife in knife_section:GetChildren() do --// change later
                            formatted_knives[#formatted_knives+1] = knife.Name
                        end
                    
                        sections.misc_tab.unlocks:AddDropdown(`{tostring(knife_section)}_section`, {
                            Values = formatted_knives,
                            Default = 1, 
                            Multi = true,
                        
                            Text = knife_section.Name,
                            Tooltip = nil,
                        })
                    
                    end
                
                    sections.misc_tab.unlocks:AddDivider()
                
                    sections.misc_tab.unlocks:AddToggle("unlock_attachments", {
                        Text = "unlock attachments",
                        Default = false,
                        Tooltip = nil,
                    
                        Callback = function(Value)
                            features.misc.player.unlocks.attachments = Value
                        end
                    })
                    
                end
            
                do --// localplayer
                
                    sections.misc_tab.local_player:AddToggle("walkspeed_enabled", {
                        Text = "walkspeed",
                        Default = false,
                        Tooltip = nil,
                    
                        Callback = function(Value)
                            features.misc.player.walkspeed.enabled = Value
                        end
                    })
                    
                    sections.misc_tab.local_player:AddSlider("walkspeed_value", {
                        Text = "speed",
                        Default = 0,
                        Min = 0,
                        Max = 55,
                        Rounding = 1,
                        Compact = false,
                    
                        Callback = function(Value)
                            features.misc.player.walkspeed.speed = Value
                        end
                    })
                    
                    sections.misc_tab.local_player:AddDivider()
                    
                    sections.misc_tab.local_player:AddToggle("bhop_enabled", {
                        Text = "bhop",
                        Default = false,
                        Tooltip = nil,
                    })
                    
                end
            
                do --// sounds
                
                    local hitsound_packed = {}
                    local killsound_packed = {}
                
                    for index, id in storage.hitsounds do
                        hitsound_packed[#hitsound_packed+1] = index
                    end
                
                    for index, id in storage.killsounds do
                        killsound_packed[#killsound_packed+1] = index
                    end
                
                    sections.misc_tab.onhit:AddToggle("hitsounds_enabled", {
                        Text = "hitsounds",
                        Default = false,
                        Tooltip = nil,
                    
                        Callback = function(Value)
                            features.misc.hitsounds.enabled = Value
                        end
                    })
                    
                    sections.misc_tab.onhit:AddToggle("killsounds_enabled", {
                        Text = "killsounds",
                        Default = false,
                        Tooltip = nil,
                    })
                    
                    sections.misc_tab.onhit:AddToggle("hit_notifications_enabled", {
                        Text = "hit notifications",
                        Default = false,
                        Tooltip = nil,
                    })
                    
                    sections.misc_tab.onhit:AddToggle("kill_notifications_enabled", {
                        Text = "kill notifications",
                        Default = false,
                        Tooltip = nil,
                    })
                    
                    sections.misc_tab.onhit:AddDropdown("hitsound_id", {
                        Values = hitsound_packed,
                        Default = 1, 
                        Multi = false,
                    
                        Text = "hitsound id",
                        Tooltip = nil,
                    
                        Callback = function(Value)
                            features.misc.hitsounds.hitsound = Value
                        end
                    })
                    
                    sections.misc_tab.onhit:AddDropdown("killsound_id", {
                        Values = killsound_packed,
                        Default = 1, 
                        Multi = false,
                    
                        Text = "killsound id",
                        Tooltip = nil,
                    })
                    
                    sections.misc_tab.onhit:AddSlider("hitsound_volume", {
                        Text = "hitsound volume",
                        Default = 1,
                        Min = 1,
                        Max = 5,
                        Rounding = 1,
                        Compact = false,
                    
                        Callback = function(Value)
                            features.misc.hitsounds.volume = Value
                        end
                    })
                    
                    sections.misc_tab.onhit:AddSlider("killsound_volume", {
                        Text = "killsound volume",
                        Default = 1,
                        Min = 1,
                        Max = 5,
                        Rounding = 1,
                        Compact = false,
                    })
                    
                end
            
                do --// gun mods
                
                    sections.misc_tab.gun_mods:AddToggle("insta_reload_enabled", {
                        Text = "instant reload",
                        Default = false,
                        Tooltip = nil,
                    
                        Callback = function(Value)
                            features.misc.gun.insta_reload = Value
                        end
                    })
                    
                    sections.misc_tab.gun_mods:AddToggle("no_sway_enabled", {
                        Text = "no sway",
                        Default = false,
                        Tooltip = nil,
                    
                        Callback = function(Value)
                            features.misc.gun.no_sway = Value
                        end
                    })
                    
                    sections.misc_tab.gun_mods:AddToggle("no_spread_enabled", {
                        Text = "no spread",
                        Default = false,
                        Tooltip = nil,
                    
                        Callback = function(Value)
                            features.misc.gun.no_spread = Value
                        end
                    })
                    
                    sections.misc_tab.gun_mods:AddToggle("no_recoil_enabled", {
                        Text = "no recoil",
                        Default = false,
                        Tooltip = nil,
                    
                        Callback = function(Value)
                            features.misc.gun.no_recoil = Value
                        end
                    })
                    
                end
            
            end
            
        end
    
        do --// ui
        
            library:SetWatermarkVisibility(true)
            library:SetWatermark("homohack BACKUP")
        
            library.KeybindFrame.Visible = false
            
            library:OnUnload(function()    
                print("Unloaded!")
                library.Unloaded = true
            end)
            
            local MenuGroup = tabs["settings"]:AddLeftGroupbox("Menu")
            
            MenuGroup:AddButton("Unload", function() library:Unload() end)
            MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "End", NoUI = true, Text = "Menu keybind" })
            
            library.ToggleKeybind = Options.MenuKeybind
            
            theme_manager:SetLibrary(library)
            save_manager:SetLibrary(library)
            
            save_manager:IgnoreThemeSettings()
            
            save_manager:SetIgnoreIndexes({ "MenuKeybind" })
            theme_manager:SetFolder("Homohack-v2")
            save_manager:SetFolder("Homohack-v2/phantom_forces")
            
            save_manager:BuildConfigSection(tabs["settings"])
            theme_manager:ApplyToTab(tabs["settings"])
            save_manager:LoadAutoloadConfig()
            
        end
        
    end
    
end
