extends Control

signal chat_submitted(text: String)

@onready var chat_log   : RichTextLabel = $Panel/VBoxContainer/ChatLog
@onready var chat_input : LineEdit      = $Panel/VBoxContainer/HBoxContainer/ChatInput
@onready var send_btn   : Button        = $Panel/VBoxContainer/HBoxContainer/SendButton

func _ready() -> void:
	send_btn.pressed. connect(_submit)
	chat_input.text_submitted.connect(_submit)

func _submit(_text="") -> void:
	var t := chat_input.text.strip_edges()
	if t.is_empty(): return
	emit_signal("chat_submitted", t)
	chat_input.clear()

func append_message(from: String, text: String) -> void:
	print("🖥️ append_message called:", from, text)   # debug
	chat_log.append_text("[b]%s[/b]: %s\n" % [from, text])
	chat_log.scroll_to_line(chat_log.get_line_count())
