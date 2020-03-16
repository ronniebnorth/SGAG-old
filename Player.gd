extends KinematicBody

################# SETTINGS ########################
var default_heartrate = 50
var starting_heartrate = 60
var max_heartrate = 320
var wall_collide_heartrate_increase = 25
var wall_collide_vibration = 120

var collision_vs_scrape_angle = 0.5 #higher value means more thuds
var longtouch_vibration = 60

var falling_gravity = 5
var floor_gravity = 0.5
var footstep_distance = 0.5

var top_walk_speed = 100
var top_swim_speed = 60
var top_fly_speed = 300

var walk_sensitivity = 0.01
var rotate_sensitivity = 0.3
var long_touch_time = 0.9
#drag_trigger is for a little play in the joystick, for long touch
var drag_trigger = 10
var auto_rotate_speed = 0.02 #1.2
var wallhits_before_help = 1

###################################################

var top_speed = top_walk_speed
var cumulative_dragy = 0
var cumulative_dragx = 0

var fingers_touched = 0
var is_touching = false
var long_touch_timer = Timer.new()
var current_area = null

var player_wallhits = 0
var is_on_wall = false
var is_on_front = false
var is_on_floor = false
var is_on_right = false
var is_on_left = false


onready var footfalls = [
	{"name":"normal", "node":$Footfall},
	{"name":"carpet", "node":$FootfallCarpet},
	{"name":"concrete", "node":$FootfallConcrete},
	{"name":"creaky", "node":$FootfallCreaky},
	{"name":"dirt", "node":$FootfallDirt},
	{"name":"dirt2", "node":$FootfallDirt2},
	{"name":"floor", "node":$FootfallFloor},
	{"name":"forest", "node":$FootfallForest},
	{"name":"gravel", "node":$FootfallGravel},
	{"name":"gravel2", "node":$FootfallGravel2},
	{"name":"hardfemale", "node":$FootfallHardFemale},
	{"name":"heavy", "node":$FootfallHeavy},
	{"name":"mellow", "node":$FootfallMellow},
	{"name":"metal", "node":$FootfallMetal},
	{"name":"mud", "node":$FootfallMud},
	{"name":"sand", "node":$FootfallSand},
	{"name":"snow", "node":$FootfallSnow},
	{"name":"snow2", "node":$FootfallSnow2},
	{"name":"snow3", "node":$FootfallSnow3},
	{"name":"stone", "node":$FootfallStone},
	{"name":"swim", "node":$FootfallSwim},
	{"name":"tapstep", "node":$FootfallTapstep},
	{"name":"tile", "node":$FootfallTile},
	{"name":"water", "node":$FootfallWater},
	{"name":"wood", "node":$FootfallWood}
]
	
onready var last_x = translation.x 
onready var last_z = translation.z
onready var last_y = translation.y

onready var current_wallscrape = $PlayerWallScrape
onready var residual_footfalls = []
onready var last_footfall = $Footfall
onready var base_footfall = $FootfallBase
var base_footfall_disabled = false

var footfall_demo = false
var held_footfalls = []
var held_footfall_demo_timer = Timer.new()

var heartrate_timer = Timer.new()
var heartrate = starting_heartrate

var rotation_timer = Timer.new()
var rotation_time = 0.25

var vibration

var rotation_sound = false

var firefly_timer = Timer.new()
var firefly_time = 3

var wake_up_timer = Timer.new()
var wake_up_time = 15

var passout_timer = Timer.new()
var passout_time = 0.5
var passing_out = false
var passed_out = false

var cam_timer = Timer.new()
var cam_time = 0.1


var locked_door_timer = Timer.new()
var locked_door_time = 0.15

var fan_timer = Timer.new()
var fan_time = 0.2

onready var viewport1 = $"../../ViewportContainer3"
onready var cam1 = $"../../ViewportContainer3/Viewport/MainCamera"

onready var left_ear_cam = $"../../HBoxContainer/LeftEarCam/Viewport/Camera"
onready var right_ear_cam = $"../../HBoxContainer/RightEarCam/Viewport/Camera"
onready var left_ear_plate_cam = $"../../HBoxContainer/LeftEarPlateCam/Viewport/Camera"
onready var right_ear_plate_cam = $"../../HBoxContainer/RightEarPlateCam/Viewport/Camera"

onready var face_plate_cam = $"../../HBoxContainer/FaceEarCam/Viewport/Camera"

#onready var face_cam = $"../../HBoxContainer/ViewportContainer6/Viewport/Camera"

var doing_sounds = false

var shadow_world_y = -100
	
var cam_in_shadow_world = false

func _ready():
	#Input.vibrate_handheld(900)
	#
	
	
	$"LeftEar".translation.y += shadow_world_y
	$"RightEar".translation.y += shadow_world_y
	$"FaceEar".translation.y += shadow_world_y
	
	var shadow_members = get_tree().get_nodes_in_group("ShadowWorldMember")
	var count = 0
	for shadow_member in shadow_members:
		var wname = "Wall" + String(count) 
		var nwall = find_node_by_name($"../Walls", wname)
		var w = shadow_member
		
		nwall.set_name(w.get_name())
		nwall.transform = w.transform
		nwall.translation.y = nwall.translation.y + shadow_world_y
		#print(w.get_name())
		#print(nwall.get_name())
		if w.SGMaterial == "Wood":
			nwall.material_override = load("res://trans_205.tres")
			
			
		count = count + 1
		
				
	for sl in $"../SoundLights".get_children():
		sl.translation.y = sl.translation.y + shadow_world_y

		
	$"../../HBoxContainer".set_custom_minimum_size(Vector2(get_viewport().size.x,8))

	
	if Engine.has_singleton("Vibration"):
		vibration = Engine.get_singleton("Vibration")
	#print(Global.gtest())
	setup_timer(long_touch_timer, "long_touch_timer", long_touch_time, false, false)
	setup_timer(held_footfall_demo_timer, "held_footfall_demo_timer", 0.25, false, false)
	setup_timer(heartrate_timer, "heartrate_timer", 60 / heartrate, true, true)
	setup_timer(rotation_timer, "rotation_timer", rotation_time, false, true)
	setup_timer(firefly_timer, "firefly_timer", firefly_time, false, false)
	setup_timer(passout_timer, "passout_timer", passout_time, false, true)
	setup_timer(wake_up_timer, "wake_up_timer", wake_up_time, false, true)
	setup_timer(cam_timer, "cam_timer", cam_time, true, false)
	setup_timer(locked_door_timer, "locked_door_timer", locked_door_time, false, true)
	setup_timer(fan_timer, "fan_timer", fan_time, false, false)

		
func setup_timer(timer, timer_name, time, auto_start, one_shot):
	if one_shot:
		timer.set_one_shot(true)
	timer.set_wait_time(time)
	timer.connect("timeout",self,"_on_" + timer_name + "_timeout")
	add_child(timer)
	if auto_start:
		timer.start()
		

func change_fan_speed():
	var curspeed = fan_timer.wait_time 
	if curspeed < 0.005:
		curspeed = 0.2
	else:
		curspeed = curspeed / 2

	#print(curspeed)
	fan_timer.wait_time = curspeed
				
		
func find_node_by_type(root, type):
	if(root.get_class() == type): return root
	for child in root.get_children():
		if(child.get_class() == type):
			return child
		var found = find_node_by_type(child, type)
		if(found): return found
	return null
	
	
func find_node_by_name(root, name):

	if(root.get_name() == name):
		return root
	for child in root.get_children():
		if(child.get_name() == name):
			return child
		var found = find_node_by_name(child, name)
		if(found): return found
	return null
	
	

func _on_rotation_timer_timeout():
	footfall()
	var v = AudioServer.get_bus_volume_db(5)
	AudioServer.set_bus_volume_db(5, v + 7)
	

func do_rotation_sound(y):
	y = abs(y)
	if (y < 5) or (y > 175) or (y > 85 and y < 95):
		if rotation_sound:
			rotation_sound = false
			var v = AudioServer.get_bus_volume_db(5)
			AudioServer.set_bus_volume_db(5, v - 7)
			footfall()
			rotation_timer.start()
	elif (y > 40 and y < 50) or (y > 130 and y < 140):
		rotation_sound = true
		

func _on_wake_up_timer_timeout():
	heartrate = default_heartrate
	heartrate_timer.start()
	$Passout.play()
	passed_out = false
	AudioServer.set_bus_volume_db(0, 12)


func _on_passout_timer_timeout():
	var vol = AudioServer.get_bus_volume_db(0)
	if vol > -30:
		AudioServer.set_bus_volume_db(0, vol - 5)
		passout_timer.start()
	else:
		heartrate_timer.stop()
		passed_out = true
		passing_out = false
		wake_up_timer.start()
		
						
func _on_heartrate_timer_timeout():
	#print(heartrate)
	if heartrate > max_heartrate - 40 and not $Passout.is_playing():
		$Passout.play()
	if heartrate > max_heartrate and not passing_out:
		passout_timer.start()
		passing_out = true

	if current_area:
		if not current_area.disable_heartrate:
			if current_area.new_arrival or current_area.constant_heartrate:
				if current_area.heartrate == 0:
					pass
				else:
					heartrate = current_area.heartrate
				current_area.new_arrival = false
				
	$Heart.play()
	if heartrate > default_heartrate:
		heartrate -= 3

	if vibration:
		if heartrate > 150:
			vibration.pattern(0,30,90,30,0,0,0,0,0,0,0,-1)	
			$Heart.volume_db = 10
		elif heartrate > 120:
			vibration.pattern(0,25,95,25,0,0,0,0,0,0,0,-1)
			$Heart.volume_db = 7
		elif heartrate > 100:
			vibration.pattern(0,20,100,20,0,0,0,0,0,0,0,-1)
			$Heart.volume_db = 3
		elif heartrate > 80:
			vibration.pattern(0,15,105,15,0,0,0,0,0,0,0,-1)
			$Heart.volume_db = 0
		elif heartrate > 60:
			vibration.pattern(0,10,110,10,0,0,0,0,0,0,0,-1)
			$Heart.volume_db = -3
		else:
			vibration.pattern(0,6,114,6,0,0,0,0,0,0,0,-1)
			$Heart.volume_db = -6
	var wait_time = 60.0 / heartrate
	heartrate_timer.set_wait_time(wait_time)
	heartrate_timer.start()
	
	

func _on_held_footfall_demo_timer_timeout():
	#$Camera/FootfallHeld.show()
	held_footfall_demo_timer.stop()


func _on_cam_timer_timeout():
	do_sounds()
	

func do_sounds():
	
	doing_sounds = true

	#print("right ear cam")
	var r_ear = get_light($"../../HBoxContainer/RightEarCam/Viewport", false)
	#print("left ear cam")
	var l_ear = get_light($"../../HBoxContainer/LeftEarCam/Viewport", false)
	#print("right ear plate")
	var r_earp = get_light($"../../HBoxContainer/RightEarPlateCam/Viewport", false)
	#print("left ear plate")
	var l_earp = get_light($"../../HBoxContainer/LeftEarPlateCam/Viewport", false)
	#print("front ear")
	var facep = get_light($"../../HBoxContainer/FaceEarCam/Viewport", false)
	
	r_ear = r_ear + r_earp
	l_ear = l_ear + l_earp
	var ear_avg = (r_ear + l_ear) / 2
	var peff = AudioServer.get_bus_effect(8,0)
	var veff = AudioServer.get_bus_effect(8,1)	
	print(AudioServer.get_bus_name(8))
	var pan_level = abs(abs(r_ear) - abs(l_ear)) * 0.15
	#print(pan_level)
	if pan_level > 1:
		pan_level = 1
	if(l_ear > r_ear):
		peff.pan = -pan_level
	if(l_ear < r_ear):
		peff.pan = pan_level

	var vol_level = -60 + ear_avg + facep
	#print(vol_level)
	if vol_level > -20:
		vol_level = -20
	veff.volume_db = vol_level	
	#print(vol_level)
	doing_sounds = false
	do_sounds2()

func do_sounds2():
	
	doing_sounds = true

	#print("right ear cam")
	var r_ear = get_light2($"../../HBoxContainer/RightEarCam/Viewport", false)
	#print("left ear cam")
	var l_ear = get_light2($"../../HBoxContainer/LeftEarCam/Viewport", false)
	#print("right ear plate")
	var r_earp = get_light2($"../../HBoxContainer/RightEarPlateCam/Viewport", false)
	#print("left ear plate")
	var l_earp = get_light2($"../../HBoxContainer/LeftEarPlateCam/Viewport", false)
	#print("front ear")
	var facep = get_light2($"../../HBoxContainer/FaceEarCam/Viewport", false)
	
	r_ear = r_ear + r_earp
	l_ear = l_ear + l_earp
	var ear_avg = (r_ear + l_ear) / 2
	var peff = AudioServer.get_bus_effect(9,0)
	var veff = AudioServer.get_bus_effect(9,1)	
	#print(AudioServer.get_bus_name(8))
	var pan_level = abs(abs(r_ear) - abs(l_ear)) * 0.15
	#print(pan_level)
	if pan_level > 1:
		pan_level = 1
	if(l_ear > r_ear):
		peff.pan = -pan_level
	if(l_ear < r_ear):
		peff.pan = pan_level

	var vol_level = -60 + ear_avg + facep
	#print(vol_level)
	if vol_level > -20:
		vol_level = -20
	veff.volume_db = vol_level	
	#print(vol_level)
	doing_sounds = false
	
		

func get_light(viewport, full_rect = false):
	full_rect = true
	
	var image = viewport.get_texture().get_data()	
	var s = 0
	var vpx = viewport.size.x
	var vpy = viewport.size.y
	
	image.lock()
	
	#print(image.get_pixel(100,100).to_html(false))
	var add = 0
	if full_rect:
		for y in range(0,vpy):
			for x in range(y, vpx):	
				add = image.get_pixel(x,y).g
				#if viewport == $"../../HBoxContainer/RightEarCam/Viewport":
					#print('hi', image.get_pixel(x,y).r)
				#add += image.get_pixel(x,y).g
				#add += image.get_pixel(x,y).b

				s += add #/ 3
				#image.set_pixel(x,y,"000000")
	else:	
		for x in range(0, vpx):	
			s += image.get_pixel(x,vpy / 2).r
			s += image.get_pixel(x,vpy / 2).g
			s += image.get_pixel(x,vpy / 2).b
			s = s / 2
			
	image.unlock()
	#print(viewport.get_name())
	#print(s)
	return s
		
							
func get_light2(viewport, full_rect = false):
	full_rect = true
	
	var image = viewport.get_texture().get_data()	
	var s = 0
	var vpx = viewport.size.x
	var vpy = viewport.size.y
	
	image.lock()
	
	#print(image.get_pixel(100,100).to_html(false))
	var add = 0
	if full_rect:
		for y in range(0,vpy):
			for x in range(y, vpx):	
				add = image.get_pixel(x,y).r
				#if viewport == $"../../HBoxContainer/RightEarCam/Viewport":
					#print('hi', image.get_pixel(x,y).r)
				#add += image.get_pixel(x,y).g
				#add += image.get_pixel(x,y).b

				s += add #/ 3
				#image.set_pixel(x,y,"000000")
	else:	
		for x in range(0, vpx):	
			s += image.get_pixel(x,vpy / 2).r
			s += image.get_pixel(x,vpy / 2).g
			s += image.get_pixel(x,vpy / 2).b
			s = s / 2
			
	image.unlock()
	#print(viewport.get_name())
	#print(s)
	return s
			
func footfall():
	do_default_footfall()
	do_extra_footfall()	
	do_residual_footfall()
	do_wallscrape()
	

func do_default_footfall():
	var ff = last_footfall
	if current_area:
		var aff = get_footfall(current_area.default_footfall)
		if aff:
			ff = aff
			last_footfall = ff
		if current_area.base_footfall:
			base_footfall_disabled = false
			base_footfall.play()
		else:
			base_footfall_disabled = true
	else:
		if not base_footfall_disabled:
			base_footfall.play()
	ff.volume_db = 0
	if held_footfalls:
		for hff in held_footfalls:
			#print(hff.get_name())
			hff.play()
	ff.play()
	
		
func do_extra_footfall():
	var ff = null
	if current_area:
		ff = get_footfall(current_area.extra_footfall)
	else:
		return
		
	var dist
	if current_area.extra_footfall_gradient != 'none':
		var tarea = current_area.translation
		var x_diff = (translation.x - tarea.x) * (translation.x - tarea.x)
		var z_diff = (translation.z - tarea.z) * (translation.z - tarea.z)
		var ffg = current_area.extra_footfall_gradient
		if ffg == "x-axis":
			dist = sqrt(x_diff)
		elif ffg == "z-axis":
			dist = sqrt(z_diff)
		elif ffg == "center":
			dist = sqrt(x_diff + z_diff)
	if dist:
		ff.volume_db = dist * -15
	if ff:
		ff.play()			

			
func do_residual_footfall():
	for ff in residual_footfalls:
		var tfl = ff.footfall
		if ff.count < ff.duration:
			if ff.count == 0:
				tfl.volume_db = 0
			tfl.play()
			tfl.volume_db -= 50 / ff.duration
			ff.count += 1
		else:
			residual_footfalls = []
			tfl.volume_db = 0
				
	
func do_wallscrape():
	if is_on_wall:
		heartrate += 10
		var peff = AudioServer.get_bus_effect(4,0)
		if is_on_left:
			peff.pan = -0.75
		elif is_on_right:
			peff.pan = 0.75
		else:
			peff.pan = 0
		current_wallscrape.play()	
	
	
func get_footfall(name):
	for ff in footfalls:
		if ff.name == name:
			return ff.node
	return null
		
					
func _input(event):
		
	if passed_out:
		return
	if event is InputEventScreenTouch:
		handle_touch(event)
	if event is InputEventScreenDrag:
		handle_drag(event)


func handle_touch(event):
	if not event.is_pressed():
		cumulative_dragy = 0
		cumulative_dragx = 0
		fingers_touched -=1
	else:
		fingers_touched += 1
		
	if fingers_touched == 2:
		if footfall_demo:
			held_footfalls = []
			#$Camera/FootfallHeld.hide()
	if fingers_touched == 3:
		toggle_blackscreen()
	if fingers_touched == 4:
		drop_main_cam()
	if fingers_touched == 1:
		is_touching = true
		long_touch_timer.start()
	else:
		stop_long_touch_timer()
			

func drop_main_cam():
	var mc = $"../../ViewportContainer3/Viewport/MainCamera"
	var mcy = mc.translation.y
	#print(mcy)
	if not cam_in_shadow_world:
		mc.translate(Vector3(0,-20,0))
		cam_in_shadow_world = true
	else:
		mc.translate(Vector3(0,20,0))
		cam_in_shadow_world = false
				
	#print(mc.translation.y)
	
func handle_drag(event):
	var rel = event.get_relative()
	cumulative_dragy += -rel.y
	if abs(cumulative_dragy) > drag_trigger:
		stop_long_touch_timer()
	cumulative_dragx += rel.x
	if abs(cumulative_dragx) > drag_trigger:
		stop_long_touch_timer()
		rotation_degrees.y -= rotate_sensitivity * rel.x



func stop_long_touch_timer():
	is_touching = false
	long_touch_timer.stop()	
	

var tg = 1
	
func _on_long_touch_timer_timeout():
	#$"../MainHall/Walls/MeshInstance".material_override.albedo_color = Color(3, 4, 5, 0.0)
	#$"../MainHall/Walls/MeshInstance".get_material_override().uv1_scale = Vector3(90,90,90) 

	#$"../MainHall/Walls/LockedDoor".get_material_override().set_albedo(Color(3, 4, 5, 0.0))
	#$"../MainHall/Walls/LockedDoor".get_material_override().set_uv1_scale(Vector3(20,20,20)) 
	#var nwall = find_node_by_name($"../Walls", "LockedDoor")
	if tg == 1:
		#nwall.material_override = load("res://trans_205.tres")
		print("door_1")
		$"../Walls/LockedDoor".material_override = load("res://sgsq1.tres")
		tg = 2
	elif tg == 2:
		print("door_2")
		#nwall.material_override = load("res://door_2.tres")
		$"../Walls/LockedDoor".material_override = load("res://sgsq2.tres")
		tg = 3
	elif tg == 3:
		print("door_3")
		#nwall.material_override = load("res://door_1.tres")
		$"../Walls/LockedDoor".material_override = load("res://sgsq3.tres")
		tg = 4
	elif tg == 4:
		print("door_4")
		#nwall.material_override = load("res://door_1.tres")
		$"../Walls/LockedDoor".material_override = load("res://sgsq4.tres")
		tg = 5
	elif tg == 5:
		print("door_5")
		#nwall.material_override = load("res://door_1.tres")
		$"../Walls/LockedDoor".material_override = load("res://sgsq5.tres")
		tg = 6
	elif tg == 6:
		print("door_6")
		#nwall.material_override = load("res://door_1.tres")
		$"../Walls/LockedDoor".material_override = load("res://sgsq6.tres")
		tg = 7
	elif tg == 7:
		print("door_7")
		#nwall.material_override = load("res://door_1.tres")
		$"../Walls/LockedDoor".material_override = load("res://sgsq7.tres")
		tg = 8
	elif tg == 8:
		print("door_8")
		#nwall.material_override = load("res://door_1.tres")
		$"../Walls/LockedDoor".material_override = load("res://sgsq8.tres")
		tg = 9
	else:
		print("door_9")
		#nwall.material_override = load("res://door_1.tres")
		$"../Walls/LockedDoor".material_override = load("res://sgsq9.tres")
		tg = 1	
		
	#set_albedo(Color(3, 4, 5, 0.5))
	Input.vibrate_handheld(longtouch_vibration)
	#if vibration:
		#vibration.vibrate(longtouch_vibration)
	if footfall_demo:
		held_footfalls.append(last_footfall)
		#$Camera/FootfallHeld.hide()
		held_footfall_demo_timer.start()
	if not current_area:

		return
	if get_global_condition(current_area.longtouch_do_condition) == false:

		return
	play_area_longtouch_sound(current_area)
	set_global_condition(current_area.longtouch_done_condition, true)

		

func get_global_condition(name):
	for gc in Global.conditions:
		if gc.name == name:
			return gc.satisfied
	return null
	

func set_global_condition(name, val):
	for gc in Global.conditions:
		if gc.name == name:
			gc.satisfied = val
	
		
func play_area_longtouch_sound(area):

	var ltplayer
	if area.longtouch_sound_3d:
		ltplayer = area.get_node("Sound")
	else:
		ltplayer = $Sound
	if not ltplayer:
		return
	if not area.longtouch_sound:
		return
	if area.longtouch_sound_playtimes == area.longtouch_sound_times_played:
		return
	var sound = load("res://sounds/" + area.longtouch_sound + ".ogg")
	if sound:
		ltplayer.stream = sound
		ltplayer.play()
		if area.longtouch_sound_playtimes != -1:
			area.longtouch_sound_times_played += 1
	

 
func update_cameras():
	if not doing_sounds:
		#do_sounds()
		cam1.translation = translation
		if cam_in_shadow_world:
			cam1.translate(Vector3(0,shadow_world_y,0))
			
		cam1.rotation = rotation	
		right_ear_cam.translation = translation
		right_ear_cam.translate(Vector3(0,shadow_world_y,0))
		right_ear_cam.rotation = rotation
		right_ear_cam.rotate(Vector3(0, 1, 0), deg2rad(270))
		left_ear_cam.translation = translation
		left_ear_cam.translate(Vector3(0,shadow_world_y,0))
		left_ear_cam.rotation = rotation
		left_ear_cam.rotate(Vector3(0, 1, 0), deg2rad(90))
		
		left_ear_plate_cam.translation = translation
		left_ear_plate_cam.translate(Vector3(0,shadow_world_y,0))
		left_ear_plate_cam.translate(Vector3(0, 0, 0.2))
		left_ear_plate_cam.rotation = rotation
		left_ear_plate_cam.rotate(Vector3(0, 1, 0), deg2rad(250))		
		
		right_ear_plate_cam.translation = translation
		right_ear_plate_cam.translate(Vector3(0,shadow_world_y,0))
		right_ear_plate_cam.translate(Vector3(0, 0, 0.2)) #.1
		right_ear_plate_cam.rotation = rotation
		right_ear_plate_cam.rotate(Vector3(0, 1, 0), deg2rad(110))
		
		face_plate_cam.translation = translation
		face_plate_cam.translate(Vector3(0,shadow_world_y,0))
		face_plate_cam.translate(Vector3(0, 0, 0.8)) #.1
		face_plate_cam.rotation = rotation
		face_plate_cam.rotate(Vector3(0, 1, 0), deg2rad(180))
							
func _physics_process(delta):
	
	if abs(cumulative_dragx) > drag_trigger:
		if cumulative_dragx > 0:
			rotation_degrees.y -= rotate_sensitivity * auto_rotate_speed * abs(cumulative_dragx)
		else:
			rotation_degrees.y -= rotate_sensitivity * -auto_rotate_speed * abs(cumulative_dragx) 
		
	do_rotation_sound(rotation_degrees.y)
	
	var move_vec = Vector3()
	if is_on_floor() and cumulative_dragy > drag_trigger:
		move_vec.z -= 1
	if is_on_floor() and cumulative_dragy < -drag_trigger:
		move_vec.z += 1

	
	move_vec = move_vec.normalized()
	move_vec = move_vec.rotated(Vector3(0, 1, 0), rotation.y)
	
	var abs_dragy = abs(cumulative_dragy)
	if abs_dragy > top_speed:
		abs_dragy = top_speed
		
	var move = move_vec * abs_dragy * walk_sensitivity

	if is_on_floor():
		move.y = -floor_gravity
	else:
		move.y = -falling_gravity
		
	#var collision_info = move_and_slide_with_snap(move, Vector3(0,-1,0), Vector3(0,1,0), true)
	var collision_info = move_and_slide(move, Vector3(0,1,0), true)
	
	update_cameras()
	
	if collision_info:
		handle_collision(collision_info)	



func get_raycast_colliders():
	
	is_on_front = is_raycast_colliding($RayCastForward,"Walls")
	is_on_right = is_raycast_colliding($RayCastForwardRight, "Walls")
	is_on_left = is_raycast_colliding($RayCastForwardLeft, "Walls")
	is_on_floor = is_raycast_colliding($RayCastDown, "Floors")
	if is_on_front or is_on_right or is_on_left:
		is_on_wall = true
	else:
		is_on_wall = false
	if is_on_right:
		rotate(Vector3(0,1,0),0.01)
		cumulative_dragx = 0
	if is_on_left:
		rotate(Vector3(0,1,0),-0.01)	
		cumulative_dragx = 0	

	
func is_raycast_colliding(rc, name):
	var rcc = rc.get_collider()
	if rcc:
		if rcc.get_parent().get_parent().name == name:
			return true	
	return false
	
	
func handle_collision(collision_info):
	get_raycast_colliders()
	if is_on_wall:
		handle_wall_collision(collision_info)		
	handle_distance_traveled()
		

func handle_distance_traveled():
	var xdiff = abs(last_x - translation.x)
	var zdiff = abs(last_z - translation.z)
	var ydiff = abs(last_y - translation.y)
	var dsq = xdiff * xdiff + zdiff * zdiff + ydiff * ydiff
	var distance_traveled = sqrt(dsq)	
	if is_on_floor and distance_traveled > footstep_distance:
		footfall()
		last_x = translation.x
		last_z = translation.z
		last_y = translation.y
			
	
func handle_wall_collision(collision_info):
	var sc = get_slide_collision(0)
	if not sc:
		return
	var nm = sc.get_collider().get_parent().get_parent().get_name()

	if nm == "Walls" and not $PlayerCollide.is_playing():
		var cangle = abs(collision_info.x) + abs(collision_info.z)

		if cangle < collision_vs_scrape_angle:
			
			var eff = AudioServer.get_bus_effect(4,0)
			eff.pan = 0.0
			var disable_default_collision = false
			if current_area:
				if current_area.disable_default_collision == true:
					disable_default_collision = true
				do_area_collision()
			if not disable_default_collision:
				$PlayerCollide.play()
			heartrate += wall_collide_heartrate_increase
			Input.vibrate_handheld(wall_collide_vibration)
			#if vibration:
				#vibration.vibrate(wall_collide_vibration)
			player_wallhits += 1
			if player_wallhits > wallhits_before_help:
				do_collision_help()
				

func do_area_collision():
	if current_area.collision_sound:
		var sound = load("res://sounds/" + current_area.collision_sound + ".ogg")
		if sound:
			var Sound = current_area.find_node("Sound")
			if not Sound.is_playing():
				Sound.stream = sound
				Sound.play()
							
												
func do_collision_help():
	if get_global_condition("is_cat_out") == true:
		$"../Cat/Meow".play()
		player_wallhits = 0
				
									
func toggle_blackscreen():
	if $"../../ViewportContainer3/Viewport/MainCamera/Blackscreen".visible:
		$"../../ViewportContainer3/Viewport/MainCamera/Blackscreen".hide()
	else:
		$"../../ViewportContainer3/Viewport/MainCamera/Blackscreen".show()
#	var vp = $"../../ViewportContainer3/Viewport"
#	print(vp.shadow_atlas_size)
#	if vp.shadow_atlas_size == 0:
#		$"../DirectionalLight".light_color = "ffffff"
#		vp.shadow_atlas_size = 100
#	else:
#
#		$"../DirectionalLight".light_color = "000000"
#		vp.shadow_atlas_size = 0


func _on_Area_area_entered(area):
	current_area = area


func _on_Area_area_exited(area):
	if current_area == area:
		current_area = null


func _on_SandPitBridgeAreaOffLeft_body_entered(body):
	if body.name == "Player":
		$"../SandPit/CatPurrLoop".stop()


func _on_SandPitBridgeAreaOffLeft_body_exited(body):
	if body.name == "Player":
		$"../SandPit/CatPurrLoop".play()
		

func _on_SwimArea_body_entered(body):
	if body.name == "Player":
		#print("hiii")
		if get_global_condition("did_splash") == false:
			
			$"../Swim/SwimArea/Splash".play()
			$"../MainHall/WaterDripArea/WaterDripping".stop()
			change_soundcast()
			fan_timer.start()
			set_global_condition("did_splash", true)
		top_speed = top_swim_speed
	

var fan_forward = true
func _on_fan_timer_timeout():
	$"../Swim/Walls/FanBlade".rotate(Vector3(1,0,0),deg2rad(7))
	$"../Swim/Walls/FanBlade2".rotate(Vector3(1,0,0),deg2rad(7))
	
#	var wall = $"../Swim/Walls/Wall5"
#	if wall.translation.x < -5:
#		fan_forward = true
#	if wall.translation.x > -4:
#		fan_forward = false
#
#	if fan_forward:
#		wall.translate(Vector3(1, 0, 0))
#	else:
#		wall.translate(Vector3(-1, 0, 0))	

		
func change_soundcast():
	var sound = load("res://sounds/hum.ogg")
	if sound:
		$LightSound.stop()
		$LightSound.stream = sound
		$LightSound.play()
		
				
func _on_SwimArea_body_exited(body):
	if body.name == "Player":
		residual_footfalls = [{"footfall":$FootfallWater, "duration":15, "count":0}]
		top_speed = top_walk_speed
		

func _on_SandyBank_body_exited(body):
	if body.name == "Player":
		residual_footfalls = [{"footfall":$FootfallSand, "duration":8, "count":0}]


func _on_SandPitArea_body_entered(body):
	if body.name == "Player":
		$"../SandPit/CatPurrLoop".stop()
		$PlayerFallingIntoSandPit.play()


func _on_SandPitArea_body_exited(body):
	if body.name == "Player":
		residual_footfalls = [{"footfall":$FootfallSand, "duration":8, "count":0}]
		
				
func _on_PitLandingArea_body_entered(body):
	if body.name == "Player":
		$"../SandPit/CatPurrLoop".play()


func _on_Cat_camera_entered(camera):
	if camera.get_name() == "MainCamera" and get_global_condition("is_cat_out") == true:
		#print("cat purr")
		$"../Cat/Purr".play()
	
	
func _on_Sound_finished():
	if current_area:

		if current_area.longtouch_complete_function:

			call(current_area.longtouch_complete_function)

		
func cat_comes_out():
	if get_global_condition("is_cat_out") == true:
		$"../MainHall/CatArea/Purring".play()


var hall_unlocked_opened = false
func open_hall_door():
	if get_global_condition("door_unlocked") == true:
		#$"../MainHall/Walls/LockedDoor".translation.x = 2.26	
		locked_door_timer.start()
		if hall_unlocked_opened == false:
			var sound = load("res://sounds/area/open_locked_door.ogg")
			if sound:
				var snd = $"../MainHall/LockedDoorArea/Sound"
				snd.stop()
				snd.stream = sound
				snd.play()
				hall_unlocked_opened = true


func _on_locked_door_timer_timeout():
	#-0.024
	if $"../MainHall/Walls/LockedDoor".translation.x < 2.26:
		$"../MainHall/Walls/LockedDoor".translation.x += 0.2
		$"../Walls/LockedDoor".translation.x += 0.2
		#print("opening")
		locked_door_timer.start()
		

func _on_FireflyArea_body_entered(body):
	if body.name == "Player":
		firefly_timer.start()

var firefly_distance = 4
onready var firefly_target = translation
onready var firefly_pending_target = translation
var track_count = 0

func _on_firefly_timer_timeout():
	var t = rand_range(0.1,1)
	firefly_timer.set_wait_time(t)
	
	if passed_out:
		return
		
	if track_count == 8:
		firefly_pending_target = translation
	elif track_count > 16:
		firefly_target = firefly_pending_target
		track_count = 0
		if firefly_target != firefly_pending_target:
			firefly_distance = 4
	track_count += 1
	
	track_count += 1
	firefly_distance -= 0.1
	if firefly_distance < 1:
		firefly_distance = 1
	randomize()
	
	var x = rand_range(0, firefly_distance)
	var z = rand_range(0, firefly_distance)
	var neg = randi()%2+1
	if neg == 1:
		x = x * -1
	var neg2 = randi()%2+1
	if neg2 == 1:
		z = z * -1

	var firefly_pos = Vector3(firefly_target.x + x, translation.y, firefly_target.z + z)
	$"../Fireflies/Firefly".translation = firefly_pos
	$"../Fireflies/Firefly2".translation = firefly_pos
	
	var xdiff = abs($"../Fireflies/Firefly".translation.x - translation.x)
	var zdiff = abs($"../Fireflies/Firefly".translation.z - translation.z)
	var dsq = xdiff * xdiff + zdiff * zdiff
	var distance_traveled = sqrt(dsq)
	if distance_traveled < 1:
		if heartrate < 65:
			Input.vibrate_handheld(500)
			#if vibration:
				#vibration.vibrate(500)
			heartrate += 80
		else:
			Input.vibrate_handheld(300)
			#if vibration:
				#vibration.vibrate(300)
			heartrate += 12
		$"../Fireflies/Firefly2".play()
	else:	
		$"../Fireflies/Firefly".play()	
		

	#if vibration:
		#vibrate - takes a duration parm
		#vibration.vibrate(50)
		
		#loop - 1st parm is vibe duration, 2nd parm is silence duration
		#vibration.loop(1000, 100)
		
		#pattern - series of 11 off/on durations that start with silence (start with 0 for no delay)
		#final parm is 0 to loop or -1 to not loop
		#vibration.pattern(0,100,100,200,100,300,100,400,100,500,100,0)
		
		#vibration.stop() to end a loop
		#vibration.pattern(0,30,100,30,1000,0,0,0,0,0,0,0) #heartbeat	
	
	





