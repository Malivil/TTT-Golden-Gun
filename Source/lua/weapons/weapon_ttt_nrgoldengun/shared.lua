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

function SWEP:PrimaryAttack()
    if (not self:CanPrimaryAttack()) then return end
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    local trace = util.GetPlayerTrace(self.Owner)
    local tr = util.TraceLine(trace)

    if tr.Entity.IsPlayer() then
        -- Kill traitors outright
        if tr.Entity:IsRole(ROLE_TRAITOR) or tr.Entity:IsRole(ROLE_HYPNOTIST) or tr.Entity:IsRole(ROLE_ASSASSIN) then
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
            self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
            self:TakePrimaryAmmo(1)
            self.Weapon:EmitSound(Sound("Weapon_Deagle.Single"))
            return
        -- Kill the owner if the target was innocent
        elseif tr.Entity:IsRole(ROLE_INNOCENT) or tr.Entity:IsRole(ROLE_DETECTIVE) or tr.Entity:IsRole(ROLE_MERCENARY) or tr.Entity:IsRole(ROLE_GLITCH) then
            self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
            self.Weapon:EmitSound(Sound("Weapon_Deagle.Single"))
            self:TakePrimaryAmmo(1)
            if SERVER then self.Owner:Kill() end
            return
        -- Kill the Jester/Swapper
        elseif tr.Entity:IsRole(ROLE_JESTER) or tr.Entity:IsRole(ROLE_SWAPPER) then
            self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
            self.Weapon:EmitSound(Sound("Weapon_Deagle.Single"))
            self:TakePrimaryAmmo(1)
            if SERVER then
                self.Owner:Kill()
                tr.Entity:SetHealth(0)
                tr.Entity:Kill()
            end
            return
        -- Set the owner on fire for 5 seconds
        elseif tr.Entity:IsRole(ROLE_PHANTOM) then
            self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
            self.Weapon:EmitSound(Sound("Weapon_Deagle.Single"))
            self:TakePrimaryAmmo(1)
            if SERVER then self.Owner:Ignite(5) end
            return
        -- Reduce the health of both the Owner and the Target by the configured amount
        elseif tr.Entity:IsRole(ROLE_KILLER) then
            self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
            self.Weapon:EmitSound(Sound("Weapon_Deagle.Single"))
            self:TakePrimaryAmmo(1)
            if SERVER then
                local killerdamage = GetConVar("ttt_gdeagle_killer_damage"):GetInt()
                if self.Owner:Health() > killerdamage then
                    self.Owner:SetHealth(self.Owner:Health() - killerdamage)
                else
                    self.Owner:Kill()
                end
                if tr.Entity:Health() > killerdamage then
                    tr.Entity:SetHealth(tr.Entity:Health() - killerdamage)
                else
                    tr.Entity:Kill()
                end
            end
            return
        -- Turn the owner into a Zombie thrall
        elseif tr.Entity:IsRole(ROLE_ZOMBIE) then
            self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
            self.Weapon:EmitSound(Sound("Weapon_Deagle.Single"))
            self:TakePrimaryAmmo(1)
            if SERVER then
                net.Start("TTT_Zombified")
                net.WriteString(self.Owner:Nick())
                net.Broadcast()

                self.Owner:SetRole(ROLE_ZOMBIE)
                self.Owner:SetZombiePrime(false)
                self.Owner:StripWeapons()
                self.Owner:Give("weapon_zom_claws")
                SendFullStateUpdate()
            end
            return
        -- Turn the owner into a pile of bones and heal the target
        elseif tr.Entity:IsRole(ROLE_VAMPIRE) then
            self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
            self.Weapon:EmitSound(Sound("Weapon_Deagle.Single"))
            self:TakePrimaryAmmo(1)
            if SERVER then
                local vamheal = GetConVar("ttt_gdeagle_vampire_heal"):GetInt()
                local vamoverheal = GetConVar("ttt_gdeagle_vampire_overheal"):GetInt()
                tr.Entity:SetHealth(math.min(tr.Entity:Health() + vamheal, tr.Entity:GetMaxHealth() + vamoverheal))
                self:DropBones(self.Owner)
                local sid = self.Owner:SteamID()
                self.Owner:Kill()
                RemoveRagdoll(sid)
            end
            return
        end
    end

    SendFullStateUpdate()
    self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    self:TakePrimaryAmmo(1)
    self.Owner:EmitSound(Sound("Weapon_Deagle.Single"))
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