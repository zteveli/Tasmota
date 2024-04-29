import webserver
import json

class McParam
  var name
  var act_value
  var value_list
end

class McProp
  var name
  var value
end

class McGpio
  var chid
  var opt
end

class McPin
  var name
  var num
  var func_idx
  var func # Reference to McFunc
end

class McFunc
  var name
  var desc
  var type
  var gpios # List of McGpio
  var params # List of McParam references
  var props # List of McProp references
  var pins # List of McPin. Evaluated when pins are already processed
end

class McBoardInfo
  var name
  var desc
  var version
  var prod_date
  var props # List of McProp
  var params # List of McParam
  var pins # List of McPin
  var funcs # List of McFunc
end

class McExtBoard

  static ch_types = {1:'output', 2:'input', 3:'PWM output', 4:'Latching relay set output', 5:'Latching relay reset output'}
  var info

  def init(dev_conf)
    # Create internal representation of device information
    var info_map = json.load(dev_conf)
    if (info_map)
      self.info = McBoardInfo()
      self.info.name = info_map.find('NAME', '')
      self.info.desc = info_map.find('DESC', '')
      self.info.version = info_map.find('VER', '')
      self.info.prod_date = info_map.find('PD', '')
      self.info.props = []
      self.info.params = []
      self.info.pins = []
      self.info.funcs = []

      var params_json = info_map.find('PRMS', [])
      var props_json = info_map.find('PROPS', [])
      var pins_json = info_map.find('PINS', [])
      var funcs_json = info_map.find('FUNCS', [])

      self.get_detailed_board_info(params_json, props_json, pins_json, funcs_json)
    else
      self.info = nil
    end
  end

  def get_param_list(params_json)
    var ret_params = []

    for param_json : params_json
      var param = McParam()
      param.name = param_json.find("NAME", '')
      param.value_list = param_json.find("VLIST", [])

      ret_params.push(param)
    end

    return ret_params
end

  def get_property_list(props_json)
    var ret_props = []

    for prop_json : props_json
      var prop = McProp()
      prop.name = prop_json.find("NAME", '')
      prop.value = prop_json.find("VAL", '')

      ret_props.push(prop)
    end

    return ret_props
  end

  def get_pin_list(pins_json)
    var ret_pins = []

    for pin_json : pins_json
      var pin = McPin()
      pin.name = pin_json.find("NAME", '')
      pin.num = pin_json.find("NUM", nil)
      pin.func_idx = pin_json.find("FIDX", nil)
 
      ret_pins.push(pin)
    end

    return ret_pins
  end

  def get_gpio_list(gpios_json)
    var ret_gpios = []

    for gpio_json : gpios_json
      var gpio = McGpio()
      gpio.chid = gpio_json.find("CHID", nil)
      gpio.opt = gpio_json.find("OPT", nil)

      ret_gpios.push(gpio)
    end

    return ret_gpios
  end

  def get_function_list(funcs_json, params, props)
    var ret_func_list = []

    for func_json : funcs_json
      var func = McFunc()
      func.name = func_json.find("NAME", '')
      func.desc = func_json.find("DESC", '')
      func.type = func_json.find("TYPE", nil)
      func.gpios = self.get_function_list(func_json.find("GPIOS", []))
      func.params = []
      func.props = []
      func.pins = []
    
      # Find parameter references
      for param_json : func_json.find("PRMS", [])
        var param_idx = param_json.find("PIDX", nil)

        if (param_idx)
          var param = params[param_idx]
          param.act_value = param_json.find("ACT", '')
          func.params.push(param)
        end
      end

      # Find property references
      for prop_idx : func_json.find("PROPS", [])
        func.props.push(props[prop_idx])
      end

      ret_func_list.push(func)
    end

    return ret_func_list
  end

  def get_detailed_board_info(params_json, props_json, pins_json, funcs_json)
    self.info.params = self.get_param_list(params_json)
    self.info.props = self.get_property_list(props_json)
    self.info.pins = self.get_pin_list(pins_json)
    self.info.funcs = self.get_function_list(funcs_json, self.info.params, self.info.props)

    # Find function references for pins
    for pin : self.info.pins
      if (pin.func_idx)
        var func = self.info.funcs[pin.func_idx]
        pin.func = func
        func.pins.push(pin)
      end
    end
  end
end

#edi = McExtBoard('{"NAME":"High power PWM FET board","DESC":"6pcs high power FETs with current limiting","VER":"1.0","PD":"2024.01.01","PRMS":{"PRM_1":{"NAME":"Current limit","PLIST":["0.5A","1A","2A","3A","5A"]}},"PROPS":{"PR_1":{"NAME":"Maximum output current","VAL":"5A"},"PR_2":{"NAME":"Maximum working voltage","VAL":"24V"}},"IOCH":[{"NAME":"PWM out 1","DESC":"","POS":1,"TYPE":1,"PRMS":[{"PREF":"PRM_1","ACT":"1A"}],"PROPS":["PR_1"]},{"NAME":"PWM out 2","DESC":"","POS":2,"TYPE":1,"PRMS":[{"PREF":"PRM_1","ACT":"1A"}],"PROPS":["PR_1"]},{"NAME":"PWM out 3","DESC":"","POS":3,"TYPE":1,"PRMS":[{"PREF":"PRM_1","ACT":"1A"}],"PROPS":["PR_1"]},{"NAME":"PWM out 4","DESC":"","POS":4,"TYPE":1,"PRMS":[{"PREF":"PRM_1","ACT":"1A"}],"PROPS":["PR_1"]},{"NAME":"PWM out 5","DESC":"","POS":5,"TYPE":1,"PRMS":[{"PREF":"PRM_1","ACT":"1A"}],"PROPS":["PR_1"]},{"NAME":"PWM out 6","DESC":"","POS":6,"TYPE":1,"PRMS":[{"PREF":"PRM_1","ACT":"1A"}],"PROPS":["PR_1"]}]}')
#edi.display_dev_info()

class Multicontroller

  static ext1gpios = ['GPIO5', 'GPIO35', 'GPIO36', 'GPIO37', 'GPIO38', 'GPIO39']
  static ext2gpios = ['GPIO6', 'GPIO6', 'GPIO15', 'GPIO16', 'GPIO17', 'GPIO8']
  static ext3gpios = ['GPIO14', 'GPIO13', 'GPIO12', 'GPIO11', 'GPIO10', 'GPIO9']
  static ext4gpios = ['GPIO21', 'GPIO47', 'GPIO48', 'GPIO40', 'GPIO41', 'GPIO42']
  var all_ext_gpios

  def init()
    self.all_ext_gpios = [self.ext1gpios, self.ext2gpios, self.ext3gpios, self.ext4gpios]
    tasmota.add_driver(self)
    self.web_add_handler()
  end

  def close()
    tasmota.remove_driver(self)
  end

  def create_func_params(params)
    var ret = ''

    if (params.size() > 0)
      ret += '<table><thead><tr><th>Name</th><th>Value</th></tr></thead><tbody>'

      for param : params
        ret += '<tr><td>' + param.name + '</td><td><select>'
        for value : param.value_list
          ret += '<option value="opt_' + value + '"'
          if (value == param.act_value)
            ret += ' selected'
          end
          ret += '>' + value + '</option>'
        end
        ret += '</select></td></tr>'
      end

      ret += '</tbody></table>'
    end

    return ret
  end

  def create_func_props(props)
    var ret = ''

    if (props.size() > 0)
      ret = '<table><thead><tr><th>Name</th><th>Value</th></tr></thead><tbody>'

      for prop : props
        ret += '<tr><td>' + prop.name + "</td><td>" + prop.value + '</td></tr>'
      end

      ret += '</tbody></table>'
    end

    return ret
  end

  def show_func(func)
    webserver.content_send('<td>' + func.name + '</td>')
    webserver.content_send('<td>' + func.desc + '</td>')

    var props = self.create_func_props(func.props)
    var params = self.create_func_params(func.params)

    webserver.content_send('<td>' + props + '</td>')
    webserver.content_send('<td>' + params + '</td>')
  end

  def show_dev_info(dev_info, all_gpios, ext_gpios)
    # Show board information
    webserver.content_send('<p></p><fieldset><legend><b>Board information</b></legend>')
    if (dev_info)
      webserver.content_send('<p></p><table><tbody>')
      if (dev_info.name) webserver.content_send('<tr><td><b>Name:</b></td><td>' + dev_info.name + '</td></tr>') end
      if (dev_info.desc) webserver.content_send('<tr><td><b>Desc.:</b></td><td>' + dev_info.desc + '</td></tr>') end
      if (dev_info.version) webserver.content_send('<tr><td><b>Ver.:</b></td><td>' + dev_info.version + '</td></tr>') end
      if (dev_info.prod_date) webserver.content_send('<tr><td><b>Prod.:</b></td><td>' + dev_info.prod_date + '</td></tr>') end
      webserver.content_send('</tbody></table></fieldset>')

      # Show board connector pinout
      webserver.content_send('<p></p><fieldset><legend><b>Board connector pinout</b></legend>')
      webserver.content_send('<p></p><table>')
      webserver.content_send('<thead><tr><th>Pin num.</th>')
      for pin_num : 1..12
        webserver.content_send(format('<th>%i</th>', pin_num))
      end
      webserver.content_send('</tr></thead>')
      webserver.content_send('<tbody>')
      webserver.content_send('<tr><td>Pin name</td>')
      var pin_names = []
      for idx : 0..11 pin_names.push('N.C.') end

      for pin : dev_info.pins
        if (pin.num)
          pin_names[pin.num - 1] = pin.name
        end
      end

      for pin_name : pin_names
        webserver.content_send('<td>' + pin_name + '</td>')
      end
      webserver.content_send('</tr>')

      class FuncCell
        var name
        var span
        var first_pin_num
        var last_pin_num
      end

      var func_cell_list = []
      for func : dev_info.funcs
        var func_cell = FuncCell()
        func_cell.name = func.name
        func_cell.span = func.pins.size()
        func_cell.first_pin_num = (func.pins.item(0)).num
        func_cell.last_pin_num = (func.pins.item(-1)).num
        func_cell_list.push(func_cell)
      end

      # Fill the gaps
#      var idx = 0
#      while true
#        var func_cell1 = func_cell_list.item(idx)
#        var func_cell2 = func_cell_list.item(idx + 1)
#        if (func_cell1 && func_cell2)
#          var pin_num_diff = func_cell2.first_pin_num - func_cell1.last_pin_num
#          if (pin_num_diff > 1)
#            var func_cell = FuncCell()
#            func_cell.name = ''
#            func_cell.span = pin_num_diff - 1
#            func_cell_list.insert(func_cell)
#            idx += 2
#          end
#        end
#      end

      webserver.content_send('<tr><td>Func.</td>')
      for func_cell : func_cell_list
        if (func_cell.span > 1)
          webserver.content_send('<td rowspan="' + str(func_cell.span) + '">' + func_cell.name + '</td>')
        else
          webserver.content_send('<td>' + func_cell.name + '</td>')
        end
      end
      webserver.content_send('</tr>')
      webserver.content_send('</tbody></table>')
      webserver.content_send('</fieldset>')
  
      # Show functions
      webserver.content_send('<p></p><fieldset><legend><b>Functions</b></legend>')
      webserver.content_send('<p></p>')
      webserver.content_send('<table>')
      webserver.content_send('<thead><tr><th>Name</th><th>Description</th><th>Properties</th><th>Parameters</th></tr></thead>')
      webserver.content_send('<tbody>')
      for func : dev_info.funcs
        webserver.content_send('<tr>')
        self.show_func(func)
        webserver.content_send('</tr>')
      end
      webserver.content_send('</tbody></table>')
    else
      webserver.content_send('<p></p><b>NO DEVICE INFORMATION!</b>')
    end
    webserver.content_send('</fieldset>')

    # Show GPIO configuration
    webserver.content_send('<p></p><fieldset><legend><b>Tasmota GPIO configuration</b></legend>')
    for gpio_idx : 0 .. 5
      gpio = all_gpios.find(ext_gpios[gpio_idx], [])
      for item : gpio
        webserver.content_send("<p></p><b>Channel " + str(gpio_idx + 1) + ":</b> " + item)
        print(gpio.tostring())
      end
    end
    webserver.content_send('</fieldset>')
  end

  def show_ext_board_conf(ext_board_id, conf_json)
    var ext_gpios = self.all_ext_gpios[ext_board_id]
    var all_gpios = tasmota.cmd('GPIO')
    var mc_ext_dev = McExtBoard(conf_json)
    var dev_info = mc_ext_dev.info

    self.show_dev_info(dev_info, all_gpios, ext_gpios)
  end

  def page_mc_conf_page()
    var test_json_confs = []
    test_json_confs.push('{"NAME":"High power PWM FET board","DESC":"6pcs high power FETs with current limiting","VER":"1.0","PD":"2024.01.01","PRMS":[{"NAME":"Current limit","VLIST":["0.5A","1A","2A","3A","5A"]}],"PROPS":[{"NAME":"Maximum output current","VAL":"5A"},{"NAME":"Maximum working voltage","VAL":"24V"}],"PINS":[{"NAME":"GND","NUM":1,"FIDX":0},{"NAME":"OUT","NUM":2,"FIDX":0},{"NAME":"GND","NUM":3,"FIDX":1},{"NAME":"OUT","NUM":4,"FIDX":1},{"NAME":"GND","NUM":5,"FIDX":2},{"NAME":"OUT","NUM":6,"FIDX":2},{"NAME":"GND","NUM":7,"FIDX":3},{"NAME":"OUT","NUM":8,"FIDX":3},{"NAME":"GND","NUM":9,"FIDX":4},{"NAME":"OUT","NUM":10,"FIDX":4},{"NAME":"GND","NUM":11,"FIDX":5},{"NAME":"OUT","NUM":12,"FIDX":5}],"FUNCS":[{"NAME":"PWM out 1","DESC":"","TYPE":5,"GPIOS":[{"CHID":0,"OPT":3}],"PRMS":[{"PIDX":0,"ACT":"1A"}],"PROPS":[0,1]},{"NAME":"PWM out 2","DESC":"","TYPE":5,"GPIOS":[{"CHID":1,"OPT":3}],"PRMS":[{"PIDX":0,"ACT":"1A"}],"PROPS":[0,1]},{"NAME":"PWM out 3","DESC":"","TYPE":5,"GPIOS":[{"CHID":2,"OPT":3}],"PRMS":[{"PIDX":0,"ACT":"1A"}],"PROPS":[0,1]},{"NAME":"PWM out 4","DESC":"","TYPE":5,"GPIOS":[{"CHID":3,"OPT":3}],"PRMS":[{"PIDX":0,"ACT":"1A"}],"PROPS":[0,1]},{"NAME":"PWM out 5","DESC":"","TYPE":5,"GPIOS":[{"CHID":4,"OPT":3}],"PRMS":[{"PIDX":0,"ACT":"1A"}],"PROPS":[0,1]},{"NAME":"PWM out 6","DESC":"","TYPE":5,"GPIO":[{"CHID":5,"OPT":3}],"PRMS":[{"PIDX":0,"ACT":"1A"}],"PROPS":[0,1]}]}')
    test_json_confs.push('')
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
        var ext_board_id = i2x_addr - 79

        # Display board information
        webserver.content_send('<p></p><p></p><fieldset><legend><b>Extension slot ' + str(ext_board_id) + '</b></legend>')
        self.show_ext_board_conf(ext_board_id - 1, test_json_confs[ext_board_id - 1])
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
