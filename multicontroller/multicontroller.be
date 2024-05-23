import webserver
import json

# Class to collect information for printing a function cells for pin list table
class FuncCell
  var name
  var span

  def init(name)
    if (name!= nil) self.name = name else self.name = '---' end
    self.span = 1
  end
end

# Init default pin name list
class PinFuncInfo
  var pin_names
  var func_cell_list
  var func_cell_idx
  var last_func_idx

  def init()
    self.pin_names = []
    self.func_cell_list = []
    self.func_cell_idx = -1
    self.last_func_idx = -2
  end
end

class Multicontroller

  # ESP32 GPIOs and extension boards GPIOs channel assignment
  static ext_gpio_assignments = [['GPIO5', 'GPIO35', 'GPIO36', 'GPIO37', 'GPIO38', 'GPIO39'],  # Ext 1
                                 ['GPIO6', 'GPIO7', 'GPIO15', 'GPIO16', 'GPIO17', 'GPIO8'],    # Ext 2
                                 ['GPIO14', 'GPIO13', 'GPIO12', 'GPIO11', 'GPIO10', 'GPIO9'],  # Ext 3
                                 ['GPIO21', 'GPIO47', 'GPIO48', 'GPIO40', 'GPIO41', 'GPIO42']] # Ext 4

  # Assignment of extension board GPIO channels and Tasmota GPIO positions in the template.
  static ext_gpio_template_assignments = [[5 , 24, 25, 26, 27, 28],
                                          [6 , 7 , 15, 16, 17, 8],
                                          [14, 13, 12, 11, 10, 9],
                                          [21, 36, 37, 29, 30, 31]]

  static i2c_addr_2_ext_board_idx = {80 : 0, 81 : 2, 82 : 1, 83 : 3}

  # Berry representation of Multicontroller's default Tasmota template for ESP32
  static default_template = {"NAME":"MultiController","GPIO":[0,608,640,0,576,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,0,0,1,1,1,1,1,1,1,1,0,0,0,0,1,1],"FLAG":0,"BASE":1}

  static ext_gpiofunc_2_tasm_gpio_func = [
    224,  # GPIO_REL1
    9312, # GPIO_REL1_BI
    416,  # GPIO_PWM1
    7648  # GPIO_INPUT
    ]

  def init()
    tasmota.add_driver(self)
    self.web_add_handler()
  end

  def close()
    tasmota.remove_driver(self)
  end

  def show_dev_head(board_info)
    var ret = true

    webserver.content_send('<p></p><fieldset><legend><b>Board information</b></legend>')
    if (board_info)
      webserver.content_send('<p></p><table><tbody>')
      webserver.content_send('<tr><td><b>Name:</b></td><td>' + board_info.find("NAME", '') + '</td></tr>')
      webserver.content_send('<tr><td><b>Desc.:</b></td><td>' + board_info.find("DESC", '') + '</td></tr>')
      webserver.content_send('<tr><td><b>Ver.:</b></td><td>' + board_info.find("VER", '') + '</td></tr>')
      webserver.content_send('<tr><td><b>Prod.:</b></td><td>' + board_info.find("PD", '') + '</td></tr>')
      webserver.content_send('</tbody></table>')
    else
      webserver.content_send('<p></p><b>NO DEVICE INFORMATION!</b>')
      ret = false
    end

    webserver.content_send('</fieldset>')
    return ret
  end

  def show_gpio_conf(board_id, board_info, board_funcs, tasm_gpios, board_gpios)
    webserver.content_send('<p></p><fieldset><legend><b>Tasmota GPIO configuration</b></legend>')
    webserver.content_send('<p></p><table><tr><th>MC Function</th><th>GPIO</th><th>Current GPIO Func</th><th>Requested GPIO Func</th></tr>')
    for func : board_funcs
      var func_gpios = func.find('GPIOS', [])
      for gpio : func_gpios
        var gpio_idx = gpio.find('CHID', nil)
        var option = gpio.find('OPT', nil)
        var option_idx = gpio.find('OPTIDX', nil)
        if ((gpio_idx != nil) && (option != nil) && (option_idx != nil))
          var gpio_name = board_gpios[gpio_idx]
          var esp_gpio = tasm_gpios.find(gpio_name, {})
          var tasm_gpio_id = self.ext_gpiofunc_2_tasm_gpio_func[option] + (board_id * 6) + option_idx
          webserver.content_send('<tr><td>' + func.find("NAME", '') + '</td><td>' + gpio_name + '</td><td>' + esp_gpio.tostring() + '</td><td>' + str(tasm_gpio_id) + '</td></tr>')
        end
      end
    end
    webserver.content_send('</table></fieldset>')
  end

  def handle_pind_and_function_cell(pfi, pin_name, func_name, pin_func_idx)
    # Add pin name to pin cell list
    pfi.pin_names.push(pin_name)

    if (pfi.last_func_idx != pin_func_idx)
      # Create new function cell
      pfi.func_cell_list.push(FuncCell(func_name))
      pfi.func_cell_idx += 1
    else
      # Increase span
      pfi.func_cell_list[pfi.func_cell_idx].span += 1
    end

    # Update last pin function index
    pfi.last_func_idx = pin_func_idx
  end

  def show_board_conn_pinout(board_info, board_funcs)
    var pfi = PinFuncInfo()

    # Iterate over all pins
    for pin_idx : 0..11
      # Find pin number in pin configuration
      var found = false
      for pin : board_info.find("PINS", [])
        var pin_num = pin.find("NUM", nil)
        var pin_func_idx = pin.find("FIDX", nil)
        if (pin_num != nil)
          # Check whether we have pin config for the current pin
          if (pin_num == (pin_idx + 1))
            # Find function name
            var func_name = (board_funcs[pin_func_idx]).find('NAME')

            # Evaluate function cell
            self.handle_pind_and_function_cell(pfi, pin.find("NAME", '---'), func_name, pin_func_idx)
            found = true
            break
          end
        end
      end
      if (!found)
        # Evaluate function cell
        self.handle_pind_and_function_cell(pfi, '---', nil, -1)
      end
    end
        
    webserver.content_send('<p></p><fieldset><legend><b>Board connector pinout</b></legend>')
    webserver.content_send('<p></p><table>')
    # Init table header
    webserver.content_send('<tbody><tr><th>Pin num.</th>')
    for pin_num : 1..12
      webserver.content_send(format('<td>%i</td>', pin_num))
    end

    # Create table cells for pin names
    webserver.content_send('</tr><tr><th>Pin name</th>')
    for pin_name : pfi.pin_names
      webserver.content_send('<td>' + pin_name + '</td>')
    end
    webserver.content_send('</tr>')

    # Create table cells for function names
    webserver.content_send('<tr><th>Function</th>')
    for func_cell : pfi.func_cell_list
      webserver.content_send('<td colspan="' + str(func_cell.span) + '">' + func_cell.name + '</td>')
    end
    webserver.content_send('</tr>')

    webserver.content_send('</tbody></table>')
    webserver.content_send('</fieldset>')
  end

  def show_func(board_info, func)
    # Calculate the number of rows required for for one function row
    var rows = 0
    var func_props = func.find("PROPS", [])
    var func_params = func.find("PRMS", [])
    var board_props = board_info.find("PROPS", [])
    var board_params = board_info.find("PRMS", [])
    if (func_props.size() > func_params.size())
      rows = func_props.size()
    else
      rows = func_params.size()
    end

    if (rows == 0) rows = 1 end

    for row : 0..rows - 1
      webserver.content_send('<tr>')
#      if (row == 0) webserver.content_send(format('<td rowspan="%i">%s</td>'), rows, func.name) end
#      if (row == 0) webserver.content_send(format('<td rowspan="%i">%s</td>'), rows, func.desc) end
      if (row == 0) webserver.content_send('<td rowspan="' + str(rows) + '">' + func.find("NAME", '') + '</td>') end
      if (row == 0) webserver.content_send('<td rowspan="' + str(rows) + '">' + func.find("DESC", '') + '</td>') end

      # Get the property assigned to the function if any
      var board_prop = nil
      if (row < func_props.size())
        var func_prop_idx = func_props[row]
        board_prop = board_props[func_prop_idx]
      end

      # Get the parameter assigned to the function if any and the actual parameter
      var board_param = nil
      var func_param_act = nil
      var board_param_value_list = []
      if (row < func_params.size())
        var func_param = func_params[row]
        var func_param_idx = func_param.find("PIDX", nil)
        if (func_param_idx != nil)
          board_param = board_params[func_param_idx]
          var func_param_act_idx = func_param.find("ACTIDX", nil)
          if (func_param_act_idx != nil)
            board_param_value_list = board_param.find("VLIST", '')
            func_param_act = board_param_value_list[func_param_act_idx]
          end
        end
      end

      if (board_prop != nil) webserver.content_send('<td>' + board_prop.find("NAME", '') + '</td><td>' + board_prop.find("VAL", '') + '</td>') else webserver.content_send('<td></td><td></td>') end
      if (board_param != nil)
        webserver.content_send('<td>' + board_param.find("NAME", '') + '</td>')
        var option_list = '<select>'
        for value : board_param_value_list
          option_list += '<option value="opt_' + value + '"'
          if (value == func_param_act)
            option_list += ' selected'
          end
          option_list += '>' + value + '</option>'
        end
        option_list += '</select>'
        webserver.content_send('<td>' + option_list + '</td>')
      else
        webserver.content_send('<td></td><td></td>')
      end
      webserver.content_send('</tr>')
    end
  end

  def show_board_funcs(board_info, board_funcs)
    webserver.content_send('<p></p><fieldset><legend><b>Board functions</b></legend>')
    webserver.content_send('<p></p>')
    webserver.content_send('<table>')
    webserver.content_send('<thead><tr><th>Name</th><th>Description</th><th colspan="2">Properties</th><th colspan="2">Parameters</th></tr></thead>')
    webserver.content_send('<tbody>')
    for func : board_funcs
      self.show_func(board_info, func)
    end
    webserver.content_send('</tbody></table></fieldset>')
  end

  def show_emplate(board_funcs)
    var template = self.default_template

    for func : board_funcs
      for gpio : func.find('GPIOS', [])
        var channel = gpio.find('CHID', nil)
        var opt = gpio.find('OPT', nil)
        var optidx = gpio.find('OPTIDX', nil)
        if ((channel != nil) && (opt != nil) && (optidx != nil))
        # TODO Continue here
        end
      end
    end
  end

  def show_board_conf(board_id, board_info, tasm_gpios, board_gpios)
    print(board_id)
    print(board_info)
    print(tasm_gpios)
    print(board_gpios)
    var board_funcs = board_info.find("FUNCS", [])
    # Show board header
    print('sbc1')
    if (self.show_dev_head(board_info))

      # Show board connector pinout
      print('sbc2')
      self.show_board_conn_pinout(board_info, board_funcs)

      # Show functions
      print('sbc3')
      self.show_board_funcs(board_info, board_funcs)

      # Show GPIO configuration
      self.show_gpio_conf(board_id, board_info, board_funcs, tasm_gpios, board_gpios)
      print('sbc4')
    end
    print('sbc5')
  end

  def show_ext_board_conf(tasm_gpios, ext_board_id, board_desc_json)
    # Get board GPIO assignments
    var board_gpios = self.ext_gpio_assignments[ext_board_id]
    # Parse JSON
    var board_info = json.load(board_desc_json)

    self.show_board_conf(ext_board_id, board_info, tasm_gpios, board_gpios)
  end

  def page_mc_conf_page()
    var test_json_confs = []
    # Get Tasmota GPIOs
    var tasm_gpios = tasmota.cmd('GPIO')
    test_json_confs.push('{"NAME":"Bistable relay board","DESC":"3pcs of HF3F-L-5-1HL1T relays","VER":"1.0","PD":"2024.01.01","PROPS":[{"NAME":"Maximum rated current","VAL":"10A"},{"NAME":"Maximum rated voltage","VAL":"250VAC"}],"PINS":[{"NAME":"C1","NUM":4,"FIDX":0},{"NAME":"COM","NUM":5,"FIDX":0},{"NAME":"C2","NUM":6,"FIDX":0},{"NAME":"C1","NUM":7,"FIDX":1},{"NAME":"COM","NUM":8,"FIDX":1},{"NAME":"C2","NUM":9,"FIDX":1},{"NAME":"C1","NUM":10,"FIDX":2},{"NAME":"COM","NUM":11,"FIDX":2},{"NAME":"C2","NUM":12,"FIDX":2}],"FUNCS":[{"NAME":"Relay 1","DESC":"Bistabil relay","GPIOS":[{"CHID":0,"OPT":1,"OPTIDX":0},{"CHID":1,"OPT":1,"OPTIDX":1}],"PROPS":[0,1]},{"NAME":"Relay 2","DESC":"Bistabil relay","GPIOS":[{"CHID":2,"OPT":1,"OPTIDX":2},{"CHID":3,"OPT":1,"OPTIDX":3}],"PROPS":[0,1]},{"NAME":"Relay 3","DESC":"Bistabil relay","GPIOS":[{"CHID":4,"OPT":1,"OPTIDX":4},{"CHID":5,"OPT":1,"OPTIDX":5}],"PROPS":[0,1]}]}')
    test_json_confs.push('{"NAME":"High power PWM FET board","DESC":"6pcs high power FETs with current limiting","VER":"1.0","PD":"2024.01.01","PRMS":[{"NAME":"Current limit","VLIST":["0.5A","1A","2A","3A","5A"]}],"PROPS":[{"NAME":"Maximum output current","VAL":"5A"},{"NAME":"Maximum working voltage","VAL":"24V"}],"PINS":[{"NAME":"GND","NUM":1,"FIDX":0},{"NAME":"OUT","NUM":2,"FIDX":0},{"NAME":"GND","NUM":3,"FIDX":1},{"NAME":"OUT","NUM":4,"FIDX":1},{"NAME":"GND","NUM":5,"FIDX":2},{"NAME":"OUT","NUM":6,"FIDX":2},{"NAME":"GND","NUM":7,"FIDX":3},{"NAME":"OUT","NUM":8,"FIDX":3},{"NAME":"GND","NUM":9,"FIDX":4},{"NAME":"OUT","NUM":10,"FIDX":4},{"NAME":"GND","NUM":11,"FIDX":5},{"NAME":"OUT","NUM":12,"FIDX":5}],"FUNCS":[{"NAME":"PWM 1","DESC":"PWM Channel 1","GPIOS":[{"CHID":0,"OPT":2,"OPTIDX":0}],"PRMS":[{"PIDX":0,"ACTIDX":0}],"PROPS":[0,1]},{"NAME":"PWM 2","DESC":"PWM Channel 2","GPIOS":[{"CHID":1,"OPT":2,"OPTIDX":1}],"PRMS":[{"PIDX":0,"ACTIDX":1}],"PROPS":[0,1]},{"NAME":"PWM 3","DESC":"PWM Channel 3","GPIOS":[{"CHID":2,"OPT":2,"OPTIDX":2}],"PRMS":[{"PIDX":0,"ACTIDX":0}],"PROPS":[0,1]},{"NAME":"PWM 4","DESC":"PWM Channel 4","GPIOS":[{"CHID":3,"OPT":2,"OPTIDX":3}],"PRMS":[{"PIDX":0,"ACTIDX":2}],"PROPS":[0,1]},{"NAME":"PWM 5","DESC":"PWM Channel 5","GPIOS":[{"CHID":4,"OPT":2,"OPTIDX":4}],"PRMS":[{"PIDX":0,"ACTIDX":0}],"PROPS":[0,1]},{"NAME":"PWM 6","DESC":"PWM Channel 6","GPIOS":[{"CHID":5,"OPT":2,"OPTIDX":5}],"PRMS":[{"PIDX":0,"ACTIDX":0}],"PROPS":[0,1]}]}')
    test_json_confs.push('{"NAME":"Relay board","DESC":"6pcs of HF32FA-G-005-HSL1 relays","VER":"1.0","PD":"2024.01.01","PROPS":[{"NAME":"Maximum rated current","VAL":"10A"},{"NAME":"Maximum rated voltage","VAL":"250VAC"}],"PINS":[{"NAME":"COM","NUM":1,"FIDX":0},{"NAME":"N.O.","NUM":2,"FIDX":0},{"NAME":"COM","NUM":3,"FIDX":1},{"NAME":"N.O.","NUM":4,"FIDX":1},{"NAME":"COM","NUM":5,"FIDX":2},{"NAME":"N.O.","NUM":6,"FIDX":2},{"NAME":"COM","NUM":7,"FIDX":3},{"NAME":"N.O.","NUM":8,"FIDX":3},{"NAME":"COM","NUM":9,"FIDX":4},{"NAME":"N.O.","NUM":10,"FIDX":4},{"NAME":"COM","NUM":11,"FIDX":5},{"NAME":"N.O.","NUM":12,"FIDX":5}],"FUNCS":[{"NAME":"Relay 1","DESC":"Normally open relay","GPIOS":[{"CHID":0,"OPT":0,"OPTIDX":0}],"PROPS":[0,1]},{"NAME":"Relay 2","DESC":"Normally open relay","GPIOS":[{"CHID":1,"OPT":0,"OPTIDX":1}],"PROPS":[0,1]},{"NAME":"Relay 3","DESC":"Normally open relay","GPIOS":[{"CHID":2,"OPT":0,"OPTIDX":2}],"PROPS":[0,1]},{"NAME":"Relay 4","DESC":"Normally open relay","GPIOS":[{"CHID":3,"OPT":0,"OPTIDX":3}],"PROPS":[0,1]},{"NAME":"Relay 5","DESC":"Normally open relay","GPIOS":[{"CHID":4,"OPT":0,"OPTIDX":4}],"PROPS":[0,1]},{"NAME":"Relay 6","DESC":"Normally open relay","GPIOS":[{"CHID":5,"OPT":0,"OPTIDX":5}],"PROPS":[0,1]}]}')
    test_json_confs.push('{"NAME":"6 input board","DESC":"Provides inputs for 3 isolated groups","VER":"1.0","PD":"2024.01.01","PROPS":[{"NAME":"Maximum input voltage","VAL":"30V"},{"NAME":"Minimum input voltage","VAL":"5V"}],"PINS":[{"NAME":"VCC_1","NUM":1,"FIDX":0},{"NAME":"GND_1","NUM":2,"FIDX":0},{"NAME":"I1_1","NUM":3,"FIDX":0},{"NAME":"I2_1","NUM":4,"FIDX":0},{"NAME":"VCC_2","NUM":5,"FIDX":1},{"NAME":"GND_2","NUM":6,"FIDX":1},{"NAME":"I1_2","NUM":7,"FIDX":1},{"NAME":"I2_2","NUM":8,"FIDX":1},{"NAME":"VCC_3","NUM":9,"FIDX":2},{"NAME":"GND_3","NUM":10,"FIDX":2},{"NAME":"I1_3","NUM":11,"FIDX":2},{"NAME":"I2_3","NUM":12,"FIDX":2}],"FUNCS":[{"NAME":"Input 1_1","DESC":"Input 1 of 1st group","GPIOS":[{"CHID":0,"OPT":3,"OPTIDX":0}],"PROPS":[0,1]},{"NAME":"Input 2_1","DESC":"Input 2 of 1st group","GPIOS":[{"CHID":1,"OPT":3,"OPTIDX":1}],"PROPS":[0,1]},{"NAME":"Input 1_2","DESC":"Input 1 of 2nd group","GPIOS":[{"CHID":2,"OPT":3,"OPTIDX":2}],"PROPS":[0,1]},{"NAME":"Input 2_2","DESC":"Input 2 of 2nd group","GPIOS":[{"CHID":3,"OPT":3,"OPTIDX":3}],"PROPS":[0,1]},{"NAME":"Input 1_3","DESC":"Input 1 of 3rd group","GPIOS":[{"CHID":4,"OPT":3,"OPTIDX":4}],"PROPS":[0,1]},{"NAME":"Input 2_3","DESC":"Input 2 of 3rd group","GPIOS":[{"CHID":5,"OPT":3,"OPTIDX":5}],"PROPS":[0,1]}]}')

    # Scan I2C bus for device addresses
    var i2c_addr_list = wire1.scan()
    webserver.content_start("Multicontroller Configuration")
    webserver.content_send_style()
    webserver.content_send('<style>table{width: 100%;border-collapse: collapse;}th, td{border: 1px solid gray;padding: 8px;text-align: center;}th{background-color: gray;}</style>')

    var found = false

    for i2c_addr: i2c_addr_list
      # Find external board addresses
      var ext_board_id = self.i2c_addr_2_ext_board_idx.find(i2c_addr, nil)
      if (ext_board_id != nil)
        # Display board information
        webserver.content_send('<p></p><p></p><fieldset><legend><b>Extension slot ' + str(ext_board_id + 1) + '</b></legend>')
        self.show_ext_board_conf(tasm_gpios, ext_board_id, test_json_confs[ext_board_id])
        webserver.content_send('</fieldset>')
        found = true
      end
    end

    if (!found)
      webserver.content_send('<p></p>No extension boards are connected!<p></p>')
    else
      # Show the template to be used
      #self.show_emplate(board_funcs)
    end

    webserver.content_send("<p></p><button onclick='la(\"&m_toggle_conf=1\");'>Test Button</button>")
    # Button back to main page
    webserver.content_button(webserver.BUTTON_MAIN)
    webserver.content_stop()
  end

  #- create a method for adding a button to the main menu -#
  def web_add_main_button()
    webserver.content_send("<p></p><form action='/mc_conf' method='post'><button>Multicontroller</button></form>")
  end

  #- create a method for adding a button to the configuration menu-#
  #def web_add_config_button()
    #- the onclick function "la" takes the function name and the respective value you want to send as an argument -#
 #   webserver.content_send("<p></p><form action='/mc_conf' method='post'><button>Multicontroller Configuration</button></form>")
 # end

  #- As we can add only one sensor method we will have to combine them besides all other sensor readings in one method -#
  def web_sensor()

#    webserver.content_send("<p></p><button onclick='la(\"&m_toggle_conf=1\");'>Test Button</button>")

    if webserver.has_arg("m_toggle_conf")
      print("m_toggle_conf")
    end

    if webserver.has_arg("m_go_conf") # takes a string as argument name and returns a boolean

      # we can even call another function and use the value as a parameter
      var myValue = int(webserver.arg("m_go_conf")) # takes a string or integer(index of arguments) to get the value of the argument
      self.myOtherFunction(myValue)
    end
  end

  def web_add_handler()
    webserver.on("/mc_conf", / -> self.page_mc_conf_page())
    print("Multicontroller configuration page available at '/mc_conf'")
    end
end

mc = Multicontroller()
