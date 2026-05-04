local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/taaaaaze/archive.wtf/main/UI/Library.lua"))()

-- Initialize the library
Library.Init({
    Theme = "Dark",
    ToggleKey = Enum.KeyCode.RightShift,
    UseLucideIcons = true -- Automatically downloads and maps the font using AssetManager
})

-- Create the main window
local Window = Library.CreateWindow({
    Title = "TAURUS",
    Size = UDim2.fromOffset(650, 450)
})

-- Create some basic tabs
local AimbotTab = Window:CreateTab({ 
    Name = "Aimbot", 
    Icon = "rbxassetid://6031225815" -- Example icon ID, could also use a Lucide char if we mapped it 
})

local VisualsTab = Window:CreateTab({ 
    Name = "Visuals", 
    Icon = "rbxassetid://6031763426" 
})

local SettingsTab = Window:CreateTab({ 
    Name = "Settings", 
    Icon = "rbxassetid://6031265976" 
})

-- Notify the user it loaded successfully
print("TAURUS UI Base Loaded Successfully")
