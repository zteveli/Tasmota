import string

class MupsDisplayData
  var usb1_en
  var usb2_en
  var hp1_en
  var hp2_en
  var system_voltage
  var system_current
  var system_power
  var input_voltage
  var input_current
  var input_power
  var is_charging
  var batt_percentage
  var batt_voltage
  var batt_charge_current
  var batt_charge_power
  var batt_discharge_current
  var batt_discharge_power

  def init()
    self.usb1_en = false
    self.usb2_en = false
    self.hp1_en = false
    self.hp2_en = false
    self.is_charging = false
    self.batt_percentage = 0
    self.system_voltage = 0
    self.system_current = 0
    self.system_power = 0
    self.input_voltage = 0
    self.input_current = 0
    self.input_power = 0
    self.batt_voltage = 0
    self.batt_charge_current = 0
    self.batt_charge_power = 0
    self.batt_discharge_current = 0
    self.batt_discharge_power = 0
    end
end

class MupsDisplay
  var content_idx
  var on_time
  var on_timer
  var show_symbols
  var data

  def init()
    self.data = MupsDisplayData()
    self.content_idx = 0
    self.on_time = 80
    self.on_timer = self.on_time
    self.show_symbols = true
  end

  def update_data(data)
    self.data = data
  end

  def set_on_time(on_time_s)
    self.on_time = on_time_s * 4 + 1
  end

  def reset_on_timer()
    self.on_timer = self.on_time
  end

  def display_on()
    if (self.on_timer == 0)
      print('display on')
      tasmota.cmd('DisplayText [O]', true)
      self.reset_on_timer()
    end
  end

  def display_off()
    if (self.on_timer > 0)
      print('display off')
      self.main_content()
      self.on_timer = 0
      tasmota.cmd('DisplayText [o]', true)
    end
  end

  # Adds button name from 0 to 2 position to display
  def add_button_name(pos, text)
    return format("[x106y%d]%s", pos * 21 + 5, text)
  end

  def create_right_side_menu(text1, text2, text3)
    var cmd = "DisplayText [zs1]"
    cmd += "[x102y0v64x102y21h26x102y42h26]"
    cmd += self.add_button_name(0, text1)
    cmd += self.add_button_name(1, text2)
    cmd += self.add_button_name(2, text3)

    return cmd
  end

  def create_data_display_content(title, mv, ma, w)
    var cmd = "DisplayText [zs1]"

    cmd += self.create_right_side_menu('O1', 'O2', 'MNU')
    cmd += "[x0y0]" + title + "[x0y12h101]"
    cmd += '[x0y18]Volt.: ' + str(mv) + 'mV'
    cmd += '[x0y30]Curr.: ' + str(ma) + 'mA'
    cmd += '[x0y42]Power: ' + str(w) + 'W'

    return cmd
  end

  def create_input_display_content()
    return self.create_data_display_content('INPUT', self.data.input_voltage, self.data.input_current, self.data.input_power)
  end

  def create_system_display_content()
    return self.create_data_display_content('SYSTEM', self.data.system_voltage, self.data.system_current, self.data.system_power)
  end

  def create_battery_charge_display_content()
    return self.create_data_display_content('BATT. CHARGE', self.data.batt_voltage, self.data.batt_charge_current, self.data.batt_charge_power)
  end

  def create_battery_discharge_display_content()
    return self.create_data_display_content('BATT. DISCHARGE', self.data.batt_voltage, self.data.batt_discharge_current, self.data.batt_discharge_power)
  end

  def add_battery_symbol(percentage, is_charging)
    var cmd = '[x3y30r8:2x0y32r14:32'
    var level

    if (percentage == 0) level = 0
    elif ((percentage > 0) && (percentage <= 20)) level = 1
    elif ((percentage > 20) && (percentage <= 40)) level = 2
    elif ((percentage > 40) && (percentage <= 60)) level = 3
    elif ((percentage > 60) && (percentage <= 80)) level = 4
    else level = 5 end

    if (self.data.is_charging)
      if (!self.show_symbols)
        if (level > 0) 
          level -= 1
        end
      end
    end
  
    if (level > 0)
      for i:0..level-1
        cmd += format("x2y%dR10:4", 58 - i * 6)
      end
    end
    cmd += ']'

    return cmd
  end

  def create_main_content()
    var cmd = "DisplayText [zs1]"
    cmd += self.create_right_side_menu('O1', 'O2', 'MNU')
    if (self.data.usb1_en) cmd += "[x2y4K2x6y0]USB1" else cmd += "[x6y0]USB1" end
    if (self.data.usb2_en) cmd += "[x40y4K2x44y0]USB2" else cmd += "[x44y0]USB2" end
    if (self.data.hp1_en) cmd += "[x2y16K2x6y12]OUT1" else cmd += "[x6y12]OUT1" end
    if (self.data.hp2_en) cmd += "[x40y16K2x44y12]OUT2" else cmd += "[x44y12]OUT2" end
    cmd += self.add_battery_symbol(self.data.batt_percentage)
    # Add time to display
    cmd += "[x18y55tS]"
    cmd += format("[x18y28]Psys: %dW", self.data.system_power)
    return cmd
  end

  def next_content()
    if (self.on_timer > 0)
      if (self.content_idx < 4)
        self.content_idx += 1
      else
        self.content_idx = 0
      end
    end
  end

  def main_content()
    self.content_idx = 0
  end

  def create_display_content()
    var cmd = ''
    if (self.content_idx == 0)
      cmd = self.create_main_content()
    elif (self.content_idx == 1)
      cmd = self.create_input_display_content()
    elif (self.content_idx == 2)
      cmd = self.create_system_display_content()
    elif (self.content_idx == 3)
      cmd = self.create_battery_charge_display_content()
    else
      cmd = self.create_battery_discharge_display_content()
    end

    return cmd
  end

  def refresh_content(reset_on_timer)
    if (reset_on_timer)
      self.display_on()
    end
    if (self.on_timer > 0)
      if (reset_on_timer)
        self.reset_on_timer()
      end
      tasmota.cmd(self.create_display_content(), true)
    end
  end

  def handler_250ms()
    if (self.on_timer > 0)
      if (self.on_timer == 1)
        self.display_off()
      else
        self.on_timer -= 1
      end
    end
  end

  def handler_1s()
    if (self.show_symbols) self.show_symbols = false else self.show_symbols = true end
    self.refresh_content(false)
  end
end

md = MupsDisplay()