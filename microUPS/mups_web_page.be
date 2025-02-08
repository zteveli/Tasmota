import webserver
import string

class MicroUPSWebPage

  def page()
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

  def init()
  end
end

# Create an instance
webp = MicroUPSWebPage()