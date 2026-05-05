local type = type
local typeof = typeof
local setmetatable = setmetatable
local spawn = task.spawn
local clear = table.clear

local abs = math.abs
local clamp = math.clamp
local sin = math.sin
local cos = math.cos
local sqrt = math.sqrt
local pi = math.pi
local pow = math.pow or function(b, e) return b ^ e end

return function(Signal, Environment)
	local Animation = {}

	local RunService = Environment.Services.RunService
	local _activeTweens = {}
	local _activeSprings = {}
	local _connection = nil
	local _count = 0

	local EPSILON = 0.01 -- Larger epsilon = faster settling, less wasted frames

	local Easing = {}
	Animation.Easing = Easing

	function Easing.Linear(t) return t end
	function Easing.InQuad(t) return t * t end
	function Easing.OutQuad(t) return t * (2 - t) end
	function Easing.InOutQuad(t) return t < 0.5 and 2 * t * t or -1 + (4 - 2 * t) * t end
	function Easing.InCubic(t) return t * t * t end
	function Easing.OutCubic(t) local u = t - 1 return u * u * u + 1 end
	function Easing.InOutCubic(t) return t < 0.5 and 4 * t * t * t or (t - 1) * (2 * t - 2) * (2 * t - 2) + 1 end
	function Easing.InQuart(t) return t * t * t * t end
	function Easing.OutQuart(t) local u = t - 1 return 1 - u * u * u * u end
	function Easing.InOutQuart(t) return t < 0.5 and 8 * t * t * t * t or 1 - 8 * (t - 1) * (t - 1) * (t - 1) * (t - 1) end
	function Easing.InQuint(t) return t * t * t * t * t end
	function Easing.OutQuint(t) local u = t - 1 return 1 + u * u * u * u * u end
	function Easing.InOutQuint(t) return t < 0.5 and 16 * t * t * t * t * t or 1 + 16 * (t - 1) * (t - 1) * (t - 1) * (t - 1) * (t - 1) end
	function Easing.InSine(t) return 1 - cos(t * pi / 2) end
	function Easing.OutSine(t) return sin(t * pi / 2) end
	function Easing.InOutSine(t) return -(cos(pi * t) - 1) / 2 end
	function Easing.InExpo(t) return t == 0 and 0 or pow(2, 10 * (t - 1)) end
	function Easing.OutExpo(t) return t == 1 and 1 or 1 - pow(2, -10 * t) end

	function Easing.InOutExpo(t)
		if t == 0 then return 0 end
		if t == 1 then return 1 end
		return t < 0.5 and pow(2, 20 * t - 10) / 2 or (2 - pow(2, -20 * t + 10)) / 2
	end

	function Easing.InCirc(t) return 1 - sqrt(1 - t * t) end
	function Easing.OutCirc(t) local u = t - 1 return sqrt(1 - u * u) end

	function Easing.InOutCirc(t)
		return t < 0.5
			and (1 - sqrt(1 - (2 * t) * (2 * t))) / 2
			or (sqrt(1 - (-2 * t + 2) * (-2 * t + 2)) + 1) / 2
	end

	function Easing.InBack(t) local s = 1.70158 return t * t * ((s + 1) * t - s) end
	function Easing.OutBack(t) local s = 1.70158 local u = t - 1 return u * u * ((s + 1) * u + s) + 1 end

	function Easing.InOutBack(t)
		local s = 1.70158 * 1.525
		return t < 0.5
			and (2 * t) * (2 * t) * ((s + 1) * 2 * t - s) / 2
			or ((2 * t - 2) * (2 * t - 2) * ((s + 1) * (t * 2 - 2) + s) + 2) / 2
	end

	function Easing.InElastic(t)
		if t == 0 then return 0 end
		if t == 1 then return 1 end
		return -pow(2, 10 * t - 10) * sin((t * 10 - 10.75) * (2 * pi) / 3)
	end

	function Easing.OutElastic(t)
		if t == 0 then return 0 end
		if t == 1 then return 1 end
		return pow(2, -10 * t) * sin((t * 10 - 0.75) * (2 * pi) / 3) + 1
	end

	function Easing.InOutElastic(t)
		if t == 0 then return 0 end
		if t == 1 then return 1 end
		return t < 0.5
			and -(pow(2, 20 * t - 10) * sin((20 * t - 11.125) * (2 * pi) / 4.5)) / 2
			or (pow(2, -20 * t + 10) * sin((20 * t - 11.125) * (2 * pi) / 4.5)) / 2 + 1
	end

	function Easing.InBounce(t) return 1 - Easing.OutBounce(1 - t) end

	function Easing.OutBounce(t)
		if t < 1 / 2.75 then
			return 7.5625 * t * t
		elseif t < 2 / 2.75 then
			t -= 1.5 / 2.75
			return 7.5625 * t * t + 0.75
		elseif t < 2.5 / 2.75 then
			t -= 2.25 / 2.75
			return 7.5625 * t * t + 0.9375
		else
			t -= 2.625 / 2.75
			return 7.5625 * t * t + 0.984375
		end
	end

	function Easing.InOutBounce(t)
		return t < 0.5
			and (1 - Easing.OutBounce(1 - 2 * t)) / 2
			or (1 + Easing.OutBounce(2 * t - 1)) / 2
	end

	local function LerpValue(a, b, t, valueType)
		if valueType == "number" then
			return a + (b - a) * t
		elseif valueType == "Color3" then
			return a:Lerp(b, t)
		elseif valueType == "Vector2" then
			return a:Lerp(b, t)
		elseif valueType == "Vector3" then
			return a:Lerp(b, t)
		elseif valueType == "UDim2" then
			return UDim2.new(
				a.X.Scale + (b.X.Scale - a.X.Scale) * t,
				a.X.Offset + (b.X.Offset - a.X.Offset) * t,
				a.Y.Scale + (b.Y.Scale - a.Y.Scale) * t,
				a.Y.Offset + (b.Y.Offset - a.Y.Offset) * t
			)
		elseif valueType == "UDim" then
			return UDim.new(
				a.Scale + (b.Scale - a.Scale) * t,
				a.Offset + (b.Offset - a.Offset) * t
			)
		end
		return b
	end

	local function DetermineValueType(value)
		local t = typeof(value)
		if t == "number" or t == "Color3" or t == "Vector2" or t == "Vector3" or t == "UDim2" or t == "UDim" then
			return t
		end
		return nil
	end

	local function EnsureConnection()
		if _connection then
			return
		end
		if not RunService then
			return
		end
		_connection = RunService.Heartbeat:Connect(function(dt)
			dt = clamp(dt, 0.001, 0.05) -- Clamp dt: floor prevents div-by-zero, ceiling prevents physics explosions
			if _count == 0 then
				if _connection then
					_connection:Disconnect()
					_connection = nil
				end
				return
			end

			for handle, tween in _activeTweens do
				if tween.Paused then
					continue
				end
				tween.Elapsed += dt
				local progress = clamp(tween.Elapsed / tween.Duration, 0, 1)
				local easedProgress = tween.EasingFn(progress)

				for propName, propData in tween.Properties do
					local value = LerpValue(propData.Start, propData.Target, easedProgress, propData.ValueType)
					tween.Object[propName] = value
				end

				if progress >= 1 then
					_activeTweens[handle] = nil
					_count -= 1
					tween.Completed:Fire()
				end
			end

			for handle, spring in _activeSprings do
				local allSettled = true

				for propName, propData in spring.Properties do
					if propData.ValueType == "number" then
						local displacement = propData.Position - propData.Target
						local springForce = -spring.Stiffness * displacement
						local dampingForce = -spring.Damping * propData.Velocity
						local acceleration = springForce + dampingForce
						propData.Velocity += acceleration * dt
						propData.Position += propData.Velocity * dt
						spring.Object[propName] = propData.Position

						if abs(propData.Velocity) > EPSILON or abs(displacement) > EPSILON then
							allSettled = false
						end
					elseif propData.ValueType == "Color3" then
						local rDisp = propData.PositionR - propData.TargetR
						local gDisp = propData.PositionG - propData.TargetG
						local bDisp = propData.PositionB - propData.TargetB

						propData.VelocityR += (-spring.Stiffness * rDisp - spring.Damping * propData.VelocityR) * dt
						propData.VelocityG += (-spring.Stiffness * gDisp - spring.Damping * propData.VelocityG) * dt
						propData.VelocityB += (-spring.Stiffness * bDisp - spring.Damping * propData.VelocityB) * dt

						propData.PositionR += propData.VelocityR * dt
						propData.PositionG += propData.VelocityG * dt
						propData.PositionB += propData.VelocityB * dt

						spring.Object[propName] = Color3.new(
							clamp(propData.PositionR, 0, 1),
							clamp(propData.PositionG, 0, 1),
							clamp(propData.PositionB, 0, 1)
						)

						if abs(propData.VelocityR) > EPSILON or abs(rDisp) > EPSILON
							or abs(propData.VelocityG) > EPSILON or abs(gDisp) > EPSILON
							or abs(propData.VelocityB) > EPSILON or abs(bDisp) > EPSILON then
							allSettled = false
						end
					elseif propData.ValueType == "Vector2" then
						local xDisp = propData.PositionX - propData.TargetX
						local yDisp = propData.PositionY - propData.TargetY

						propData.VelocityX += (-spring.Stiffness * xDisp - spring.Damping * propData.VelocityX) * dt
						propData.VelocityY += (-spring.Stiffness * yDisp - spring.Damping * propData.VelocityY) * dt

						propData.PositionX += propData.VelocityX * dt
						propData.PositionY += propData.VelocityY * dt

						spring.Object[propName] = Vector2.new(propData.PositionX, propData.PositionY)

						if abs(propData.VelocityX) > EPSILON or abs(xDisp) > EPSILON
							or abs(propData.VelocityY) > EPSILON or abs(yDisp) > EPSILON then
							allSettled = false
						end
					elseif propData.ValueType == "UDim2" then
						local sxDisp = propData.PositionSX - propData.TargetSX
						local oxDisp = propData.PositionOX - propData.TargetOX
						local syDisp = propData.PositionSY - propData.TargetSY
						local oyDisp = propData.PositionOY - propData.TargetOY

						propData.VelocitySX += (-spring.Stiffness * sxDisp - spring.Damping * propData.VelocitySX) * dt
						propData.VelocityOX += (-spring.Stiffness * oxDisp - spring.Damping * propData.VelocityOX) * dt
						propData.VelocitySY += (-spring.Stiffness * syDisp - spring.Damping * propData.VelocitySY) * dt
						propData.VelocityOY += (-spring.Stiffness * oyDisp - spring.Damping * propData.VelocityOY) * dt

						propData.PositionSX += propData.VelocitySX * dt
						propData.PositionOX += propData.VelocityOX * dt
						propData.PositionSY += propData.VelocitySY * dt
						propData.PositionOY += propData.VelocityOY * dt

						spring.Object[propName] = UDim2.new(
							propData.PositionSX, propData.PositionOX,
							propData.PositionSY, propData.PositionOY
						)

						if abs(propData.VelocitySX) > EPSILON or abs(sxDisp) > EPSILON
							or abs(propData.VelocityOX) > EPSILON or abs(oxDisp) > EPSILON
							or abs(propData.VelocitySY) > EPSILON or abs(syDisp) > EPSILON
							or abs(propData.VelocityOY) > EPSILON or abs(oyDisp) > EPSILON then
							allSettled = false
						end
					end
				end

				if allSettled then
					for propName, propData in spring.Properties do
						if propData.ValueType == "number" then
							spring.Object[propName] = propData.Target
						elseif propData.ValueType == "Color3" then
							spring.Object[propName] = Color3.new(
								clamp(propData.TargetR, 0, 1),
								clamp(propData.TargetG, 0, 1),
								clamp(propData.TargetB, 0, 1)
							)
						elseif propData.ValueType == "Vector2" then
							spring.Object[propName] = Vector2.new(propData.TargetX, propData.TargetY)
						elseif propData.ValueType == "UDim2" then
							spring.Object[propName] = UDim2.new(propData.TargetSX, propData.TargetOX, propData.TargetSY, propData.TargetOY)
						end
					end
					_activeSprings[handle] = nil
					_count -= 1
					spring.Completed:Fire()
				end
			end
		end)
	end

	local TweenHandle = {}
	TweenHandle.__index = TweenHandle

	function TweenHandle:Cancel()
		if _activeTweens[self] then
			_activeTweens[self] = nil
			_count -= 1
		end
	end

	function TweenHandle:Pause()
		local tween = _activeTweens[self]
		if tween then
			tween.Paused = true
		end
	end

	function TweenHandle:Resume()
		local tween = _activeTweens[self]
		if tween then
			tween.Paused = false
		end
	end

	local SpringHandle = {}
	SpringHandle.__index = SpringHandle

	function SpringHandle:Cancel()
		if _activeSprings[self] then
			_activeSprings[self] = nil
			_count -= 1
		end
	end

	function SpringHandle:SetTarget(properties)
		local spring = _activeSprings[self]
		if not spring then
			return
		end
		for propName, target in properties do
			local propData = spring.Properties[propName]
			if propData then
				if propData.ValueType == "number" then
					propData.Target = target
				elseif propData.ValueType == "Color3" then
					propData.TargetR = target.R
					propData.TargetG = target.G
					propData.TargetB = target.B
				elseif propData.ValueType == "Vector2" then
					propData.TargetX = target.X
					propData.TargetY = target.Y
				elseif propData.ValueType == "UDim2" then
					propData.TargetSX = target.X.Scale
					propData.TargetOX = target.X.Offset
					propData.TargetSY = target.Y.Scale
					propData.TargetOY = target.Y.Offset
				end
			end
		end
	end

	function Animation.Tween(object, properties, duration, easingFn)
		Animation.CancelObject(object)
		easingFn = easingFn or Easing.OutQuad
		duration = duration or 0.2

		if type(easingFn) == "string" then
			easingFn = Easing[easingFn] or Easing.OutQuad
		end

		local tweenProps = {}
		for propName, target in properties do
			local current = object[propName]
			local valueType = DetermineValueType(current)
			if valueType then
				tweenProps[propName] = {
					Start = current,
					Target = target,
					ValueType = valueType,
				}
			end
		end

		local handle = setmetatable({ Completed = Signal.New() }, TweenHandle)
		local tween = {
			Object = object,
			Properties = tweenProps,
			Duration = duration,
			EasingFn = easingFn,
			Elapsed = 0,
			Paused = false,
			Completed = handle.Completed,
		}

		_activeTweens[handle] = tween
		_count += 1
		EnsureConnection()

		return handle
	end

	function Animation.Spring(object, properties, damping, stiffness)
		Animation.CancelObject(object)
		damping = damping or 26
		stiffness = stiffness or 300

		local springProps = {}
		for propName, target in properties do
			local current = object[propName]
			local valueType = DetermineValueType(current)
			if valueType == "number" then
				springProps[propName] = {
					ValueType = "number",
					Position = current,
					Target = target,
					Velocity = 0,
				}
			elseif valueType == "Color3" then
				springProps[propName] = {
					ValueType = "Color3",
					PositionR = current.R, PositionG = current.G, PositionB = current.B,
					TargetR = target.R, TargetG = target.G, TargetB = target.B,
					VelocityR = 0, VelocityG = 0, VelocityB = 0,
				}
			elseif valueType == "Vector2" then
				springProps[propName] = {
					ValueType = "Vector2",
					PositionX = current.X, PositionY = current.Y,
					TargetX = target.X, TargetY = target.Y,
					VelocityX = 0, VelocityY = 0,
				}
			elseif valueType == "UDim2" then
				springProps[propName] = {
					ValueType = "UDim2",
					PositionSX = current.X.Scale, PositionOX = current.X.Offset,
					PositionSY = current.Y.Scale, PositionOY = current.Y.Offset,
					TargetSX = target.X.Scale, TargetOX = target.X.Offset,
					TargetSY = target.Y.Scale, TargetOY = target.Y.Offset,
					VelocitySX = 0, VelocityOX = 0, VelocitySY = 0, VelocityOY = 0,
				}
			end
		end

		local handle = setmetatable({ Completed = Signal.New() }, SpringHandle)
		local spring = {
			Object = object,
			Properties = springProps,
			Damping = damping,
			Stiffness = stiffness,
			Completed = handle.Completed,
		}

		_activeSprings[handle] = spring
		_count += 1
		EnsureConnection()

		return handle
	end

	function Animation.CancelAll()
		clear(_activeTweens)
		clear(_activeSprings)
		_count = 0
		if _connection then
			_connection:Disconnect()
			_connection = nil
		end
	end

	function Animation.CancelObject(object)
		for handle, tween in _activeTweens do
			if tween.Object == object then
				_activeTweens[handle] = nil
				_count -= 1
			end
		end
		for handle, spring in _activeSprings do
			if spring.Object == object then
				_activeSprings[handle] = nil
				_count -= 1
			end
		end
	end

	function Animation.GetActiveCount()
		return _count
	end

	function Animation.Destroy()
		Animation.CancelAll()
	end

	return Animation
end
