UIGameMap = extends(UIMap, "UIGameMap")

function UIGameMap.create()
  local gameMap = UIGameMap.internalCreate()
  gameMap:setKeepAspectRatio(false)
  gameMap:setVisibleDimension({width = 45, height = 27})
  gameMap:setDrawLights(true)
  return gameMap
end

function UIGameMap:onDragEnter(mousePos)
  local tile = self:getTile(mousePos)
  if not tile then return false end

  local thing = tile:getTopMoveThing()
  if not thing then return false end

  self.currentDragThing = thing

  g_mouse.pushCursor('target')
  self.allowNextRelease = false
  return true
end

function UIGameMap:onDragLeave(droppedWidget, mousePos)
  self.currentDragThing = nil
  self.hoveredWho = nil
  g_mouse.popCursor('target')
  return true
end

function UIGameMap:onDrop(widget, mousePos)
  if not self:canAcceptDrop(widget, mousePos) then
    return false
  end

  local tile = self:getTile(mousePos)
  if not tile then
    return false
  end

  local thing = widget.currentDragThing
  local thingPos = thing:getPosition()
  if not thingPos then
    return false
  end

  local thingTile = thing:getTile()
  if thingPos.x ~= 65535 and not thingTile then
    return false
  end

  local toPos = tile:getPosition()
  if thingPos.x == toPos.x and thingPos.y == toPos.y and thingPos.z == toPos.z then
    return false
  end

  if thing:isItem() and thing:getCount() > 1 then
    modules.game_interface.moveStackableItem(thing, toPos)
  else
    g_game.move(thing, toPos, 1)
  end

  return true
end

function UIGameMap:onMousePress()
  if not self:isDragging() then
    self.allowNextRelease = true
  end
end


-- g_keyboard.bindKeyDown('Shift+W', function() g_map.updateCamera(North) end, gameRootPanel)
-- g_keyboard.bindKeyDown('Shift+S', function() g_map.updateCamera(South) end, gameRootPanel)
-- g_keyboard.bindKeyDown('Shift+D', function() g_map.updateCamera(East) end, gameRootPanel)
-- g_keyboard.bindKeyDown('Shift+A', function() g_map.updateCamera(West) end, gameRootPanel)
local mapScrollDelay = 0.250
local lastMapScroll = 0
function UIGameMap:onMouseMove(mousePos, mouseMove, x)
  if os.clock() < lastMapScroll then return end
  print(os.clock(), lastMapScroll)

  local factor = 0.05
  local width, height = g_window.getWidth(), g_window.getHeight()
  local limit = { 
    north = height * factor, 
    south = height * (1 - factor),
    east = width * (1 - factor), 
    west = width * factor
  }

  if (mousePos.y <= limit.north) then
    print("N", mousePos.x, mousePos.y)
    print("mouse m", mouseMove.x, mouseMove.y)
  end

  if (mousePos.y >= limit.south) then
    print("S", mousePos.x, mousePos.y)
    print("mouse m", mouseMove.x, mouseMove.y)
  end

  if (mousePos.x >= limit.east) then
    print("E", mousePos.x, mousePos.y)
    print("mouse m", mouseMove.x, mouseMove.y)
  end

  if (mousePos.x <= limit.west) then
    print("W", mousePos.x, mousePos.y)
    print("mouse m", mouseMove.x, mouseMove.y)
  end

  lastMapScroll = os.clock() + mapScrollDelay
end

function UIGameMap:onMouseRelease(mousePosition, mouseButton)
  if not self.allowNextRelease then
    return true
  end

  local autoWalkPos = self:getPosition(mousePosition)

  -- happens when clicking outside of map boundaries
  if not autoWalkPos then return false end

  local localPlayerPos = g_game.getLocalPlayer():getPosition()
  if autoWalkPos.z ~= localPlayerPos.z then
    local dz = autoWalkPos.z - localPlayerPos.z
    autoWalkPos.x = autoWalkPos.x + dz
    autoWalkPos.y = autoWalkPos.y + dz
    autoWalkPos.z = localPlayerPos.z
  end

  local lookThing
  local useThing
  local creatureThing
  local multiUseThing
  local attackCreature

  local tile = self:getTile(mousePosition)
  if tile then
    lookThing = tile:getTopLookThing()
    useThing = tile:getTopUseThing()
    creatureThing = tile:getTopCreature()
  end

  local autoWalkTile = g_map.getTile(autoWalkPos)
  if autoWalkTile then
    attackCreature = autoWalkTile:getTopCreature()
  end

  local ret = modules.game_interface.processMouseAction(mousePosition, mouseButton, autoWalkPos, lookThing, useThing, creatureThing, attackCreature)
  if ret then
    self.allowNextRelease = false
  end

  return ret
end

function UIGameMap:canAcceptDrop(widget, mousePos)
  if not widget or not widget.currentDragThing then return false end

  local children = rootWidget:recursiveGetChildrenByPos(mousePos)
  for i=1,#children do
    local child = children[i]
    if child == self then
      return true
    elseif not child:isPhantom() then
      return false
    end
  end

  error('Widget ' .. self:getId() .. ' not in drop list.')
  return false
end
