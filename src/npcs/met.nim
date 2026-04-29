import ../entities

var metTimer: int

proc metEnemy*(npc, target: base): updateNpc =
  var update: updateNpc
  var name: string = "Met"

  if metTimer > 0:
    metTimer -= 1
    if metTimer == 1:
      update.updateNeeded = true

  if player(target).fire:
    if target.pos[1] + target.colY2 >= npc.pos[1] + npc.colY2:
      if target.pos[1] + target.colY2 <= npc.pos[1] + npc.colY2 + 24:
        name = name & "_HIDE"
        npc.textureName = name
        update.updateNeeded = true
        metTimer = 21

  if target.pos[0] + target.colX2 / 2 < npc.pos[0] + npc.colX2 / 2:
    if npc.facing == 1 or update.updateNeeded: 
      npc.facing = -1
      npc.textureName = name & "_LEFT"
      update.updateNeeded = true
  else: 
    if npc.facing == -1 or update.updateNeeded:
      npc.facing = 1
      npc.textureName = name & "_RIGHT"
      update.updateNeeded = true
  
  if update.updateNeeded:
    update.npcData = npc

  return update
