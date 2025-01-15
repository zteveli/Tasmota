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

  def read_device_id()
    # Read charger ManufactureID and Device ID registers
    return wire1.read(0x6B, 0x2E, 2)
  end

  def read_charge_voltage()
    var reg1 = wire1.read(0x6B, 0x04, 1)
    var reg2 = wire1.read(0x6B, 0x05, 1)
    var voltage = 0
    var multiplier = 8

    reg1 >>= 3
    for i: 0..4
      voltage += (reg1 & 0x01) * multiplier
      multiplier <<= 1
      reg1 >>= 1
    end

    for i: 0..6
      voltage += (reg2 & 0x01) * multiplier
      multiplier <<= 1
      reg2 >>= 1
    end

    return voltage
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

    # Start battery charge with 512mA
    wire1.write(0x6B, 0x02, 0x0001, 2)
    print(string.hex(wire1.read(0x6B, 0x02, 1)))
    print(string.hex(wire1.read(0x6B, 0x03, 1)))

    if (charge_voltage != nil)
      webserver.content_send("<p></p>Charge Voltage: " + str(charge_voltage) + "mV")
    end

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
