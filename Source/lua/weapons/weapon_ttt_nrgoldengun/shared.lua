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

function SetRole(ply, role)
    ply:SetRole(role)

    if SERVER then
        net.Start("TTT_RoleChanged")
        net.WriteInt(ply:UserID(), 8)
        net.WriteInt(role, 8)
        net.Broadcast()
    end
end

function SWEP:PrimaryAttack()
    if (not self:CanPrimaryAttack()) then return end
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    local trace = util.GetPlayerTrace(self.Owner)
    local tr = util.TraceLine(trace)

    if tr.Entity.IsPlayer() then
        if tr.Entity:IsRole(ROLE_TRAITOR) or tr.Entity:IsRole(ROLE_HYPNOTIST) or tr.Entity:IsRole(ROLE_ASSASSIN) then
            local bullet = {}
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
        elseif tr.Entity:IsRole(ROLE_INNOCENT) or tr.Entity:IsRole(ROLE_DETECTIVE) or tr.Entity:IsRole(ROLE_MERCENARY) or tr.Entity:IsRole(ROLE_GLITCH) then
            self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
            self.Weapon:EmitSound(Sound("Weapon_Deagle.Single"))
            self:TakePrimaryAmmo(1)
            if SERVER then self.Owner:Kill() end
            return
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
        elseif tr.Entity:IsRole(ROLE_PHANTOM) then
            self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
            self.Weapon:EmitSound(Sound("Weapon_Deagle.Single"))
            self:TakePrimaryAmmo(1)
            if SERVER then self.Owner:Ignite(5) end
            return
        elseif tr.Entity:IsRole(ROLE_KILLER) then
            self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
            self.Weapon:EmitSound(Sound("Weapon_Deagle.Single"))
            self:TakePrimaryAmmo(1)
            if SERVER then
                if self.Owner:Health() >= 36 then
                    self.Owner:SetHealth(self.Owner:Health() - 35)
                else
                    self.Owner:Kill()
                end
                if tr.Entity:Health() >= 36 then
                    tr.Entity:SetHealth(tr.Entity:Health() - 35)
                else
                    tr.Entity:Kill()
                end
            end
            return
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
        elseif tr.Entity:IsRole(ROLE_VAMPIRE) then
            self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
            self.Weapon:EmitSound(Sound("Weapon_Deagle.Single"))
            self:TakePrimaryAmmo(1)
            if SERVER then
                SetRole(self.Owner, ROLE_VAMPIRE)
                self.Owner:StripWeapon("weapon_ttt_wtester")
                self.Owner:Give("weapon_vam_fangs")
                SendFullStateUpdate()
            end
            return
        end
    end

    SendFullStateUpdate()
    self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    self:TakePrimaryAmmo(1)
    self.Owner:EmitSound(Sound("Weapon_Deagle.Single"))
end

