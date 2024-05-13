import webserver
import json

class Multicontroller

  static ext_gpio_assignments = [['GPIO5', 'GPIO35', 'GPIO36', 'GPIO37', 'GPIO38', 'GPIO39'], # Ext 1
                                 ['GPIO6', 'GPIO7', 'GPIO15', 'GPIO16', 'GPIO17', 'GPIO8'],   # Ext 2
                                 ['GPIO14', 'GPIO13', 'GPIO12', 'GPIO11', 'GPIO10', 'GPIO9'], # Ext 3
                                 ['GPIO21', 'GPIO47', 'GPIO48', 'GPIO40', 'GPIO41', 'GPIO42']]# Ext 4

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

  def show_gpio_conf(board_info, tasm_gpios, board_gpios)
    webserver.content_send('<p></p><fieldset><legend><b>Tasmota GPIO configuration</b></legend>')
    var funcs = board_info.find("FUNCS", [])

    webserver.content_send('<p></p><table><tr><th>MC Function</th><th>GPIO</th><th>Current GPIO Func</th></tr>')
    for func : funcs
      var func_gpios = func.find('GPIOS', [])
      for gpio : func_gpios
        var gpio_idx = gpio.find('CHID', nil)
        var option = gpio.find('OPT', nil)
        if ((gpio_idx != nil) && (option != nil))
          var gpio_name = board_gpios[gpio_idx]
          var esp_gpio = tasm_gpios.find(gpio_name, {})
          webserver.content_send('<tr><td>' + func.find("NAME", '') + '</td><td>' + gpio_name + '</td><td>' + esp_gpio.tostring() + '</td></tr>')
        end
      end
    end
    webserver.content_send('</table>')
#    for gpio_idx : 0 .. 5
#      var gpio_name = board_gpios[gpio_idx]
#      var gpio = tasm_gpios.find(gpio_name, {})
#      webserver.content_send('<p></p><b>' + gpio_name + '</b>: ' + gpio.tostring())
#    end
    webserver.content_send('</fieldset>')
  end

  def show_board_conn_pinout(board_info)
    # Class to collect information for printing a function cells for pin list table
    class FuncCell
      var name
      var span
      var pin_num_list
      var first_pin_num
      var last_pin_num

      def init()
        self.pin_num_list = []
        self.span = 1
        self.first_pin_num = 0
        self.last_pin_num = 0
      end
    end

    # Collect functions
    var func_cell_list = []
    var funcs = board_info.find("FUNCS", [])
    for func : funcs
      var func_cell = FuncCell()
      func_cell.name = func.find("NAME", '')
      func_cell_list.push(func_cell)
    end

    webserver.content_send('<p></p><fieldset><legend><b>Board connector pinout</b></legend>')
    webserver.content_send('<p></p><table>')
    # Init table header
    webserver.content_send('<tbody><tr><th>Pin num.</th>')
    for pin_num : 1..12
      webserver.content_send(format('<td>%i</td>', pin_num))
    end

    # Init default pin name list
    var pin_names = []
    for idx : 0..11 pin_names.push('---') end

    # Adjust pin name list
    for pin : board_info.find("PINS", [])
      var pin_num = pin.find("NUM", nil)
      if (pin_num != nil)
        pin_names[pin_num - 1] = pin.find("NAME", '---')

        # Get function index
        var pin_func_idx = pin.find("FIDX", nil)
        if (pin_func_idx != nil)
          var func_cell = func_cell_list[pin_func_idx]
          func_cell.pin_num_list.push(pin_num)
          if ((func_cell.first_pin_num == 0) || (pin_num < func_cell.first_pin_num))
            func_cell.first_pin_num = pin_num
          end
          if ((func_cell.last_pin_num == 0) || (pin_num > func_cell.last_pin_num))
            func_cell.last_pin_num = pin_num
          end
        end
      end
    end

    # Create table cells for pin names
    webserver.content_send('</tr><tr><th>Pin name</th>')
    for pin_name : pin_names
      webserver.content_send('<td>' + pin_name + '</td>')
    end
    webserver.content_send('</tr>')

    # Determine function cell span
    for fc : func_cell_list
      fc.span = (fc.last_pin_num - fc.first_pin_num) + 1
    end

    # Add empty function cells if there ar unused pins
    var idx = 0
    while ((idx + 1) < func_cell_list.size())
      var func_cell1 = func_cell_list[idx]
      var func_cell2 = func_cell_list[idx + 1]
      var pin_num_diff = func_cell2.first_pin_num - func_cell1.last_pin_num
      if (pin_num_diff > 1)
        var func_cell = FuncCell()
        func_cell.name = '---'
        func_cell.span = pin_num_diff - 1
        func_cell_list.insert(idx + 1, func_cell)
        idx += 2
      else
        idx += 1
      end
    end

    # Create table cells for function names
    webserver.content_send('<tr><th>Function</th>')
    for func_cell : func_cell_list
      if (func_cell.span > 1)
        webserver.content_send('<td colspan="' + str(func_cell.span) + '">' + func_cell.name + '</td>')
      else
        webserver.content_send('<td>' + func_cell.name + '</td>')
      end
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

  def show_board_funcs(board_info)
    webserver.content_send('<p></p><fieldset><legend><b>Board functions</b></legend>')
    webserver.content_send('<p></p>')
    webserver.content_send('<table>')
    webserver.content_send('<thead><tr><th>Name</th><th>Description</th><th colspan="2">Properties</th><th colspan="2">Parameters</th></tr></thead>')
    webserver.content_send('<tbody>')
    for func : board_info.find("FUNCS", [])
      self.show_func(board_info, func)
    end
    webserver.content_send('</tbody></table></fieldset>')
  end

  def show_board_conf(board_info, tasm_gpios, board_gpios)
    # Show board header
    if (self.show_dev_head(board_info))

      # Show board connector pinout
      self.show_board_conn_pinout(board_info)

      # Show functions
      self.show_board_funcs(board_info)

      # Show GPIO configuration
      self.show_gpio_conf(board_info, tasm_gpios, board_gpios)
    end
  end

  def show_ext_board_conf(tasm_gpios, ext_board_id, board_desc_json)
    # Get board GPIO assignments
    var board_gpios = self.ext_gpio_assignments[ext_board_id]
    # Parse JSON
    var board_info = json.load(board_desc_json)

    self.show_board_conf(board_info, tasm_gpios, board_gpios)
  end

  def page_mc_conf_page()
    var test_json_confs = []
    # Get Tasmota GPIOs
    var tasm_gpios = tasmota.cmd('GPIO')
    test_json_confs.push('{"NAME":"High power PWM FET board","DESC":"6pcs high power FETs with current limiting","VER":"1.0","PD":"2024.01.01","PRMS":[{"NAME":"Current limit","VLIST":["0.5A","1A","2A","3A","5A"]}],"PROPS":[{"NAME":"Maximum output current","VAL":"5A"},{"NAME":"Maximum working voltage","VAL":"24V"}],"PINS":[{"NAME":"GND","NUM":1,"FIDX":0},{"NAME":"OUT","NUM":2,"FIDX":0},{"NAME":"GND","NUM":3,"FIDX":1},{"NAME":"OUT","NUM":4,"FIDX":1},{"NAME":"GND","NUM":5,"FIDX":2},{"NAME":"OUT","NUM":6,"FIDX":2},{"NAME":"GND","NUM":7,"FIDX":3},{"NAME":"OUT","NUM":8,"FIDX":3},{"NAME":"GND","NUM":9,"FIDX":4},{"NAME":"OUT","NUM":10,"FIDX":4},{"NAME":"GND","NUM":11,"FIDX":5},{"NAME":"OUT","NUM":12,"FIDX":5}],"FUNCS":[{"NAME":"PWM 1","DESC":"","TYPE":5,"GPIOS":[{"CHID":0,"OPT":3}],"PRMS":[{"PIDX":0,"ACTIDX":0}],"PROPS":[0,1]},{"NAME":"PWM 2","DESC":"","TYPE":5,"GPIOS":[{"CHID":1,"OPT":3}],"PRMS":[{"PIDX":0,"ACTIDX":1}],"PROPS":[0,1]},{"NAME":"PWM 3","DESC":"","TYPE":5,"GPIOS":[{"CHID":2,"OPT":3}],"PRMS":[{"PIDX":0,"ACTIDX":0}],"PROPS":[0,1]},{"NAME":"PWM 4","DESC":"","TYPE":5,"GPIOS":[{"CHID":3,"OPT":3}],"PRMS":[{"PIDX":0,"ACTIDX":2}],"PROPS":[0,1]},{"NAME":"PWM 5","DESC":"","TYPE":5,"GPIOS":[{"CHID":4,"OPT":3}],"PRMS":[{"PIDX":0,"ACTIDX":0}],"PROPS":[0,1]},{"NAME":"PWM 6","DESC":"","TYPE":5,"GPIOS":[{"CHID":5,"OPT":3}],"PRMS":[{"PIDX":0,"ACTIDX":0}],"PROPS":[0,1]}]}')
    test_json_confs.push('{"NAME":"Relay board","DESC":"6pcs of HF32FA-G-005-HSL1 relays","VER":"1.0","PD":"2024.01.01","PROPS":[{"NAME":"Maximum rated current","VAL":"10A"},{"NAME":"Maximum rated voltage","VAL":"250VAC"}],"PINS":[{"NAME":"COM","NUM":1,"FIDX":0},{"NAME":"N.O.","NUM":2,"FIDX":0},{"NAME":"COM","NUM":3,"FIDX":1},{"NAME":"N.O.","NUM":4,"FIDX":1},{"NAME":"COM","NUM":5,"FIDX":2},{"NAME":"N.O.","NUM":6,"FIDX":2},{"NAME":"COM","NUM":7,"FIDX":3},{"NAME":"N.O.","NUM":8,"FIDX":3},{"NAME":"COM","NUM":9,"FIDX":4},{"NAME":"N.O.","NUM":10,"FIDX":4},{"NAME":"COM","NUM":11,"FIDX":5},{"NAME":"N.O.","NUM":12,"FIDX":5}],"FUNCS":[{"NAME":"Relay 1","DESC":"Normally open relay","TYPE":1,"GPIOS":[{"CHID":0,"OPT":1}],"PROPS":[0,1]},{"NAME":"Relay 2","DESC":"Normally open relay","TYPE":1,"GPIOS":[{"CHID":1,"OPT":1}],"PROPS":[0,1]},{"NAME":"Relay 3","DESC":"Normally open relay","TYPE":1,"GPIOS":[{"CHID":2,"OPT":1}],"PROPS":[0,1]},{"NAME":"Relay 4","DESC":"Normally open relay","TYPE":1,"GPIOS":[{"CHID":3,"OPT":1}],"PROPS":[0,1]},{"NAME":"Relay 5","DESC":"Normally open relay","TYPE":1,"GPIOS":[{"CHID":4,"OPT":1}],"PROPS":[0,1]},{"NAME":"Relay 6","DESC":"Normally open relay","TYPE":1,"GPIOS":[{"CHID":5,"OPT":1}],"PROPS":[0,1]}]}')
    test_json_confs.push('{"NAME":"Test board desc","DESC":"This is the descriptor","VER":"1.0","PD":"2024.01.01","PROPS":[{"NAME":"property 1","VAL":"value1"},{"NAME":"property 2","VAL":"value 2"}],"PRMS":[{"NAME":"Param1","VLIST":["val1","val2","val3"]},{"NAME":"Param2","VLIST":["val11","val22","val33"]}],"PINS":[{"NAME":"Pin1","NUM":1,"FDIDX":0},{"NAME":"Pin2","NUM":2,"FDIDX":1},{"NAME":"Pin3","NUM":3,"FDIDX":1},{"NAME":"Pin4","NUM":4,"FDIDX":1},{"NAME":"Pin7","NUM":7,"FDIDX":2},{"NAME":"Pin8","NUM":8,"FDIDX":2},{"NAME":"Pin10","NUM":10,"FDIDX":3},{"NAME":"Pin11","NUM":11,"FDIDX":3}],"FUNCS":[{"NAME":"Func1","DESC":"Func1 desc","TYPE":1,"GPIOS":[{"CHID":2,"OPT":1},{"CHID":3,"OPT":1}],"PROPS":[0],"PRMS":[{"PIDX":1,"ACTIDX":1}]},{"NAME":"Func2","DESC":"Func2 desc","TYPE":1,"GPIO":[{"CHID":4,"OPT":1}],"PROPS":[1]},{"NAME":"Func3","DESC":"Func3 desc","TYPE":1,"GPIO":[{"CHID":5,"OPT":1}],"PRMS":[{"PIDX":0,"ACTIDX":1},{"PIDX":1,"ACTIDX":2}]},{"NAME":"Func4","DESC":"Func4 desc","TYPE":1,"GPIO":[{"CHID":5,"OPT":1}],"PRMS":[{"PIDX":0,"ACTIDX":0}]}]}')
    test_json_confs.push('')

    # Scan I2C bus for device addresses
    var i2x_addr_list = wire1.scan()
    webserver.content_start("Multicontroller Configuration")
    webserver.content_send_style()
    webserver.content_send('<style>table{width: 100%;border-collapse: collapse;}th, td{border: 1px solid gray;padding: 8px;text-align: center;}th{background-color: gray;}</style>')

    for i2x_addr: i2x_addr_list
      # Find external board addresses
      if (i2x_addr >= 80) && (i2x_addr <= 83)

        # Calculate board ID
        var ext_board_id = i2x_addr - 80

        # Display board information
        webserver.content_send('<p></p><p></p><fieldset><legend><b>Extension slot ' + str(ext_board_id + 1) + '</b></legend>')
        self.show_ext_board_conf(tasm_gpios, ext_board_id, test_json_confs[ext_board_id])
        webserver.content_send('</fieldset>')
      end
    end

    webserver.content_send("<p></p><button onclick='la(\"&m_toggle_conf=1\");'>Test Button</button>")
    webserver.content_button(webserver.BUTTON_CONFIGURATION) #- button back to configuration page -#
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
