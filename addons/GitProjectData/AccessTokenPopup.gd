tool
extends PopupPanel


signal token_entered(token)


func _on_LineEdit_text_entered(new_text):
	emit_signal("token_entered", new_text)
	hide()
	queue_free()


func _on_Button_pressed():
	emit_signal("token_entered", "EXIT")
	hide()
	queue_free()
