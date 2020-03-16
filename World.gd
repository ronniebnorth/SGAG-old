extends Spatial

var baby_cry_time = 10.0
var baby_cry_timer = Timer.new()


func _ready():
	setup_timer(baby_cry_timer, "baby_cry_timer", baby_cry_time)
	
	#$"../ViewportContainer3/Viewport/Camera".target = $"Player"

func setup_timer(timer, timer_name, time):
	timer.set_one_shot(true)
	timer.set_wait_time(time)
	timer.connect("timeout",self,"_on_" + timer_name + "_timeout")
	add_child(timer)
	#timer.start()

func _on_baby_cry_timer_timeout():
	var baby = randi()%7+0
	if baby == 0:
		$Babies/Baby_0.play()
	elif baby == 1:
		$Babies/Baby_1.play()
	elif baby == 2:
		$Babies/Baby_2.play()
	elif baby == 3:
		$Babies/Baby_3.play()
	elif baby == 4:
		$Babies/Baby_4.play()
	elif baby == 5:
		$Babies/Baby_5.play()
	else:
		$Babies/Baby_6.play()
		
	baby_cry_timer.set_wait_time(randi()%31+20)
	baby_cry_timer.start()


func toggle_blackscreen():
	if $Player/Camera/Blackscreen.visible:
		$Player/Camera/Blackscreen.hide()
	else:
		$Player/Camera/Blackscreen.show()



func _on_PickupKeys_finished():
	$MainHall/KickKeysArea.queue_free()


