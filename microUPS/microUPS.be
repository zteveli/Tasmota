import webserver
import string

class bqRegs

  var charge_option_0
  var charge_current
  var manufacture_id
  var device_id
  end

class microUPS

  def init()
    tasmota.add_driver(self)
    self.web_add_handler()
  end

  def close()
    tasmota.remove_driver(self)
  end

  def swap_bytes(value)
    return ((value >> 8) & 0xFF) + ((value << 8) & 0xFF00)
  end

  # Utility to read and decode value register
  def read_value_reg(reg_addr, one_byte)
    var reg = wire1.read(0x6B, reg_addr, 2)
    var ret = self.swap_bytes(reg)

    if one_byte
      ret = ret * 100
    end

    return ret
  end

  # Utility to write to value register
  def write_value_reg(reg_addr, one_byte, value)
    if one_byte
      value -= 100
    end

    value = self.swap_bytes(value)
    wire1.write(0x6B, reg_addr, value, 2)
  end
  
  def read_device_id()
    # Read charger ManufactureID and Device ID registers
    return wire1.read(0x6B, 0x2E, 2)
  end

  def read_charge_voltage()
    return self.read_value_reg(0x04, false)
  end

  def read_charge_current()
    return self.read_value_reg(0x02, false) << 1
  end

  def write_charge_current(value)
    self.write_value_reg(0x02, false, value >> 1)
  end

  def enable_adc()
    # ADC_CONV, EN_ADC_VBUS, EN_ADC_PSYS, EN_ADC_IIN, EN_ADC_IDCHG, EN_ADC_ICHG, EN_ADC_VSYS, EN_ADC_VBAT
    wire1.write(0x6B, 0x3A, 0x7F80, 2)
  end

  def read_adc_vsys()
    return wire1.read(0x6B, 0x2D, 1) * 64 + 8160
  end

  def read_adc_vbat()
    return wire1.read(0x6B, 0x2C, 1) * 64 + 8160
  end

  def read_adc_vbus()
    return wire1.read(0x6B, 0x27, 1) * 96
  end

  def read_adc_ichg()
    return wire1.read(0x6B, 0x29, 1) * 128
  end

  def read_adc_idchg()
    return wire1.read(0x6B, 0x28, 1) * 512
  end

  def read_adc_iin()
    return wire1.read(0x6B, 0x2B, 1) * 100
  end

  def page_mu()
    webserver.content_start("microUPS")
    webserver.content_send_style()
    webserver.content_send('<style>table{width: 100%;border-collapse: collapse;}th, td{border: 1px solid gray;padding: 8px;text-align: center;}th{background-color: gray;}</style>')
    webserver.content_send("<p></p>Device ID: ")

    var dev_id = self.read_device_id()
    var charge_voltage = self.read_charge_voltage()

    if (dev_id != nil)
      webserver.content_send(string.hex(dev_id))
    else
      webserver.content_send("NOT FOUND!")
    end

    # Start ADC conversion
    self.enable_adc()

    # Start battery charge with 512mA
    webserver.content_send("<p></p>Charge Current: " + str(self.read_charge_current()) + "mA")
    self.write_charge_current(512)
    webserver.content_send("<p></p>Charge Current: " + str(self.read_charge_current()) + "mA")

    if (charge_voltage != nil)
      webserver.content_send("<p></p>Charge Voltage: " + str(charge_voltage) + "mV")
    end

    webserver.content_send("<p></p>VSYS voltage: " + str(self.read_adc_vsys()) + "mV")
    webserver.content_send("<p></p>VBAT voltage: " + str(self.read_adc_vbat()) + "mV")
    webserver.content_send("<p></p>VBUS voltage: " + str(self.read_adc_vbus()) + "mV")
    webserver.content_send("<p></p>Battery charge current: " + str(self.read_adc_ichg()) + "mA")
    webserver.content_send("<p></p>Battery discharge current: " + str(self.read_adc_idchg()) + "mA")
    webserver.content_send("<p></p>Input current: " + str(self.read_adc_iin()) + "mA")

    webserver.content_send("<p></p><button onclick='la(\"&m_toggle_conf=1\");'>Test Button</button>")
    # Button back to main page
    webserver.content_button(webserver.BUTTON_MAIN)
    webserver.content_stop()
  end

  #- create a method for adding a button to the main menu -#
  def web_add_main_button()
    webserver.content_send("<p></p><form action='/mu_conf' method='post'><button>microUPS</button></form>")
  end

  #- As we can add only one sensor method we will have to combine them besides all other sensor readings in one method -#
  def web_sensor()

#    webserver.content_send("<p></p><button onclick='la(\"&m_toggle_conf=1\");'>Test Button</button>")
    if webserver.has_arg("m_toggle_conf")
      print("m_toggle_conf")
    end
  end

  def web_add_handler()
    webserver.on("/mu_conf", / -> self.page_mu())
    print("microUPS page available at '/mu_conf'")
    end
end

mc = microUPS()
