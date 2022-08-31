local ESX = nil;

TriggerEvent('esx:getSharedObject', function(obj) 
	ESX = obj 
end)

function getContacts(identifier)
    local result = MySQL.Sync.fetchAll("SELECT phone_users_contacts.* FROM phone_users_contacts WHERE phone_users_contacts.identifier = @identifier", {
        ['@identifier'] = identifier
    })
    return result
end

local function UpdatePhone(identifier, phoneNumber)
	local xPlayer = ESX.GetPlayerFromIdentifier(identifier);
	
	if not xPlayer then
		return;
	end
	
    local contacts = MySQL.Sync.fetchAll("SELECT phone_users_contacts.* FROM phone_users_contacts WHERE phone_users_contacts.identifier = @identifier", {
        ['@identifier'] = identifier,
    });
	local messages = MySQL.Sync.fetchAll("SELECT phone_messages.*, users.phone_number FROM phone_messages LEFT JOIN users ON users.identifier = @identifier WHERE phone_messages.receiver = users.phone_number", {
         ['@identifier'] = identifier,
    });
	TriggerClientEvent("gcPhon:updatePhone", xPlayer.playerId, phoneNumber, contacts, messages);
end

local function GetPhoneNumber(identifier, cb)
	MySQL.Async.fetchAll('SELECT * FROM users WHERE identifier = @identifier', {
		['@identifier'] = identifier
	}, function(results)
		if #results > 0 then
			cb(results[1].phone_number);
		else
			cb(nil);
		end
	end);
end

local function SetPhoneNumber(identifier, phoneNumber, cb)
	MySQL.Async.execute('UPDATE users SET phone_number = @phoneNumber WHERE identifier = @identifier', {
		['@identifier'] = identifier,
		['@phoneNumber'] = phoneNumber,
	}, function()
		UpdatePhone(identifier, phoneNumber);
		cb();
	end);
end

local function GetPhone(job, cb)
	--[[
	MySQL.Async.fetchAll("SELECT * FROM ngJobphone_phones WHERE job = @job", {
		["@job"] = xPlayer.getJob().name,
	}, function(phones)
		cb(phones)
	end);
	]]--
	
	for k,v in pairs(Config.Phones) do
		if v.job == job then
			cb(v);
			return;
		end
	end
	
	cb(nil);
end

local function GetPhoneInfo(src, cb) 
	local xPlayer = ESX.GetPlayerFromId(src);
	
	local job = xPlayer.getJob().name;
	GetPhone(job, function(phone)
		if not phone then
			cb(nil);
			return;
		end
		
		MySQL.Async.fetchAll("SELECT * FROM ng_jobphone WHERE job = @job", {
			["@job"] = job,
		}, function(results)
			if #results > 0 then
				local xOccupiedPlayer = ESX.GetPlayerFromIdentifier(results[1].identifier);
				if xOccupiedPlayer then
					cb({
						name = xPlayer.getJob().label,
						phoneNumber = phone.phone_number,
						occupiedBy = {
							identifier = xOccupiedPlayer.identifier,
							name = xOccupiedPlayer.getName(),
							phoneNumber = results[1].phone_number,
						}
					});
				else
					MySQL.Async.fetchAll("SELECT firstname, lastname FROM users WHERE identifier=@identifier", {
						["@identifier"] = results[1].identifier,
					}, function(res)
						cb({
						name = xPlayer.getJob().label,
						phoneNumber = phone.phone_number,
						occupiedBy = {
							identifier = results[1].identifier,
							name = res[1].firstname .. " " .. res[1].lastname,
							phoneNumber = results[1].phone_number,
						}
					});
					end);
				end
			else
				cb({
					name = xPlayer.getJob().label,
					phoneNumber = phone.phone_number,
					occupiedBy = nil,
				});
			end
		end);
	end);
end
ESX.RegisterServerCallback("ngJobphone:GetPhoneInfo", GetPhoneInfo);

--[[RegisterNetEvent("playerDropped", function(reason)
	local xPlayer = ESX.GetPlayerFromId(source);
	MySQL.Async.execute("DELETE FROM ng_jobphone WHERE identifier = @identifier", {
		["@identifier"] = xPlayer.identifier,
	});
end)]]--

local function TakePhone(src, cb)
	local xPlayer = ESX.GetPlayerFromId(src);
	
	GetPhoneInfo(src, function(info)
		if info == nil then
			-- no phone found for job
			cb(false);
			return;
		end
		
		if info.occupiedBy ~= nil then
			-- phone already occupied
			xPlayer.showNotification(_U("already_occupied"));
			--cb(false);
			return;
		end
	
		GetPhoneNumber(xPlayer.identifier, function(phoneNumber)
			MySQL.Sync.execute('INSERT INTO ng_jobphone (identifier, phone_number, job) VALUES (@identifier, @phoneNumber, @job)', {
				['@identifier'] = xPlayer.identifier,
				['@phoneNumber'] = phoneNumber,
				['@job'] = xPlayer.getJob().name,
			});
			
			SetPhoneNumber(xPlayer.identifier, info.phoneNumber, function()
				xPlayer.showNotification(_U("new_number", info.phoneNumber));
				cb(true);
			end);
		end);
	end);
end
ESX.RegisterServerCallback("ngJobphone:TakePhone", TakePhone);

local function ReturnPhone(src, cb)
	local xPlayer = ESX.GetPlayerFromId(src);

	GetPhoneInfo(src, function(info)
		if info == nil then
			-- no phone found
			cb(false);
			return;
		end
		
		if info.occupiedBy == nil then
			xPlayer.showNotification(_U("not_occupied"));
			cb(false);
			return;
		end
		
		SetPhoneNumber(info.occupiedBy.identifier, info.occupiedBy.phoneNumber, function()
			MySQL.Async.execute("DELETE FROM ng_jobphone WHERE identifier = @identifier", {
				["@identifier"] = info.occupiedBy.identifier
			}, function()
				local xOccupiedPlayer = ESX.GetPlayerFromIdentifier(info.occupiedBy.identifier);
				if xOccupiedPlayer then
					xOccupiedPlayer.showNotification(_U("new_number", info.occupiedBy.phoneNumber));
				end
				cb(true);
			end);
		end);
	end);
end
ESX.RegisterServerCallback("ngJobphone:ReturnPhone", ReturnPhone);