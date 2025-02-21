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
  debouncing = false
}

local function set_asl(reset)
  if state.debouncing == false then
    clock.run(function() 
      -- print("set asl")
      state.debouncing = true
      local rise,wait_top,wait_bottom,fall,asl
      local freq = params:get("freq")
      local ramp = params:get("ramp")
      local curve = params:string("curve")
      local intone = params:get("intone")
      -- local delay = params:get("phase")
      if reset then state.last_shape = nil end 
      if curve == "square" then
        if state.last_shape ~= "square" then
          print("square")
          rise = "to(dyn{rise_level=5},dyn{rise_time=0.01},'now')"
          wait_top = "to(dyn{rise_level=5},dyn{wait_time_top=0.3},'wait')"
          fall = "to(dyn{fall_level=0},dyn{fall_time=0.01},'now')"
          wait_bottom = "to(dyn{fall_level=0},dyn{wait_time_bottom=0.3},'wait')"
          asl = "loop{" .. rise .. "," .. wait_top .. "," .. fall .. "," .. wait_bottom .."}"
          state.last_shape = "square"
        end
      elseif curve == "log" then
        if state.last_shape ~= "log" then
          print("log")
          rise = "to(dyn{rise_level=5},dyn{rise_time=0.3},'log')"
          fall = "to(dyn{fall_level=0},dyn{fall_time=0.3},'log')"
          asl = "loop{" .. rise .. "," .. fall .."}"
          state.last_shape = "log"
        end
      elseif curve == "lin" then
        if state.last_shape ~= "lin" then
          print("lin")
          rise = "to(dyn{rise_level=5},dyn{rise_time=0.3},'lin')"
          fall = "to(dyn{fall_level=0},dyn{fall_time=0.3},'lin')"
          asl = "loop{" .. rise .. "," .. fall .."}"
          state.last_shape = "lin"
        end
      elseif curve == "exp" then
        if state.last_shape ~= "exp" then
          print("exp")
          rise = "to(dyn{rise_level=5},dyn{rise_time=0.3},'exp')"
          fall = "to(dyn{fall_level=0},dyn{fall_time=0.3},'exp')"
          asl = "loop{" .. rise .. "," .. fall .."}"
          state.last_shape = "exp"
        end
      elseif curve == "sine" then
        if state.last_shape ~= "sine" then
          print("sine")
          rise = "to(dyn{rise_level=5},dyn{rise_time=0.3},'sine')"
          fall = "to(dyn{fall_level=0},dyn{fall_time=0.3},'sine')"
          asl = "loop{" .. rise .. "," .. fall .."}"
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

      for i=1,4 do        
        local intone_mult 
        if i == 1 or intone == 0.5 then
          intone_mult = 1
        elseif intone < 0.5 then
          intone_mult = util.linlin(0,0.5,i,1,intone) 
        else
          intone_mult = util.linlin(0.5,1,1,1/i,intone) 
        end 

        if asl then 
          crow.output[i].action = asl 
        end

        if state.last_shape == "square" then  
          crow.output[i].dyn.rise_time = 0.01
          crow.output[i].dyn.rise_time = 0.01
          crow.output[i].dyn.wait_time_top = wait_time_top * freq * (intone_mult)
          crow.output[i].dyn.fall_time = 0.01
          crow.output[i].dyn.wait_time_bottom = wait_time_bottom * freq * (intone_mult)
        else
          crow.output[i].dyn.rise_time = rise_time * freq * (intone_mult)
          crow.output[i].dyn.fall_time = fall_time * freq * (intone_mult)
        end
        -- crow.output[i]()
      end
      -- clock.sleep(0.01)
      state.debouncing = false
    end)
  end
  
end

local function init_params()
  params:add_group("flutter",5)
  params:add_taper("freq","freq",5,0.001,0.3)
  params:set_action("freq",function(val) 
    set_asl()
  end)
  params:add_control("ramp","ramp",controlspec.new(-5,10,"lin",0.1,0,nil,0.1/11))
  params:set_action("ramp",function(val) 
    set_asl()
  end)
  params:add_option("curve","curve",{"square","log","lin","exp","sine"},3)
  params:set_action("curve",function()
    set_asl()
  end)
  params:add_control("intone","intone",controlspec.new(-5,10,"lin",0.1,0,nil,0.1/11))
  params:set_action("intone",function(val) 
    set_asl()
  end)
  -- params:add_control("phase","phase",controlspec.new(-5,10,"lin",0.1,0,nil,0.1/11))
  -- params:set_action("phase",function(val) 
  --   set_asl(nil)
  -- end)
  

  params:add_trigger("reset","reset")
  params:set_action("reset",function(val) 
    set_asl(1)
  end)
  

  state.mod_params_inited = true

  -- local p = params:lookup_param("curve")
  -- p:bang()
  print("mod params inited")
end


-- m.process_stream = function (volts)
--   crow.output[2].dyn.v = volts
-- end

local function init_crow()
  local rise = "to(dyn{rise_level=5},dyn{rise_time=0.3},'lin')"
  local fall = "to(dyn{fall_level=0},dyn{fall_time=0.3},'lin')"
  local asl = "loop{" .. rise .. "," .. fall .."}"

  -- local rise = "to(dyn{rise_level=5},dyn{rise_time=0.01},'now')"
  -- local wait_top = "to(-dyn{fall_level=0},dyn{wait_time_top=0.3},'wait')"
  -- local fall = "to(-dyn{fall_level=0},dyn{fall_time=0.01},'now')"
  -- local wait_bottom = "to(-dyn{fall_level=0},dyn{wait_time_bottom=0.15},'wait')"
  -- local asl = "loop{" .. rise .. "," .. wait_top .. "," .. fall .. "," .. wait_bottom .. "}"
  
  for i=1,4 do    
    crow.output[i].action = asl
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