import webserver
import string

class ChargerStatus
  var power_adapter_present
  var in_fast_charge_mode
  var in_pre_charge_mode
  end

class ChargerValues
  var charge_status
  var charge_voltage
  var charge_current
  var adc_vsys
  var adc_vbat
  var adc_vbus
  var adc_ichg
  var adc_idchg
  var adc_iin
  var vsysmin
  var iin_host
  var input_voltage_limit

  def init()
    self.charge_status = ChargerStatus()
  end
end

class DerivedValues
  var input_pwr
  var output_pwr
  var charge_pwr
  var discharge_pwr
  var sys_current
  var sys_pwr
  var battery_percentage
end

class Supplies
  var usb1_en
  var usb2_en
  var out1_en
  var out2_en

  def init()
    self.usb1_en = false
    self.usb2_en = false
    self.out1_en = false
    self.out2_en = false
    end
end

class microUPS
  var charger_values
  var derived_values
  var charge_enabled
  var pw_supplies
  var isShowSymbols
  var display_content_idx

  def swap_bytes(value)
    return ((value >> 8) & 0xFF) + ((value << 8) & 0xFF00)
  end

  def i2c_read(addr, reg_addr, byte_num)
    return wire2.read(addr, reg_addr, byte_num)
  end

  def i2c_write(addr, reg_addr, value, byte_num)
    return wire2.write(addr, reg_addr, value, byte_num)
  end

  # Utility to read and decode value register
  def read_value_reg(reg_addr, lsb_val, bit_offset)
    var value = self.i2c_read(0x6B, reg_addr, 2)
    value = self.swap_bytes(value)
    value >>=  bit_offset
    value *= lsb_val

    return value
  end

  # Utility to write to value register
  def write_value_reg(reg_addr, value, lsb_val, bit_offset)

    value /= lsb_val
    value <<= bit_offset
    value = self.swap_bytes(value)
    self.i2c_write(0x6B, reg_addr, value, 2)
  end
  
  def read_device_id()
    # Read charger ManufactureID and Device ID registers
    return self.i2c_read(0x6B, 0x2E, 2)
  end

  def read_charge_voltage()
    return self.read_value_reg(0x04, 8, 3)
  end

  def write_charge_voltage(mv)
    return self.write_value_reg(0x04, mv, 8, 3)
  end

  def read_charge_current()
    return self.read_value_reg(0x02, 128, 6)
  end

  def write_charge_current(value)
    self.write_value_reg(0x02, value, 128, 6)
  end

  def enable_adc()
    # ADC_CONV, EN_ADC_VBUS, EN_ADC_PSYS, EN_ADC_IIN, EN_ADC_IDCHG, EN_ADC_ICHG, EN_ADC_VSYS, EN_ADC_VBAT
    self.i2c_write(0x6B, 0x3A, 0x7F80, 2)
  end

  def read_adc_vsys()
    return self.i2c_read(0x6B, 0x2D, 1) * 64 + 8160
  end

  def read_adc_vbat()
    return self.i2c_read(0x6B, 0x2C, 1) * 64 + 8160
  end

  def read_adc_vbus()
    return self.i2c_read(0x6B, 0x27, 1) * 96
  end

  def read_adc_ichg()
    return self.i2c_read(0x6B, 0x29, 1) * 128
  end

  def read_adc_idchg()
    return self.i2c_read(0x6B, 0x28, 1) * 512
  end

  def read_adc_iin()
    return self.i2c_read(0x6B, 0x2B, 1) * 100
  end

  def read_vsysmin()
    return self.read_value_reg(0x0C, 100, 8)
  end

  def write_vsysmin(voltage)
    self.write_value_reg(0x0C, voltage, 100, 8)
  end

  def read_iin_host()
    return self.read_value_reg(0x0E, 100, 8)
  end

  def write_iin_host(ma)
    self.write_value_reg(0x0E, ma, 100, 8)
  end

  def read_input_voltage_limit()
    return self.read_value_reg(0x0A, 64, 6)
  end

  def read_charge_status()
    var cs = ChargerStatus()
    var reg = self.i2c_read(0x6B, 0x21, 1)

    cs.power_adapter_present = ((reg & 0x80) == 0x80)
    cs.in_fast_charge_mode = ((reg & 0x04) == 0x04)
    cs.in_pre_charge_mode = ((reg & 0x02) == 0x02)
  
    return cs
  end

  def read_charger()
    self.charger_values.charge_status = self.read_charge_status()
    self.charger_values.charge_voltage = self.read_charge_voltage()
    self.charger_values.charge_current = self.read_charge_current()
    self.charger_values.adc_vsys = self.read_adc_vsys()
    self.charger_values.adc_vbat = self.read_adc_vbat()
    self.charger_values.adc_vbus = self.read_adc_vbus()
    self.charger_values.adc_ichg = self.read_adc_ichg()
    self.charger_values.adc_idchg = self.read_adc_idchg()
    self.charger_values.adc_iin = self.read_adc_iin()
    self.charger_values.vsysmin = self.read_vsysmin()
    self.charger_values.iin_host = self.read_iin_host()
    self.charger_values.input_voltage_limit = self.read_input_voltage_limit()
  end

  def page_mu()
    var cv = self.charger_values
    webserver.content_start("microUPS")
    webserver.content_send_style()
    webserver.content_send('<style>table{width: 100%;border-collapse: collapse;}th, td{border: 1px solid gray;padding: 8px;text-align: center;}th{background-color: gray;}</style>')
    webserver.content_send("<p></p>Device ID: ")

    var dev_id = self.read_device_id()

    if (dev_id != nil)
      webserver.content_send(string.hex(dev_id))
    else
      webserver.content_send("NOT FOUND!")
    end

    webserver.content_send('<p></p><fieldset><legend><b>Parameters</b></legend>')
    webserver.content_send('<p></p><fieldset><legend><b>Input</b></legend>')
    webserver.content_send("<p></p>Min. input voltage limit: <b>" + str(cv.input_voltage_limit) + "</b>mV")
    webserver.content_send("<p></p>Input current limit: <b>" + str(cv.iin_host) + "</b>mA")
    webserver.content_send('</fieldset>')
    webserver.content_send('<p></p><fieldset><legend><b>System</b></legend>')
    webserver.content_send("<p></p>VSYS min. voltage: <b>" + str(cv.vsysmin) + "</b>mV")
    webserver.content_send('</fieldset>')
    webserver.content_send('<p></p><fieldset><legend><b>Battery charger</b></legend>')
    webserver.content_send("<p></p>Max. charge Voltage: <b>" + str(cv.charge_voltage) + "</b>mV")
    webserver.content_send("<p></p>Charge Current: <b>" + str(cv.charge_current) + "</b>mA")
    webserver.content_send('</fieldset>')
    webserver.content_send('</fieldset>')

    webserver.content_send('<p></p><fieldset><legend><b>Measurements</b></legend>')
    webserver.content_send('<p></p><fieldset><legend><b>Input</b></legend>')
    webserver.content_send("<div class='vbus_voltage' id='vbus_voltage'>VBUS voltage: <b>" + str(cv.adc_vbus) + "</b>mV")
    webserver.content_send("<p></p>VBUS voltage: <b>" + str(cv.adc_vbus) + "</b>mV")
    webserver.content_send("<p></p>Input current: <b>" + str(cv.adc_iin) + "</b>mA")
    webserver.content_send('</fieldset>')
    webserver.content_send('<p></p><fieldset><legend><b>System</b></legend>')
    webserver.content_send("<p></p>VSYS voltage: <b>" + str(cv.adc_vsys) + "</b>mV")
    webserver.content_send('</fieldset>')
    webserver.content_send('<p></p><fieldset><legend><b>Battery</b></legend>')
    webserver.content_send("<p></p>VBAT voltage: <b>" + str(cv.adc_vbat) + "</b>mV")
    webserver.content_send("<p></p>Battery charge current: <b>" + str(cv.adc_ichg) + "</b>mA")
    webserver.content_send("<p></p>Battery discharge current: <b>" + str(cv.adc_idchg) + "</b>mA")
    webserver.content_send('</fieldset>')
    webserver.content_send('</fieldset>')

    webserver.content_send('<p></p><fieldset><legend><b>Status</b></legend>')
    webserver.content_send("<p></p>Power adapter present: <b>" + str(cv.charge_status.power_adapter_present) + "</b>")
    webserver.content_send("<p></p>In fast charge: <b>" + str(cv.charge_status.in_fast_charge_mode) + "</b>")
    webserver.content_send("<p></p>In pre-charge: <b>" + str(cv.charge_status.in_pre_charge_mode) + "</b>")
    webserver.content_send('</fieldset>')

#    Measurement update code

#    webserver.content_send("<script>")
#    webserver.content_send("function updateValues() {")
#    webserver.content_send("document.getElementById('vbus_voltage').textContent = 'VBUS voltage: <b>" + str(self.read_adc_vbus()) + "</b>mV;')
#    webserver.content_send('')
    
    # Start charge button
    # webserver.content_send("<p><form id=charge_start style='display: block;' action='/mu_page?charge_start=1' method='post'><button>Start charge</button></form></p>")
    webserver.content_send("<p><form id=micro_ups_ui style='display: block;' action='/mu_page' method='post'>")
    webserver.content_send("<p></p><button name='charge_start' class='button bgrn'>Start charge</button>")
    webserver.content_send("</form>")
    # Button back to main page
    webserver.content_button(webserver.BUTTON_MAIN)
    webserver.content_stop()
  end

  def page_mu_ctl()
    if !webserver.check_privileged_access() return nil end

    if webserver.has_arg("charge_start")
      # Start charge with 3072mA
      self.write_charge_current(3072)
      self.charge_enabled = true
      print("charge_start")
    end

    self.page_mu()
  end

  # Adds button name from 0 to 2 position to display
  def disp_add_button_name(pos, text)
    return format("[x106y%d]%s", pos * 21 + 5, text)
  end

  def disp_add_battery_symbol(percentage)
    var cmd = '[x3y30r8:2x0y32r14:32'
    var level

    if (percentage == 0) level = 0
    elif ((percentage > 0) && (percentage <= 20)) level = 1
    elif ((percentage > 20) && (percentage <= 40)) level = 2
    elif ((percentage > 40) && (percentage <= 60)) level = 3
    elif ((percentage > 60) && (percentage <= 80)) level = 4
    else level = 5 end

    if (self.charger_values.charge_status.in_fast_charge_mode)
      if (!self.isShowSymbols)
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

  def disp_add_time()
    return "[x18y55tS]"
  end

  def convert_fraction(num)
    num /= 100
    return format("%d.%d", num / 10, num % 10)
  end

  def create_input_display_content()
    var cmd = "DisplayText [zs1x50]INPUT[x0y12h128]"
    var cv = self.charger_values
    var dv = self.derived_values

    cmd += '[x0y18]Voltage: ' + str(cv.adc_vbus) + 'mV'
    cmd += '[x0y30]Current: ' + str(cv.adc_iin) + 'mA'
    cmd += '[x0y42]Power:   ' + str(dv.input_pwr) + 'W'

    return cmd
  end

  def create_system_display_content()
    var cmd = "DisplayText [zs1x50]SYSTEM[x0y12h128]"
    var cv = self.charger_values
    var dv = self.derived_values

    cmd += '[x0y18]Voltage: ' + str(cv.adc_vsys) + 'mV'
    cmd += '[x0y30]Current: ' + str(dv.sys_current) + 'mA'
    cmd += '[x0y42]Power:   ' + str(dv.sys_pwr) + 'W'

    return cmd
  end

  def create_main_display_content()
    var cmd = "DisplayText [zs1]"
    var power_list = tasmota.get_power()
    if (self.pw_supplies.usb1_en) cmd += "[x2y4K2x6y0]USB1" else cmd += "[x6y0]USB1" end
    if (self.pw_supplies.usb2_en) cmd += "[x40y4K2x44y0]USB2" else cmd += "[x44y0]USB2" end
    if (power_list[0]) cmd += "[x2y16K2x6y12]OUT1" else cmd += "[x6y12]OUT1" end
    if (power_list[1]) cmd += "[x40y16K2x44y12]OUT2" else cmd += "[x44y12]OUT2" end
    # Add button name surrounding lines
    cmd += "[x102y0v64x102y21h26x102y42h26]"
    cmd += self.disp_add_battery_symbol(self.derived_values.battery_percentage)
    cmd += self.disp_add_button_name(0, 'O1')
    cmd += self.disp_add_button_name(1, 'O2')
    cmd += self.disp_add_button_name(2, 'MNU')
    cmd += self.disp_add_time()
    cmd += format("[x18y28]Psys: %dW", self.derived_values.sys_pwr)
    return cmd
  end

  def create_display_content()
    var cmd = ''
    if (self.display_content_idx == 0)
      cmd = self.create_main_display_content()
    elif (self.display_content_idx == 1)
      cmd = self.create_input_display_content()
    else
      cmd = self.create_system_display_content()
    end

    return cmd
  end

  def update_display()
    tasmota.cmd(self.create_display_content(), true)
  end

  def calculate_derived_values()
    var cv = self.charger_values
    self.derived_values.input_pwr = cv.adc_vbus * cv.adc_iin / 1000000
    self.derived_values.output_pwr = 0
    self.derived_values.charge_pwr = cv.adc_vbat * cv.adc_ichg / 1000000
    self.derived_values.discharge_pwr = cv.adc_vbat * cv.adc_idchg / 1000000
    self.derived_values.sys_current = cv.adc_iin + cv.adc_ichg + cv.adc_idchg
    self.derived_values.sys_pwr = (cv.adc_vbat * (cv.adc_idchg + cv.adc_idchg) + cv.adc_vbus * cv.adc_iin) / 1000000
    self.derived_values.battery_percentage = (cv.adc_vbat - 15000) * 100 / 6000
  end

  def every_second()
    if self.charge_enabled == true
      self.write_charge_current(3072)
    end

    if (self.isShowSymbols) self.isShowSymbols = false else self.isShowSymbols = true end

    self.read_charger()
    self.calculate_derived_values()
    #self.page_mu()

    # Refresh display content
    self.update_display()
  end

  #- create a method for adding a button to the main menu -#
  def web_add_main_button()
    webserver.content_send("<p></p><form action='/mu_page' method='post'><button>microUPS</button></form>")
  end

  def button_pressed(cmd, idx)
    var mp_state = (idx >> 24) & 0xFF
    var payload = (idx >> 16) & 0xFF
  	var cmd_ = (idx >> 8) & 0xFF
  	var index = (idx & 0xFF)

    if ((cmd_ == 0))
      if (index == 0) tasmota.cmd('Power1 2', true) self.update_display() end
      if (index == 1) tasmota.cmd('Power2 2', true) self.update_display() end
      if (index == 2)
        if (self.display_content_idx < 2)
          self.display_content_idx += 1
        else
          self.display_content_idx = 0
        end
      end
    end


    print(format('button_pressed: mp_state: %x, payload: %x, cmd_: %x, index: %x', mp_state, payload, cmd_, index))
  end

  #- As we can add only one sensor method we will have to combine them besides all other sensor readings in one method -#
  def web_sensor()
    if webserver.has_arg("btn1")
      print("btn1")
    end
  end

  def web_add_handler()
    webserver.on("/mu_page", / -> self.page_mu(), webserver.HTTP_GET)
    webserver.on("/mu_page", / -> self.page_mu_ctl(), webserver.HTTP_POST)
    print("microUPS page available at '/mu_page'")
  end

  def init()
    self.charger_values = ChargerValues()
    self.derived_values = DerivedValues()
    self.pw_supplies = Supplies()
    self.charge_enabled = false
    self.isShowSymbols = true
    self.display_content_idx = 0

    tasmota.add_driver(self)
    self.web_add_handler()

    # Set maximum charge voltage
    self.write_charge_voltage(20600)

    # Set input current limit to 8A
    self.write_iin_host(8000)

    # Start ADC conversion
    self.enable_adc()
  end

  def close()
    tasmota.remove_driver(self)
  end
end

mc = microUPS()
