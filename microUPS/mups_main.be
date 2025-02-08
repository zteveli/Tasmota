import webserver
import string

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
  var pw_supplies

  def page_mu_ctl()
    if !webserver.check_privileged_access() return nil end

    if webserver.has_arg("charge_start")
      if !chrg.is_charging()
        chrg.start_charge()
        print("charge_start")
      end
    end

    # Refresh page
    webp.page()
  end

  def convert_fraction(num)
    num /= 100
    return format("%d.%d", num / 10, num % 10)
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
      if (index == 0) tasmota.cmd('Power1 2', true) md.main_content() md.refresh_content(true) end
      if (index == 1) tasmota.cmd('Power2 2', true) md.main_content() md.refresh_content(true) end
      if (index == 2) md.next_content() md.refresh_content(true) end
    end

#    print(format('button_pressed: mp_state: %x, payload: %x, cmd_: %x, index: %x', mp_state, payload, cmd_, index))
  end

  #- As we can add only one sensor method we will have to combine them besides all other sensor readings in one method -#
  def web_sensor()
    if webserver.has_arg("btn1")
      print("btn1")
    end
  end

  def every_250ms()
    var power_list = tasmota.get_power()

    self.pw_supplies.usb1_en = false
    self.pw_supplies.usb2_en = false
    self.pw_supplies.out1_en = power_list[0]
    self.pw_supplies.out2_en = power_list[1]

    # Run display handler
    md.handler_250ms()
  end

  def every_second()
    var disp_data = MupsDisplayData()

    #self.page_mu()

    # Run display handler
    var m = chrg.read_measurements()
    var dv = chrg.read_derived_values()
    var cs = chrg.read_status()

    disp_data.usb1_en = false
    disp_data.usb2_en = false
    disp_data.hp1_en = self.pw_supplies.out1_en
    disp_data.hp2_en = self.pw_supplies.out2_en
    disp_data.system_voltage = m.system_voltage
    disp_data.system_current = dv.sys_current
    disp_data.system_power = dv.sys_power
    disp_data.input_voltage = m.vbus_voltage
    disp_data.input_current = m.input_current
    disp_data.input_power = dv.input_power
    disp_data.is_charging = cs.in_fast_charge_mode || cs.in_pre_charge_mode
    disp_data.batt_percentage = dv.battery_percentage
    disp_data.batt_voltage = m.battery_voltage
    disp_data.batt_charge_current = m.battery_charge_current
    disp_data.batt_charge_power = dv.charge_power
    disp_data.batt_discharge_current = m.battery_discharge_current
    disp_data.batt_discharge_power = dv.discharge_power

    md.update_data(disp_data)
    md.handler_1s()
  end

  def web_add_handler()
    webserver.on("/mu_page", / -> webp.page(), webserver.HTTP_GET)
    webserver.on("/mu_page", / -> self.page_mu_ctl(), webserver.HTTP_POST)
    print("microUPS page available at '/mu_page'")
  end

  def init()
    self.pw_supplies = Supplies()

    tasmota.add_driver(self)
    self.web_add_handler()

    # Display on
    md.refresh_content(true)
  end

  def close()
    tasmota.remove_driver(self)
  end
end

mc = microUPS()
