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
  var dev

  def init(dev_conf)
    # Create internal representation of device information
    var info_map = json.load(dev_conf)
    self.dev = ExtDevInfo()
    self.dev.name = info_map.find('NAME', nil)
    self.dev.desc = info_map.find('DESC', nil)
    self.dev.version = info_map.find('VER', nil)
    self.dev.prod_date = info_map.find('PD', nil)
    self.dev.properties = info_map.find('PROPS', nil)
    self.dev.parameters = info_map.find('PRMS', nil)
    self.dev.io_channels = []
    var io_channels = info_map.find('IOCH', [])

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
          var global_prop = self.dev.properties.find(prop, nil)
  
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
            var global_param = self.dev.parameters.find(pref, nil)

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

      self.dev.io_channels.push(ioch_info)
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

edi = MCExtDev('{"NAME":"High power PWM FET board","DESC":"6pcs high power FETs with current limiting","VER":"1.0","PD":"2024.01.01","PRMS":{"PRM_1":{"NAME":"Current limit","PLIST":["0.5A","1A","2A","3A","5A"]}},"PROPS":{"PR_1":{"NAME":"Maximum output current","VAL":"5A"},"PR_2":{"NAME":"Maximum working voltage","VAL":"24V"}},"IOCH":[{"NAME":"PWM out 1","DESC":"","POS":1,"TYPE":1,"PRMS":[{"PREF":"PRM_1","ACT":"1A"}],"PROPS":["PR_1"]},{"NAME":"PWM out 2","DESC":"","POS":2,"TYPE":1,"PRMS":[{"PREF":"PRM_1","ACT":"1A"}],"PROPS":["PR_1"]},{"NAME":"PWM out 3","DESC":"","POS":3,"TYPE":1,"PRMS":[{"PREF":"PRM_1","ACT":"1A"}],"PROPS":["PR_1"]},{"NAME":"PWM out 4","DESC":"","POS":4,"TYPE":1,"PRMS":[{"PREF":"PRM_1","ACT":"1A"}],"PROPS":["PR_1"]},{"NAME":"PWM out 5","DESC":"","POS":5,"TYPE":1,"PRMS":[{"PREF":"PRM_1","ACT":"1A"}],"PROPS":["PR_1"]},{"NAME":"PWM out 6","DESC":"","POS":6,"TYPE":1,"PRMS":[{"PREF":"PRM_1","ACT":"1A"}],"PROPS":["PR_1"]}]}')
edi.display_dev_info()