-- title:  shooty
-- author: Abiko
-- desc:   short description
-- script: lua

--system constants
t=0
debug=true --enable dev barf?

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
 posit={
  x=120,
  y=68
 }
}
----

--blank tables, kitchen sink
bullet={}
monster={}
score=0
hasBeenWarned=false
initialised=false

function TIC() --called 60 times per second
 if initialised==false then
  initialise()
 end
 t=t+1 --master timer
 cls(0) --screen refresh
 borderWatch() --keep player in bounds
 drawPlayer()
 drawBullet()
 drawMonster()
 drawHUD()
 cullEntities() --remove bullets that hit edges or monsters, and monsters that get shot or wander off
 updateBullet() --move bullets
 updateMonster()--move beasts
 checkBulletCollision()
 cullEntities() --do it twice per tic to be certain nothing outruns physics
 if nextSpawn<=t and math.random(16)==1 then spawnController() end
 sniffControls() --accept input
 if debug==true then debugHUD() end
end
----
function borderWatch()
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
 if btn(BUTTON_B) and debug==true then debugBanish() end
 if btn(BUTTON_Y) and debug==true then debugRearm() end
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
--    spr(SPR_MONSTER,monster[cm].posit.x,monster[cm].posit.y,0,1,0,0,1,1)
    rect(monster[cm].posit.x,monster[cm].posit.y,monster[cm].width,monster[cm].height,RED)
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
  break end
  if monster[cm].hit==true then
    monster[cm].posit.x=(BRAZIL-255) --keeping inactive beasts and bullets separate shouldn't matter
    monster[cm].posit.y=(BRAZIL-255) --if you're only checking collision between active entities.
    monster[cm].alive=false          --Collision here is cursed enough without being that specific, though.
    monster[cm].hit=false
    addKillPoints() --you got the badman, have a cookie
   break end              --giving points for that here instead of on the collision
end                 --to keep as few moving parts as possible on that function
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
   speed=0,
   outOfBounds=true,
   posit={
    x=(BRAZIL-255), 
    y=(BRAZIL-255)
   },
  }
  end
end

function updateMonster()
 for cm=1, 16 do
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
end

function spawnController()
  for cm=1, 16 do
   newSpawnSide=math.random(0,3)
   if monster[cm].alive==true then end
   if monster[cm].alive==false then
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


function initialise()
 poke(0x03FF8, BLUE)-- set the border value in vram to blue
 setupBullets()
 setupMonsters()--company's coming, set the tables~
 spawnInterval=4 --try to spawn a monster every 4 tics when starting
 monstersSpawned=0
 nextSpawn=t --start spawning immediately
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
end

function spawnEast(cm)
  monster[cm].posit.x=224
  monster[cm].posit.y=math.random(8,128)
  monster[cm].alive=true
  monster[cm].outOfBounds=false
  if monstersSpawned>5 then spawnInterval=300 end --After spawning five, throttle back the spawn rolls
  nextspawn=t+spawnInterval
  monstersSpawned=monstersSpawned+1
end

function spawnSouth(cm)
  monster[cm].posit.x=math.random(8,232)
  monster[cm].posit.y=120
  monster[cm].alive=true
  monster[cm].outOfBounds=false
  if monstersSpawned>5 then spawnInterval=300 end --After spawning five, throttle back the spawn rolls
  nextspawn=t+spawnInterval
  monstersSpawned=monstersSpawned+1
end

function spawnWest(cm)
  monster[cm].posit.x=8
  monster[cm].posit.y=math.random(8,128)
  monster[cm].alive=true
  monster[cm].outOfBounds=false
  if monstersSpawned>5 then spawnInterval=300 end --After spawning five, throttle back the spawn rolls
  nextspawn=t+spawnInterval
  monstersSpawned=monstersSpawned+1
end

function debugBanish() --set all monsters out of bounds so they're culled next tick
 for cm=1, 16 do
    monster[cm].outOfBounds=true
 end
end

function debugRearm() --fully restock ammo
 player.ammo=500
 sfx(PICKUP,'F#4',6,1,15,0)
end

function checkBulletCollision() --see if any beasts get shot
  for cb=1, 16 do
    for cm=1, 16 do
      if (bullet[cb].posit.x >= monster[cm].posit.x) then                             --if we're past the target's left edge in the X axis,
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