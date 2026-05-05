local function LoadAcrylic()
	local GuiSystem = {};

	local Twen = game:GetService('TweenService');
	local RunService = game:GetService('RunService');
	local CurrentCamera = workspace.CurrentCamera;

	function GuiSystem:Hash()
		return string.reverse(string.gsub(game:GetService('HttpService'):GenerateGUID(false),'..',function(aa)
			return string.reverse(aa)
		end))
	end

	local function Hiter(planePos, planeNormal, rayOrigin, rayDirection)
		local n = planeNormal
		local d = rayDirection
		local v = rayOrigin - planePos

		local num = (n.x*v.x) + (n.y*v.y) + (n.z*v.z)
		local den = (n.x*d.x) + (n.y*d.y) + (n.z*d.z)
		local a = -num / den

		return rayOrigin + (a * rayDirection), a;
	end;

	function GuiSystem.new(frame,NoAutoBackground)
		local Part = Instance.new('Part',workspace);
		local DepthOfField = Instance.new('DepthOfFieldEffect',game:GetService('Lighting'));
		local SurfaceGui = Instance.new('SurfaceGui',Part);
		local BlockMesh = Instance.new("BlockMesh");

		BlockMesh.Parent = Part;

		Part.Material = Enum.Material.Glass;
		Part.Transparency = 1;
		Part.Reflectance = 1;
		Part.CastShadow = false;
		Part.Anchored = true;
		Part.CanCollide = false;
		Part.CanQuery = false;
		Part.CollisionGroup = GuiSystem:Hash();
		Part.Size = Vector3.new(1, 1, 1) * 0.01;
		Part.Color = Color3.fromRGB(0,0,0);

		Twen:Create(Part,TweenInfo.new(1,Enum.EasingStyle.Quint,Enum.EasingDirection.In),{
			Transparency = 0.8;
		}):Play()

		DepthOfField.Enabled = true;
		DepthOfField.FarIntensity = 1;
		DepthOfField.FocusDistance = 0;
		DepthOfField.InFocusRadius = 500;
		DepthOfField.NearIntensity = 1;

		SurfaceGui.AlwaysOnTop = true;
		SurfaceGui.Adornee = Part;
		SurfaceGui.Active = true;
		SurfaceGui.Face = Enum.NormalId.Front;
		SurfaceGui.ZIndexBehavior = Enum.ZIndexBehavior.Global;

		DepthOfField.Name = GuiSystem:Hash();
		Part.Name = GuiSystem:Hash();
		SurfaceGui.Name = GuiSystem:Hash();

		local C4 = {
			Update = nil,
			Collection = SurfaceGui,
			Enabled = true,
			Instances = {
				BlockMesh = BlockMesh,
				Part = Part,
				DepthOfField = DepthOfField,
				SurfaceGui = SurfaceGui,
			},
			Signal = nil
		};

			-- Cache state to avoid redundant work
		local lastPos = Vector2.zero
		local lastSize = Vector2.zero
		local lastCamCF = CFrame.new()
		local qualityCheckTimer = 0
		local INSET = 4

		local Update = function(dt)
			dt = dt or 0

			-- Only check quality every 2 seconds instead of every frame
			qualityCheckTimer += dt
			if qualityCheckTimer >= 2 then
				qualityCheckTimer = 0
				pcall(function()
					local userSettings = UserSettings():GetService("UserGameSettings")
					local qualityLevel = userSettings.SavedQualityLevel.Value
					local targetTransparency = qualityLevel < 8 and 1 or 0.8
					if Part.Transparency ~= targetTransparency then
						Twen:Create(Part,TweenInfo.new(1,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{
							Transparency = targetTransparency;
						}):Play()
					end
				end)
			end

			-- Skip mesh recalculation if frame hasn't moved or resized and camera is the same
			local curPos = frame.AbsolutePosition
			local curSize = frame.AbsoluteSize
			local camCF = CurrentCamera.CFrame
			if curPos == lastPos and curSize == lastSize and camCF == lastCamCF then
				return
			end
			lastPos = curPos
			lastSize = curSize
			lastCamCF = camCF

			local corner0 = curPos + Vector2.new(INSET, INSET);
			local corner1 = curPos + curSize - Vector2.new(INSET, INSET);

			local ray0 = CurrentCamera:ScreenPointToRay(corner0.X, corner0.Y, 1);
			local ray1 = CurrentCamera:ScreenPointToRay(corner1.X, corner1.Y, 1);

			local lookVector = camCF.LookVector
			local planeOrigin = camCF.Position + lookVector * (0.05 - CurrentCamera.NearPlaneZ);

			local pos0 = Hiter(planeOrigin, lookVector, ray0.Origin, ray0.Direction);
			local pos1 = Hiter(planeOrigin, lookVector, ray1.Origin, ray1.Direction);

			pos0 = camCF:PointToObjectSpace(pos0);
			pos1 = camCF:PointToObjectSpace(pos1);

			local size   = pos1 - pos0;
			local center = (pos0 + pos1) / 2;

			BlockMesh.Offset = center
			BlockMesh.Scale  = size / 0.0101;
			Part.CFrame = camCF;
		end

		C4.Update = Update;
		C4.Signal = RunService.RenderStepped:Connect(Update);

		pcall(function()
			C4.Signal2 = CurrentCamera:GetPropertyChangedSignal('CFrame'):Connect(function()
				Part.CFrame = CurrentCamera.CFrame;
			end);
		end)

		C4.Destroy = function()
			C4.Signal:Disconnect();
			if C4.Signal2 then C4.Signal2:Disconnect(); end
			C4.Update = function() end;

			Twen:Create(Part,TweenInfo.new(1),{
				Transparency = 1
			}):Play();

			DepthOfField:Destroy();
			Part:Destroy()
		end;

		return C4;
	end;

	return GuiSystem;
end

return LoadAcrylic()
