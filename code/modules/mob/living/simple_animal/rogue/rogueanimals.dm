

//these mobs run away when attacked
/mob/living/simple_animal/hostile/retaliate/rogue
	turns_per_move = 5
	see_in_dark = 6
	response_help_continuous = "pets"
	response_help_simple = "pet"
	response_disarm_continuous = "gently pushes aside"
	response_disarm_simple = "gently push aside"
	response_harm_continuous = "kicks"
	response_harm_simple = "kick"
	faction = list("rogueanimal")
	robust_searching = 1
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	attack_sound = PUNCHWOOSH
	health = 40
	maxHealth = 40
	move_to_delay = 5
	d_intent = INTENT_DODGE
	minbodytemp = 180
	lose_patience_timeout = 150
	vision_range = 5
	aggro_vision_range = 18
	harm_intent_damage = 5
	attack_same = 0
	environment_smash = ENVIRONMENT_SMASH_NONE
	blood_volume = BLOOD_VOLUME_NORMAL
	food_type = list(
		/obj/item/reagent_containers/food/snacks/grown
		)
	var/food_max = 50
	var/obj/item/udder/udder = null
	footstep_type = FOOTSTEP_MOB_SHOE
	var/milkies = FALSE
	stop_automated_movement_when_pulled = 0
	tame_chance = 0
	retreat_distance = 10
	minimum_distance = 10
	dodge_sound = 'sound/combat/dodge.ogg'
	dodge_prob = 0

	var/deaggroprob = 10
	var/eat_forever

	candodge = TRUE

	var/summon_tier = 0 // Tier of summoning
	var/summon_primer = null // The message they get when summoned

	//If the creature is doing something they should STOP MOVING.
	var/can_act = TRUE

	var/last_charge_time = 0
	var/last_charge_hit_time = 0
	var/last_charge_dir = NORTH
	var/charge_power = 0
	var/charge = 0

	var/def_prob = 0
	var/atk_prob = 0

/mob/living/simple_animal/hostile/retaliate/rogue/Move()
	//If you cant act and dont have a player stop moving.
	if(!can_act && !client)
		return FALSE
	..()

/mob/living/simple_animal/hostile/retaliate/rogue/apply_damage(damage = 0,damagetype = BRUTE, def_zone = null, blocked = FALSE, forced = FALSE)
	..()
	if(damagetype == BRUTE)
		if(damage > 5 && prob(damage * 3))
			emote("pain")
		if(damage > 10)
			Immobilize(clamp(damage/2, 1, 30))
			shake_camera(src, 1, 1)
		if(show_redflash())
			if(damage < 10)
				flash_fullscreen("redflash1")
			else if(damage < 20)
				flash_fullscreen("redflash2")
			else if(damage >= 20)
				flash_fullscreen("redflash3")
	if(damagetype == BURN)
		if(damage > 10 && prob(damage))
			emote("pain")
			shake_camera(src, 1, 1)
		if(show_redflash())
			if(damage < 10)
				flash_fullscreen("redflash1")
			else if(damage < 20)
				flash_fullscreen("redflash2")
			else if(damage >= 20)
				flash_fullscreen("redflash3")

/mob/living/simple_animal/hostile/retaliate/rogue/death(gibbed)
	emote("death")
	..(gibbed)

/mob/living/simple_animal/hostile/retaliate/rogue/handle_automated_movement()
	set waitfor = FALSE
	if(!stop_automated_movement && wander && !doing)
		if(ssaddle && has_buckled_mobs())
			return 0
		if(find_food())
			return
		else
			..()

/mob/living/simple_animal/hostile/retaliate/rogue/proc/find_food()
	if(food > 50 && !eat_forever)
		return
	var/list/around = view(1, src)
	var/list/foundfood = list()
	if(stat)
		return
	for(var/obj/item/F in around)
		if(is_type_in_list(F, food_type))
			foundfood += F
			if(src.Adjacent(F))
				face_atom(F)
				playsound(src,'sound/misc/eat.ogg', rand(30,60), TRUE)
				qdel(F)
				food = max(food + 30, 100)
				return TRUE
	for(var/obj/item/F in foundfood)
		if(is_type_in_list(F, food_type))
			var/turf/T = get_turf(F)
			Goto(T,move_to_delay,0)
			return TRUE
	return FALSE

/mob/living/simple_animal/hostile/retaliate/rogue/AttackingTarget()
	//If you can't act and dont have a player stop moving.
	if(!can_act && !client)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/retaliate/rogue/proc/eat_bodies()
	var/mob/living/L
//	var/list/around = view(aggro_vision_range, src)
	var/list/around = hearers(1, src)
	var/list/foundfood = list()
	if(stat)
		return
	for(var/mob/living/eattarg in around)
		if(eattarg.stat != CONSCIOUS)
			foundfood += eattarg
			L = eattarg
			if(src.Adjacent(L))
				if(iscarbon(L))
					var/mob/living/carbon/C = L
					if(attack_sound)
						playsound(src, pick(attack_sound), 100, TRUE, -1)
					face_atom(C)
					src.visible_message(span_danger("[src] starts to rip apart [C]!"))
					if(do_after(src,100, target = L))
						var/obj/item/bodypart/limb
						var/list/limb_list = list(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
						for(var/zone in limb_list)
							limb = C.get_bodypart(zone)
							if(limb)
								limb.dismember()
								return TRUE
						limb = C.get_bodypart(BODY_ZONE_HEAD)
						if(limb)
							limb.dismember()
							return TRUE
						limb = C.get_bodypart(BODY_ZONE_CHEST)
						if(limb)
							if(!limb.dismember())
								C.gib()
							return TRUE
				else
					if(attack_sound)
						playsound(src, pick(attack_sound), 100, TRUE, -1)
					src.visible_message(span_danger("[src] starts to rip apart [L]!"))
					if(do_after(src,100, target = L))
						L.gib()
						return TRUE
	for(var/mob/living/eattarg in foundfood)
		var/turf/T = get_turf(eattarg)
		Goto(T,move_to_delay,0)
		return TRUE
	return FALSE

/mob/living/simple_animal/hostile/retaliate/rogue/Initialize()
	. = ..()
	if(milkies)
		udder = new()
	if(tame)
		tamed()
	ADD_TRAIT(src, TRAIT_SIMPLE_WOUNDS, TRAIT_GENERIC)

/mob/living/simple_animal/hostile/retaliate/rogue/LoseTarget()
	..()
	retreat_distance = initial(retreat_distance)
	minimum_distance = initial(minimum_distance)

/mob/living/simple_animal/hostile/retaliate/rogue/tamed(mob/user)
	del_on_deaggro = 0
	aggressive = 0
	if(enemies.len)
		if(prob(23))
			enemies = list()
			src.visible_message(span_notice("[src] calms down."))
			LoseTarget()
		else
			return
	if(user)
		friends |= user
	..()

/mob/living/simple_animal/hostile/retaliate/rogue/Destroy()
	QDEL_NULL(udder)
	return ..()

/mob/living/simple_animal/hostile/retaliate/rogue/Life()
	. = ..()
	if(.)
		if(enemies.len)
			if(prob(4))
				emote("cidle")
			if(prob(deaggroprob))
				if(mob_timers["aggro_time"])
					if(world.time > mob_timers["aggro_time"] + 30 SECONDS)
						enemies = list()
						src.visible_message(span_info("[src] calms down."))
						LoseTarget()
				else
					mob_timers["aggro_time"] = world.time
		else
			if(prob(2)) //Plays an idle sound
				emote("idle")

			if(adult_growth)
				growth_prog += 0.5
				if(growth_prog >= 100)
					if(isturf(loc))
						var/mob/living/simple_animal/animal_defender = new adult_growth(loc)
						if(tame)
							animal_defender.tame = TRUE
						qdel(src)
						return
			else
				if(childtype)
					make_babies()
		if(udder)
			if(production > 0)
				production--
				udder.generateMilk()

/mob/living/simple_animal/hostile/retaliate/rogue/Retaliate()
//	if(!enemies.len && message)
//		src.visible_message(span_warning("[src] panics!"))
//	if(flee)
//		retreat_distance = 10
//		minimum_distance = 10
	mob_timers["aggro_time"] = world.time
	..()

/mob/living/simple_animal/hostile/retaliate/rogue/attackby(obj/item/O, mob/user, params)
	if(!stat && istype(O, /obj/item/reagent_containers/glass))
		if(udder)
			udder.milkAnimal(O, user)
			return 1
	else
		return ..()

/mob/living/simple_animal/hostile/retaliate/rogue/proc/return_action()
	stop_automated_movement = FALSE
	walk(src,0)

/mob/living/simple_animal/hostile/retaliate/rogue/shood(mob/user)
	if(tame)
		Retaliate()

/mob/living/simple_animal/hostile/retaliate/rogue/onkick(mob/defender)
	..()
	Retaliate()
	GiveTarget(defender)

/mob/living/simple_animal/hostile/retaliate/rogue/beckoned(mob/user)
	if(tame && !stop_automated_movement)
		stop_automated_movement = TRUE
		Goto(user,move_to_delay)
		addtimer(CALLBACK(src, PROC_REF(return_action)), 3 SECONDS)

/mob/living/simple_animal/hostile/retaliate/rogue/food_tempted(obj/item/O, mob/user)

	if(is_type_in_list(O, food_type) && !stop_automated_movement)

		stop_automated_movement = TRUE
		Goto(user,move_to_delay)
		addtimer(CALLBACK(src, PROC_REF(return_action)), 3 SECONDS)

/mob/living/simple_animal/hostile/retaliate/rogue/Move()
	. = ..()
	if(has_buckled_mobs())
		var/mob/living/carbon/mounted_attacker = buckled_mobs[1]
		if(mounted_attacker.m_intent == MOVE_INTENT_RUN)
			// lose all power if you reverse direction or wait too long
			if(dir == GLOB.reverse_dir[last_charge_dir] || world.time > last_charge_time + 1 SECONDS)
				charge_power = 0
			charge_power = clamp(charge_power + 0.5, 0, 5)
			last_charge_dir = dir
			last_charge_time = world.time
		else if(mounted_attacker.m_intent == MOVE_INTENT_WALK)
			charge_power = 0

/mob/living/simple_animal/hostile/retaliate/rogue/MobBump(mob/living/defender) // CHARGE AND TRAMPLE
	if(has_buckled_mobs())
		var/mob/living/carbon/mounted_attacker = buckled_mobs[1]
		if(world.time > last_charge_hit_time + 10 SECONDS && mounted_attacker.m_intent == MOVE_INTENT_RUN && dir == get_dir(src, defender)) // If you are charging
			last_charge_hit_time = world.time
			var/obj/item/mounted_attacker_held_item = mounted_attacker.get_active_held_item()
			var/obj/item/defender_held_item = defender.get_active_held_item()
			var/amt = mounted_attacker.get_skill_level(/datum/skill/misc/riding)
			var/pole_skill_atk = mounted_attacker.get_skill_level(/datum/skill/combat/polearms)
			var/pole_skill_def = defender.get_skill_level(/datum/skill/combat/polearms)
			var/defending = FALSE
			charge = amt * 10 + charge_power * 10
			var/weapon_boost = charge_power + (mounted_attacker.STASTR / 2)
			var/def_boost = charge_power + (defender.STASTR / 2)
			if(istype(defender_held_item, /obj/item/rogueweapon) && defender_held_item.associated_skill == /datum/skill/combat/polearms && defender_held_item.wielded && defender.dir == get_dir(defender, src) && (defender.cmode))// Target has a polearm and is facing you with combat mode on
				defending = TRUE
				def_prob = pole_skill_def * 10 + defender.STACON * 10 + rand(10, 30) // small defensive buff
			if(istype(mounted_attacker_held_item, /obj/item/rogueweapon) && mounted_attacker_held_item.associated_skill == /datum/skill/combat/polearms && mounted_attacker.used_intent.type == SPEAR_THRUST && mounted_attacker_held_item.wielded && (mounted_attacker.cmode))// If you have a lance/spear is equipped
				atk_prob = pole_skill_atk * 10 + charge_power * 100
				mounted_attacker.used_intent.damfactor += weapon_boost
				mounted_attacker.used_intent.penfactor += weapon_boost
				defender.used_intent.damfactor += def_boost
				defender.used_intent.penfactor += def_boost
				if(defending) // If charging a braced spearman
					if(atk_prob > def_prob)
						mounted_attacker_held_item.melee_attack_chain(mounted_attacker, defender)
					else if(atk_prob < def_prob)
						playsound(src, 'sound/combat/clash_struck.ogg', 100, FALSE)
						defender_held_item.melee_attack_chain(defender, mounted_attacker)
						Knockdown(rand(15,30))
						Immobilize(30)
						if(mounted_attacker.STACON < 10)
							unbuckle_all_mobs()
							mounted_attacker.Knockdown(rand(15,30))
							mounted_attacker.Immobilize(30)
					else if(atk_prob == def_prob)
						playsound(src, 'sound/combat/clash_draw.ogg', 100, FALSE)
						defender.Immobilize(30)
				else // if charging non-spears
					mounted_attacker_held_item.melee_attack_chain(mounted_attacker, defender)
				mounted_attacker.used_intent.damfactor -= weapon_boost
				mounted_attacker.used_intent.penfactor -= weapon_boost
				defender.used_intent.damfactor -= def_boost
				defender.used_intent.penfactor -= def_boost
			if(defending)
				if(STASTR + charge > defender.STACON + def_prob + rand(10,20))
					defender.throw_at(get_edge_target_turf(src, dir),rand(1,3),5,src,TRUE)
					defender.emote("scream")
					defender.Knockdown(rand(15,30))
					defender.Immobilize(30)
				else if(STASTR + charge < defender.STACON + def_prob + rand(10,20))
					Immobilize(30)
					emote("pain")
					mounted_attacker.Immobilize(30)
					if(mounted_attacker.STACON < 10)
						unbuckle_all_mobs()
						mounted_attacker.Knockdown(rand(15,30))
						mounted_attacker.Immobilize(30)
					if(defender.STASTR > 10)
						if(prob(60))
							unbuckle_all_mobs()
							mounted_attacker.throw_at(get_edge_target_turf(src, dir),rand(1,3),5,src,TRUE)
							mounted_attacker.emote("scream")
							mounted_attacker.Knockdown(rand(15,30))
							mounted_attacker.Immobilize(30)
				else if(STASTR + charge == defender.STACON + def_prob + rand(10,20))
					Immobilize(30)
					emote("pain")
					mounted_attacker.Immobilize(30)
					if(mounted_attacker.STACON < 5)
						unbuckle_all_mobs()
						mounted_attacker.Knockdown(rand(15,30))
						mounted_attacker.Immobilize(30)
			else
				if(STASTR + charge > defender.STACON)
					defender.throw_at(get_edge_target_turf(src, dir),charge_power,5,src,TRUE)
					defender.emote("scream")
					defender.Knockdown(rand(15,30))
					defender.Immobilize(30)
				else if(STASTR + charge < defender.STACON)
					Knockdown(1)
					mounted_attacker.Knockdown(rand(15,30))
					Immobilize(30)
					mounted_attacker.Immobilize(30)
					if(mounted_attacker.STACON < defender.STACON)
						unbuckle_all_mobs()
						mounted_attacker.Knockdown(rand(15,30))
						mounted_attacker.Immobilize(30)
					if(defender.STASTR > mounted_attacker.STACON)
						if(prob(60))
							unbuckle_all_mobs()
							mounted_attacker.throw_at(get_edge_target_turf(src, dir),rand(1,3),5,src,TRUE)
							mounted_attacker.emote("scream")
							mounted_attacker.Knockdown(rand(15,30))
							mounted_attacker.Immobilize(30)
				else if(STASTR + charge == defender.STACON)
					mounted_attacker.emote("scream")
					defender.emote("scream")
					defender.Knockdown(rand(15,30))
					Knockdown(30)

			/// If target is mounted v
			if(istype(defender, /mob/living/simple_animal/hostile/retaliate/rogue))
				var/mob/living/simple_animal/hostile/retaliate/rogue/animal_defender = defender
				if(animal_defender.has_buckled_mobs())
					var/mob/living/carbon/mounted_defender = animal_defender.buckled_mobs[1]
					var/obj/item/E = mounted_defender.get_active_held_item()
					def_boost = charge_power + (mounted_defender.STASTR / 2)
					if(istype(E, /obj/item/rogueweapon) && E.associated_skill == /datum/skill/combat/polearms && E.wielded && mounted_defender.dir == get_dir(mounted_defender, src) && (mounted_defender.cmode)) // Target is bracing with a polearm
						defending = TRUE
						pole_skill_def = mounted_defender.get_skill_level(/datum/skill/combat/polearms)
						def_prob = pole_skill_def * 10 + rand(10, 30)
					if(mounted_defender.m_intent == MOVE_INTENT_RUN && animal_defender.dir == get_dir(animal_defender, src)) //Target is charging you too
						if(istype(mounted_attacker_held_item, /obj/item/rogueweapon) && mounted_attacker_held_item.associated_skill == /datum/skill/combat/polearms && mounted_attacker_held_item.wielded && (mounted_attacker.cmode)) //You are charging with a polearm
							atk_prob = pole_skill_atk * 10 + rand(10, 30)
							mounted_attacker.used_intent.damfactor += weapon_boost
							mounted_attacker.used_intent.penfactor += weapon_boost
							if(animal_defender.atk_prob) //Enemy has a polearm
								if(atk_prob > animal_defender.atk_prob)
									mounted_attacker_held_item.melee_attack_chain(mounted_attacker, mounted_defender)
									if(mounted_defender.STACON < 10)
										animal_defender.unbuckle_all_mobs()
										mounted_defender.Knockdown(rand(15,30))
										mounted_defender.Immobilize(30)
								else if(atk_prob == animal_defender.atk_prob)
									playsound(src, 'sound/combat/clash_draw.ogg', 100, FALSE)
									defender.Immobilize(30)
						else // You are charging WITHOUT a polearm
							if(animal_defender.atk_prob) // But the enemy has one
								if(mounted_attacker.STACON + charge <= animal_defender.atk_prob)
									defender_held_item.melee_attack_chain(mounted_defender, mounted_attacker)
									Immobilize(30)
									mounted_attacker.Immobilize(30)
									if(prob(50))
										unbuckle_all_mobs()
								else
									defender_held_item.melee_attack_chain(mounted_defender, mounted_attacker)
							else //Both are charging each other WITHOUT polearms
								if(mounted_attacker.STACON + charge >= mounted_defender.STACON + animal_defender.charge)
									animal_defender.unbuckle_all_mobs()
									animal_defender.Immobilize(30)
									mounted_defender.Immobilize(30)
									mounted_defender.apply_damage(charge_power, BRUTE, "chest", defender.run_armor_check("chest", "blunt", damage = charge_power))
							mounted_attacker.used_intent.damfactor -= weapon_boost
							mounted_attacker.used_intent.penfactor -= weapon_boost
					else // target is not charging you
						if(istype(mounted_attacker_held_item, /obj/item/rogueweapon) && mounted_attacker_held_item.associated_skill == /datum/skill/combat/polearms && mounted_attacker_held_item.wielded && (mounted_attacker.cmode)) //You are charging with a polearm
							mounted_attacker.used_intent.damfactor += weapon_boost
							mounted_attacker.used_intent.penfactor += weapon_boost
							mounted_defender.used_intent.damfactor += def_boost
							mounted_defender.used_intent.penfactor += def_boost
							if(defending) // If target is braced with spear on horseback
								if(atk_prob > def_prob)
									mounted_attacker_held_item.melee_attack_chain(mounted_attacker, mounted_defender)
									if(mounted_defender.STACON < 10)
										animal_defender.unbuckle_all_mobs()
										mounted_defender.Knockdown(rand(15,30))
										mounted_defender.Immobilize(30)
								if(atk_prob < def_prob)
									playsound(src, 'sound/combat/clash_struck.ogg', 100, FALSE)
									defender_held_item.melee_attack_chain(mounted_defender, mounted_attacker)
									Knockdown(rand(15,30))
									Immobilize(30)
									if(mounted_attacker.STACON < 10)
										unbuckle_all_mobs()
										mounted_attacker.Knockdown(rand(15,30))
										mounted_attacker.Immobilize(30)
								if(atk_prob == def_prob)
									playsound(src, 'sound/combat/clash_draw.ogg', 100, FALSE)
									defender.Immobilize(30)
							else	//if target is not braced with spear
								if(STASTR + pole_skill_atk + charge >= mounted_defender.STACON)
									mounted_attacker_held_item.melee_attack_chain(mounted_attacker, mounted_defender)
									if(mounted_defender.STACON < 10)
										animal_defender.unbuckle_all_mobs()
										mounted_defender.Knockdown(rand(15, 30))
										mounted_defender.Immobilize(30)
							mounted_attacker.used_intent.damfactor -= weapon_boost
							mounted_attacker.used_intent.penfactor -= weapon_boost
							mounted_defender.used_intent.damfactor -= def_boost
							mounted_defender.used_intent.penfactor -= def_boost
						if(defending)
							if(STASTR + charge > mounted_defender.STACON + def_prob)
								mounted_defender.throw_at(get_edge_target_turf(src, dir),rand(1,3),5,src,TRUE)
								mounted_defender.emote("scream")
								mounted_defender.Knockdown(rand(15,30))
								mounted_defender.Immobilize(30)
							else if(STASTR + charge < mounted_defender.STACON + def_prob)
								Immobilize(30)
								emote("pain")
								E.melee_attack_chain(defender, mounted_attacker)
								mounted_attacker.Immobilize(30)
								if(mounted_attacker.STACON < 10)
									unbuckle_all_mobs()
									mounted_attacker.Knockdown(rand(15,30))
									mounted_attacker.Immobilize(30)
							else if(STASTR + charge == mounted_defender.STACON + def_prob)
								Immobilize(30)
								emote("pain")
								mounted_attacker.Immobilize(30)
								if(mounted_attacker.STACON < 5)
									unbuckle_all_mobs()
									mounted_attacker.Knockdown(rand(15,30))
									mounted_attacker.Immobilize(30)
						else
							if(STASTR + charge > mounted_defender.STACON)
								mounted_defender.throw_at(get_edge_target_turf(src, dir),rand(1,3),5,src,TRUE)
								mounted_defender.emote("scream")
								mounted_defender.Knockdown(rand(15,30))
								mounted_defender.Immobilize(30)
							else if(STASTR + charge < mounted_defender.STACON)
								Knockdown(1)
								mounted_attacker.Knockdown(rand(15,30))
								Immobilize(30)
								mounted_attacker.Immobilize(30)
							else if(STASTR + charge == mounted_defender.STACON)
								mounted_attacker.emote("scream")
								mounted_defender.emote("scream")
								mounted_defender.Knockdown(rand(15,30))
								Knockdown(30)

			Immobilize(30)
			defending = FALSE
			def_prob = 0
			var/playsound = FALSE
			if(defender.apply_damage((charge_power*10), BRUTE, "chest", defender.run_armor_check("chest", "blunt", damage = (charge_power*10))))
				playsound = TRUE
			if(playsound)
				playsound(src, "genblunt", 100, TRUE)
			emote("aggro")
			visible_message(span_warning("[mounted_attacker] charges into [defender] with [src]!"))
			defending = FALSE
			charge_power = 0
			return TRUE
	return ..()
