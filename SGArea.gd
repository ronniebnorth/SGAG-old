extends Area

export (int, 50, 200) var heartrate
export var oneshot_heartrate = false
export var constant_heartrate = false
var disable_heartrate = false
var new_arrival = true

export var base_footfall = true
export (String, 'none', 'normal', 'carpet', 'concrete', 'creaky', 'dirt', 'dirt2', 'floor', 'forest', 'gravel', 'gravel2', 'hardfemale', 'heavy', 'mellow', 'metal', 'mud', 'sand', 'snow', 'snow2', 'snow3', 'stone', 'swim', 'tapstep', 'tile', 'water', 'wood') var default_footfall
#export (String, 'none', 'normal', 'sand', 'water', 'mud', 'swim', 'dirt', 'creaky', 'tile') var residual_footfall
export (String, 'none', 'normal', 'carpet', 'concrete', 'creaky', 'dirt', 'dirt2', 'floor', 'forest', 'gravel', 'gravel2', 'hardfemale', 'heavy', 'mellow', 'metal', 'mud', 'sand', 'snow', 'snow2', 'snow3', 'stone', 'swim', 'tapstep', 'tile', 'water', 'wood') var extra_footfall
export (String, 'none', 'x-axis', 'z-axis', 'center') var extra_footfall_gradient
export (String) var next_target_area

export (String) var longtouch_sound
export (int, -1, 10) var longtouch_sound_playtimes #-1 is infinite
export var longtouch_sound_3d = false 
export (String) var longtouch_do_condition
export (String) var longtouch_done_condition
export (String) var longtouch_complete_function
# if true, must add AudioStreamPlayer3d named LongtouchSound to area
var longtouch_sound_times_played = 0

export (String) var entry_sound #ie baby/baby_crying_0
export (int, -1, 10) var entry_sound_playtimes #-1 is infinite
export var entry_sound_3d = false 
# if true, must add AudioStreamPlayer3d named LongtouchSound to area
export var deactivate_entry_after_longtouch = false
# this will deactivate entry sounds after longtouch has completed playtimes, which is never if set to infinite
var entry_sound_times_played = 0

export (String) var exit_sound #ie baby/baby_crying_0
export (int, -1, 10) var exit_sound_playtimes #-1 is infinite
export var exit_sound_3d = false 
# if true, must add AudioStreamPlayer3d named LongtouchSound to area
export var deactivate_exit_after_longtouch = false
# this will deactivate exit sounds after longtouch has completed playtimes, which is never if set to infinite
var exit_sound_times_played = 0

export (String) var collision_sound
export var disable_default_collision = false

func _on_SGArea_body_entered(body):
	if body.name == "Player":
		if next_target_area:
			var node = find_node_by_name(get_tree().get_root(), next_target_area)
			$"../../Cat".translation = node.translation
		if deactivate_entry_after_longtouch and longtouch_sound_times_played == longtouch_sound_playtimes:
			return
		play_area_entry_sound()

		

func _on_SGArea_body_exited(body):
	if body.name == "Player":
		if deactivate_exit_after_longtouch and longtouch_sound_times_played == longtouch_sound_playtimes:
			return
		play_area_exit_sound()
		if oneshot_heartrate:
			disable_heartrate = true
		new_arrival = true
		
func play_area_entry_sound():
	var ltplayer
	if entry_sound_3d:
		ltplayer = get_node("Sound")
	else:
		ltplayer = $Sound
	if not ltplayer:
		return
	if ltplayer.is_playing():
		return
	if not entry_sound:
		return
	if entry_sound_playtimes == entry_sound_times_played:
		return
	var sound = load("res://sounds/" + entry_sound + ".ogg")
	if sound:
		ltplayer.stream = sound
		ltplayer.play()
		
		if entry_sound_playtimes != -1:
			entry_sound_times_played += 1
			

func play_area_exit_sound():
	var ltplayer
	if exit_sound_3d:
		ltplayer = get_node("Sound")
	else:
		ltplayer = $Sound
	if not ltplayer:
		return
#	if ltplayer.is_playing():
#		return
	if not exit_sound:
		return
	if exit_sound_playtimes == exit_sound_times_played:
		return
	var sound = load("res://sounds/" + exit_sound + ".ogg")
	if sound:
		ltplayer.stream = sound
		ltplayer.play()
		
		if exit_sound_playtimes != -1:
			exit_sound_times_played += 1
			
						
func find_node_by_name(root, name):

	if(root.get_name() == name): return root

	for child in root.get_children():
		if(child.get_name() == name):
			return child

		var found = find_node_by_name(child, name)

		if(found): return found

	return null
	


