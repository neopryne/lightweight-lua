
--[[

	LIBZHL_API AugmentBlueprint *GetAugmentBlueprint(const std::string &name);
	LIBZHL_API float GetAugmentValue(const std::string &name);
	LIBZHL_API std::vector<std::string> GetBlueprintList(const std::string &name);
	LIBZHL_API CrewBlueprint GetCrewBlueprint(const std::string &name);
	LIBZHL_API std::string GetCrewName(bool *isMale_ret);
	LIBZHL_API DroneBlueprint *GetDroneBlueprint(const std::string &name);
	LIBZHL_API ItemBlueprint *GetItemBlueprint(const std::string &name);
	LIBZHL_API std::vector<AugmentBlueprint*> GetRandomAugment(int count, bool demo_lock);
	LIBZHL_API std::vector<DroneBlueprint*> GetRandomDrone(int count, bool demo_lock);
	LIBZHL_API std::vector<WeaponBlueprint*> GetRandomWeapon(int count, bool demo_lock);
	LIBZHL_API ShipBlueprint *GetShipBlueprint(const std::string &name, int sector);
	LIBZHL_API static GL_Texture *__stdcall GetSkillIcon(int skill, bool outline);
	LIBZHL_API SystemBlueprint *GetSystemBlueprint(const std::string &name);
	LIBZHL_API std::string GetUnusedCrewName(bool *isMale_ret);
	LIBZHL_API WeaponBlueprint *GetWeaponBlueprint(const std::string &name);
	LIBZHL_API Description ProcessDescription(rapidxml::xml_node<char> *node);
	LIBZHL_API DroneBlueprint ProcessDroneBlueprint(rapidxml::xml_node<char> *node);
	LIBZHL_API EffectsBlueprint ProcessEffectsBlueprint(rapidxml::xml_node<char> *node);
	LIBZHL_API ShipBlueprint ProcessShipBlueprint(rapidxml::xml_node<char> *node);
	LIBZHL_API WeaponBlueprint ProcessWeaponBlueprint(rapidxml::xml_node<char> *node);
	LIBZHL_API void ResetRarities();
	LIBZHL_API void SetRarity(const std::string &name, int rarity);
	
	int rarityTotal;
	std::map<std::string, ShipBlueprint> shipBlueprints;
	std::map<std::string, WeaponBlueprint> weaponBlueprints;
	std::map<std::string, DroneBlueprint> droneBlueprints;
	std::map<std::string, AugmentBlueprint> augmentBlueprints;
	std::map<std::string, CrewBlueprint> crewBlueprints;
	std::map<std::string, bool> nameList;
	std::map<std::string, std::string> shortNames;
	std::map<std::string, std_map_std_string_bool> languageNameLists;
	std::map<std::string, ItemBlueprint> itemBlueprints;
	std::map<std::string, SystemBlueprint> systemBlueprints;
	std::map<std::string, std::vector<std::string>> blueprintLists;
	std::vector<std::string> currentNames;

]]

--[[
metavar table of all the things that you've seen
It's all the guns/crew names.
Then pass the list of things you know about to this API
Ones that don't exist are ignored safely.

The downside of this is you don't get to see what you're missing, and it's hard to tell when you've found new stuff.
I can make flags for when you have things you haven't looked at in the catalogue.
]]