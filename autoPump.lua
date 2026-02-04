-- Credits: Fox
local component = require('component')
local me = component.me_controller
local pumps = {}
local n = 0

-- CTRL+ALT+C to stop the script at any time.

-- ===================== CONFIG ======================

-- Only change the TARGET and PRIORITY values. Do not change the SETTING or RATE values.

local master = {
  -- Planet 2 -----------------------------------------------------------------------------
  ['Chlorobenzene'] =     {target=1e10,  priority=0,  setting={2,1},  rate=896000}, -- Gas 1

  -- Planet 3 -----------------------------------------------------------------------------
  ['Ender Goo'] =         {target=1e10,  priority=0,  setting={3,1},  rate=32000}, -- Gas 1
  ['Very Heavy Oil'] =    {target=1e10,  priority=0,  setting={3,2},  rate=1400000}, -- Gas 2
  ['Lava'] =              {target=1e10,  priority=0,  setting={3,3},  rate=1800000}, -- Gas 3
  ['Natural Gas'] =       {target=1e10,  priority=0,  setting={3,4},  rate=1400000}, -- Gas 4

  -- Planet 4 -----------------------------------------------------------------------------
  ['Sulfuric Acid'] =     {target=1e10,  priority=0,  setting={4,1},  rate=784000}, -- Gas 1
  ['Molten Iron'] =       {target=1e10,  priority=0,  setting={4,2},  rate=896000}, -- Gas 2
  ['Oil'] =               {target=1e10,  priority=0,  setting={4,3},  rate=1400000}, -- Gas 3
  ['Heavy Oil'] =         {target=1e10,  priority=0,  setting={4,4},  rate=1792000}, -- Gas 4
  ['Molten Lead'] =       {target=1e10,  priority=0,  setting={4,5},  rate=896000}, -- Gas 5
  ['Raw Oil'] =           {target=1e10,  priority=0,  setting={4,6},  rate=1400000}, -- Gas 6
  ['Light Oil'] =         {target=1e10,  priority=0,  setting={4,7},  rate=780000}, -- Gas 7
  ['Carbon Dioxide'] =    {target=1e10,  priority=0,  setting={4,8},  rate=1680000}, -- Gas 8

  -- Planet 5 -----------------------------------------------------------------------------
  ['Carbon Monoxide'] =   {target=1e10,  priority=0,  setting={5,1},  rate=4480000}, -- Gas 1
  ['Helium-3'] =          {target=1e10,  priority=0,  setting={5,2},  rate=2800000}, -- Gas 2
  ['Salt Water'] =        {target=1e10,  priority=0,  setting={5,3},  rate=2800000}, -- Gas 3
  ['Helium'] =            {target=1e10,  priority=0,  setting={5,4},  rate=1400000}, -- Gas 4
  ['Liquid Oxygen'] =     {target=1e10,  priority=0,  setting={5,5},  rate=896000}, -- Gas 5
  ['Neon'] =              {target=1e10,  priority=0,  setting={5,6},  rate=32000}, -- Gas 6
  ['Argon'] =             {target=1e10,  priority=0,  setting={5,7},  rate=32000}, -- Gas 7
  ['Krypton'] =           {target=1e10,  priority=0,  setting={5,8},  rate=8000}, -- Gas 8
  ['Methane'] =           {target=1e10,  priority=0,  setting={5,9},  rate=1792000}, -- Gas 9
  ['Hydrogen Sulfide'] =  {target=1e10,  priority=0,  setting={5,10},  rate=392000}, -- Gas 10
  ['Ethane'] =            {target=1e10,  priority=0,  setting={5,11},  rate=1194000}, -- Gas 11

  -- Planet 6 -----------------------------------------------------------------------------
  ['Deuterium'] =         {target=1e10,  priority=0,  setting={6,1},  rate=1568000}, -- Gas 1
  ['Tritium'] =           {target=1e10,  priority=0,  setting={6,2},  rate=240000}, -- Gas 2
  ['Ammonia'] =           {target=1e10,  priority=0,  setting={6,3},  rate=240000}, -- Gas 3
  ['Xenon'] =             {target=1e10,  priority=0,  setting={6,4},  rate=16000}, -- Gas 4
  ['Ethylene'] =          {target=1e10,  priority=0,  setting={6,5},  rate=1792000}, -- Gas 5

  -- Planet 7 -----------------------------------------------------------------------------
  ['Hydrofluoric Acid'] = {target=1e10,  priority=0,  setting={7,1},  rate=672000}, -- Gas 1
  ['Fluorine'] =          {target=1e10,  priority=0,  setting={7,2},  rate=1792000}, -- Gas 2
  ['Nitrogen'] =          {target=1e10,  priority=0,  setting={7,3},  rate=1792000}, -- Gas 3
  ['Oxygen'] =            {target=1e10,  priority=0,  setting={7,4},  rate=1729000}, -- Gas 4

  -- Planet 8 -----------------------------------------------------------------------------
  ['Hydrogen'] =          {target=1e10,  priority=0,  setting={8,1},  rate=1568000}, -- Gas 1
  ['Liquid Air'] =        {target=1e10,  priority=0,  setting={8,2},  rate=875000}, -- Gas 2
  ['Molten Copper'] =     {target=1e10,  priority=0,  setting={8,3},  rate=672000}, -- Gas 3
  ['Unknown Liquid'] =    {target=1e10,  priority=0,  setting={8,4},  rate=672000}, -- Gas 4
  ['Distilled Water'] =   {target=1e10,  priority=0,  setting={8,5},  rate=17920000}, -- Gas 5
  ['Radon'] =             {target=1e10,  priority=0,  setting={8,6},  rate=64000}, -- Gas 6
  ['Molten Tin'] =        {target=1e10,  priority=0,  setting={8,7},  rate=672000}} -- Gas 7

-- The % of the target for when to start pumping (Default: <75%)
local threshold = 0.75

-- The upper limit on the duration of an iteration (Default: 30s)
local maxBatchSize = 30

-- =================== END CONFIG ====================

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

  -- Identify Low Fluids
  for _, fluid in pairs(master) do
    if fluid.amount < threshold * fluid.target then
      table.insert(lowFluids, fluid)
    end
  end

  -- Sort Based on Priority
  table.sort(lowFluids, function(a, b) return a.priority > b.priority end)
  return lowFluids
end


local function updatePumps(lowFluids)
  local c = 1
  for _, pump in ipairs(pumps) do

    -- Next fluid in the list
    local fluid = lowFluids[c]
    if fluid ~= nil then
      c = c+1

      -- Ensure pump is disabled
      while pump.module.isMachineActive() do os.sleep(1) end

      -- Change planet and gas for ALL threads
      for i=1, pump.threads do
        pump.module.setParameters(2*(i-1), 0, fluid.setting[1]) -- Planet
        pump.module.setParameters(2*(i-1), 1, fluid.setting[2]) -- Gas
      end

      -- Change batch size based on distance from target
      local batchSize = math.min(maxBatchSize, math.ceil((fluid.target - fluid.amount) / (fluid.rate * pump.mult)))
      pump.module.setParameters(9, 1, batchSize) -- Batch Size
      print(string.format('autoPump: Running %s for %d Seconds', fluid.label, batchSize))

      -- Run once
      pump.module.setWorkAllowed(true)
      os.sleep(0.05)
      pump.module.setWorkAllowed(false)

    else
      return
    end
  end
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

      -- Wait for Pumps to Finish
      for _, pump in ipairs(pumps) do
        while pump.module.isMachineActive() do os.sleep(1) end
      end

    -- Nothing to Update, Sleep 3 Minutes
    elseif n==0 then
      print('autoPump: Sleeping...\n')
      os.sleep(180)
      n=1
    end
  end
end

main()