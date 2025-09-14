import string

class MupsMqtt

  def init()
    tasmota.add_driver(self)
  end

  def every_second()
    import mqtt

    var input_payload = {}
    var system_payload = {}
    var batt_payload = {}
    var output_payload = {}
    var payload = {}
    var topic = string.replace(string.replace(
              tasmota.cmd('_FullTopic',true)['FullTopic'],
              '%topic%', tasmota.cmd('_Topic',true)['Topic']),
              '%prefix%', tasmota.cmd('_Prefix',true)['Prefix3'])
            + 'SENSOR'

    input_payload["voltage"] = md.data.input_voltage
    input_payload["current"] = md.data.input_current
    input_payload["power"] = md.data.input_power
    system_payload["voltage"] = md.data.system_voltage
    system_payload["current"] = md.data.system_current
    system_payload["power"] = md.data.system_power
    batt_payload["percentage"] = md.data.batt_percentage
    batt_payload["voltage"] = md.data.batt_voltage
    batt_payload["charge_current"] = md.data.batt_charge_current
    batt_payload["charge_power"] = md.data.batt_charge_power
    batt_payload["discharge_current"] = md.data.batt_discharge_current
    batt_payload["discharge_power"] = md.data.batt_discharge_power
    output_payload["USB1"] = md.data.usb1_en
    output_payload["USB2"] = md.data.usb2_en
    output_payload["HP1"] = md.data.hp1_en
    output_payload["HP2"] = md.data.hp2_en

    payload["input"] = input_payload
    payload['system'] = system_payload
    payload["battey"] = batt_payload
    payload["output"] = output_payload

    mqtt.publish(topic, str(payload))
    print(payload)
  end
end

mq = MupsMqtt()