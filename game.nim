import std/[os, sequtils, strutils, strformat, math]
import kirpi

const
  screenWidth: int = 800
  screenHeight: int = 600
  bits: int = 64
  gravity: float = 1.5

type entity = object
  textureName: string
  colX1, colY1: float
  colX2, colY2: float
  isGrounded: bool
  jumpBuffer: int
  maxJumpBuffer: int

  vel, maxVel: array[2, int]
  accel, maxAccel, size, pos: array[2, float]

var 
  textures: seq[Texture]
  textureList: seq[seq[string]]
  scrollPos: array[2, float]
  startHeight: float
  map: seq[string]
  scrollHorizontal: array[2, bool]
  scrollVertical: array[2, bool]
  scrollSet: array[2, float]
  upperX, upperY: int
  entities: seq[entity]
  blankEntitiy: entity
  slide: float
  storeValues: seq[float]
  storeMatch: seq[string]
  direction: string
  scrollDirection: bool

let walkTextures: seq[tuple[kind: PathComponent, path: string]] = 
  toSeq(walkDir("textures", relative = true))

proc storeMatching(name: string): int = 
  if storeMatch.len > 0:
    for i in 0 .. storeMatch.len - 1:
      if storeMatch[i] == name:
        return i

proc storeAdd(name: string, value: float) =
  storeValues.add(value)
  storeMatch.add(name)

proc createPlayer() =
  entities.add(blankEntitiy)
  entities[0].textureName = "Rockman_X"
  entities[0].colX1 = 0
  entities[0].colY1 = 6
  entities[0].colX2 = 64
  entities[0].colY2 = 128
  entities[0].jumpBuffer = 15
  entities[0].maxjumpBuffer = 15
  entities[0].maxAccel = [5, 50]
  entities[0].maxVel = [5, 10]
  entities[0].size = [64, 128]

  storeAdd("maxVelX", entities[0].maxVel[0].toFloat)
  storeAdd("maxVelY", entities[0].maxVel[1].toFloat)
  storeAdd("maxAccelX", entities[0].maxAccel[0])

proc match(search: string, option: int): Texture =
  for i in 0 .. textureList.len - 1:
    if textureList[i][option] == search:
      return textures[i]

proc loadMap(name: string) =
  map = readFile("maps/" & name & "/main").splitLines
  upperX = map[0].len - 1
  upperY = map.len - 2

  for i in 0 .. upperY:
    if map[i][0] == 'A':
      startHeight = (screenHeight - bits * (i + 1)).toFloat
      break

  let 
    loadTextures: seq[string] = 
      readFile("maps/" & name & "/textures").splitLines
    startPosition: seq[string] =
      readFile("maps/" & name & "/start").splitLines[0].split(',')
  
  entities[0].pos[0] = startPosition[0].parseFloat * bits.toFloat
  entities[0].pos[1] = startHeight + startPosition[1].parseFloat * bits.toFloat
  scrollSet[1] = screenHeight div 2
  if startHeight == 0: 
    scrollSet[1] = entities[0].pos[1] + entities[0].size[1]

  scrollSet[0] = screenWidth div 2
  textures.setLen(loadTextures.len - 1)

  for i in 0 .. loadTextures.len - 2:
    let tileMatch: seq[string] = loadTextures[i].split('|')
    for j in 0 .. walkTextures.len - 1:
      if walkTextures[j][1].split('.')[0] == tileMatch[1]:
        textures[i] = newTexture("textures/" & walkTextures[j][1])
        textureList.add(tileMatch)
        break

proc setScrollBounds(i: int) =
  if i == 0:
    let lowerScrollX: float = scrollPos[0] / bits.toFloat
    if lowerScrollX <= 0: scrollHorizontal[0] = false
    else: scrollHorizontal[0] = true

    let upperScrollX: float = lowerScrollX + screenWidth.toFloat / bits.toFloat
    if upperScrollX >= upperX.toFloat + 1: scrollHorizontal[1] = false
    else: scrollHorizontal[1] = true

  else:
    let lowerScrollY: float = (scrollPos[1] - startHeight) / bits.toFloat
    if lowerScrollY <= 0: scrollVertical[0] = false
    else: scrollVertical[0] = true

    let upperScrollY: float = lowerScrollY + screenHeight / bits
    if upperScrollY >= upperY.toFloat + 1: scrollVertical[1] = false
    else: scrollVertical[1] = true

proc drawMap(name: string) =
  var 
    lowerXBound: int = scrollPos[0].toInt div bits
    upperXBound: int = lowerXBound + screenWidth div bits + 1
    lowerYBound: int = (scrollPos[1] - startHeight).toInt div bits
    upperYBound: int = lowerYBound + screenHeight div bits + 1

  if lowerXBound < 0: lowerXBound = 0
  if upperXBound > upperX: upperXBound = upperX
  if lowerYBound < 0: lowerYBound = 0
  if upperYBound > upperY: upperYBound = upperY

  for y in lowerYBound .. upperYBound:
    for x in lowerXBound .. upperXBound:
      let tile = match(&"{map[y][x]}", 0)
      let tileY: float = startHeight + (y.toFloat * bits.toFloat)
      let tileX: float = x.toFloat * bits.toFloat
      draw(tile, tileX - scrollPos[0], tileY - scrollPos[1])
  
  for id in 0 .. entities.len - 1:
    draw(
      match(entities[id].textureName, 1), 
      entities[id].pos[0] - scrollPos[0], 
      entities[id].pos[1] - scrollPos[1]
    )

proc checkTile(x, y: int): char =
  # This will include adjusting tile hitboxes eventually
  return map[(y / bits).trunc.toInt][(x / bits).trunc.toInt]

proc collision(id: int, direction: string, hit: bool): bool =
  let 
    posX: float = entities[id].pos[0]
    posY: float = entities[id].pos[1] - startHeight
    lowerYBound: int = (posY + entities[id].colY1).toInt
    upperYBound: int = (posY + entities[id].colY2).toInt - 1
    lowerXBound: int = (posX + entities[id].colX1).toInt
    upperXBound: int = (posX + entities[id].colX2).toInt - 1

  case direction
  of "right":
    for i in lowerYBound .. upperYBound:
      if checkTile((posX + entities[id].colX2).toInt, i) != ' ':
        if hit == true:
          entities[id].vel[0] = 0
          if entities[id].accel[0] > 0:
            entities[id].accel[0] = 0
        return true

  of "left":
    for i in lowerYBound .. upperYBound:
      if checkTile((posX + entities[id].colX1).toInt - 1, i) != ' ':
        if hit == true:
          entities[id].vel[0] = 0
          if entities[id].accel[0] < 0:
            entities[id].accel[0] = 0
        return true

  of "down":
    for i in lowerXBound .. upperXBound:
      if checkTile(i, (posY + entities[id].colY2).toInt) != ' ':
        entities[id].isGrounded = true
        if hit == true:
          entities[id].vel[1] = 0
          if entities[id].accel[1] < 0:
            entities[id].accel[1] = 0
        return true

  of "up":
    for i in lowerXBound .. upperXBound:
      if checkTile(i, (posY + entities[id].colY1).toInt - 1) != ' ':
        if hit == true:
          entities[id].vel[1] = 0
          if entities[id].accel[1] < 0:
            entities[id].accel[1] = 0
        return true


proc move(id: int, scroll: bool) =
  entities[id].isGrounded = collision(id, "down", false)

  for i in 0 .. 1:
    var accel: float = entities[id].accel[i]
    if accel.abs != 0:
      let accelDirection: float = accel / accel.abs
      let maxAccel: float = entities[id].maxAccel[i]
      if accel.abs > maxAccel:
        accel = maxAccel * accelDirection
        entities[id].accel[i] = accel

    entities[id].vel[i] += accel.trunc.toInt
    var vel: int = entities[id].vel[i]
    if vel.abs != 0: 
      let velDirection: int = vel div vel.abs
      var maxVel: int = entities[id].maxVel[i]
      if vel.abs > maxVel:
        vel = maxVel * velDirection
        entities[id].vel[i] = vel

      for j in 0 .. vel.abs:
        setScrollBounds(i)
        if vel > 0:
          if i == 0: 
            direction = "right"
            scrollDirection = scrollHorizontal[1]
          else: 
            direction = "down"
            scrollDirection = scrollVertical[1]

          if collision(id, direction, true) == false:
            if scroll == true:
              if scrollDirection == true:
                if entities[id].pos[i] + (entities[id].size[i] / 2) - scrollPos[i] >= scrollSet[i]:
                  scrollPos[i] += 1
            entities[id].pos[i] += 1
        if vel < 0:
          if i == 0: 
            direction = "left"
            scrolldirection = scrollHorizontal[0]
          else: 
            direction = "up"
            scrollDirection = scrollVertical[0]

          if collision(id, direction, true) == false:
            if scroll == true:
              if scrollDirection == true:
                if entities[id].pos[i] + (entities[id].size[i] / 2) - scrollPos[i] <= scrollSet[i]:
                  scrollPos[i] -= 1
            entities[id].pos[i] -= 1

proc load() =
  createPlayer()
  loadMap("test")

proc checkSlide(direction: string): bool =
  if collision(0, direction, true) == true:
    if entities[0].isGrounded == false:
      entities[0].isGrounded = true
      slide = 0.05
      if isKeyPressed(C):
        slide = 1
        entities[0].isGrounded = false
        entities[0].jumpBuffer -= 1
        case direction
        of "right":
          entities[0].accel[0] -= 1.5
        of "left":
          entities[0].accel[0] += 1.5
      if entities[0].vel[1] < 0: entities[0].vel[1] = 0
      if entities[0].accel[1] < 0: entities[0].accel[1] = 0
    return true

proc update(dt: float) =
  if entities[0].isGrounded == true or slide != 1:
    if isKeyDown(V):
      entities[0].maxVel[0] = 2 * storeValues[storeMatching("maxVelX")].toInt
      entities[0].maxAccel[0] = 2 * storeValues[storeMatching("maxAccelX")]
    elif entities[0].isGrounded or slide != 1:
      entities[0].maxVel[0] = storeValues[storeMatching("maxVelX")].toInt
      entities[0].maxAccel[0] = storeValues[storeMatching("maxAccelX")]

  if isKeyDown(RIGHT):
    if checkSlide("right") == false:
      slide = 1 
      if entities[0].isGrounded == true:
        if entities[0].vel[1] < 0: entities[0].vel[1] = 0
        if entities[0].accel[1] < 0: entities[0].accel[1] = 0 
        entities[0].accel[0] += 2
      else:
        entities[0].accel[0] += 0.3

  elif not isKeyDown(LEFT):
    slide = 1
    if entities[0].vel[0] > 0:
      entities[0].accel[0] -= 5
      if entities[0].vel[0] + entities[0].accel[0].trunc.toInt <= 0:
        entities[0].accel[0] = 0
        entities[0].vel[0] = 0

  if isKeyDown(LEFT):
    if checkSlide("left") == false:
      slide = 1
      if entities[0].isGrounded == true:
        if entities[0].vel[1] > 0: entities[0].vel[1] = 0
        if entities[0].accel[1] > 0: entities[0].accel[1] = 0
        entities[0].accel[0] -= 2
      else:
        entities[0].accel[0] -= 0.3

  elif not isKeyDown(RIGHT):
    slide = 1
    if entities[0].vel[0] < 0:
      entities[0].accel[0] += 2
      if entities[0].vel[0] + entities[0].accel[0].trunc.toInt >= 0:
        entities[0].accel[0] = 0
        entities[0].vel[0] = 0

  if isKeyDown(C):
    if entities[0].isGrounded == true or entities[0].jumpBuffer < entities[0].maxJumpBuffer:
      if entities[0].jumpBuffer > 0:
        entities[0].accel[1] -= 20
        entities[0].jumpBuffer -= 1
      else:
        entities[0].accel[1] = gravity * slide + 1
  else:
    if entities[0].isGrounded == true:
      entities[0].jumpBuffer = entities[0].maxJumpBuffer
    else:
      entities[0].jumpBuffer = 0
    entities[0].accel[1] = gravity * slide + 1

  if isKeyPressed(ESCAPE):
    quit()
 
  entities[0].maxVel[1] = (storeValues[storeMatching("maxVelY")] * slide).toInt + 1

  move(0, true)

proc draw() =
  clear(Black)
  setColor(White)
  drawMap("test")

proc config(appSettings:var AppSettings) =
  appSettings.window.width=screenWidth
  appSettings.window.height=screenHeight

run("Rockman X Fossil Hunter",load,update,draw,config)
