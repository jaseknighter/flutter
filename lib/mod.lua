--
-- require the `mods` module to gain access to hooks, menu, and other utility
-- functions.
--

local mod = require 'core/mods'
local controlspec = require 'controlspec'

--
-- [optional] a mod is like any normal lua module. local variables can be used
-- to hold any state which needs to be accessible across hooks, the menu, and
-- any api provided by the mod itself.
--
-- here a single table is used to hold some x/y values
--

local state = {
  mod_params_inited = false,
  last_shape = "lin",
  debouncing = {false,false,false,false},
  last_freq = nil,
  last_ramp = nil,
  last_curve = nil,
  last_intone = nil
}

local function update_asl(ix,reset,new_shape)
  local rise,wait_top,wait_bottom,fall,asl
  local freq = params:get("freq")/1000
  local ramp = params:get("ramp")
  local curve = params:string("curve")
  local intone = params:get("intone")
  -- local delay = params:get("phase")
  if (reset == true or new_shape == true) then state.last_shape = nil end 
  if curve == "square" then
    if new_shape == true or state.last_shape ~= "square" then
      -- print("square")
      rise = "to(dyn{rise_level=5},dyn{rise_time=0.01},'now')"
      wait_top = "to(dyn{rise_level=5},dyn{wait_time_top=0.3},'wait')"
      fall = "to(dyn{fall_level=0},dyn{fall_time=0.01},'now')"
      wait_bottom = "to(dyn{fall_level=0},dyn{wait_time_bottom=0.3},'wait')"
      asl = rise .. "," .. wait_top .. "," .. fall .. "," .. wait_bottom
      -- asl = "loop{" .. rise .. "," .. wait_top .. "," .. fall .. "," .. wait_bottom .."}"
      state.last_shape = "square"
    end
  elseif curve == "log" then
    if state.last_shape ~= "log" then
      -- print("log")
      rise = "to(dyn{rise_level=5},dyn{rise_time=0.3},'log')"
      wait_top = "to(dyn{rise_level=5},dyn{wait_time_top=0},'wait')"
      fall = "to(dyn{fall_level=0},dyn{fall_time=0.3},'log')"
      wait_bottom = "to(dyn{fall_level=0},dyn{wait_time_bottom=0},'wait')"
      asl = rise .. "," .. wait_top .. ",".. fall .. "," .. wait_bottom
      -- asl = "loop{" .. rise .. "," .. fall .."}"
      state.last_shape = "log"
    end
  elseif curve == "lin" then
    if state.last_shape ~= "lin" then
      -- print("lin")
      rise = "to(dyn{rise_level=5},dyn{rise_time=0.3},'lin')"
      wait_top = "to(dyn{rise_level=5},dyn{wait_time_top=0},'wait')"
      fall = "to(dyn{fall_level=0},dyn{fall_time=0.3},'lin')"
      wait_bottom = "to(dyn{fall_level=0},dyn{wait_time_bottom=0},'wait')"
      asl = rise .. "," .. wait_top .. ",".. fall .. "," .. wait_bottom
      -- asl = "loop{" .. rise .. "," .. fall .."}"
      state.last_shape = "lin"
      -- print("lin again")
    end
  elseif curve == "exp" then
    if state.last_shape ~= "exp" then
      -- print("exp")
      rise = "to(dyn{rise_level=5},dyn{rise_time=0.3},'exp')"
      wait_top = "to(dyn{rise_level=5},dyn{wait_time_top=0},'wait')"
      fall = "to(dyn{fall_level=0},dyn{fall_time=0.3},'exp')"
      wait_bottom = "to(dyn{fall_level=0},dyn{wait_time_bottom=0},'wait')"
      asl = rise .. "," .. wait_top .. ",".. fall .. "," .. wait_bottom
      -- asl = "loop{" .. rise .. "," .. fall .."}"
      state.last_shape = "exp"
    end
  elseif curve == "sine" then
    if state.last_shape ~= "sine" then
      -- print("sine")
      rise = "to(dyn{rise_level=5},dyn{rise_time=0.3},'sine')"
      wait_top = "to(dyn{rise_level=5},dyn{wait_time_top=0},'wait')"
      fall = "to(dyn{fall_level=0},dyn{fall_time=0.3},'sine')"
      wait_bottom = "to(dyn{fall_level=0},dyn{wait_time_bottom=0},'wait')"
      asl = rise .. "," .. wait_top .. ",".. fall .. "," .. wait_bottom
      -- asl = "loop{" .. rise .. "," .. fall .."}"
      state.last_shape = "sine"
    end
  end


  local rise_time = util.linlin(-5,10,0.001,1,ramp) 
  local wait_time_top = util.linlin(-5,10,0.001,1,ramp)
  local fall_time = util.linlin(-5,10,1,0.001,ramp) 
  local wait_time_bottom = util.linlin(-5,10,0.5,0.0005,ramp)

  if intone < 0 then 
    intone = util.linlin(-5,0,0,0.5,intone)
  else
    intone = util.linlin(0,10,0.5,1,intone)
  end

  -- for i=1,4 do        
    local intone_mult 
    if ix == 1 or intone == 0.5 then
      intone_mult = 1
    elseif intone < 0.5 then
      intone_mult = util.linlin(0,0.5,ix,1,intone) 
    else
      intone_mult = util.linlin(0.5,1,1,1/ix,intone) 
    end 

    if asl then 
      asl = "loop{" .. asl .. "}" 
      crow.output[ix].action = asl
      crow.output[ix]()
    end

    if curve == "square" then  
      crow.output[ix].dyn.rise_time = 0.01
      crow.output[ix].dyn.rise_time = 0.01
      crow.output[ix].dyn.wait_time_top = wait_time_top * freq * (intone_mult)
      crow.output[ix].dyn.fall_time = 0.01
      crow.output[ix].dyn.wait_time_bottom = wait_time_bottom * freq * (intone_mult)
    else
      crow.output[ix].dyn.rise_time = rise_time * freq * (intone_mult)
      crow.output[ix].dyn.fall_time = fall_time * freq * (intone_mult)
    end
    -- crow.output[i]()
  
end

local debounce_time = 0 --0.05
local function init_params()
  params:add_group("flutter",5)
  -- params:add_taper("freq","freq",5,0.001,0.3)
  params:add_control("freq","freq",controlspec.new(10,5000,"lin",1,300,"ms",1/499))
  params:set_action("freq",function(val) 
    for i=1,4 do 
      if state.debouncing[i] == false and state.last_freq ~= val then
        state.debouncing[i] = true
        clock.run(function() 
          clock.sleep(debounce_time)
          update_asl(i,false,false)
          state.debouncing[i] = false
        end)      
      end
    end
    state.last_freq = val
  end)
  params:add_control("ramp","ramp",controlspec.new(-5,10,"lin",0.1,0,nil,0.1/11))
  params:set_action("ramp",function(val) 
    for i=1,4 do 
      if state.debouncing[i] == false and state.last_ramp ~= val then
        state.debouncing[i] = true
        clock.run(function() 
          clock.sleep(debounce_time)
          update_asl(i,false,false)
          state.debouncing[i] = false
        end)      
      end
    end
    state.last_ramp = val
  end)
  params:add_option("curve","curve",{"square","log","lin","exp","sine"},3)
  params:set_action("curve",function(val)
    for i=1,4 do 
      if state.debouncing[i] == false and state.last_curve ~= val then
        state.debouncing[i] = true
        clock.run(function() 
          clock.sleep(debounce_time)
          update_asl(i,false,true)
          state.debouncing[i] = false
        end)      
      end
    end
    state.last_curve = val
  end)
  params:add_control("intone","intone",controlspec.new(-5,10,"lin",0.1,0,nil,0.1/11))
  params:set_action("intone",function(val) 
    for i=1,4 do 
      if state.debouncing[i] == false and state.last_intone ~= val then
       state.debouncing[i] = true
        clock.run(function() 
          clock.sleep(debounce_time)
          update_asl(i,false,false)
          state.debouncing[i] = false
        end)      
      end
    end
    state.last_intone = val
  end)
  params:add_trigger("reset_cycle","reset cycle")
  params:set_action("reset_cycle",function() 
    for i=1,4 do 
      update_asl(i,true,false) 
      crow.output[i]() 
    end
  end)

  state.mod_params_inited = true

  print("mod params inited")
end


-- m.process_stream = function (volts)
--   crow.output[2].dyn.v = volts
-- end

local function end_of_cycle(out_ix)
  -- print("end of cycle",out_ix)
  -- update_asl(out_ix,true,false)
  -- clock.run(function() 
    -- clock.sleep(0.01)
  -- crow.output[out_ix]()
  -- end)
  
end

local function end_of_cycle1() end_of_cycle(1) end
local function end_of_cycle2() end_of_cycle(2) end
local function end_of_cycle3() end_of_cycle(3) end
local function end_of_cycle4() end_of_cycle(4) end


local function init_crow()
  local rise = "to(dyn{rise_level=5},dyn{rise_time=0.3},'lin')"
  local fall = "to(dyn{fall_level=0},dyn{fall_time=0.3},'lin')"
  local asl = "loop{" .. rise .. "," .. fall .."}"
  -- local asl = "times(1,{" .. rise .. "," .. fall .."})"
  
  for i=1,4 do    
    crow.output[i].action = asl
    -- if i==1 then crow.output[i].done = end_of_cycle1 end
    -- if i==2 then crow.output[i].done = end_of_cycle2 end
    -- if i==3 then crow.output[i].done = end_of_cycle3 end
    -- if i==4 then crow.output[i].done = end_of_cycle4 end
    crow.output[i]()
  end
  
end

--
-- [optional] hooks are essentially callbacks which can be used by multiple mods
-- at the same time. each function registered with a hook must also include a
-- name. registering a new function with the name of an existing function will
-- replace the existing function. using descriptive names (which include the
-- name of the mod itself) can help debugging because the name of a callback
-- function will be printed out by matron (making it visible in maiden) before
-- the callback function is called.
--
-- here we have dummy functionality to help confirm things are getting called
-- and test out access to mod level state via mod supplied fuctions.
--

mod.hook.register("system_post_startup", "my startup hacks", function()
  state.system_post_startup = true
end)

mod.hook.register("script_pre_init", "script pre init", function()
  print("pre init")
  -- tweak global environment here ahead of the script `init()` function being called
end)

mod.hook.register("script_post_init", "script post init", function()
  -- run code after the scripts `init()` function being called
  init_params()
  init_crow()
  print("post init")
end)

--
-- [optional] menu: extending the menu system is done by creating a table with
-- all the required menu functions defined.
--

local m = {}

m.key = function(n, z)
  if n == 2 and z == 1 then
    -- return to the mod selection menu
    mod.menu.exit()
  end
end

m.enc = function(n, d)
  -- tell the menu system to redraw, which in turn calls the mod's menu redraw
  -- function
  -- mod.menu.redraw()
end

m.redraw = function()
  screen.clear()
  screen.move(64,30)
  screen.text_center("find flutter controls ")
  screen.move(64,50)
  screen.text_center("in the params menu")
  screen.update()
end

m.init = function()
  if state.mod_params_inited == false then
    print("init mod")
    init_params()
    init_crow()
  end
end -- on menu entry, ie, if you wanted to start timers

m.deinit = function() end -- on menu exit

-- register the mod menu
--
-- NOTE: `mod.this_name` is a convienence variable which will be set to the name
-- of the mod which is being loaded. in order for the menu to work it must be
-- registered with a name which matches the name of the mod in the dust folder.
--
mod.menu.register(mod.this_name, m)


--
-- [optional] returning a value from the module allows the mod to provide
-- library functionality to scripts via the normal lua `require` function.
--
-- NOTE: it is important for scripts to use `require` to load mod functionality
-- instead of the norns specific `include` function. using `require` ensures
-- that only one copy of the mod is loaded. if a script were to use `include`
-- new copies of the menu, hook functions, and state would be loaded replacing
-- the previous registered functions/menu each time a script was run.
--
-- here we provide a single function which allows a script to get the mod's
-- state table. using this in a script would look like:
--
-- local mod = require 'name_of_mod/lib/mod'
-- local the_state = mod.get_state()
--
local api = {}

api.get_state = function()
  return state
end

return api