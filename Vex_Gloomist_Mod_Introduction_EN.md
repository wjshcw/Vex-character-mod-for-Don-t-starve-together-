# Vex the Gloomist — Complete Mod Introduction

> Version status: 2026-10-10 · **0.2.1** · Core gameplay, progression system, four skills, summonable shadow, and art assets are all implemented
> This is a Don't Starve Together character mod, `all_clients_require_mod = true` (everyone must install it)

---

## 1. Character Overview

Vex comes from Bandle City on the Shadow Isles (inspired by the character of the same name from *League of Legends*), a gloomist who dances with shadows.

| Stat         | Value                                                       |
| ------------ | ----------------------------------------------------------- |
| Health       | 150                                                         |
| Hunger       | 150                                                         |
| Sanity       | 300                                                         |
| Starts with  | The Shadow (exclusive progression armor) + Shadow Isle Charm (summons the shadow) |

Vex has a second resource bar independent of Sanity — **Gloom**, a unique environmental-interaction passive — **Gloom Mist**, a **modular progression system** built around her exclusive equipment "the Shadow", and a **summonable companion "Shadow"**

---

## 2. Core Resource: Gloom

An independent resource bar (0–200, starts at 100), displayed as a purple badge next to the sanity bar. It is simultaneously a resource, a state, and a combat resource:

| Mechanic        | Value                                   |
| --------------- | --------------------------------------- |
| Daylight        | -5/min                                  |
| Dusk            | +3/min                                  |
| Night / Caves   | +5/min                                  |
| Wetness         | Increases with wetness                  |
| Teammates       | Ghost teammates +3.3/min, living teammates -3.3/min |
| **>195**        | Shadow Creatures become neutral and stop attacking |
| **>150**        | Sanity +30/min                          |
| **<50**         | Sanity -30/min                          |

**Sources of gain**:

- Killing creatures: +Naughtiness ×2 (some special creatures excluded)
- Killing epic bosses: +0.5% of their max health
- Reviving: refills to max
- The summonable shadow taking damage: deducted 1:1 (its HP and Gloom share the same 200 cap, two-way link)
- The summonable shadow's self-healing consuming Nightmare Fuel / Pure Horror

**Sources of consumption**:

- Picking flowers: -5 (flower / rose / cave flower / moon flower)
- Eating desserts (GOODIES): -sanity gained ×5
- Gloom-condensed Nightmare Fuel recipe: costs 75

---

## 3. Gloom Mist Passive System

Vex's signature environmental interaction: **any combat creature can become enshrouded in Gloom Mist**. Meeting any one condition applies 6 seconds of Gloom Mist (1-second re-apply cooldown after removal):

| Trigger                          | Threshold (normal creatures) | Threshold (epic bosses) |
| -------------------------------- | ---------------------------- | ----------------------- |
| Sustained running                | Move speed ≥8 for 2 seconds  | Same                    |
| Speed spike                      | ≥12                          | ≥10                     |
| Position jump (teleport / dash)  | ≥5                           | ≥3                      |

---

## 4. Exclusive Passives

| Passive                   | Effect                                                                 |
| ------------------------- | ---------------------------------------------------------------------- |
| Spoiled Food Immunity     | Eating stale food incurs no hunger/sanity/health penalty (all spoilage penalties removed) |
| Miasma Immunity           | Takes no miasma damage, ×1.2 movement speed in miasma, and does not cover the face while walking (sandstorm/moonstorm face-covering is kept) |
| Monkey Curse Immunity     | Cannot be turned into a monkey                                         |
| Alignment Advantage       | Deals ×1.2 damage to lunar-aligned; takes ×0.8 from shadow-aligned; takes ×1.2 from lunar-aligned |
| Stealth Synergy           | Wearing the three disguise hats reduces creature aggro detection        |

---

## 5. The Shadow — Core Progression System

### 5.1 Basics

- Exclusive armor: **20% damage reduction + ×1.1 movement speed**, infinite durability
- Built-in **3 upgrade slots** (badge-slot UI pops up when equipped, supports drag rearranging)
- Only Vex can hold it (other characters drop it immediately on pickup); auto-returns to the owner's inventory when dropped
- Upgrade slots only accept modules (non-module items are ejected when the container closes)



### 5.2 Six Module Categories (24 modules, 4 tiers each)

Placing a module in an upgrade slot activates it; the highest tier of each type takes effect; removing it deactivates the effect. **Some module effects also apply to the summonable shadow** (speed/defense/preservation/lightning immunity/storage expansion, see Section 7):

| Category         | Tier 1                            | Tier 2          | Tier 3                                | Tier 4                                                                     |
| ---------------- | --------------------------------- | --------------- | ------------------------------------- | -------------------------------------------------------------------------- |
| **Speed**        | Move ×1.15                        | ×1.25           | ×1.5                                  | ×2.0 + **Flight** (walks on water, ignores obstacles, cannot land on the ocean) |
| **Defense**      | Damage taken ×0.85                | ×0.95           | +10 planar defense, fire/freeze/knockback immunity | +15 planar defense, fire/freeze/knockback/sleep immunity (50% of damage taken converts to Gloom and heals half back) |
| **Survival**     | Insulation 60 / winter warmth 60 / water resistance 20% | +lightning immunity | +goggles / hunger drain -25%      | +fixed body temperature 30°C                                                |
| **Gloom**        | Restores 3/min                    | 5/min           | 10/min                                | 6000/min (≈instant)                                                          |
| **Preservation** | Spoilage ×0.75                    | ×0.5            | ×0.25                                 | **Permanent freshness**                                                      |
| **Skill Boost**  | Damage +10%, Q range/speed +50%   | +25% + W grants 3s invincibility | +75% + E radius +50% / E cooldown -25% | +100% + all skill cooldowns halved                                          |

### 5.3 Storage Charm (independent 7th category, tiers 1–4)

- Capacity: 4 / 9 / 12 / 14 slots
- **Can only be opened while equipped** (right-clicking in inventory or on the ground does nothing); auto-opens when placed in a Shadow slot, auto-closes when removed
- Swapping storage charms automatically moves contents into a hidden stash, zero loss; on shard migration/disconnect the contents return to the charm automatically
- Tier 4: infinite stacking of identical items in one slot
- Food inside the storage charm also benefits from preservation modules

---

## 6. The Four Skills

All key bindings can be changed in the mod configuration (defaults: Q→X, R→R, W→Z, E→V). **Unified mechanics**: Gloom Mist targets take **double damage** from all skills and trigger fear (3s panic, 20s cooldown, -10s on Gloom Mist targets / kills); server-authoritative validation with two-sided cooldown sync; **all skills deal no damage to the summonable shadow**.

| Skill              | Default Key | Mechanic                                         | Numbers                                                                                 |
| ------------------ | ----------- | ------------------------------------------------ | --------------------------------------------------------------------------------------- |
| **Mistral Bolt**   | X           | Hold to aim → release to fire a piercing wave (directional arrow indicator) | 50 damage (×boost), total range 10 (first 5 slow & wide-3, last 5 fast & wide-2.5), 5s cooldown |
| **Shadow Surge**   | R           | Two stages: wave hit marks the target (4s window) → press R again for an invincible dash landing | Wave 100 damage, landing 300 area damage (radius 4), invincible dash speed 40, 60s cooldown; **killing the target within 6s refreshes the cooldown** |
| **Personal Space** | Z           | Instant close-range burst (1s virtual circle)    | 75 damage, radius 3.5, 15s cooldown; Gloom Mist targets take double damage and restore Gloom equal to half the damage |
| **Looming Darkness** | V         | Dual-circle aiming (outer 8 selection / inner 2.5 damage) → lands after 1s delay | 35 damage, slowed to 40% move speed for 3s, fear 3s, 12s cooldown                       |

---

## 7. The Summonable "Shadow" System (Companion)

An **independent summonable companion** that shares its name with the equipment Shadow, summoned via the starting **Shadow Isle Charm**:

### 7.1 Charm and Summoning

- **Shadow Isle Charm**: starts in the character's inventory, no recipe; character-exclusive, cannot be dropped (auto-returns when dropped), stays in the inventory only (cannot enter any container)
- Right-click the charm to summon/recall; press the key while holding the charm to open the spell wheel
- **Death**: after the shadow dies it dissipates and can be re-summoned immediately
- Automatically recalled when Vex becomes a ghost, restored on revival

### 7.2 Combat

- Fixed 25 damage, aura AOE + active pursuit
- **Defensive mode** (default): counter-attacks attackers, protects the master; **Aggressive mode** (wheel toggle): actively attacks all hostile/neutral creatures in range
- In aggressive mode it actively hunts and instantly kills small moon Gestalts

### 7.3 Spell Wheel — Four Buttons

Recall / Aggressive↔Calm / **Explore↔Return** / **Gather↔Stop gathering** (buttons toggle with state)

### 7.4 Explore / Gather / Pickup / Tools / Feeding / Self-heal

- **Explore**: flies along unexplored terrain, revealing the map for the master along the way (private minimap reveal); button recalls / return trip is faster
- **Gather**: automatically picks tool-free resources (grass/twigs/berries etc., never flowers), products go into the bag
- **Tool work**: with an axe/pickaxe/shovel in its bag, automatically chops trees (only fully grown), mines rocks, digs stumps
- **Pickup**: picks up nearby dropped items into the bag
- **Feeding**: proactively feeds a hungry master (only real food, cooked food first, won't feed while the master is busy)
- **Self-heal**: when injured, consumes Nightmare Fuel / Pure Horror from its bag to restore the master's Gloom (HP rises with the Gloom pulse sync)

### 7.5 HP ↔ Gloom Two-Way Link

- The shadow's max HP = the master's Gloom
- The shadow taking a hit immediately deducts the master's Gloom 1:1
- Gloom modules restoring Gloom → indirectly restore the shadow's max HP (module-companion synergy)

### 7.6 Bag (9~25 slots)

- Base 9 slots; expands to **12/16/20/25** when the master equips storage charms (by highest tier)
- On shrinkage, excess items go into a hidden buffer with zero loss; bag contents survive shard migration/saves fully
- Only the master can open it; the shadow stands still while the bag is open

### 7.7 Shared Modules

The master's **speed/defense/preservation/lightning immunity/storage expansion** modules on the Shadow armor also apply to the summonable shadow; unequipping removes the effects from the companion as well.

---

## 8. Recipes

- **Gloom-condensed Nightmare Fuel**: consumes 75 Gloom to craft 1 Nightmare Fuel (cost shown in the crafting menu, cannot craft with insufficient Gloom)
- All exclusive item recipes are only visible to Vex

---

## 9. Equipment

### Multitool (3 tiers)

| Tier | Harvesting efficiency              | Skill                                     | Special                        |
| ---- | ---------------------------------- | ----------------------------------------- | ------------------------------ |
| 1    | Chop/mine/dig/hammer ×1 + tilling  | —                                         | 400 durability, disappears when used up |
| 2    | ×1.5                               | **Area demolition** (including stumps, 30s cooldown, costs 30 durability) | Nightmare Fuel right-click repair (+80 durability) |
| 3    | ×2                                 | **Area demolition** (10s cooldown, no durability cost) | Infinite durability           |

Area demolition: radius 5, destroys trees/rocks/statues/stumps etc., with three waves of ground-impact effects.

### Weapons and Staves

| Weapon         | Damage          | Notes                                                           |
| -------------- | --------------- | --------------------------------------------------------------- |
| Shadow Scratcher | Melee 50       | 200 durability; **Nightmare Fuel right-click repair** (+40 durability); does not disappear at 0 durability but becomes useless |
| Shadow Staff   | Ranged 50       | No durability                                                   |
| Gloom Embrace  | Ranged 50 + planar 50 | 100 true damage, ×1.5 attack speed, no durability        |

All three weapons have exclusive ground models and hand-held swap displays.

### Three Disguise Hats (Stealth System)

| Hat               | Aggro detection multiplier                 |
| ----------------- | ------------------------------------------- |
| Camouflage Hat    | ×0.7 (neutral to beefalo in heat / insects / buzzards) |
| Concealment Hat   | ×0.5 (also spiders / merms)                 |
| Invisibility Hat  | ×0 (neutral to everything)                  |

---

## 10. Interaction & UI

- **Gloom badge**: purple liquid bar next to the sanity bar, hover to show the value
- **Shadow upgrade slots**: badge slots, drag to rearrange / middle-click to reset, position is persisted
- **Spell wheel commands**: four charm wheel buttons (icons + state toggles)
- **Right-click repair**: hold Nightmare Fuel and right-click to repair items (Multitool tier 2 / Shadow Sword)
- **Old-save compatibility**: existing players automatically receive the charm on loading after an update (dropped at their feet if the inventory is full, never duplicated)

---

## 11. Writing (In Progress)

- Recipe descriptions and item hover descriptions are in place; inspection lines are being filled in gradually

---

## 12. To-do

1. Finish writing (speech lines)
2. Balance tuning
3. Clean up leftover debug prints and dead code files

---

*Parts of this mod were implemented with reference to the Gwen mod and the Briar mod (both with the authors' permission) as well as the vanilla game implementation.*
