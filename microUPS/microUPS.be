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
  var charge_enabled
  var pw_supplies

  def page_mu()
    var m = chrg.read_measurements()
    var cs = chrg.read_status()
    var st = chrg.read_settings()

    webserver.content_start("microUPS")
    webserver.content_send_style()
    webserver.content_send('<style>table{width: 100%;border-collapse: collapse;}th, td{border: 1px solid gray;padding: 8px;text-align: center;}th{background-color: gray;}</style>')
    webserver.content_send("<p></p>Device ID: ")

    var dev_id = chrg.read_device_id()

    if (dev_id != nil)
      webserver.content_send(string.hex(dev_id))
    else
      webserver.content_send("NOT FOUND!")
    end

    webserver.content_send('<p></p><fieldset><legend><b>Parameters</b></legend>')
    webserver.content_send('<p></p><fieldset><legend><b>Input</b></legend>')
    webserver.content_send("<p></p>Minimum input voltage: <b>" + str(st.input_voltage_min) + "</b>mV")
    webserver.content_send("<p></p>Input current limit (1): <b>" + str(st.input_current_limit_1) + "</b>mA")
    webserver.content_send("<p></p>Input current limit (2): <b>" + str(st.input_current_limit_2) + "</b>mA")
    webserver.content_send('</fieldset>')
    webserver.content_send('<p></p><fieldset><legend><b>System</b></legend>')
    webserver.content_send("<p></p>VSYS min. voltage: <b>" + str(st.system_voltage_min) + "</b>mV")
    webserver.content_send('</fieldset>')
    webserver.content_send('<p></p><fieldset><legend><b>Battery charger</b></legend>')
    webserver.content_send("<p></p>Max. charge Voltage: <b>" + str(st.charge_voltage_max) + "</b>mV")
    webserver.content_send("<p></p>Max. charge Current: <b>" + str(st.charge_current_max) + "</b>mA")
    webserver.content_send('</fieldset>')
    webserver.content_send('</fieldset>')

    webserver.content_send('<p></p><fieldset><legend><b>Measurements</b></legend>')
    webserver.content_send('<p></p><fieldset><legend><b>Input</b></legend>')
    webserver.content_send("<div class='vbus_voltage' id='vbus_voltage'>VBUS voltage: <b>" + str(m.vbus_voltage) + "</b>mV")
    webserver.content_send("<p></p>VBUS voltage: <b>" + str(m.vbus_voltage) + "</b>mV")
    webserver.content_send("<p></p>Input current: <b>" + str(m.input_current) + "</b>mA")
    webserver.content_send('</fieldset>')
    webserver.content_send('<p></p><fieldset><legend><b>System</b></legend>')
    webserver.content_send("<p></p>VSYS voltage: <b>" + str(m.system_voltage) + "</b>mV")
    webserver.content_send('</fieldset>')
    webserver.content_send('<p></p><fieldset><legend><b>Battery</b></legend>')
    webserver.content_send("<p></p>VBAT voltage: <b>" + str(m.battery_voltage) + "</b>mV")
    webserver.content_send("<p></p>Battery charge current: <b>" + str(m.battery_charge_current) + "</b>mA")
    webserver.content_send("<p></p>Battery discharge current: <b>" + str(m.battery_discharge_current) + "</b>mA")
    webserver.content_send('</fieldset>')
    webserver.content_send('</fieldset>')

    webserver.content_send('<p></p><fieldset><legend><b>Status</b></legend>')
    webserver.content_send("<p></p>Power adapter present: <b>" + str(cs.power_adapter_present) + "</b>")
    webserver.content_send("<p></p>In fast charge: <b>" + str(cs.in_fast_charge_mode) + "</b>")
    webserver.content_send("<p></p>In pre-charge: <b>" + str(cs.in_pre_charge_mode) + "</b>")
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
      chrg.start_charge()
      self.charge_enabled = true
      print("charge_start")
    end

    self.page_mu()
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
    # Run display handler
    md.handler_250ms()
  end

  def every_second()
    var disp_data = MupsDisplayData()
    var power_list = tasmota.get_power()

    if self.charge_enabled == true
      chrg.start_charge()
    end

    #self.page_mu()

    # Run display handler
    var m = chrg.read_measurements()
    var dv = chrg.read_derived_values()
    var cs = chrg.read_status()

    disp_data.usb1_en = false
    disp_data.usb2_en = false
    disp_data.hp1_en = power_list[0]
    disp_data.hp2_en = power_list[1]
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
    webserver.on("/mu_page", / -> self.page_mu(), webserver.HTTP_GET)
    webserver.on("/mu_page", / -> self.page_mu_ctl(), webserver.HTTP_POST)
    print("microUPS page available at '/mu_page'")
  end

  def init()
    self.pw_supplies = Supplies()
    self.charge_enabled = false

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
