mapPanel = modules.game_interface.getMapPanel()
gameRootPanel = modules.game_interface.gameBottomPanel
gameLeftPanel = modules.game_interface.getLeftPanel()

-- define this true to see bosses around you and false for target bosses only
showNearBosses = true
bosses = {}
bossesBadges = {
  ['Ferumbras'] = 'ferumbras'
}

function currentViewMode()
  return modules.game_interface.currentViewMode
end

healthCircle = nil
manaCircle = nil

g_ui.loadUI('game_healthcircle')

healthCircleFront = nil
manaCircleFront = nil

function init()
  healthCircle = g_ui.createWidget('HealthCircle', mapPanel)
  manaCircle = g_ui.createWidget('ManaCircle', mapPanel)

  healthCircleFront = g_ui.createWidget('HealthCircleFront', mapPanel)
  manaCircleFront = g_ui.createWidget('ManaCircleFront', mapPanel)

  setCirclesPosition()
  initOnHpAndMpChange()
  initOnGeometryChange()
  initOnLoginChange()
  initOnCreatureAppearDisappear()
end

function terminate()
  healthCircle:destroy()
  manaCircle:destroy()
  healthCircleFront:destroy()
  manaCircleFront:destroy()

  for i,k in ipairs(bosses) do
    destroyBossWidget(i)
  end

  terminateOnHpAndMpChange()
  terminateOnGeometryChange()
  terminateOnLoginChange()
  terminateOnCreatureAppearDisappear()
end

-------------------------------------------------
--Scripts----------------------------------------
-------------------------------------------------

function initOnHpAndMpChange()
  connect(LocalPlayer, { onHealthPercentChange = whenHealthChange,
                         onManaChange = whenManaChange, })
end

function terminateOnHpAndMpChange()
  disconnect(LocalPlayer, { onHealthChange = whenHealthChange,
                            onManaChange = whenManaChange, })
end

function initOnCreatureAppearDisappear()
  connect(Creature, {
    onAppear = onCreatureAppear,
    onDisappear = onCreatureDisappear,
    onHealthPercentChange = whenHealthChange,
  })
end

function terminateOnCreatureAppearDisappear()
  disconnect(Creature, {
    onAppear = onCreatureAppear,
    onDisappear = onCreatureDisappear,
    onHealthPercentChange = whenHealthChange,
  })
end

function initOnGeometryChange()
  connect(gameRootPanel, { onGeometryChange = setCirclesPosition })
end

function terminateOnGeometryChange()
  disconnect(gameRootPanel, { onGeometryChange = setCirclesPosition })
end

function initOnLoginChange()
  connect(g_game, { onGameStart = setCirclesPosition,
    onAttackingCreatureChange = onAttack, })
end

function terminateOnLoginChange()
  disconnect(g_game, { onGameStart = setCirclesPosition,
  onAttackingCreatureChange = onAttack, })
end

function widgetSetHealthColor(widget, healthPercent)
  if not widget then return end

  if healthPercent > 92 then
    widget:setImageColor("#00BC00")
  elseif healthPercent > 60 then
    widget:setImageColor("#50A150")
  elseif healthPercent > 30 then
    widget:setImageColor("#A1A100")
  elseif healthPercent > 8 then
    widget:setImageColor("#BF0A0A")
  elseif healthPercent > 3 then
    widget:setImageColor("#910F0F")
  else
    widget:setImageColor("#850C0C")
  end
end

function whenHealthChange(creature)
  if g_game.isOnline() then
    local healthPercent = creature:getHealthPercent()
    local widget;
    if creature:isLocalPlayer() then
      widget = healthCircleFront
      local Yhppc = math.floor(208 * (1 - (healthPercent/ 100)))
      local rect = { x = 0, y = Yhppc, width = 63, height = 208 }
      widget:setImageClip(rect)
      widget:setY(mapPanel:getHeight() / 2 - healthCircle:getHeight() / 2 + 0 + Yhppc)
    elseif creature:isBoss() then
      boss = bosses[creature:getId()]
      if boss then
        widget = boss.lifeWidget
        if widget then
          local Xhppc = math.floor(229 * (healthPercent/ 100)) + 1
          local rect = { x = 35, y = 15, width = Xhppc, height = 20 }
          widget:setImageRect(rect)
          local emptyRect = { x = 35, y = 15, width = 230, height = 20 }
          boss.lifeEmptyWidget:setImageRect(emptyRect)
        end
      end
    end
    widgetSetHealthColor(widget, healthPercent)
  end
end

function whenManaChange(creature)
  local mana, maxMana = creature:getMana(), creature:getMaxMana()
  if g_game.isOnline() then
    if creature:isLocalPlayer() then
      local Ymppc = math.floor(208 * (1 - (math.floor((maxMana - (maxMana - mana)) * 100 / maxMana) / 100)))
      local rect = { x = 0, y = Ymppc, width = 63, height = 208 }
      manaCircleFront:setImageClip(rect)
      manaCircleFront:setY(mapPanel:getHeight() / 2 - manaCircle:getHeight() / 2 + 0 + Ymppc)
    end
  end
end

function setCirclesPosition()
  if g_game.isOnline() then
    local localPlayer = g_game.getLocalPlayer()
    whenHealthChange(localPlayer)
    whenManaChange(localPlayer)

    healthCircleFront:setX(math.floor((mapPanel:getWidth() / 2 + healthCircle:getWidth() / 2 - 150)) * 0.92)
    manaCircleFront:setX(math.floor((mapPanel:getWidth() / 2 + manaCircle:getWidth() / 2 + 0)) * 1.08)

    healthCircle:setX(math.floor((mapPanel:getWidth() / 2 + healthCircle:getWidth() / 2 - 150)) * 0.92)
    manaCircle:setX(math.floor((mapPanel:getWidth() / 2 + manaCircle:getWidth() / 2 + 0)) * 1.08)

    healthCircle:setY(mapPanel:getHeight() / 2 - healthCircle:getHeight() / 2)
    manaCircle:setY(mapPanel:getHeight() / 2 - manaCircle:getHeight() / 2)
  end
end

function onCreatureAppear(creature)
  if not showNearBosses then return end 

  if creature:isBoss() then
    initBossWidget(creature)
  end
end

function onCreatureDisappear(creature)
  if not showNearBosses then return end 

  if creature:isBoss() and bosses[creature:getId()] then
    destroyBossWidget(creature:getId())

    -- redraw to change panel position
    for i,boss in pairs(bosses) do
      if boss then
        destroyBossWidget(i)
        initBossWidget(boss.creature)
      end
    end
  end
end

function initBossWidget(creature)
  local localPlayer = g_game.getLocalPlayer()
  if not creature or not localPlayer then return end
  if bosses[creature:getId()] then return end
  
  local playerPosition = localPlayer:getPosition()
  local creaturePosition = creature:getPosition()
  
  if playerPosition.z ~= creaturePosition.z then return end

  local boss = {}
  boss.creature = creature
  boss.infoPanel = g_ui.createWidget('BossInfo', gameLeftPanel)

  boss.lifeEmptyWidget = g_ui.createWidget('BossHealthEmpty', boss.infoPanel)
  boss.lifeEmptyWidget:setImageSource('/images/game/bosses/healthbar_empty')
  
  boss.lifeWidget = g_ui.createWidget('BossHealth', boss.infoPanel)
  boss.lifeWidget:setImageSource('/images/game/bosses/healthbar')
  boss.lifeWidget:setText(creature:getName())

  boss.iconWidget = g_ui.createWidget('BossIcon', boss.infoPanel)
  boss.iconWidget:setImageSource('/images/game/bosses/' .. getBossBadge(creature:getName()) .. '')

  bosses[creature:getId()] = boss

  whenHealthChange(creature)
end

function destroyBossWidget(id)
  bosses[id].iconWidget:destroy()
  bosses[id].lifeWidget:destroy()
  bosses[id].lifeEmptyWidget:destroy()
  bosses[id].infoPanel:destroy()

  bosses[id].infoPanel = nil
  bosses[id].iconWidget = nil
  bosses[id].lifeEmptyWidget = nil
  bosses[id].lifeWidget = nil

  bosses[id] = nil
end

function onAttack(creature)
  if showNearBosses then return end 

  for id,k in pairs(bosses) do
    destroyBossWidget(id)
  end

  if creature and creature:isBoss() then
    initBossWidget(creature)
  end
end

function getBossBadge(bossName) 
  local badgeName = bossesBadges[bossName]
  return badgeName and badgeName or 'ferumbras'
end