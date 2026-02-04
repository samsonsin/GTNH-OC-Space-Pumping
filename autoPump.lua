-- Credits: Fox, samsonsin
local component = require('component')
local me = component.me_controller
local pumps = {}
local n = 0

-- CTRL+ALT+C to stop the script at any time.

-- ===================== CONFIG ======================

-- Only change the PRIORITY value. Do not change the SETTING or RATE values.

local master = {
  -- Planet 2 -----------------------------------------------------------------------------
  ['Chlorobenzene'] =     {priority=0,  amount=0,  setting={2,1},  rate=896000}, -- Gas 1

  -- Planet 3 -----------------------------------------------------------------------------
  ['Ender Goo'] =         {priority=0,  amount=0,  setting={3,1},  rate=32000}, -- Gas 1
  ['Very Heavy Oil'] =    {priority=0,  amount=0,  setting={3,2},  rate=1400000}, -- Gas 2
  ['Lava'] =              {priority=0,  amount=0,  setting={3,3},  rate=1800000}, -- Gas 3
  ['Natural Gas'] =       {priority=0,  amount=0,  setting={3,4},  rate=1400000}, -- Gas 4

  -- Planet 4 -----------------------------------------------------------------------------
  ['Sulfuric Acid'] =     {priority=0,  amount=0,  setting={4,1},  rate=784000}, -- Gas 1
  ['Molten Iron'] =       {priority=0,  amount=0,  setting={4,2},  rate=896000}, -- Gas 2
  ['Oil'] =               {priority=0,  amount=0,  setting={4,3},  rate=1400000}, -- Gas 3
  ['Heavy Oil'] =         {priority=0,  amount=0,  setting={4,4},  rate=1792000}, -- Gas 4
  ['Molten Lead'] =       {priority=0,  amount=0,  setting={4,5},  rate=896000}, -- Gas 5
  ['Raw Oil'] =           {priority=0,  amount=0,  setting={4,6},  rate=1400000}, -- Gas 6
  ['Light Oil'] =         {priority=0,  amount=0,  setting={4,7},  rate=780000}, -- Gas 7
  ['Carbon Dioxide'] =    {priority=0,  amount=0,  setting={4,8},  rate=1680000}, -- Gas 8

  -- Planet 5 -----------------------------------------------------------------------------
  ['Carbon Monoxide'] =   {priority=0,  amount=0,  setting={5,1},  rate=4480000}, -- Gas 1
  ['Helium-3'] =          {priority=0,  amount=0,  setting={5,2},  rate=2800000}, -- Gas 2
  ['Salt Water'] =        {priority=0,  amount=0,  setting={5,3},  rate=2800000}, -- Gas 3
  ['Helium'] =            {priority=0,  amount=0,  setting={5,4},  rate=1400000}, -- Gas 4
  ['Liquid Oxygen'] =     {priority=0,  amount=0,  setting={5,5},  rate=896000}, -- Gas 5
  ['Neon'] =              {priority=0,  amount=0,  setting={5,6},  rate=32000}, -- Gas 6
  ['Argon'] =             {priority=0,  amount=0,  setting={5,7},  rate=32000}, -- Gas 7
  ['Krypton'] =           {priority=0,  amount=0,  setting={5,8},  rate=8000}, -- Gas 8
  ['Methane'] =           {priority=0,  amount=0,  setting={5,9},  rate=1792000}, -- Gas 9
  ['Hydrogen Sulfide'] =  {priority=0,  amount=0,  setting={5,10},  rate=392000}, -- Gas 10
  ['Ethane'] =            {priority=0,  amount=0,  setting={5,11},  rate=1194000}, -- Gas 11

  -- Planet 6 -----------------------------------------------------------------------------
  ['Deuterium'] =         {priority=0,  amount=0,  setting={6,1},  rate=1568000}, -- Gas 1
  ['Tritium'] =           {priority=0,  amount=0,  setting={6,2},  rate=240000}, -- Gas 2
  ['Ammonia'] =           {priority=0,  amount=0,  setting={6,3},  rate=240000}, -- Gas 3
  ['Xenon'] =             {priority=0,  amount=0,  setting={6,4},  rate=16000}, -- Gas 4
  ['Ethylene'] =          {priority=0,  amount=0,  setting={6,5},  rate=1792000}, -- Gas 5

  -- Planet 7 -----------------------------------------------------------------------------
  ['Hydrofluoric Acid'] = {priority=0,  amount=0,  setting={7,1},  rate=672000}, -- Gas 1
  ['Fluorine'] =          {priority=0,  amount=0,  setting={7,2},  rate=1792000}, -- Gas 2
  ['Nitrogen'] =          {priority=0,  amount=0,  setting={7,3},  rate=1792000}, -- Gas 3
  ['Oxygen'] =            {priority=0,  amount=0,  setting={7,4},  rate=1729000}, -- Gas 4

  -- Planet 8 -----------------------------------------------------------------------------
  ['Hydrogen'] =          {priority=0,  amount=0,  setting={8,1},  rate=1568000}, -- Gas 1
  ['Liquid Air'] =        {priority=0,  amount=0,  setting={8,2},  rate=875000}, -- Gas 2
  ['Molten Copper'] =     {priority=0,  amount=0,  setting={8,3},  rate=672000}, -- Gas 3
  ['Unknown Liquid'] =    {priority=0,  amount=0,  setting={8,4},  rate=672000}, -- Gas 4
  ['Distilled Water'] =   {priority=0,  amount=0,  setting={8,5},  rate=17920000}, -- Gas 5
  ['Radon'] =             {priority=0,  amount=0,  setting={8,6},  rate=64000}, -- Gas 6
  ['Molten Tin'] =        {priority=0,  amount=0,  setting={8,7},  rate=672000}} -- Gas 7


local target = 1
local dynamicTargetOffset = 10e9 -- adds to the median fluid amount to set as the target
local singularityCellSize = 4.61e18
local maxStorageAmount = singularityCellSize*0.99

-- The upper limit on the duration of an iteration (Default: 60s)
local maxBatchSize = 60

-- =================== END CONFIG ====================

local function sortFluidsByPriorityThenFillRatio(lowFluids)
  table.sort(lowFluids, function(a, b)
    if a.priority - b.priority ~= 0 then
        return a.priority > b.priority
    else
        return (a.amount / target) < (b.amount / target)
    end
  end)
end

local function sortFluidsByAmount(lowFluids)
  table.sort(lowFluids, function(a, b)
    return a.amount  < b.amount 
  end)
end

local function formatFluid(amount)
        local suffixes = {' ', 'K', 'M', 'G', 'T', 'P', 'E', 'Z', 'Y'}
        local index = 1
        local value = amount
        
        while value >= 1000 and index < #suffixes do
          value = value / 1000
          index = index + 1
        end
        
        return string.format('%.3f %sL', value, suffixes[index])
      end

local function findPumps()
  for address in component.list('gt_machine') do
    local module = component.proxy(component.get(address))
    local name = module.getName()

    -- Tier 1 Module
    if name == "projectmodulepumpt1" then
      table.insert(pumps, {module=module, threads=1, mult=4, priority=1})

    -- Tier 2 Module
    elseif name == "projectmodulepumpt2" then
      table.insert(pumps, {module=module, threads=4, mult=16, priority=2})

    -- Tier 3 Module
    elseif name == "projectmodulepumpt3" then
      table.insert(pumps, {module=module, threads=4, mult=256, priority=3})
    end
  end

  -- Sort Based on Priority
  table.sort(pumps, function(a, b) return a.priority > b.priority end)
end

local function updateFluids()

  -- Reset Everything to Zero
  local lowFluids = {}
  for _, fluid in pairs(master) do
    fluid.amount = 0
  end

  -- Update the Fluids Available
  for _, fluid in ipairs(me.getFluidsInNetwork()) do
    if master[fluid.label] ~= nil then
      master[fluid.label].amount = fluid.amount
    end
  end

  -- Convert master dictionary to array for sorting
  local fluidArray = {}
  for _, fluid in pairs(master) do
    table.insert(fluidArray, fluid)
  end
  
  -- Find Median to set dynamic target
  sortFluidsByAmount(fluidArray)
  local medianFluid = #fluidArray > 0 and fluidArray[math.ceil(#fluidArray / 2)] or nil
  target = medianFluid ~= nil and math.min(medianFluid.amount + dynamicTargetOffset, maxStorageAmount) or maxStorageAmount

  print('┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐')
  print(string.format('│ Target set according to Median: │ %-20s │ %10s + %10s = %10s %66s', medianFluid.label, formatFluid(medianFluid.amount), formatFluid(dynamicTargetOffset), formatFluid(target), '│'))
  print('├──────────────────────┬───────┬────────────────────────────────────────────────────────────────┬──────────────────────────────────────────────┬───────────────┤')
  print('│ Name                 │ Dur   │        Old +      Added =        New :  Target +% =   Target % │                                           +% │           L/s │')
  print('├──────────────────────┼───────┼────────────────────────────────────────────────────────────────┼──────────────────────────────────────────────┼───────────────┤')
 
  -- Identify Low Fluids
  for _, fluid in pairs(master) do
    if fluid.amount < target then
      table.insert(lowFluids, fluid)
    end
  end

  return lowFluids
end

local function updatePumps(lowFluids)
  for _, pump in ipairs(pumps) do
    -- Ensure pump is disabled
    while pump.module.isMachineActive() do os.sleep(1) end

    sortFluidsByPriorityThenFillRatio(lowFluids)
    local fluid = lowFluids[1]
    if fluid ~= nil then

      -- Ensure pump is disabled
      while pump.module.isMachineActive() do os.sleep(1) end

      -- Remove fluid if already at target. next fluid will be at position 1 after removal
      if lowFluids[1].amount >= target then
        table.remove(lowFluids, 1)
      end

      -- Change planet and gas for ALL threads
      for i=1, pump.threads do
        pump.module.setParameters(2*(i-1), 0, fluid.setting[1]) -- Planet
        pump.module.setParameters(2*(i-1), 1, fluid.setting[2]) -- Gas
      end

      -- Calculate varous amounts, update fluid amount preemptively
      local batchSize = math.min(maxBatchSize, math.ceil((maxStorageAmount - fluid.amount) / (fluid.rate * pump.mult)))
      local oldAmount = fluid.amount
      fluid.amount = fluid.amount + (batchSize * fluid.rate * pump.mult)
      local percentageGain = oldAmount > 0 and ((fluid.amount - oldAmount) / oldAmount) * 100 or 0
      local targetPercentageGain = target > 0 and ((fluid.amount - oldAmount) / target) * 100 or 0
      local targetFillPercentage = (fluid.amount / target) * 100
      
      print(string.format('│ %-20s │ %3d s │ %10s + %10s = %10s : %+8.3f %% = %8.3f %% │ %+42.3f %% │ %8.3f ML/s │', 
      fluid.label, 
      batchSize, 
      formatFluid(oldAmount), 
      formatFluid((fluid.amount - oldAmount)), 
      formatFluid(fluid.amount), 
      targetPercentageGain,
      targetFillPercentage,
      percentageGain, 
      (fluid.amount - oldAmount)/1e6/batchSize))
      
      pump.module.setParameters(9, 1, batchSize) -- Batch Size
      
      -- Run once
      pump.module.setWorkAllowed(true)
      os.sleep(0.1)
      pump.module.setWorkAllowed(false)

    else
      return
    end
  end
  print('└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘')
end

-- ====================== MAIN =======================

local function main()
  print('autoPump: Reading Config... Scanning Pumps...')
  findPumps()

  for k, fluid in pairs(master) do
    fluid.label = k
  end

  -- THE LOOP
  while true do

    -- Update Fluid Amounts
    local lowFluids = updateFluids()

    -- Update Pump Settings
    if next(lowFluids) ~= nil then
      updatePumps(lowFluids)
      n=0

    -- Nothing to Update, Sleep 3 Minutes
    elseif n==0 then
      print('autoPump: Sleeping...\n')
      os.sleep(180)
      n=1
    end
  end
end

main()