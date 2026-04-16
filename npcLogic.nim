import entities

type
  updateNpc* = object
    updateNeeded*: bool
    textureName*: string
    accel*: array[2, float]
    addEntities*: seq[base]

proc calcNpc*(npc: base): updateNpc =
  discard
