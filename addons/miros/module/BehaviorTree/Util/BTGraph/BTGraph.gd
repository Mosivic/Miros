tool
extends Control

const BTClassBD = preload("res://addons/miros/module/BehaviorTree/Util/BTClassDB.gd")
# 行为树节点
var bt_gragh_node = preload("res://addons/miros/module/BehaviorTree/Util/BTGraph/BTGraphNode.tscn")


onready var graph = $GraphEdit

var root

# 插件类引用
var _plugin:EditorPlugin

# 保存当前行为树中所有实例节点的字典,key为节点name,value为节点引用
var bt_graph_nodes = {}
# 保存Actions
var actions = {}

var temp


func set_plugin(value:EditorPlugin):
	_plugin = value
	if not self.is_inside_tree():
		yield(self,"ready")
	# 默认实例化根节点root
	root = _add_node("Root")
	# 建立context操作UI
#	for key in BTClassBD.BTNode:
#		if key == "Root":continue
#		var b = ToolButton.new()
#		b.set_meta("bt_data",{
#			script = BTClassBD.BTNode[key] ,
#			type = key,
#		})
#		b.text = key
#		b.connect("pressed",self,"_on_Button_pressed",[b])
#		b.icon = _plugin.get_editor_interface().get_base_control().get_icon("Node","EditorIcons")
#		b.rect_min_size = Vector2(100,40)
#		get_node("UI/Context/VBoxContainer").add_child(b)
	
# Context菜单中新建节点按钮被点击事件, 取消
func _on_Button_pressed(button:Button):
#	var data = button.get_meta("bt_data")
#	_add_node(data.type)
	pass


# 实例化节点
func _add_node(node_type:String,pos:Vector2 = Vector2.ZERO)->GraphNode:
	var n = bt_gragh_node.instance()
	n.title = node_type
	n.graph = self
	# 节点实例命名方式 节点类型 + _ + 节点实例id
	n.name = n.title + "_" +str(n.get_instance_id())
	n.offset = pos
	bt_graph_nodes[n.name] = n
	graph.add_child(n)
	return n


# 连接节点, from为左节点name,to为右节点name
func _on_GraphEdit_connection_request(from, from_slot, to, to_slot):
	var graph:GraphEdit = get_node("GraphEdit")
	graph.connect_node(from, from_slot, to, to_slot)
	_add_node_link_info(from,to)
	

# 连接完成后各自将对方节点加入到节点信息中
func _add_node_link_info(from:String,to:String):
	var left = bt_graph_nodes[from]
	var right = bt_graph_nodes[to]
	left.add_right_node(right)
	right.add_left_node(left)


# 解除连接后清楚双方节点的节点信息
func _remove_node_link_info(from:String,to:String):
	var left = bt_graph_nodes[from]
	var right = bt_graph_nodes[to]
	left.remove_node(right)
	right.remove_node(left)


func _save_graph(path:String):
	pass
	
func _load_graph(path:String):
	pass

# 将行为树节点信息封装为data
func _pack_graph_data(c_node:GraphNode)->Dictionary:
	var data:Dictionary
	var c_node_info = {
		"name":c_node.name,
		"lns":[], # link nodes info
		"offset":c_node.offset, #self position
		"action":c_node.action_name
		}
	for n in c_node.right_nodes:
		c_node_info["lns"].append(_pack_graph_data(n))
	data = c_node_info
	return data
	
# 根据data信息建立行为树节点
func _unpack_graph_by_data(data:Dictionary):
	# 销毁之前节点与存储数据
	for n in bt_graph_nodes.values():
		n.queue_free()
	bt_graph_nodes.clear()
	# 根据data建立节点
	# 建立root的叶节点们
	root = _restore_node(null,data) #头节点为空

func _restore_node(left_node,node_info:Dictionary)->GraphNode:
	var node:GraphNode
	var type = node_info["name"].split("_")[0]
	node = _add_node(type,node_info["offset"])
	for ni in node_info["lns"]:
		var right_node = _restore_node(node,ni)
		_on_GraphEdit_connection_request(node.name,0,right_node.name,0)
	return node



func build_actions():
	var path = "res://addons/miros/module/Action/ActionLibrary/"
	actions = SavaManager.GetFilesInDirectory({},path,false)



func refresh_inspecter():
	_plugin.get_editor_interface().get_inspector().refresh()

func _parse_begin(plugin:EditorInspectorPlugin):
	# 创建标题栏
	plugin.add_custom_control(UIBuilder.create_category_header())
	# 创建节点类型选择
	plugin.add_custom_control(HSeparator.new())
	
	var vbox = HBoxContainer.new()
	var dropdown = OptionButton.new()
	for key in BTClassBD.BTNode:
		dropdown.add_item(key)
	vbox.add_child(dropdown)
	var createNodebutton = Button.new()
	createNodebutton.text = "Create"
	createNodebutton.connect("pressed",self,"_on_createNodeButton_pressed",[dropdown])
	createNodebutton.size_flags_horizontal = Control.SIZE_EXPAND + Control.SIZE_SHRINK_END
	vbox.add_child(createNodebutton)
	plugin.add_custom_control(vbox)
	
	plugin.add_custom_control(HSeparator.new())
	# 创建保存与加载按钮
	var hbox = VBoxContainer.new()
	var saveButton = Button.new()
	var loadButton = Button.new()
	saveButton.text = "Save"
	loadButton.text = "Load"
	saveButton.connect("button_down",self,"_on_SaveBtn_pressed")
	loadButton.connect("button_down",self,"_on_LoadBtn_pressed")
	hbox.add_child(saveButton)
	hbox.add_child(loadButton)
	plugin.add_custom_control(hbox)
	plugin.add_custom_control(HSeparator.new())
	# 创建构建Actions按钮
	var buildActionsButtion = Button.new()
	buildActionsButtion.text = "Build Actions"
	buildActionsButtion.connect("button_down",self,"build_actions")
	plugin.add_custom_control(buildActionsButtion)



func _on_createNodeButton_pressed(optionButton:OptionButton):
	var nodeName = optionButton.get_item_text(optionButton.selected)
	_add_node(nodeName)

func _on_SaveBtn_pressed():
#	var data:Dictionary = {"Root_127446":{"lns":[{"CompositeSequence_130357":{"lns":[], "pos":Vector2(340, 28.75)}}], "pos":Vector2(0, 88.75)}}
#	_restore_graph_by_data(data)
	temp = _pack_graph_data(root)
	print(temp)


func _on_LoadBtn_pressed():
	_unpack_graph_by_data(temp)


func _on_ShowInspector_pressed():
	_plugin.get_editor_interface().inspect_object(self)

