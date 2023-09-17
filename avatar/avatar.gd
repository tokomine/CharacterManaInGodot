extends Node2D

@export_dir 
var avatar_path = "" : 
	set(value):
		if not DirAccess.dir_exists_absolute(value):
			push_error("path is not exists: ", value)
			return
		var xml_path: String = value+"/character.xml"
		if not FileAccess.file_exists(xml_path):
			push_error("character.xml is not exists.")
			return
		avatar_path = value
		_load_character_xml(xml_path)
		pass

func _load_character_xml(path):
	var dict = XML.parse_file(path).to_dict()
	print(dict)

func load_xml(filepath):
	var parser: XMLParser = XMLParser.new()
	parser.open(filepath)
	
	while parser.read() != ERR_FILE_EOF:
		var node_type = parser.get_node_type()
		if node_type == XMLParser.NODE_ELEMENT || node_type == XMLParser.NODE_ELEMENT_END:
			var node_name = parser.get_node_name()
			print(node_type, " name: ", node_name, " is_empty:", parser.is_empty())
			
		elif node_type == XMLParser.NODE_TEXT:
			var node_data = parser.get_node_data()
			print(node_type, " data: ", node_data)
		else:
			print(node_type)

func test_load(filepath):
	var dict = XML.parse_file(filepath).to_dict()
	print(dict)

# Called when the node enters the scene tree for the first time.
func _ready():
	#test_load("res://avatar/「みゆ」サイズ小/character.xml")
	#test_load("res://avatar/test.xml")
	#load_xml("res://avatar/test.xml")
	#load_xml("res://avatar/「みゆ」サイズ小/character.xml")
	print(avatar_path)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
