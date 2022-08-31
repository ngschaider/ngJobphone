Config = {}

Config.Locale = 'en'

-- adjust command (default: "jobphone")
-- there will not be a command available if this is set to nil
Config.Command = "jobphone";

-- Hotkey to open the menu (default: 314, this corresponds to NUM+)
-- there will not be a hotkey if this is set to nil
Config.Key = 314

Config.Phones = {
	{
		phone_number = 911,
		job = "police",
	},
	{
		phone_number = 912,
		job = "ambulance",
	},
	{
		phone_number = 913,
		job = "lsfd",
	},
	{
		phone_number = 5555555,
		job = "taxi",
	},
		{
		phone_number = 922,
		job = "sheriff",
	},
}
