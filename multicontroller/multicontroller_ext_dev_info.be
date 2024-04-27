import json

class MultiControllerExtDevInfo

  static ch_types = {1:'output', 2:'input'}

  def display_info()
    var test_info1 = '{"NAME":"Relay board", "DESC":"Board with relays", "VER":"1.0", "PD":"2024.01.01", "IOCH":[{"NAME":"Relay 1", "DESC":"NC/NO relay", "POS": 1, "TYPE":1}, {"NAME":"Relay 2", "DESC":"NC/NO relay", "POS": 2}]}'

    var info_map = json.load(test_info1)

    # Start print
    var dev_name = info_map.find('NAME', nil)
    var dev_desc = info_map.find('DESC', nil)
    var dev_ver = info_map.find('VER', nil)
    var dev_pd = info_map.find('PD', nil)

    print("Device:")
    if (dev_name) print("  Name: " + dev_name) end
    if (dev_desc) print("  Description: " + dev_desc) end
    if (dev_ver) print("  Version: " + dev_ver) end
    if (dev_pd) print("  Production date: " + dev_pd) end

    print("\n  I/O channels:")

    var dev_iochs = info_map.find('IOCH', [])
    for ioch : dev_iochs
      var ioch_pos = ioch.find('POS', nil)
      if (ioch_pos)
        print("    " + str(ioch_pos) + ":")
        var ioch_name = ioch.find('NAME', nil)
        var ioch_desc = ioch.find('DESC', nil)
        var ioch_type = ioch.find('TYPE', nil)

        if (ioch_name) print("      Name: " + ioch_name) end
        if (ioch_desc) print("      Description: " + ioch_desc) end
        if (ioch_type) print("      Type: " + self.ch_types.find(ioch_type)) end
      end
    end
  end
end

edi = MultiControllerExtDevInfo()
edi.display_info()