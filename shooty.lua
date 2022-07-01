-- title:  shooty
-- author: Abiko
-- desc:   short description
-- script: lua

--system constants
t=0
gt=0 --tics elapsed in current life
debug=false --enable dev barf?
markTime=false

--control aliases
PAD_UP=0
PAD_DOWN=1
PAD_LEFT=2
PAD_RIGHT=3
BUTTON_A=4
BUTTON_B=5
BUTTON_X=6
BUTTON_Y=7
--colour aliases 
BLACK=0
PURPLE=1
RED=2
ORANGE=3
YELLOW=4
LIGHT_GREEN=5
GREEN=6
DARK_GREEN=7
DARK_BLUE=8
BLUE=9
LIGHT_BLUE=10
CYAN=11
WHITE=12
LIGHT_GREY=13
GREY=14
DARK_GREY=15
--sprite aliases
SPR_PLAYER_UP=256
SPR_PLAYER_DOWN=257
SPR_PLAYER_LEFT=258
SPR_PLAYER_RIGHT=259
SPR_MONSTER=260
SPR_AMMO_BOX=272
SPR_SPAWN_SPARK=288
SPR_AGGRO_SPARK=304
--sound aliases
GUNFIRE=0
CLICK=1
LOW_AMMO=2 --note: E-6
PICKUP=3 --note: F#4
--facing aliases
UP=0
DOWN=1
LEFT=2
RIGHT=3
--posit aliases
BRAZIL=-255

--muzzle offsets
MUZZLE_UP_X=4
MUZZLE_UP_Y=0
MUZZLE_DOWN_X=4
MUZZLE_DOWN_Y=8
MUZZLE_LEFT_X=0
MUZZLE_LEFT_Y=4
MUZZLE_RIGHT_X=8
MUZZLE_RIGHT_Y=4

player={--initial player stats
 aimLock=false,
 facing=0,
 ammo=500,
 kills=0,
 width=5,
 height=5,
 posit={
  x=120,
  y=68
 }
}

pickup={--initial stats of the ammo box
 active=false,
 width=5,
 height=5,
 posit={
  x=BRAZIL,
  y=BRAZIL
 }
}
----

--blank tables, kitchen sink
bullet={}
monster={}
spawnSpark={}
aggroSpark={}
score=0
seconds=0
minutes=0
hours=0
hasBeenWarned=false
initialised=false

function TIC() --called 60 times per second
 if initialised==false then
  initialise()
 end
 t=t+1 --master timer
 clock() --turn tick counter into people time
 cls(0) --screen refresh
 borderWatch() --keep player in bounds
 drawPlayer()
 drawBullet()
 drawMonster()
 drawItems()
 drawSparks()
 drawHUD()
 if not markTime==true then
  gt=gt+1
  cullEntities() --remove bullets that hit edges or monsters, items that get taken, and monsters that get shot or wander off
  updateBullet() --move bullets
  updateMonster()--move beasts
  updateSparks() --delete sparks as needed
  checkBulletCollision()
  checkPlayerCollision()
  cullEntities() --do it twice per tic to be certain nothing outruns physics
  if nextSpawn<=t and math.random(16)==1 then spawnController() end
  end
 sniffControls() --accept input
 if debug==true then debugHUD() end
end

function clock()
  if t%60==0 then seconds=seconds+1 end
  if seconds==60 then
    seconds=0
    minutes=minutes+1
  end
  if minutes==60 then
    hours=minutes+1
    minutes=0
  end
end

----
function borderWatch() --keep player in bounds
 if player.posit.x<=0 then player.posit.x=1 end
 if player.posit.x>=233 then player.posit.x=232 end
 if player.posit.y<=0 then player.posit.y=1 end
 if player.posit.y>=129 then player.posit.y=128 end
end
----
function sniffControls()
 if btn(BUTTON_X) then player.aimLock=true else player.aimLock=false end
 if btnp(BUTTON_A,0,4) and player.ammo>0 then shoot() end
 if btnp(BUTTON_A,5,60) and player.ammo<1 then sfx(CLICK,'D-3',6,0,15,0) end
 if btn(BUTTON_B) and debug==true then banish() end
 if btn(BUTTON_Y) and debug==true then rearm() end
 if btn(PAD_UP) then
  player.posit.y=player.posit.y-1
  if not player.aimLock then player.facing=0 end
 end
 if btn(PAD_DOWN) then
  player.posit.y=player.posit.y+1
  if not player.aimLock then player.facing=1 end
 end
 if btn(PAD_LEFT) then
  player.posit.x=player.posit.x-1
  if not player.aimLock then player.facing=2 end
 end
 if btn(PAD_RIGHT) then
  player.posit.x=player.posit.x+1
  if not player.aimLock then player.facing=3 end
 end
end
----
function shoot()
 for cb=1, 16 do
  if bullet[cb].active==true then end
  if not bullet[cb].active==true then
   bullet[cb].active=true
   bullet[cb].outOfBounds=false
   bullet[cb].velocity=4
   bullet[cb].facing=player.facing
   if player.facing==UP then
    bullet[cb].posit.x=(player.posit.x+MUZZLE_UP_X)
    bullet[cb].posit.y=(player.posit.y+MUZZLE_UP_Y)
   end
   if player.facing==DOWN then
    bullet[cb].posit.x=(player.posit.x+MUZZLE_DOWN_X)
    bullet[cb].posit.y=(player.posit.y+MUZZLE_DOWN_Y)
   end
   if player.facing==LEFT then
    bullet[cb].posit.x=(player.posit.x+MUZZLE_LEFT_X)
    bullet[cb].posit.y=(player.posit.y+MUZZLE_LEFT_Y)
   end
   if player.facing==RIGHT then
    bullet[cb].posit.x=(player.posit.x+MUZZLE_RIGHT_X)
    bullet[cb].posit.y=(player.posit.y+MUZZLE_RIGHT_Y)
   end
   player.ammo=player.ammo-1
   sfx(GUNFIRE,'C-1',4,0,15,0)
   break
  end
 end
end
----
function drawBullet()
 for cb=1, 16 do
  if bullet[cb].facing==UP then
  line(bullet[cb].posit.x,bullet[cb].posit.y,bullet[cb].posit.x,bullet[cb].posit.y-bullet[cb].length,bullet[cb].colour)
  end
  if bullet[cb].facing==DOWN then
  line(bullet[cb].posit.x,bullet[cb].posit.y,bullet[cb].posit.x,bullet[cb].posit.y+bullet[cb].length,bullet[cb].colour)
  end
  if bullet[cb].facing==LEFT then
  line(bullet[cb].posit.x,bullet[cb].posit.y,bullet[cb].posit.x-bullet[cb].length,bullet[cb].posit.y,bullet[cb].colour)
  end
  if bullet[cb].facing==RIGHT then
  line(bullet[cb].posit.x,bullet[cb].posit.y,bullet[cb].posit.x+bullet[cb].length,bullet[cb].posit.y,bullet[cb].colour)
  end
 end
end

----
function drawPlayer()
 if player.facing==UP then 
  spr(SPR_PLAYER_UP,player.posit.x,player.posit.y,0,1,0,0,1,1)
 elseif player.facing==DOWN then 
  spr(SPR_PLAYER_DOWN,player.posit.x,player.posit.y,0,1,0,0,1,1)
 elseif player.facing==LEFT then 
  spr(SPR_PLAYER_LEFT,player.posit.x,player.posit.y,0,1,0,0,1,1)
 elseif player.facing==RIGHT then 
  spr(SPR_PLAYER_RIGHT,player.posit.x,player.posit.y,0,1,0,0,1,1)
 end
end
----
function drawMonster()
  for cm=1, 16 do
    rect(monster[cm].posit.x,monster[cm].posit.y,monster[cm].width,monster[cm].height,monster[cm].colour)
  end
end

function updateBullet()
 for cb=1, 16 do
  if bullet[cb].facing==UP and bullet[cb].active==true then
    bullet[cb].posit.y=bullet[cb].posit.y-bullet[cb].velocity
  elseif bullet[cb].facing==DOWN and bullet[cb].active==true then
    bullet[cb].posit.y=bullet[cb].posit.y+bullet[cb].velocity
  elseif bullet[cb].facing==LEFT and bullet[cb].active==true then
    bullet[cb].posit.x=bullet[cb].posit.x-bullet[cb].velocity
  elseif bullet[cb].facing==RIGHT and bullet[cb].active==true then
    bullet[cb].posit.x=bullet[cb].posit.x+bullet[cb].velocity
  end
  if bullet[cb].posit.x>239 then
     bullet[cb].outOfBounds=true
  end
  if bullet[cb].posit.x<0 then
    bullet[cb].outOfBounds=true
  end
  if bullet[cb].posit.y>139 then
    bullet[cb].outOfBounds=true
  end
  if bullet[cb].posit.y<0 then
     bullet[cb].outOfBounds=true
  end
 end
end
----
function cullEntities() --remove bullets that hit edges or monsters, and monsters that get shot or wander off
 for cb=1, 16 do
   if bullet[cb].active==true and bullet[cb].outOfBounds==true then
    bullet[cb].posit.x=BRAZIL                                      
    bullet[cb].posit.y=BRAZIL                                      
    bullet[cb].velocity=0
    bullet[cb].active=false
    bullet[cb].outOfBounds=false
   end
  if bullet[cb].hit==true then
    bullet[cb].posit.x=BRAZIL
    bullet[cb].posit.y=BRAZIL
    bullet[cb].velocity=0
    bullet[cb].active=false
    bullet[cb].outOfBounds=false
    bullet[cb].hit=false
   end
 end
 for cm=1, 16 do
  if monster[cm].outOfBounds==true and monster[cm].alive==true then
   monster[cm].posit.x=(BRAZIL-255)
   monster[cm].posit.y=(BRAZIL-255)
   monster[cm].alive=false
   monster[cm].aggro=false
  break end
  if monster[cm].hit==true then
    if gt>monster[cm].wakeUpTic and pickup.active==false and math.random(0,3)==0 then --25% chance to drop the ammo box if a red monster is shot (only active ones can drop to keep them off the monster spawns)
     pickup.active=true
     pickup.posit.x = monster[cm].posit.x
     pickup.posit.y = monster[cm].posit.y
    end
    monster[cm].posit.x=(BRAZIL-255) --keeping inactive beasts and bullets separate shouldn't matter
    monster[cm].posit.y=(BRAZIL-255) --if you're only checking collision between active entities.
    monster[cm].alive=false          --Collision here is cursed enough without being that specific, though.
    monster[cm].hit=false
    monster[cm].aggro=false
    addKillPoints() --you got the badman, have a cookie
  break end              --giving points for that here instead of on the collision
 end                 --to keep as few moving parts as possible on that function
 if pickup.active==false then
  pickup.posit.x=BRAZIL
  pickup.posit.y=BRAZIL
 end
end

function drawItems()
 spr(SPR_AMMO_BOX,pickup.posit.x,pickup.posit.y,0)
end

function drawHUD()
  if player.ammo<200 and not hasBeenWarned==true then
   sfx(LOW_AMMO,'E-6',70,1)
   hasBeenWarned=true
  end
  if hasBeenWarned==true and player.ammo>250 then
   hasBeenWarned=false
  end
  if player.ammo==0 then
   print("AMMO: OUT",120,119,ORANGE,false,1,false)
  elseif player.ammo<200 then
   print("AMMO: "..player.ammo.."*",120,119,YELLOW,false,1,false)
  else
   print("AMMO: "..player.ammo,120,119,LIGHT_GREEN,false,1,false)
  end
  print("SCOR: "..score,120,127,LIGHT_GREEN,false,1,false)
end

function setupBullets()
 for cb=1, 16 do --"cb" = "current bullet"
  bullet[cb]={ --initial bullet stats
  velocity=0,
  length=2,
  colour=YELLOW,
  facing=UP,
  active=false,
  hit=false,
  posit={
   x=BRAZIL,
   y=BRAZIL
  },
 }
 end
end

function setupMonsters()
  for cm=1, 16 do --"cm" = "current monster"
   monster[cm]={ --initial monster stats
   alive=false,
   hit=false,
   width=8,
   height=8,
   wakeUpTic=1,
   outOfBounds=true,
   colour=0,
   aggro=false,
   posit={
    x=(BRAZIL-255), 
    y=(BRAZIL-255)
   },
  }
  end
end

function setupSparks()
 for cS=1, 32 do --"current aggro spark"; we have 32 of these so they shouldn't run out
  aggroSpark[cS]={
   active=false,
   stage=0,
   nextUpdate=0,
   frame=SPR_AGGRO_SPARK,
   posit={
    x=BRAZIL,
    y=BRAZIL
   },
 }
  spawnSpark[cS]={
   active=false,
   stage=0,
   nextUpdate=0,
   frame=SPR_SPAWN_SPARK,
   posit={
    x=BRAZIL,
    y=BRAZIL
   },
 }
 end
end

function updateMonster()
 for cm=1, 16 do
  if monster[cm].aggro==false then monster[cm].colour=BLUE end
  --i just want to get the space beasts moving at this point so a more elegant solution can wait on me remembering how math works
  --TODO: add a var for each monster to define whether it goes for pure pursuit or lead pursuit, and respect that here
  if gt>monster[cm].wakeUpTic and monster[cm].aggro==false and monster[cm].alive==true  then 
   monster[cm].colour=RED
   monster[cm].aggro=true
   nASx=monster[cm].posit.x
   nASy=monster[cm].posit.y
   createAggroSpark(nASx,nASy)
 end
  if t%3~=0 and gt>monster[cm].wakeUpTic and monster[cm].alive==true then -- only move if your wakeup time has passed and you're alive
   if monster[cm].posit.x>player.posit.x then monster[cm].posit.x = monster[cm].posit.x-1 end
   if monster[cm].posit.x<player.posit.x then monster[cm].posit.x = monster[cm].posit.x+1 end
   if monster[cm].posit.y>player.posit.y then monster[cm].posit.y = monster[cm].posit.y-1 end
   if monster[cm].posit.y<player.posit.y then monster[cm].posit.y = monster[cm].posit.y+1 end
  end
  if monster[cm].posit.x>239 then
   monster[cm].outOfBounds=true
  end
  if monster[cm].posit.x<0 then
   monster[cm].outOfBounds=true
  end
  if monster[cm].posit.y>139 then
   monster[cm].outOfBounds=true
  end
  if monster[cm].posit.y<0 then
   monster[cm].outOfBounds=true
  end
 end
end--updateMonster()

function spawnController()
  for cm=1, 16 do
   newSpawnSide=math.random(0,3)
   if monster[cm].alive==true then end
   if monster[cm].alive==false then
    monster[cm].wakeUpTic=(gt+math.random(30,180)) -- wait somewhere between half a second and three seconds to start moving
    if newSpawnSide==0 then spawnNorth(cm) return end
    if newSpawnSide==1 then spawnEast(cm) return end
    if newSpawnSide==2 then spawnSouth(cm) return end
    if newSpawnSide==3 then spawnWest(cm) return end
    nextspawn=t+spawnInterval
   break
   end
  end
end

function debugHUD()
  for ce=1, 16 do
    if bullet[ce].hit==true then BULLET_STATE_COLOUR=WHITE --print the bullet's coors in white if it's flagged as "hit"
     else BULLET_STATE_COLOUR=DARK_GREY                    --to see if they're being flagged but not culled
    end
    print("B"..ce..": "..bullet[ce].posit.x..", "..bullet[ce].posit.y,0,(ce*8),BULLET_STATE_COLOUR,true,1,true)
    print("M"..ce..": "..monster[ce].posit.x..", "..monster[ce].posit.y,80,(ce*8),DARK_GREY,true,1,true)
  end
end


function restart()
 banish()
 rearm()
 player.kills=0
 player.posit.x=120
 player.posit.y=68
end

function initialise()
 poke(0x03FF8, BLUE)-- set the border value in vram to blue
 setupSparks()
 setupBullets()
 setupMonsters()--company's coming, set the tables~
 spawnInterval=4 --try to spawn a monster every 4 tics when starting
 monstersSpawned=0
 nextSpawn=t --start spawning immediately
 markTime=false
 initialised=true
end

function addKillPoints()
 score=score+1
end

function spawnNorth(cm)
  monster[cm].posit.x=math.random(8,232)
  monster[cm].posit.y=8
  monster[cm].alive=true
  monster[cm].outOfBounds=false
  if monstersSpawned>5 then spawnInterval=300 end --After spawning five, throttle back the spawn rolls
  nextspawn=t+spawnInterval
  monstersSpawned=monstersSpawned+1
  createSpawnSpark(monster[cm].posit.x,monster[cm].posit.y)
end

function spawnEast(cm)
  monster[cm].posit.x=224
  monster[cm].posit.y=math.random(8,128)
  monster[cm].alive=true
  monster[cm].outOfBounds=false
  if monstersSpawned>5 then spawnInterval=300 end --After spawning five, throttle back the spawn rolls
  nextspawn=t+spawnInterval
  monstersSpawned=monstersSpawned+1
  createSpawnSpark(monster[cm].posit.x,monster[cm].posit.y)
end

function spawnSouth(cm)
  monster[cm].posit.x=math.random(8,232)
  monster[cm].posit.y=120
  monster[cm].alive=true
  monster[cm].outOfBounds=false
  if monstersSpawned>5 then spawnInterval=300 end --After spawning five, throttle back the spawn rolls
  nextspawn=t+spawnInterval
  monstersSpawned=monstersSpawned+1
  createSpawnSpark(monster[cm].posit.x,monster[cm].posit.y)
end

function spawnWest(cm)
  monster[cm].posit.x=8
  monster[cm].posit.y=math.random(8,128)
  monster[cm].alive=true
  monster[cm].outOfBounds=false
  if monstersSpawned>5 then spawnInterval=300 end --After spawning five, throttle back the spawn rolls
  nextspawn=t+spawnInterval
  monstersSpawned=monstersSpawned+1
  nSSx=monster[cm].posit.x
  nSSy=monster[cm].posit.y
  createSpawnSpark(nSSx, nSSy)
end

function banish() --reset player, monsters, score, ammo
 for cm=1, 16 do
    monster[cm].outOfBounds=true
 end
 rearm()
 score=0
 gt=0
 initialise() --using this for this purpose feels wrong somehow
end

function rearm() --fully restock ammo
 player.ammo=500
 sfx(PICKUP,'F#4',6,1,15,0)
 pickup.active=false
end

function checkBulletCollision() --see if any beasts get shot
  for cb=1, 16 do
    for cm=1, 16 do
      if (bullet[cb].posit.x >= monster[cm].posit.x) and bullet[cb].active==true and monster[cm].alive==true then                             --if we're past the target's left edge in the X axis,
        if (bullet[cb].posit.x <= (monster[cm].posit.x + monster[cm].width)) then     --and we're not past its right edge,
          if (bullet[cb].posit.y >= monster[cm].posit.y) then                         --and we're lower than its top edge,
            if (bullet[cb].posit.y <= (monster[cm].posit.y + monster[cm].height)) then--but higher than its bottom edge
              monster[cm].hit=true                                                    --i hate looking at this but it works...
              bullet[cb].hit=true  
            break end--so the reason bullets weren't being culled when they should is because i had [cm] on both of these
          end        --and shots'd only be culled if the monster and bullet colliding had the same index
        end
      end
    end
  end
end

function createAggroSpark(nASx, nASy)
 for cAS=1, 32 do
  if aggroSpark[cAS].active==true then end
  if not aggroSpark[cAS].active==true then
   aggroSpark[cAS].active=true
   aggroSpark[cAS].stage=0
   aggroSpark[cAS].nextUpdate=gt+10
   spawnSpark[cAS].frame=SPR_AGGRO_SPARK
   aggroSpark[cAS].posit.x=nASx
   aggroSpark[cAS].posit.y=nASy
   break
  end
 end
end

function createSpawnSpark(nSSx, nSSy)
 for cSS=1, 32 do
  if spawnSpark[cSS].active==true then end
  if not spawnSpark[cSS].active==true then
   spawnSpark[cSS].active=true
   spawnSpark[cSS].stage=0
   spawnSpark[cSS].nextUpdate=gt+10
   spawnSpark[cSS].frame=SPR_SPAWN_SPARK
   spawnSpark[cSS].posit.x=nSSx
   spawnSpark[cSS].posit.y=nSSy
   break
  end
 end
end

function drawSparks()
 for cS=1, 32 do
  if spawnSpark[cS].active==true then
   local offsetSSparkFrame=SPR_SPAWN_SPARK+spawnSpark[cS].stage
   local sSparkX=spawnSpark[cS].posit.x
   local sSparkY=spawnSpark[cS].posit.y
   spr(offsetSSparkFrame,sSparkX,sSparkY,0)
  end
  if aggroSpark[cS].active==true then
   local offsetASparkFrame=SPR_AGGRO_SPARK+aggroSpark[cS].stage
   local aSparkX=aggroSpark[cS].posit.x
   local aSparkY=aggroSpark[cS].posit.y
   spr(offsetASparkFrame,aSparkX,aSparkY,0)
  end
 end
end

function updateSparks()
 for cS=1, 32 do
  if spawnSpark[cS].active==true and gt>spawnSpark[cS].nextUpdate then
   spawnSpark[cS].stage=spawnSpark[cS].stage+1
   spawnSpark[cS].nextUpdate=spawnSpark[cS].nextUpdate+5
  end
  if spawnSpark[cS].stage>4 then spawnSpark[cS].active=false and spawnSpark[cS].stage==0 end
  if aggroSpark[cS].active==true and gt>aggroSpark[cS].nextUpdate then
   aggroSpark[cS].stage=aggroSpark[cS].stage+1
   aggroSpark[cS].nextUpdate=aggroSpark[cS].nextUpdate+5
  end
  if aggroSpark[cS].stage>4 then aggroSpark[cS].active=false and aggroSpark[cS].stage==0 end
 end
end

function checkPlayerCollision()-- with monsters and pickups TODO: find out why sometimes there is no collision
 local playerX1=player.posit.x
 local playerX2=player.posit.x+player.width
 local playerY1=player.posit.y
 local playerY2=player.posit.y+player.height
 local pickupX1=pickup.posit.x
 local pickupX2=pickup.posit.x+pickup.width
 local pickupY1=pickup.posit.y
 local pickupY2=pickup.posit.y+pickup.height
 if playerX1 <= pickupX2 and playerX2 >= pickupX1
  then if playerY1 <=pickupY2 and playerY2 >= pickupY1 then rearm() end
 end
 for cm=1, 16 do
  if monster[cm].aggro==false then break end
  local monsterX1 = monster[cm].posit.x
  local monsterX2 = monster[cm].posit.x+monster[cm].width
  local monsterY1 = monster[cm].posit.y
  local monsterY2 = monster[cm].posit.y+monster[cm].height
  if playerX1 <= monsterX2 and playerX2 >= monsterX1
   then if playerY1 <= monsterY2 and playerY2 >= monsterY1 then banish() end
  end
 end
end