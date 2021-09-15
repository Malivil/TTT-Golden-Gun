--- Golden Gun
if SERVER then
    AddCSLuaFile("shared.lua")

    resource.AddFile("materials/models/weapons/v_models/powerdeagle/deagle_skin.vmt")
	resource.AddFile("materials/models/weapons/v_models/powerdeagle/deagle_skin.vtf")
	resource.AddFile("materials/models/weapons/v_models/powerdeagle/deagle_skin1_ref.vtf")
	resource.AddFile("materials/models/weapons/v_models/powerdeagle/dot2.vmt")
	resource.AddFile("materials/models/weapons/v_models/powerdeagle/dot2.vtf")
	resource.AddFile("materials/models/weapons/v_models/powerdeagle/line.vmt")
	resource.AddFile("materials/models/weapons/v_models/powerdeagle/line.vtf")
	resource.AddFile("materials/models/weapons/v_models/powerdeagle/suppressor.vmt")
	resource.AddFile("materials/models/weapons/v_models/powerdeagle/suppressor.vtf")
	resource.AddFile("materials/models/weapons/v_models/feets/v_hands.vmt")
	resource.AddFile("materials/models/weapons/v_models/feets/v_hands.vtf")
    resource.AddFile("materials/models/weapons/v_models/feets/v_hands_normal.vtf")

    util.AddNetworkString("TTT_RoleChanged")
    util.AddNetworkString("TTT_Zombified")
    util.AddNetworkString("TTT_DrunkSober")
    util.AddNetworkString("TTT_ScoreBodysnatch")
end

if CLIENT then
    SWEP.PrintName = "Golden Deagle"
    SWEP.Slot = 6 -- add 1 to get the slot number key

    SWEP.ViewModelFOV = 72
    SWEP.ViewModelFlip = true
end

SWEP.Base = "weapon_tttbase"

--- Standard GMod values

SWEP.HoldType = "pistol"

SWEP.Primary.Delay = 0.08
SWEP.Primary.Recoil = 1.2
SWEP.Primary.Automatic = true
SWEP.Primary.Damage = 1
SWEP.Primary.Cone = 0.025
SWEP.Primary.Ammo = "AR2AltFire"
SWEP.Primary.ClipSize = 1
SWEP.Primary.ClipMax = 1
SWEP.Primary.DefaultClip = 1
SWEP.Primary.Sound = Sound("Weapon_Deagle.Single")

SWEP.ViewModel = "models/weapons/v_powerdeagle.mdl"
SWEP.WorldModel = "models/weapons/w_powerdeagle.mdl"

SWEP.Kind = WEAPON_EQUIP1
SWEP.AutoSpawnable = false
SWEP.AmmoEnt = "RPG_Round"
SWEP.CanBuy = {ROLE_DETECTIVE}
SWEP.InLoadoutFor = nil
SWEP.LimitedStock = true
SWEP.AllowDrop = true
SWEP.IsSilent = false
SWEP.NoSights = false

if CLIENT then
    -- Path to the icon material
    SWEP.Icon = "VGUI/ttt/icon_flux_goldengun"

    -- Text shown in the equip menu
    SWEP.EquipMenuData = {
        type = "Weapon",
        desc = "Shoot a traitor, kill a traitor. \nShoot an innocent, kill yourself. \nBe careful."
    };
end

if SERVER then resource.AddFile("materials/VGUI/ttt/icon_flux_goldengun.vmt") end

CreateConVar("ttt_gdeagle_killer_damage", "35")
CreateConVar("ttt_gdeagle_vampire_heal", "50")
CreateConVar("ttt_gdeagle_vampire_overheal", "25")

ROLE_MERCENARY = ROLE_MERCENARY or ROLE_SURVIVALIST or -1
ROLE_PHANTOM = ROLE_PHANTOM or ROLE_PHOENIX or -1
ROLE_KILLER = ROLE_KILLER or ROLE_SERIALKILLER or -1
ROLE_ZOMBIE = ROLE_ZOMBIE or ROLE_INFECTED or -1
ROLE_SWAPPER = ROLE_SWAPPER or -1
ROLE_GLITCH = ROLE_GLITCH or -1
ROLE_HYPNOTIST = ROLE_HYPNOTIST or -1
ROLE_ASSASSIN = ROLE_ASSASSIN or -1
ROLE_DETRAITOR = ROLE_DETRAITOR or -1
ROLE_VAMPIRE = ROLE_VAMPIRE or -1
ROLE_DRUNK = ROLE_DRUNK or -1

local function IsInnocentTeam(ply)
    if ply.IsInnocentTeam then return ply:IsInnocentTeam() end
    local role = ply:GetRole()
    return role == ROLE_DETECTIVE or role == ROLE_INNOCENT or role == ROLE_MERCENARY or role == ROLE_PHANTOM or role == ROLE_GLITCH
end

local function IsTraitorTeam(ply)
    if player.IsTraitorTeam then return player.IsTraitorTeam(ply) end
    if ply.IsTraitorTeam then return ply:IsTraitorTeam() end
    local role = ply:GetRole()
    return role == ROLE_TRAITOR or role == ROLE_HYPNOTIST or role == ROLE_ASSASSIN or role == ROLE_DETRAITOR
end

local function IsJesterTeam(ply)
    if ply.IsJesterTeam then return ply:IsJesterTeam() end
    local role = ply:GetRole()
    return role == ROLE_JESTER or role == ROLE_SWAPPER
end

local function IsIndependentTeam(ply)
    return ply.IsIndependentTeam and ply:IsIndependentTeam()
end

function SetRole(ply, role)
    ply:SetRole(role)

    net.Start("TTT_RoleChanged")
    net.WriteString(ply:SteamID64())
    if CR_VERSION and CRVersion("1.1.2") then
        net.WriteInt(role, 8)
    else
        net.WriteUInt(role, 8)
    end
    net.Broadcast()
end

function SWEP:PrimaryAttack()
    if (not self:CanPrimaryAttack()) then return end
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    self:TakePrimaryAmmo(1)
    self:GetOwner():EmitSound(Sound("Weapon_Deagle.Single"))

    local trace = util.GetPlayerTrace(self:GetOwner())
    local tr = util.TraceLine(trace)
    if tr.Entity.IsPlayer() then
        local ply = tr.Entity
        -- Set the owner on fire for 5 seconds
        if ply:GetRole() == ROLE_PHANTOM then
            if SERVER then self:GetOwner():Ignite(5) end
        -- Reduce the health of both the Owner and the Target by the configured amount
        elseif ply:GetRole() == ROLE_KILLER then
            if SERVER then
                local killerdamage = GetConVar("ttt_gdeagle_killer_damage"):GetInt()
                if self:GetOwner():Health() > killerdamage then
                    self:GetOwner():SetHealth(self:GetOwner():Health() - killerdamage)
                else
                    self:GetOwner():Kill()
                end
                if ply:Health() > killerdamage then
                    ply:SetHealth(ply:Health() - killerdamage)
                else
                    ply:Kill()
                end
            end
        -- Turn the owner into a Zombie thrall
        elseif ply:GetRole() == ROLE_ZOMBIE then
            if SERVER then
                net.Start("TTT_Zombified")
                net.WriteString(self:GetOwner():Nick())
                net.Broadcast()

                self:GetOwner():SetRole(ROLE_ZOMBIE)
                if self:GetOwner().SetZombiePrime then
                    self:GetOwner():SetZombiePrime(false)
                end
                self:GetOwner():StripWeapons()
                self:GetOwner():Give("weapon_zom_claws")
                SendFullStateUpdate()
            end
        -- Turn the owner into a pile of bones and heal the target
        elseif ply:GetRole() == ROLE_VAMPIRE then
            if SERVER then
                local vamheal = GetConVar("ttt_gdeagle_vampire_heal"):GetInt()
                local vamoverheal = GetConVar("ttt_gdeagle_vampire_overheal"):GetInt()
                ply:SetHealth(math.min(ply:Health() + vamheal, ply:GetMaxHealth() + vamoverheal))
                self:DropBones(self:GetOwner())
                local sid = self:GetOwner():SteamID()
                self:GetOwner():Kill()
                RemoveRagdoll(sid)
            end
        -- Have the drunk immediately remember their role
        elseif ply:GetRole() == ROLE_DRUNK then
            if SERVER then
                if ConVarExists("ttt_drunk_become_clown") and GetConVar("ttt_drunk_become_clown"):GetBool() then
                    ply:DrunkRememberRole(ROLE_CLOWN, true)
                elseif ply.SoberDrunk then
                    ply:SoberDrunk()
                -- Fall back to default logic if we don't have the advanced drunk options
                else
                    local role
                    if math.random() > GetConVar("ttt_drunk_innocent_chance"):GetFloat() then
                        role = ROLE_TRAITOR
                        ply:SetCredits(GetConVar("ttt_credits_starting"):GetInt())
                    else
                        role = ROLE_INNOCENT
                    end

                    ply:SetNWBool("WasDrunk", true)
                    ply:SetRole(role)
                    ply:PrintMessage(HUD_PRINTTALK, "You have remembered that you are " .. ROLE_STRINGS_EXT[role] .. ".")
                    ply:PrintMessage(HUD_PRINTCENTER, "You have remembered that you are " .. ROLE_STRINGS_EXT[role] .. ".")

                    net.Start("TTT_DrunkSober")
                    net.WriteString(ply:Nick())
                    net.WriteString(ROLE_STRINGS_EXT[role])
                    net.Broadcast()

                    SendFullStateUpdate()
                end

                if timer.Exists("drunkremember") then timer.Remove("drunkremember") end
                if timer.Exists("waitfordrunkrespawn") then timer.Remove("waitfordrunkrespawn") end
            end
        -- Switch roles with the bodysnatcher
        elseif ply:GetRole() == ROLE_BODYSNATCHER then
            if SERVER then
                local owner = self:GetOwner()
                net.Start("TTT_ScoreBodysnatch")
                net.WriteString(owner:Nick())
                net.WriteString(ply:Nick())
                net.WriteString(ROLE_STRINGS_EXT[owner:GetRole()])
                net.Broadcast()

                local victim_role = ply:GetRole()
                local attacker_role = owner:GetRole()
                owner:SetRole(victim_role)
                ply:SetRole(attacker_role)

                ply:StripWeapon("weapon_bod_bodysnatch")

                -- Give the victim all of the attacker's role weapons
                if WEAPON_CATEGORY_ROLE then
                    for _, w in ipairs(owner:GetWeapons()) do
                        if w.Category == WEAPON_CATEGORY_ROLE then
                            local weap_class = WEPS.GetClass(w)
                            owner:StripWeapon(weap_class)
                            ply:Give(weap_class)
                        end
                    end
                end

                -- Handle the DNA scanner explicitly
                if owner:HasWeapon("weapon_ttt_wtester") then
                    owner:StripWeapon("weapon_ttt_wtester")
                    ply:Give("weapon_ttt_wtester")
                end

                -- Give the attacker their own bodysnatching device
                owner:Give("weapon_bod_bodysnatch")

                SendFullStateUpdate()
            end
        -- Change beggars to be the opposite team of the player who shot them (or a random team if shot by a Jester or Independent)
        elseif ply:GetRole() == ROLE_BEGGAR then
            if SERVER then
                local target_role
                if IsTraitorTeam(self:GetOwner()) then
                    target_role = ROLE_INNOCENT
                elseif IsInnocentTeam(self:GetOwner()) then
                    target_role = ROLE_TRAITOR
                else
                    target_role = math.random(0, 1) == 1 and ROLE_INNOCENT or ROLE_TRAITOR
                end
                SetRole(ply, target_role)

                SendFullStateUpdate()
            end
        -- Kill traitors outright
        elseif IsTraitorTeam(ply) then
            local bullet = {}
            bullet.Attacker = self:GetOwner()
            bullet.Num = self.Primary.NumberofShots
            bullet.Src = self:GetOwner():GetShootPos()
            bullet.Dir = self:GetOwner():GetAimVector()
            bullet.Spread = Vector(0, 0, 0)
            bullet.Tracer = 0
            bullet.Force = 3000
            bullet.Damage = 4000
            bullet.AmmoType = self.Primary.Ammo
            self:GetOwner():FireBullets(bullet)
        -- Kill the owner if the target was innocent
        elseif IsInnocentTeam(ply) then
            if SERVER then self:GetOwner():Kill() end
        -- Set the shooter's health to the target's health, if it's less than 100
        -- Then restore the target's max health to at least 100 and fully heal them
        elseif IsIndependentTeam(ply) then
            local hp = ply:Health()
            if hp < 100 and hp < self:GetOwner():Health() then
                self:GetOwner():SetHealth(hp)
            end

            local max = ply:GetMaxHealth()
            if max < 100 then
                max = 100
            end
            ply:SetMaxHealth(max)
            ply:SetHealth(max)
        -- Kill the jester team and the shooter
        elseif IsJesterTeam(ply) then
            if SERVER then
                self:GetOwner():Kill()
                ply:SetHealth(0)
                ply:Kill()
            end
        end
    end
end

function RemoveRagdoll(sid)
    local ragdolls = ents.FindByClass("prop_ragdoll")
    for _, r in pairs(ragdolls) do
        if IsValid(r) and r.player_ragdoll == true and r.sid == sid then
            r:Remove()
        end
    end
end

function SWEP:DropBones(target)
	local pos = target:GetPos()

	local skull = ents.Create("prop_physics")
	if not IsValid(skull) then return end
	skull:SetModel("models/Gibs/HGIBS.mdl")
	skull:SetPos(pos)
	skull:Spawn()
	skull:SetCollisionGroup(COLLISION_GROUP_WEAPON)

	local ribs = ents.Create("prop_physics")
	if not IsValid(ribs) then return end
	ribs:SetModel("models/Gibs/HGIBS_rib.mdl")
	ribs:SetPos(pos + Vector(0, 0, 15))
	ribs:Spawn()
	ribs:SetCollisionGroup(COLLISION_GROUP_WEAPON)

	local spine = ents.Create("prop_physics")
	if not IsValid(ribs) then return end
	spine:SetModel("models/Gibs/HGIBS_spine.mdl")
	spine:SetPos(pos + Vector(0, 0, 30))
	spine:Spawn()
	spine:SetCollisionGroup(COLLISION_GROUP_WEAPON)

	local scapula = ents.Create("prop_physics")
	if not IsValid(scapula) then return end
	scapula:SetModel("models/Gibs/HGIBS_scapula.mdl")
	scapula:SetPos(pos + Vector(0, 0, 45))
	scapula:Spawn()
	scapula:SetCollisionGroup(COLLISION_GROUP_WEAPON)
end