local spawn = task.spawn
local type = type
local clear = table.clear

return function(Signal, Environment)
	local Input = {}

	local UIS = Environment.Services.UserInputService
	local _connections = {}
	local _actionBindings = {}
	local _initialized = false
	local _inputBlocked = false
	local _capturing = false

	local _pressedKeys = {}
	local _pressedMouse = {}
	local _mousePosition = Vector2.new(0, 0)
	local _mouseDelta = Vector2.new(0, 0)
	local _scrollDelta = 0

	Input.OnKeyPressed = Signal.New()
	Input.OnKeyReleased = Signal.New()
	Input.OnMouseButton1Down = Signal.New()
	Input.OnMouseButton1Up = Signal.New()
	Input.OnMouseButton2Down = Signal.New()
	Input.OnMouseButton2Up = Signal.New()
	Input.OnMouseMoved = Signal.New()
	Input.OnMouseScrolled = Signal.New()
	Input.OnInputBegan = Signal.New()
	Input.OnInputEnded = Signal.New()
	Input.OnCaptured = Signal.New()

	local MOUSE_BUTTON_1 = Enum.UserInputType.MouseButton1
	local MOUSE_BUTTON_2 = Enum.UserInputType.MouseButton2
	local MOUSE_BUTTON_3 = Enum.UserInputType.MouseButton3
	local MOUSE_MOVEMENT = Enum.UserInputType.MouseMovement
	local MOUSE_WHEEL = Enum.UserInputType.MouseWheel
	local KEYBOARD = Enum.UserInputType.Keyboard

	local function Store(conn)
		_connections[#_connections + 1] = conn
	end

	local function HandleInputBegan(inputObject, gameProcessed)
		local inputType = inputObject.UserInputType
		local keyCode = inputObject.KeyCode

		if _capturing then
			if inputType == KEYBOARD and keyCode ~= Enum.KeyCode.Unknown then
				_capturing = false
				Input.OnCaptured:Fire(keyCode, "Keyboard")
				return
			elseif inputType == MOUSE_BUTTON_1 or inputType == MOUSE_BUTTON_2 or inputType == MOUSE_BUTTON_3 then
				_capturing = false
				Input.OnCaptured:Fire(inputType, "Mouse")
				return
			end
		end

		Input.OnInputBegan:Fire(inputObject, gameProcessed)

		if inputType == KEYBOARD then
			_pressedKeys[keyCode] = true
			Input.OnKeyPressed:Fire(keyCode, gameProcessed)
		elseif inputType == MOUSE_BUTTON_1 then
			_pressedMouse[MOUSE_BUTTON_1] = true
			Input.OnMouseButton1Down:Fire(_mousePosition, gameProcessed)
		elseif inputType == MOUSE_BUTTON_2 then
			_pressedMouse[MOUSE_BUTTON_2] = true
			Input.OnMouseButton2Down:Fire(_mousePosition, gameProcessed)
		elseif inputType == MOUSE_BUTTON_3 then
			_pressedMouse[MOUSE_BUTTON_3] = true
		end
	end

	local function HandleInputEnded(inputObject, gameProcessed)
		local inputType = inputObject.UserInputType
		local keyCode = inputObject.KeyCode

		Input.OnInputEnded:Fire(inputObject, gameProcessed)

		if inputType == KEYBOARD then
			_pressedKeys[keyCode] = nil
			Input.OnKeyReleased:Fire(keyCode, gameProcessed)
		elseif inputType == MOUSE_BUTTON_1 then
			_pressedMouse[MOUSE_BUTTON_1] = nil
			Input.OnMouseButton1Up:Fire(_mousePosition, gameProcessed)
		elseif inputType == MOUSE_BUTTON_2 then
			_pressedMouse[MOUSE_BUTTON_2] = nil
			Input.OnMouseButton2Up:Fire(_mousePosition, gameProcessed)
		elseif inputType == MOUSE_BUTTON_3 then
			_pressedMouse[MOUSE_BUTTON_3] = nil
		end
	end

	local function HandleInputChanged(inputObject)
		local inputType = inputObject.UserInputType

		if inputType == MOUSE_MOVEMENT then
			local newPos = Vector2.new(inputObject.Position.X, inputObject.Position.Y)
			_mouseDelta = newPos - _mousePosition
			_mousePosition = newPos
			Input.OnMouseMoved:Fire(_mousePosition, _mouseDelta)
		elseif inputType == MOUSE_WHEEL then
			_scrollDelta = inputObject.Position.Z
			Input.OnMouseScrolled:Fire(_scrollDelta)
		end
	end

	function Input.Init()
		if _initialized then
			return
		end
		_initialized = true

		if not UIS then
			return
		end

		Store(UIS.InputBegan:Connect(HandleInputBegan))
		Store(UIS.InputEnded:Connect(HandleInputEnded))
		Store(UIS.InputChanged:Connect(HandleInputChanged))

		local mouse = Environment.GetMouse()
		if mouse then
			_mousePosition = Vector2.new(mouse.X, mouse.Y)
		end
	end

	function Input.IsKeyDown(keyCode)
		return _pressedKeys[keyCode] == true
	end

	function Input.IsMouseButtonDown(inputType)
		return _pressedMouse[inputType] == true
	end

	function Input.GetMousePosition()
		return _mousePosition
	end

	function Input.GetMouseDelta()
		return _mouseDelta
	end

	function Input.GetScrollDelta()
		return _scrollDelta
	end

	function Input.AreKeysDown(keys)
		for i = 1, #keys do
			if not _pressedKeys[keys[i]] then
				return false
			end
		end
		return true
	end

	function Input.GetPressedKeys()
		local keys = {}
		local n = 0
		for key in _pressedKeys do
			n += 1
			keys[n] = key
		end
		return keys
	end

	function Input.BindAction(name, keys, callback)
		if type(keys) ~= "table" then
			keys = { keys }
		end
		local binding = {
			Name = name,
			Keys = keys,
			Callback = callback,
			Connection = nil,
		}
		binding.Connection = Input.OnKeyPressed:Connect(function(keyCode)
			local matched = false
			for i = 1, #keys do
				if keys[i] == keyCode then
					matched = true
					break
				end
			end
			if not matched then
				return
			end
			for i = 1, #keys do
				if keys[i] ~= keyCode and not _pressedKeys[keys[i]] then
					return
				end
			end
			spawn(callback)
		end)
		_actionBindings[name] = binding
		return binding
	end

	function Input.UnbindAction(name)
		local binding = _actionBindings[name]
		if not binding then
			return false
		end
		if binding.Connection then
			binding.Connection:Disconnect()
		end
		_actionBindings[name] = nil
		return true
	end

	function Input.UnbindAll()
		for _, binding in _actionBindings do
			if binding.Connection then
				binding.Connection:Disconnect()
			end
		end
		clear(_actionBindings)
	end

	function Input.SetInputBlocked(blocked)
		_inputBlocked = blocked
	end

	function Input.IsInputBlocked()
		return _inputBlocked
	end

	function Input.BeginCapture()
		_capturing = true
	end

	function Input.EndCapture()
		_capturing = false
	end

	function Input.IsCapturing()
		return _capturing
	end

	function Input.IsWindowFocused()
		return Environment.IsRbxActive()
	end

	function Input.ResetState()
		clear(_pressedKeys)
		clear(_pressedMouse)
		_mouseDelta = Vector2.new(0, 0)
		_scrollDelta = 0
	end

	function Input.Destroy()
		if not _initialized then
			return
		end
		_initialized = false

		for i = 1, #_connections do
			_connections[i]:Disconnect()
		end
		clear(_connections)

		Input.UnbindAll()
		Input.ResetState()

		Input.OnKeyPressed:Destroy()
		Input.OnKeyReleased:Destroy()
		Input.OnMouseButton1Down:Destroy()
		Input.OnMouseButton1Up:Destroy()
		Input.OnMouseButton2Down:Destroy()
		Input.OnMouseButton2Up:Destroy()
		Input.OnMouseMoved:Destroy()
		Input.OnMouseScrolled:Destroy()
		Input.OnInputBegan:Destroy()
		Input.OnInputEnded:Destroy()
		Input.OnCaptured:Destroy()
	end

	return Input
end
