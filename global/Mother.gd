extends Node


var sandbox: SandboxData


#region init
func _ready() -> void:
	sandbox = SandboxData.new()
	sandbox.init_sandbox()
#endregion
