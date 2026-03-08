

--[[
A 3ray is a data structure described here https://www.youtube.com/watch?v=L4xOCvELWlU
It has three arrays, taking 3n space to vastly improve the speed of operations.

Removal is much cheaper, so it uses swap&pop.  Only the data gets things actually popped, the other two arrays never shrink.




No, maid sylvan is like skateboarding maid.  Or that maid guy.  Anyway he's really into it and 
- You _will_ be clean.

Maid sylvan determines that your ship is filthy, and has like a royal purifier and a hull repair beam.
Loose hard enough and he'll surrender.

Maid sylvan is looking for things to clean.  If you are damaged, he will fight you to fix your ship.  You have an option to intentionally damage your ship to attract him.
Hull repair beams, can't fight, not targetable, negative sabotage speed.


Maid Sylvan is also the Maid of Sylvan: he will fix things by using sylvan.  As such, he has access to the combined powers of all sylvans, and can summon them when it's useful.
Has an active ability that will summon a temporary random Sylvan to aid you.


As you enter the beacon, you can't help but notice everything seems... Brighter, somehow.  Like a film you didn't realize existed was lifted from the world.

In the distance, an incredibly pink ship with a shocking array of drones attending to it is bustling about.

    Hail the strange ship
        You open comms with the vessel, and are greeted by Sylvan in a french maid outfit.
        "Hello, Ssssstranger, you are just in time for tea!" --scrap gift, offer to help store some of the detritus he's been clearing.

            Damage your ship
                Deal some system damage, then proceed to the continue.
            Continue...
                It's a fight!  Sylvan will attack you until your ship is in perfect condition.
            Roomba: your roomba greets sylvan
                Sylvan offers to come on board, and gives you an amphi repair drone.
    storage check


--Enemy hull repair drone.  It's a hull repair drone that goes on the enemy ship.
Adds the enemy hull repair drone.

A Roomba is a maid who sweeps.  If you have the Roomba, you can immediately recruit maid sylvan ~~and he will ride it like horse jerry.~~
    I do not have the art skills to do this.
    LIST_CREW_MORPH_ROOMBA

Maid sylvan has blue options with a skateboard and totally destroyed that parking lot.
Maid sylvan is all about the blue options, and will give you all the sylvan blue options (that help)
    There are not that many blue options for sylvan.

Ok, I'm not actually sure if I want to do a fight to heal you, or just an event heal.
Event first I guess, as getting this out fast is important.

Maid Sylvan Crewser, and lots of blue option changes.
TODO ship unlock, amphi repair drones, I think I should give the player version a purifier they can't run.
Oh, this old thing?  I just like how it looks on my ship.

Do you think you have what it takes to be a maid? (maid challenge)

idk how to make an other healing drone.

<droneBlueprint name="SHIP_REPAIR">
	<type>SHIP_REPAIR</type>
	<tip>tip_crew</tip>
	<title>Hull Repair</title>
	<short>Hull Repair</short>
	<desc>Automatically repairs 3-5 damage to your hull. Drone part is consumed once it finishes.</desc>
	<power>2</power>
	<cooldown>1000</cooldown>
	<!-- Doesn't effect repair drone -->
	<dodge>0</dodge>
	<speed>20</speed>
	<!-- Change this to increase/decrease firing speed -->
	<cost>85</cost>
	<!--was 100-->
	<bp>5</bp>
	<droneImage>drone_shiprepair</droneImage>
	<image>weapons/laser_light2_strip4.png</image>
	<rarity>0</rarity>
	<iconImage>Srepair</iconImage>
</droneBlueprint>


<droneBlueprint name="AMPHI_COMBAT">
	<type>COMBAT</type>
	<tip>tip_toggle_amphi</tip>
	<title>Amphi-Drone [Combat]</title>
	<short>Amphi [C]</short>
	<desc>[CURRENT MODE: Combat] A special toggle drone that can switch between Combat and Defense modes.</desc>
	<power>2</power>
	<cooldown>1000</cooldown>
	<dodge>0</dodge>
	<speed>14</speed>
	<cost>60</cost>
	<bp>3</bp>
	<droneImage>drone_amphi_c</droneImage>
	<weaponBlueprint>DRONE_LASER</weaponBlueprint>
	<rarity>0</rarity>
	<iconImage>combat</iconImage>
</droneBlueprint>

<droneBlueprint name="AMPHI_DEFENSE">
	<type>DEFENSE</type>
	<level>1</level>
	<tip>tip_toggle_amphi</tip>
	<title>Amphi-Drone [Defense]</title>
	<short>Amphi [D]</short>
	<desc>[CURRENT MODE: Defense] A special toggle drone that can switch between Combat and Defense modes.
	Reload: 1100 MS</desc>
	<power>2</power>
	<cooldown>1100</cooldown>
	<dodge>0</dodge>
	<speed>7</speed>
	<cost>60</cost>
	<bp>2</bp>
	<droneImage>drone_amphi_d</droneImage>
	<weaponBlueprint>DRONE_LASER_DEFENSE</weaponBlueprint>
	<iconImage>defense</iconImage>
	<rarity>3</rarity>
</droneBlueprint>


]]