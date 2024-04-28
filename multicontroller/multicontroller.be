import webserver
import json

class IoChParam
  var name
  var act_value
  var value_list
end

class IoChProp
  var name
  var value
end

class IoCh
  var name
  var desc
  var position
  var type_id
  var type_name
  var properties
  var parameters
end

class ExtDevInfo
  var name
  var desc
  var version
  var prod_date
  var properties
  var parameters
  var io_channels
end

class MCExtDev

  static ch_types = {1:'output', 2:'input', 3:'PWM output', 4:'Latching relay set output', 5:'Latching relay reset output'}
  var info

  def init(dev_conf)
    # Create internal representation of device information
    var info_map = json.load(dev_conf)
    if (info_map)
      self.info = ExtDevInfo()
      self.info.name = info_map.find('NAME', nil)
      self.info.desc = info_map.find('DESC', nil)
      self.info.version = info_map.find('VER', nil)
      self.info.prod_date = info_map.find('PD', nil)
      self.info.properties = info_map.find('PROPS', nil)
      self.info.parameters = info_map.find('PRMS', nil)
      self.info.io_channels = []

      self.get_io_channels(info_map.find('IOCH', []))
    else
      self.info = nil
    end
  end

  def get_io_channels(io_channels)
    for ioch : io_channels
      var ioch_info = IoCh()
      ioch_info.name = ioch.find('NAME', nil)
      ioch_info.desc = ioch.find('DESC', nil)
      ioch_info.position = ioch.find('POS', nil)
      ioch_info.type_id = ioch.find('TYPE', nil)
      if (ioch_info.type_id)
        ioch_info.type_name = self.ch_types.find(ioch_info.type_id)
      else
        ioch_info.type_name = ""
      end
      ioch_info.properties = []
      ioch_info.parameters = []

      var props = ioch.find('PROPS', nil)
      var params = ioch.find('PRMS', nil)
  
      if (props)
        for prop : props
          var global_prop = self.info.properties.find(prop, nil)
  
          if (global_prop)
            var add_property = IoChProp()
            add_property.name = global_prop.find("NAME", "")
            add_property.value = global_prop.find("VAL", "")
            ioch_info.properties.push(add_property)
          end
        end
      end

      if (params)
        for param : params
          var pref = param.find("PREF", nil)
          var act_value = param.find("ACT", nil)
          if (pref)
            var global_param = self.info.parameters.find(pref, nil)

            if (global_param)
              var add_param = IoChParam()
              add_param.name = global_param.find("NAME", nil)
              add_param.value_list = global_param.find("PLIST", nil)
              add_param.act_value = act_value
              if (add_param.name)
                ioch_info.parameters.push(add_param)
              end
            end
          end
        end
      end

      self.info.io_channels.push(ioch_info)
    end
  end

  def display_ioch_params(params)
    print("      Parameters: ")
    for param : params
      print("        " + param.name + ": " + param.act_value)
    end
  end

  def display_ioch_properties(props)
    print("      Properties: ")
    for prop : props
      print("        " + prop.name + ": " + prop.value)
    end
  end

  def display_ioch_info(ioch)
    print("    " + str(ioch.position) + ":")
    if (ioch.name) print("      Name: " + ioch.name) end
    if (ioch.desc) print("      Description: " + ioch.desc) end
    if (ioch.type_name) print("      Type: " + ioch.type_name) end

    self.display_ioch_properties(ioch.properties)
    self.display_ioch_params(ioch.parameters)
  end

  def display_dev_info()
    # Print device descriptions
    print("Device:")
    if (self.dev.name) print("  Name: " + self.dev.name) end
    if (self.dev.desc) print("  Description: " + self.dev.desc) end
    if (self.dev.version) print("  Version: " + self.dev.version) end
    if (self.dev.prod_date) print("  Production date: " + self.dev.prod_date) end

    # Print I/O channels
    print("\n  I/O channels:")

    for ioch : self.dev.io_channels
      self.display_ioch_info(ioch)
    end
  end
end

#edi = MCExtDev('{"NAME":"High power PWM FET board","DESC":"6pcs high power FETs with current limiting","VER":"1.0","PD":"2024.01.01","PRMS":{"PRM_1":{"NAME":"Current limit","PLIST":["0.5A","1A","2A","3A","5A"]}},"PROPS":{"PR_1":{"NAME":"Maximum output current","VAL":"5A"},"PR_2":{"NAME":"Maximum working voltage","VAL":"24V"}},"IOCH":[{"NAME":"PWM out 1","DESC":"","POS":1,"TYPE":1,"PRMS":[{"PREF":"PRM_1","ACT":"1A"}],"PROPS":["PR_1"]},{"NAME":"PWM out 2","DESC":"","POS":2,"TYPE":1,"PRMS":[{"PREF":"PRM_1","ACT":"1A"}],"PROPS":["PR_1"]},{"NAME":"PWM out 3","DESC":"","POS":3,"TYPE":1,"PRMS":[{"PREF":"PRM_1","ACT":"1A"}],"PROPS":["PR_1"]},{"NAME":"PWM out 4","DESC":"","POS":4,"TYPE":1,"PRMS":[{"PREF":"PRM_1","ACT":"1A"}],"PROPS":["PR_1"]},{"NAME":"PWM out 5","DESC":"","POS":5,"TYPE":1,"PRMS":[{"PREF":"PRM_1","ACT":"1A"}],"PROPS":["PR_1"]},{"NAME":"PWM out 6","DESC":"","POS":6,"TYPE":1,"PRMS":[{"PREF":"PRM_1","ACT":"1A"}],"PROPS":["PR_1"]}]}')
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

  def create_ioch_params(params)
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

  def create_ioch_properties(props)
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

  def show_ioch_info(ioch)
    if (ioch.position) webserver.content_send('<td>' + str(ioch.position) + '</td>') else webserver.content_send('<td></td>') end
    if (ioch.name) webserver.content_send('<td>' + ioch.name + '</td>') else webserver.content_send('<td></td>') end
    if (ioch.desc) webserver.content_send('<td>' + ioch.desc + '</td>') else webserver.content_send('<td></td>') end
    if (ioch.type_name) webserver.content_send('<td>' + ioch.type_name + '</td>') else webserver.content_send('<td></td>') end

    var props = self.create_ioch_properties(ioch.properties)
    var params = self.create_ioch_params(ioch.parameters)

    webserver.content_send('<td>' + props + '</td>')
    webserver.content_send('<td>' + params + '</td>')
  end

  def show_dev_info(dev_info, all_gpios, ext_gpios)
    # Show board information
    webserver.content_send('<p></p><fieldset><legend><b>Board information</b></legend>')
    if (dev_info)
      if (dev_info.name) webserver.content_send('<p></p><b>Name:</b>' + dev_info.name) end
      if (dev_info.desc) webserver.content_send('<p></p><b>Desc.:</b> ' + dev_info.desc) end
      if (dev_info.version) webserver.content_send('<p></p><b>Ver.:</b> ' + dev_info.version) end
      if (dev_info.prod_date) webserver.content_send('<p></p><b>Prod.:</b> ' + dev_info.prod_date) end
      webserver.content_send('</fieldset>')

      # Show board connector pinout
      webserver.content_send('<p></p><fieldset><legend><b>Board connector pinout</b></legend>')
      webserver.content_send('<p></p><table>')
      webserver.content_send('<thead><tr>')
      for pin_num : 1..12
        webserver.content_send(format('<th>%i</th>', pin_num))
      end
      webserver.content_send('</tr></thead>')
      webserver.content_send('<tbody>')
      webserver.content_send('<tr></tr>')
      webserver.content_send('</tbody></table>')
      webserver.content_send('</fieldset>')
  
      # Show I/O channel configuration
      webserver.content_send('<p></p><fieldset><legend><b>I/O channels</b></legend>')
      webserver.content_send('<p></p>')
      webserver.content_send('<table>')
      webserver.content_send('<thead><tr><th>Ch.</th><th>Name</th><th>Description</th><th>Type</th><th>Properties</th><th>Parameters</th></tr></thead>')
      webserver.content_send('<tbody>')
      for ioch : dev_info.io_channels
        webserver.content_send('<tr>')
        self.show_ioch_info(ioch)
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

  def show_ext_board_conf(ext_slot, conf_json)
    var ext_gpios = self.all_ext_gpios[ext_slot]
    var all_gpios = tasmota.cmd('GPIO')
    var mc_ext_dev = MCExtDev(conf_json)
    var dev_info = mc_ext_dev.info

    self.show_dev_info(dev_info, all_gpios, ext_gpios)
  end

  def page_mc_conf_page()
    var test_json_confs = []
    test_json_confs.push('{"NAME":"Relay board","DESC":"6pcs of HF32FA-G-005-HSL1 relays","VER":"1.0","PD":"2024.01.01","PROPS":{"PR_1":{"NAME":"Maximum power load","VAL":"10A 250VAC"}},"IOCH":[{"NAME":"Relay 1","DESC":"NC/NO relay","POS":1,"TYPE":1,"PROPS":["PR_1"]},{"NAME":"Relay 2","DESC":"NC/NO relay","POS":2,"TYPE":1,"PROPS":["PR_1"]},{"NAME":"Relay 3","DESC":"NC/NO relay","POS":3,"TYPE":1,"PROPS":["PR_1"]},{"NAME":"Relay 4","DESC":"NC/NO relay","POS":4,"TYPE":1,"PROPS":["PR_1"]},{"NAME":"Relay 5","DESC":"NC/NO relay","POS":5,"TYPE":1,"PROPS":["PR_1"]},{"NAME":"Relay 6","DESC":"NC/NO relay","POS":6,"TYPE":1,"PROPS":["PR_1"]}]}')
    test_json_confs.push('{"NAME":"High power PWM FET board","DESC":"6pcs high power FETs with current limiting","VER":"1.0","PD":"2024.01.01","PRMS":{"PRM_1":{"NAME":"Current limit","PLIST":["0.5A","1A","2A","3A","5A"]}},"PROPS":{"PR_1":{"NAME":"Maximum output current","VAL":"5A"},"PR_2":{"NAME":"Maximum working voltage","VAL":"24V"}},"IOCH":[{"NAME":"PWM out 1","DESC":"","POS":1,"TYPE":1,"PRMS":[{"PREF":"PRM_1","ACT":"2A"}],"PROPS":["PR_1"]},{"NAME":"PWM out 2","DESC":"","POS":2,"TYPE":1,"PRMS":[{"PREF":"PRM_1","ACT":"1A"}],"PROPS":["PR_1"]},{"NAME":"PWM out 3","DESC":"","POS":3,"TYPE":1,"PRMS":[{"PREF":"PRM_1","ACT":"1A"}],"PROPS":["PR_1"]},{"NAME":"PWM out 4","DESC":"","POS":4,"TYPE":1,"PRMS":[{"PREF":"PRM_1","ACT":"1A"}],"PROPS":["PR_1"]},{"NAME":"PWM out 5","DESC":"","POS":5,"TYPE":1,"PRMS":[{"PREF":"PRM_1","ACT":"1A"}],"PROPS":["PR_1"]},{"NAME":"PWM out 6","DESC":"","POS":6,"TYPE":1,"PRMS":[{"PREF":"PRM_1","ACT":"1A"}],"PROPS":["PR_1"]}]}')
    test_json_confs.push('')
    test_json_confs.push('')

    var i2c_devs = wire1.scan()
    webserver.content_start("Multicontroller Configuration")
    webserver.content_send_style()
    webserver.content_send('<style>table{width: 100%;border-collapse: collapse;}th, td{border: 1px solid gray;padding: 8px;text-align: left;}th{background-color: gray;}</style>')

    for dev: i2c_devs
      if (dev >= 80) && (dev <= 83)
        var ext_slot = dev - 79
        webserver.content_send('<p></p><p></p><fieldset><legend><b>Extension slot ' + str(ext_slot) + '</b></legend>')
        self.show_ext_board_conf(ext_slot - 1, test_json_confs[ext_slot - 1])
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
