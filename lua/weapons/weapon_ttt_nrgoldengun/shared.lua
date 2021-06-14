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

    util.AddNetworkString("TTT_Zombified")
    util.AddNetworkString("TTT_DrunkSober")
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

function SWEP:PrimaryAttack()
    if (not self:CanPrimaryAttack()) then return end
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    self:TakePrimaryAmmo(1)
    self.Owner:EmitSound(Sound("Weapon_Deagle.Single"))

    local trace = util.GetPlayerTrace(self.Owner)
    local tr = util.TraceLine(trace)
    if tr.Entity.IsPlayer() then
        local ply = tr.Entity
        -- Set the owner on fire for 5 seconds
        if ply:GetRole() == ROLE_PHANTOM then
            if SERVER then self.Owner:Ignite(5) end
        -- Reduce the health of both the Owner and the Target by the configured amount
        elseif ply:GetRole() == ROLE_KILLER then
            if SERVER then
                local killerdamage = GetConVar("ttt_gdeagle_killer_damage"):GetInt()
                if self.Owner:Health() > killerdamage then
                    self.Owner:SetHealth(self.Owner:Health() - killerdamage)
                else
                    self.Owner:Kill()
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
                net.WriteString(self.Owner:Nick())
                net.Broadcast()

                self.Owner:SetRole(ROLE_ZOMBIE)
                if self.Owner.SetZombiePrime then
                    self.Owner:SetZombiePrime(false)
                end
                self.Owner:StripWeapons()
                self.Owner:Give("weapon_zom_claws")
                SendFullStateUpdate()
            end
        -- Turn the owner into a pile of bones and heal the target
        elseif ply:GetRole() == ROLE_VAMPIRE then
            if SERVER then
                local vamheal = GetConVar("ttt_gdeagle_vampire_heal"):GetInt()
                local vamoverheal = GetConVar("ttt_gdeagle_vampire_overheal"):GetInt()
                ply:SetHealth(math.min(ply:Health() + vamheal, ply:GetMaxHealth() + vamoverheal))
                self:DropBones(self.Owner)
                local sid = self.Owner:SteamID()
                self.Owner:Kill()
                RemoveRagdoll(sid)
            end
        -- Have the drunk immediately remember their role
        elseif ply:GetRole() == ROLE_DRUNK then
            local innocent = math.random() <= GetConVar("ttt_drunk_innocent_chance"):GetFloat()
            local role = innocent and ROLE_INNOCENT or ROLE_TRAITOR
            local roleString = innocent and "an innocent" or "a traitor"

            if CLIENT then
                ply:PrintMessage(HUD_PRINTTALK, "You have remembered that you are " .. roleString .. ".")
                ply:PrintMessage(HUD_PRINTCENTER, "You have remembered that you are " .. roleString .. ".")
            else
                ply:SetNWBool("WasDrunk", true)
                ply:SetRole(role)
                if not innocent then
                    ply:SetCredits(GetConVar("ttt_credits_starting"):GetInt())
                end
                net.Start("TTT_DrunkSober")
                net.WriteString(ply:Nick())
                net.WriteString(roleString)
                net.Broadcast()

                SendFullStateUpdate()
            end
        -- Kill traitors outright
        elseif IsTraitorTeam(ply) then
            local bullet = {}
            bullet.Attacker = self.Owner
            bullet.Num = self.Primary.NumberofShots
            bullet.Src = self.Owner:GetShootPos()
            bullet.Dir = self.Owner:GetAimVector()
            bullet.Spread = Vector(0, 0, 0)
            bullet.Tracer = 0
            bullet.Force = 3000
            bullet.Damage = 4000
            bullet.AmmoType = self.Primary.Ammo
            self.Owner:FireBullets(bullet)
        -- Kill the owner if the target was innocent
        elseif IsInnocentTeam(ply) then
            if SERVER then self.Owner:Kill() end
        -- Set the shooter's health to the target's health, if it's less than 100
        -- Then restore the target's max health to at least 100 and fully heal them
        elseif IsIndependentTeam(ply) then
            local hp = ply:Health()
            if hp < 100 and hp < self.Owner:Health() then
                self.Owner:SetHealth(hp)
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
                self.Owner:Kill()
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