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
    end
      webserver.content_send('</fieldset>')
  end

  def show_gpio_conf(tasm_gpios, board_gpios)
    webserver.content_send('<p></p><fieldset><legend><b>Tasmota GPIO configuration</b></legend>')
    for gpio_idx : 0 .. 5
      var gpio_name = board_gpios[gpio_idx]
      var gpio = tasm_gpios.find(gpio_name, {})
      webserver.content_send('<p></p><b>' + gpio_name + '</b>: ' + gpio.tostring())
    end
    webserver.content_send('</fieldset>')
  end

  def show_board_conn_pinout(board_info)
    webserver.content_send('<p></p><fieldset><legend><b>Board connector pinout</b></legend>')
    webserver.content_send('<p></p><table>')
    # Init table header
    webserver.content_send('<thead><tr><th>Pin num.</th>')
    for pin_num : 1..12
      webserver.content_send(format('<th text-align: center>%i</th>', pin_num))
    end

    # Init default pin name list
    var pin_names = []
    for idx : 0..11 pin_names.push('N.C.') end

    # Adjust pin name list
    for pin : board_info.find("PINS", [])
      var pin_num = pin.find("NUM", nil)
      if (pin_num != nil)
        pin_names[pin_num - 1] = pin.find("NAME", 'N.A.')
      end
    end

    # Create table cells for pi names
    webserver.content_send('</tr></thead><tbody><tr><td>Pin name</td>')
    for pin_name : pin_names
      webserver.content_send('<td>' + pin_name + '</td>')
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
    var props = board_info.find("PROPS", [])
    var params = board_info.find("PRMS", [])
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

      var prop = nil
      if (row < props.size())
        prop = props[row]
        print(prop.tostring())
      end

      var param = nil
      if (row < params.size())
        param = params[row]
        print(param.tostring())
      end

      var func_param = func_params.find(row)
      if (prop != nil) webserver.content_send('<td>' + prop.find("NAME", '') + '</td><td>' + prop.find("VAL", '') + '</td>') else webserver.content_send('<td></td><td></td>') end
      if (param != nil) 
        webserver.content_send('<td>' + param.find("NAME", '') + '</td>')
        var option_list = '<select>'
        for value : param.find("VLIST", '')
          option_list += '<option value="opt_' + value + '"'
          if ((func_param != nil) && (value == func_param.find("ACT", '')))
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
    self.show_dev_head(board_info)

    # Show board connector pinout
    self.show_board_conn_pinout(board_info)
#    class FuncCell
#      var name
#      var span
#      var first_pin_num
#      var last_pin_num
#    end

#    var func_cell_list = []
#    for func : board_info.funcs
#      var func_cell = FuncCell()
#      func_cell.name = func.name
#      func_cell.span = func.pins.size()
#      var first_pin = func.pins.item(0)
#      print(func_cell.name)
#      var itemf = func.pins.find(0)
#      var itemf = func.pins.item(0)
#      var iteml = func.pins.find(-1)
#      var iteml = func.pins.item(-1)
#      if (itemf) print(itemf.tostring()) end
#      if (iteml) print(iteml.tostring()) end
#      func_cell.first_pin_num = (func.pins.find(0)).num
#      func_cell.last_pin_num = (func.pins.find(-1)).num
#      func_cell_list.push(func_cell)
#    end

    # Fill in the gaps
#    var idx = 0
#    var exit = false
#    while (!exit)
#      var func_cell1 = func_cell_list.find(idx)
#      var func_cell2 = func_cell_list.find(idx + 1)
#      if (func_cell1 && func_cell2)
#        var pin_num_diff = func_cell2.first_pin_num - func_cell1.last_pin_num
#        if (pin_num_diff > 1)
#          var func_cell = FuncCell()
#          func_cell.name = ''
#          func_cell.span = pin_num_diff - 1
#          func_cell_list.insert(idx + 1, func_cell)
#          idx += 2
#        else
#          idx += 1
#        end
#      else
#        exit = true
#      end
#    end

#    webserver.content_send('<tr><td>Func.</td>')
#    for func_cell : func_cell_list
#      if (func_cell.span > 1)
#        webserver.content_send('<td colspan="' + str(func_cell.span) + '">' + func_cell.name + '</td>')
#      else
#        webserver.content_send('<td>' + func_cell.name + '</td>')
#      end
#    end
#    webserver.content_send('</tr>')

    # Show functions
    self.show_board_funcs(board_info)

    # Show GPIO configuration
    self.show_gpio_conf(tasm_gpios, board_gpios)
  end

  def show_ext_board_conf(ext_board_id, board_desc_json)
    # Get board GPIO assignments
    var board_gpios = self.ext_gpio_assignments[ext_board_id]
    # Get Tasmota GPIOs
    var tasm_gpios = tasmota.cmd('GPIO')
    # Parse JSON
    var board_info = json.load(board_desc_json)

    self.show_board_conf(board_info, tasm_gpios, board_gpios)
  end

  def page_mc_conf_page()
    var test_json_confs = []
    test_json_confs.push('{"NAME":"High power PWM FET board","DESC":"6pcs high power FETs with current limiting","VER":"1.0","PD":"2024.01.01","PRMS":[{"NAME":"Current limit","VLIST":["0.5A","1A","2A","3A","5A"]}],"PROPS":[{"NAME":"Maximum output current","VAL":"5A"},{"NAME":"Maximum working voltage","VAL":"24V"}],"PINS":[{"NAME":"GND","NUM":1,"FIDX":0},{"NAME":"OUT","NUM":2,"FIDX":0},{"NAME":"GND","NUM":3,"FIDX":1},{"NAME":"OUT","NUM":4,"FIDX":1},{"NAME":"GND","NUM":5,"FIDX":2},{"NAME":"OUT","NUM":6,"FIDX":2},{"NAME":"GND","NUM":7,"FIDX":3},{"NAME":"OUT","NUM":8,"FIDX":3},{"NAME":"GND","NUM":9,"FIDX":4},{"NAME":"OUT","NUM":10,"FIDX":4},{"NAME":"GND","NUM":11,"FIDX":5},{"NAME":"OUT","NUM":12,"FIDX":5}],"FUNCS":[{"NAME":"PWM out 1","DESC":"","TYPE":5,"GPIOS":[{"CHID":0,"OPT":3}],"PRMS":[{"PIDX":0,"ACT":"1A"}],"PROPS":[0,1]},{"NAME":"PWM out 2","DESC":"","TYPE":5,"GPIOS":[{"CHID":1,"OPT":3}],"PRMS":[{"PIDX":0,"ACT":"1A"}],"PROPS":[0,1]},{"NAME":"PWM out 3","DESC":"","TYPE":5,"GPIOS":[{"CHID":2,"OPT":3}],"PRMS":[{"PIDX":0,"ACT":"1A"}],"PROPS":[0,1]},{"NAME":"PWM out 4","DESC":"","TYPE":5,"GPIOS":[{"CHID":3,"OPT":3}],"PRMS":[{"PIDX":0,"ACT":"1A"}],"PROPS":[0,1]},{"NAME":"PWM out 5","DESC":"","TYPE":5,"GPIOS":[{"CHID":4,"OPT":3}],"PRMS":[{"PIDX":0,"ACT":"1A"}],"PROPS":[0,1]},{"NAME":"PWM out 6","DESC":"","TYPE":5,"GPIO":[{"CHID":5,"OPT":3}],"PRMS":[{"PIDX":0,"ACT":"1A"}],"PROPS":[0,1]}]}')
    test_json_confs.push('{"NAME":"Relay board","DESC":"6pcs of HF32FA-G-005-HSL1 relays","VER":"1.0","PD":"2024.01.01","PROPS":[{"NAME":"Maximum rated current","VAL":"10A"},{"NAME":"Maximum rated voltage","VAL":"250VAC"}],"PINS":[{"NAME":"COM","NUM":1,"FDIDX":0},{"NAME":"NO","NUM":2,"FDIDX":0},{"NAME":"COM","NUM":3,"FDIDX":1},{"NAME":"NO","NUM":4,"FDIDX":1},{"NAME":"COM","NUM":5,"FDIDX":2},{"NAME":"NO","NUM":6,"FDIDX":2},{"NAME":"COM","NUM":7,"FDIDX":3},{"NAME":"NO","NUM":8,"FDIDX":3},{"NAME":"COM","NUM":9,"FDIDX":4},{"NAME":"NO","NUM":10,"FDIDX":4},{"NAME":"COM","NUM":11,"FDIDX":5},{"NAME":"NO","NUM":12,"FDIDX":5}],"FUNCS":[{"NAME":"Relay 1","DESC":"NO relay","TYPE":1,"GPIOS":[{"CHID":0,"OPT":1}],"PROPS":[0,1]},{"NAME":"Relay 2","DESC":"NO relay","TYPE":1,"GPIO":[{"CHID":1,"OPT":1}],"PROPS":[0,1]},{"NAME":"Relay 3","DESC":"NO relay","TYPE":1,"GPIO":[{"CHID":2,"OPT":1}],"PROPS":[0,1]},{"NAME":"Relay 4","DESC":"NO relay","TYPE":1,"GPIO":[{"CHID":3,"OPT":1}],"PROPS":[0,1]},{"NAME":"Relay 5","DESC":"NO relay","TYPE":1,"GPIO":[{"CHID":4,"OPT":1}],"PROPS":[0,1]},{"NAME":"Relay 6","DESC":"NO relay","TYPE":1,"GPIO":[{"CHID":5,"OPT":1}],"PROPS":[0,1]}]}')
    test_json_confs.push('')
    test_json_confs.push('')

    # Scan I2C bus for device addresses
    var i2x_addr_list = wire1.scan()
    webserver.content_start("Multicontroller Configuration")
    webserver.content_send_style()
    webserver.content_send('<style>table{width: 100%;border-collapse: collapse;}th, td{border: 1px solid gray;padding: 8px;text-align: left;}th{background-color: gray;}</style>')

    for i2x_addr: i2x_addr_list
      # Find external board addresses
      if (i2x_addr >= 80) && (i2x_addr <= 83)

        # Calculate board ID
        var ext_board_id = i2x_addr - 80

        # Display board information
        webserver.content_send('<p></p><p></p><fieldset><legend><b>Extension slot ' + str(ext_board_id + 1) + '</b></legend>')
        self.show_ext_board_conf(ext_board_id, test_json_confs[ext_board_id])
        webserver.content_send('</fieldset>')
      end
    end

    webserver.content_send("<p></p><button onclick='la(\"&m_toggle_conf=1\");'>Test Button</button>")
    webserver.content_button(webserver.BUTTON_CONFIGURATION) #- button back to configuration page -#
    webserver.content_stop()
  end

  def page_mc_status_page()
    webserver.content_start("Multicontroller Status")
    webserver.content_send_style()
    webserver.content_send("<p></p><button onclick='la(\"&m_toggle_conf=1\");'>Test Button</button>")
    webserver.content_button(webserver.BUTTON_MAIN) #- button back to main page -#
    webserver.content_stop()
  end

  #- create a method for adding a button to the main menu -#
  def web_add_main_button()
    webserver.content_send("<p></p><form action='/mc_status' method='post'><button>Multicontroller Status</button></form>")
  end

  #- create a method for adding a button to the configuration menu-#
  def web_add_config_button()
    #- the onclick function "la" takes the function name and the respective value you want to send as an argument -#
    webserver.content_send("<p></p><form action='/mc_conf' method='post'><button>Multicontroller Configuration</button></form>")
  end

  #- As we can add only one sensor method we will have to combine them besides all other sensor readings in one method -#
  def web_sensor()

    webserver.content_send("<p></p><button onclick='la(\"&m_toggle_conf=1\");'>Test Button</button>")

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
    webserver.on("/mc_status", / -> self.page_mc_status_page())
    webserver.on("/mc_conf", / -> self.page_mc_conf_page())
    print("'/mc_status' page added")
    print("'/mc_conf' page added")
    end
end

mc = Multicontroller()
