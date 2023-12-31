@tool
extends Node2D


####################################################################################################
################ Property
####################################################################################################


@export_dir 
var avatar_path : String = "" : 
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
		_init_all_texture()
		_clear_avatar()
		display_avatar = false


@export var display_avatar = false:
	set(value):
		display_avatar = value
		if display_avatar:
			_clear_avatar()
			_setup_default_display()
		notify_property_list_changed()


func _set(property, value):
	if display_dict == null:
		display_dict = {}
	display_dict[property] = value
	if property.begins_with(DISPLAY_PREFIX):
		_display_property_sprites(property, value)
	return true


func _get(property):
	if display_dict == null:
		display_dict = {}
	if property in display_dict:
		return display_dict[property]
	return


func _get_property_list():
	# By default, `hammer_type` is not visible in the editor.
	var property_usage = PROPERTY_USAGE_NO_EDITOR

	if display_avatar:
		property_usage = PROPERTY_USAGE_DEFAULT

	var properties = []
	
	print(DISPLAY_PREFIX)
	
	properties.append({
		name = "Display",
		type = TYPE_NIL,
		hint_string = DISPLAY_PREFIX,
		usage = PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
	})
	
	for category in category_list:
		var body_name_list = category_body_names_dict[category.name] 
		var hint = PROPERTY_HINT_ENUM
		var hint_string = ",".join(body_name_list)
		var type = TYPE_STRING
		if category.multiple_selectable:
			hint = PROPERTY_HINT_FLAGS
			type = TYPE_INT
		elif category.optional:
			hint_string = "-," + hint_string
		properties.append({
			"name": DISPLAY_PREFIX + category.name,
			"type": type,
			"usage": property_usage, # See above assignment.
			"hint": hint,
			"hint_string": hint_string
		})

	return properties


func _setup_default_display():
	for category in category_list:
		if category.name not in category_body_names_dict:
			continue
		if category_body_names_dict[category.name].size() == 0:
			continue
		if category.multiple_selectable:
			continue
		if category.optional:
			_set(DISPLAY_PREFIX + category.name, "-")
		else:
			_set(DISPLAY_PREFIX + category.name, category_body_names_dict[category.name][0])


func _clear_avatar():
	display_dict = {}
	category_sprites_dict = {}
	var childs = []
	for child in $CanvasLayer.get_children():
		childs.push_back(child)
	for child in childs:
		$CanvasLayer.remove_child(child)
		child.queue_free()


####################################################################################################
################ Global Variable
####################################################################################################

const DISPLAY_PREFIX : String = "display_"

var avatar_name : String

var avatar_image_size : Vector2;

var category_list : Array[AvatarCategory]

# key : "display_" + category_name, value : body_name
var display_dict : Dictionary

# key : color_group_id, value : AvatarColorGroup
var avatar_color_group_dict : Dictionary

# key : category_id, value : category_value
var avatar_category_dict : Dictionary

# key : category.name, value : body_name_list
var category_body_names_dict : Dictionary

# key : category_name, value : category_id
var category_name_to_id_dict : Dictionary

# key : category_id,  value : { layer_id : AvatarPartLayer}
var avatar_layer_dict : Dictionary

# key : category_id,  value : { body_name : AvatarBodyPart}
var avatar_body_part_dict : Dictionary

# key : category_id,  value : { body_name : { layer_id : texture } }
var avatar_texture_dict : Dictionary

# key : category_name, value : Array[Sprite]
var category_sprites_dict : Dictionary


####################################################################################################
################ Sprite and Texture
####################################################################################################
func _init_all_texture():
	avatar_texture_dict = {}
	for category in avatar_category_dict.values():
		for body in category.bodys:
			print("category: %s, category_id: %s, body: %s" % [category.name, category.id, body.name])
			for layer in body.layers:
				var texture : Texture2D = load(avatar_path + "/" + layer.dir + "/" + body.name + ".png")
				if category.id not in avatar_texture_dict:
					avatar_texture_dict[category.id] = {}
				var body_dict = avatar_texture_dict[category.id]
				if body.name not in body_dict:
					body_dict[body.name] = {}
				var layer_dict = body_dict[body.name]
				layer_dict[layer.id] = texture


func _create_sprites(category_id, body_name) -> Array[Sprite2D]:
	var category : AvatarCategory = avatar_category_dict[category_id]
	var body : AvatarBodyPart = avatar_body_part_dict[category_id][body_name]
	var sprites : Array[Sprite2D] = []
	for layer in body.layers:
		var texture = avatar_texture_dict[category_id][body.name][layer.id]
		var sprite = Sprite2D.new()
		sprite.texture = texture
		sprite.z_index = layer.order
		sprite.offset = Vector2(texture.get_width()/2, texture.get_height()/2)
		sprite.position = Vector2(50, 50)
		print(layer.dir, "/", body.name, ".png")
#		$CanvasLayer.add_child(sprite)
		sprites.push_back(sprite)
	return sprites


func _create_sprite_by_name(category_name, body_name):
	var category_id = category_name_to_id_dict[category_name]
	var sprites = _create_sprites(category_id, body_name)
	return sprites
	

func _remove_old_sprites(sprites : Array[Sprite2D]):
	for sprite in sprites:
		$CanvasLayer.remove_child(sprite)
		sprite.queue_free()


func _display_property_sprites(property, value):
	var category_name = property.substr(DISPLAY_PREFIX.length(), property.length())
	print("_display_property_sprites category name : ", category_name)
	if category_name not in category_sprites_dict:
		var temp_sprites : Array[Sprite2D] = []
		category_sprites_dict[category_name] = temp_sprites
	var old_sprites : Array[Sprite2D] = category_sprites_dict[category_name]
	_remove_old_sprites(old_sprites)
	
	var sprites : Array[Sprite2D] = []
	if value is int:
		var body_name_list : Array = category_body_names_dict[category_name]
		for i in range(body_name_list.size()):
			if value >> i & 1 != 1:
				continue
			var body_name = body_name_list[i]
			if body_name == "-":
				continue
			var new_sprites = _create_sprite_by_name(category_name, body_name)
			for sprite in new_sprites:
				sprites.push_back(sprite)
	if value is String:
		var body_parts = value.split(",", false)
		for body_name in body_parts:
			if body_name == "-":
				continue
			var new_sprites = _create_sprite_by_name(category_name, body_name)
			for sprite in new_sprites:
				sprites.push_back(sprite)
	for sprite in sprites:
		$CanvasLayer.add_child(sprite)
	category_sprites_dict[category_name] = sprites
		
	

####################################################################################################
################ XML Parser
####################################################################################################

class AvatarPartLayer:
	var dir : String
	var id : String
	var order : int
	var color_group_id : String
	var display_name : String
	var color_model : String
	func _init(_dir, _id, _order, _color_group_id, _display_name, _color_model):
		dir = _dir
		id = _id
		order = _order
		color_group_id = _color_group_id
		display_name = _display_name
		color_model = _color_model
	func _to_string() -> String:
		var dict = {}
		dict["dir"] = dir
		dict["id"] = id
		dict["order"] = order
		dict["color_group_id"] = color_group_id
		dict["display_name"] = display_name
		dict["color_model"] = color_model
		return str(dict)
	

class AvatarBodyPart:
	var name : String
	var category_id : String
	var category_name : String
	var layers : Array[AvatarPartLayer]
	func _init(_name, _category_id, _category_name, _layers):
		name = _name
		category_id = _category_id
		category_name = _category_name
		layers = _layers
	func _to_string() -> String:
		var dict = {}
		dict["name"] = name
		dict["category_id"] = category_id
		dict["category_name"] = category_name
		dict["layers"] = layers
		return str(dict)


class AvatarCategory:
	var name : String
	var id : String
	var multiple_selectable : bool
	var optional : bool
	var bodys : Array[AvatarBodyPart]
	func _init(_name, _id, _bodys, _multiple_selectable, _optional):
		name = _name
		id = _id
		bodys = _bodys
		if _multiple_selectable.to_lower() == "true":
			multiple_selectable = true
		else:
			multiple_selectable = false
		if _optional.to_lower() == "true":
			optional = true
		else:
			optional = false
	func _to_string() -> String:
		var dict = {}
		dict["name"] = name
		dict["id"] = id
		dict["multiple_selectable"] = multiple_selectable
		dict["optional"] = optional
		dict["bodys"] = bodys
		return str(dict)
		

class AvatarColorGroup:
	var id : String
	var name : String
	func _init(_id, _name):
		id = _id
		name = _name
	func _to_string() -> String:
		var dict = {}
		dict["name"] = name
		dict["id"] = id
		return str(dict)
		

func _find_node_children(node: Dictionary, children_name: String) -> Dictionary:
	for children in node["children"]:
		if children["name"] == children_name:
			return children
	return node

	
func _find_node_children_content(node: Dictionary, children_name: String):
	var child: Dictionary = _find_node_children(node, children_name)
	if child != node:
		return child["__content__"]
	return

	
func _find_node_childrens(node: Dictionary, childrens: Array[String]) -> Dictionary:
	var currentNode = node
	for children_name in childrens:
		var child = _find_node_children(currentNode, children_name)
		if child == currentNode:
			return node
		currentNode = child
	return currentNode


func _find_node_childrens_content(node: Dictionary, childrens: Array[String]):
	var child: Dictionary = _find_node_childrens(node, childrens)
	if child != node:
		return child["__content__"]
	return


func _load_character_xml(path):
	var root = XML.parse_file(path).to_dict()
	avatar_name = _find_node_children_content(root, "name")
	print("avatar_name: ", avatar_name)

	var width : String = _find_node_childrens_content(root, ["image-size", "width"])
	var height : String = _find_node_childrens_content(root, ["image-size", "height"])
	avatar_image_size = Vector2(float(width), float(height))
	print("avatar_image_size: ", avatar_image_size)
	
	var color_groups_node = _find_node_children(root, "colorGroups")
	avatar_color_group_dict = _build_avatar_color_group_dict(color_groups_node)
	print("avatar_color_group_dict: ", avatar_color_group_dict.keys())
	
	var categories_node = _find_node_children(root, "categories")
	avatar_category_dict = _build_avatar_category_dict(categories_node)
	print("avatar_category_dict: ", avatar_category_dict.keys())
	

func _build_avatar_color_group_dict(node : Dictionary) -> Dictionary:
	var dict = {}
	for color_group_node in node["children"]:
		var id = color_group_node["attributes"]["id"]
		var group_name = _find_node_children_content(color_group_node, "display-name")
		var group = AvatarColorGroup.new(id, group_name)
		dict[id] = group
	return dict


func _build_avatar_category_dict(node : Dictionary) -> Dictionary:
	var dict = {}
	category_list = []
	category_body_names_dict = {}
	avatar_layer_dict = {}
	avatar_body_part_dict = {}
	category_name_to_id_dict = {}
	for category_node in node["children"]:
		var category_id = category_node["attributes"]["id"]
		var multiple_selectable = category_node["attributes"]["multipleSelectable"]
		var optional = category_node["attributes"]["optional"]
		var category_name = _find_node_children_content(category_node, "display-name")
		var layer_nodes = _find_node_children(category_node, "layers")
		var layer_dict = _build_avatar_part_layer_dict(layer_nodes)
		avatar_layer_dict[category_id] = layer_dict
		var body_part_dict = _build_avatar_body_part_dict(layer_nodes)
		for body_name in body_part_dict.keys():
			var layer_array : Array[AvatarPartLayer] = []
			for layer_id in body_part_dict[body_name]:
				var layer_object : AvatarPartLayer = avatar_layer_dict[category_id][layer_id]
				layer_array.push_back(layer_object)
			var body_part = AvatarBodyPart.new(body_name, category_id, category_name, layer_array)
			if category_id not in avatar_body_part_dict:
				avatar_body_part_dict[category_id] = {}
			avatar_body_part_dict[category_id][body_name] = body_part
		var bodys : Array[AvatarBodyPart] = []
		for body in avatar_body_part_dict[category_id].values():
			bodys.push_back(body)
		var category = AvatarCategory.new(category_name, category_id, bodys, multiple_selectable, optional)
		dict[category_id] = category
		var body_name_list = []
		for body in category.bodys:
			body_name_list.push_back(body.name)
		body_name_list.sort()
		category_body_names_dict[category.name] = body_name_list
		category_list.push_back(category)
		category_name_to_id_dict[category.name] = category.id
	return dict


func _build_avatar_body_part_dict(node : Dictionary) -> Dictionary:
	var dict = {}
	for layer_node in node["children"]:
		var id = layer_node["attributes"]["id"]
		var dir = _find_node_children_content(layer_node, "dir")
		var body_part_path = avatar_path + "/" + dir
		var filenames = DirAccess.get_files_at(body_part_path)
		for filename in filenames:
			if not filename.ends_with(".png"):
				continue
			var subname = filename.substr(0, len(filename)-4)
			if subname not in dict:
				dict[subname] = [id]
			else:
				dict[subname].push_back(id)
	return dict
	
func _build_avatar_part_layer_dict(node : Dictionary) -> Dictionary:
	var dict = {}
	for layer_node in node["children"]:
		var id = layer_node["attributes"]["id"]
		var color_group_node = _find_node_children(layer_node, "colorGroup")
		var color_group_id : String = ""
		if color_group_node != layer_node:
			color_group_id = color_group_node["attributes"]["refid"]
		var display_name = _find_node_children_content(layer_node, "display-name")
		var order : String = _find_node_children_content(layer_node, "order")
		var dir = _find_node_children_content(layer_node, "dir")
		var color_model = _find_node_children_content(layer_node, "colorModel")
		var partLayer = AvatarPartLayer.new(dir, id, int(order), color_group_id, display_name, color_model)
		dict[id] = partLayer
	return dict


####################################################################################################
################ Start
####################################################################################################


# Called when the node enters the scene tree for the first time.
func _ready():
#	print(avatar_path)
#	_create_sprite("cat06696cea-3435-47af-b875-f52e838807bc", "基本")
#	#_create_sprite("cat336b4aa6-a0a1-4e2e-a1ff-87be6e56bf47", "25_★制服冬（小）")
#	_create_sprite("cat2cb6a9b5-2095-40aa-8653-48b972d43127", "01_デフォルト")
#	_create_sprite("catcb1aa8d8-51d7-4736-9465-f338be11fe1c", "10_制服スカート")
#	_create_sprite("cat336b4aa6-a0a1-4e2e-a1ff-87be6e56bf47", "22_★制服春秋（小）")
#	_create_sprite("cat81b898bd-ba87-4775-9e20-6effb3940f95", "01_照れ")
#	_create_sprite("catf3d6e058-c751-4ad3-b545-6068dcd424e7", "02_微笑")
#	_create_sprite("cat9f3a860c-c062-4f45-87b1-396602bd88ec", "01_★温厚（デフォ）")
#	_create_sprite("cate515d886-9d92-4879-9327-6c418d0eea8b", "01_★たれまゆ")
#	_create_sprite("catd9ed6d23-2e9b-4a67-b49d-df5d727f7127", "01_サイドテール（右）")
#	_create_sprite("cat5b4ae97d-3b8c-416a-b4d5-c563a2e8450f", "03_かぐや（ロング）")
	pass # Replace with function body.
#

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
