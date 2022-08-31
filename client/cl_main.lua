local ESX = nil;
local menuPool = NativeUI.CreatePool();
local isMenuOpen = false;

local function OpenMenu()
    ESX.TriggerServerCallback("ngJobphone:GetPhoneInfo", function(info)
		if info == nil then
			-- no phone associated with current job
			return;
		end
		
		local mainMenu = NativeUI.CreateMenu(_U("menu_title"), _U("menu_subtitle"));
		menuPool:Clear();
		menuPool:Add(mainMenu);
		collectgarbage();
	
		if info.occupiedBy ~= nil then
			local occupiedBy = NativeUI.CreateItem(_U("occupied_by", info.occupiedBy.name), "");
			occupiedBy:SetLeftBadge(BadgeStyle.Tick)
			mainMenu:AddItem(occupiedBy);
		else
			local notOccupied = NativeUI.CreateItem(_U("not_occupied"), "");
			notOccupied:SetLeftBadge(BadgeStyle.Alert)
			mainMenu:AddItem(notOccupied);
        end
		
		local takePhone = NativeUI.CreateItem(_U("take_phone"), "");
		takePhone:RightLabel('~b~→→→');
		mainMenu:AddItem(takePhone);
		
		local returnPhone = NativeUI.CreateItem(_U("return_phone"), "");
		returnPhone:RightLabel('~b~→→→');
		mainMenu:AddItem(returnPhone);
		
		mainMenu.OnItemSelect = function(sender, item, index)
			if item == takePhone then
				ESX.TriggerServerCallback("ngJobphone:TakePhone", function(success)
					if success then
						ESX.ShowNotification(_U("take_phone_success"));
					else
						ESX.ShowNotification(_U("take_phone_error"));
					end
				end);
				menuPool:CloseAllMenus();
			elseif item == returnPhone then
				ESX.TriggerServerCallback("ngJobphone:ReturnPhone", function(success)
					if success then
						ESX.ShowNotification(_U("return_phone_success"));
					else
						ESX.ShowNotification(_U("return_phone_error"));
					end
				end);
				menuPool:CloseAllMenus();
			end
		end

		mainMenu:Visible(true);
		isMenuOpen = true;

		menuPool:MouseControlsEnabled(false);
		menuPool:MouseEdgeEnabled(false);
		menuPool:RefreshIndex();
    end);
end

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) 
			ESX = obj 
		end)        
		Citizen.Wait(100)
	end
end)


--Command-function
if Config.Command ~= nil then
    RegisterCommand(Config.Command, function(source, args)
		OpenMenu()
    end, false)
end

--Hotkey-function
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		if Config.Key ~= nil then
			if IsControlJustReleased(0, Config.Key) then
				OpenMenu();
			end
		end
		menuPool:ProcessMenus();
	end
end)