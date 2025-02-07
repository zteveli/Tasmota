class ChargerStatus
  var power_adapter_present
  var in_fast_charge_mode
  var in_pre_charge_mode

  def init()
    self.power_adapter_present = false
    self.in_fast_charge_mode = false
    self.in_pre_charge_mode = false
    end
end

class ChargerSettings
  var charge_voltage_max
  var charge_current_max
  var input_current_limit_1
  var input_current_limit_2
  var system_voltage_min
  var input_voltage_min

  def init()
    self.charge_voltage_max = 20900
    self.charge_current_max = 3072
    self.input_current_limit_1 = 8000
    self.input_current_limit_2 = 8000
    self.system_voltage_min = 15400
    self.input_voltage_min = 20032
  end
end

class ChargerMeasurements
  var system_voltage
  var battery_voltage
  var battery_charge_current
  var battery_discharge_current
  var vbus_voltage
  var input_current

  def init()
    self.system_voltage = 0
    self.battery_voltage = 0
    self.battery_charge_current = 0
    self.battery_discharge_current = 0
    self.vbus_voltage = 0
    self.input_current = 0
    end
end

class ChargerDerivedValues
  var input_power
  var charge_power
  var discharge_power
  var sys_power
  var sys_current
  var battery_percentage

  def init()
    self.input_power = 0
    self.charge_power = 0
    self.discharge_power = 0
    self.sys_power = 0
    self.sys_current = 0
    self.battery_percentage = 0
    end
end
  
class Charger
  var status
  var derived_values
  var settings
  var measurements

  def swap_bytes(value)
    return ((value >> 8) & 0xFF) + ((value << 8) & 0xFF00)
  end

  def charger_read(reg_addr, byte_num)
    return wire2.read(0x6B, reg_addr, byte_num)
  end

  def charger_write(reg_addr, value, byte_num)
    return wire2.write(0x6B, reg_addr, value, byte_num)
  end

  # Utility to read and decode value register
  def read_value_reg(reg_addr, lsb_val, bit_offset)
    var value = self.charger_read(reg_addr, 2)
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
    self.charger_write(reg_addr, value, 2)
  end
  
  def read_device_id()
    # Read charger ManufactureID and Device ID registers
    return self.charger_read(0x2E, 2)
  end

  def read_charge_voltage()
    return self.read_value_reg(0x04, 8, 3)
  end

  def set_charge_voltage_max()
    return self.write_value_reg(0x04, self.settings.charge_voltage_max, 8, 3)
  end

  def read_charge_current()
    return self.read_value_reg(0x02, 128, 6)
  end

  def write_charge_current(value)
    self.write_value_reg(0x02, value, 128, 6)
  end

  def enable_adc()
    # ADC_CONV, EN_ADC_VBUS, EN_ADC_PSYS, EN_ADC_IIN, EN_ADC_IDCHG, EN_ADC_ICHG, EN_ADC_VSYS, EN_ADC_VBAT
    self.charger_write(0x3A, 0x7F80, 2)
  end

  def read_adc_vsys()
    return self.charger_read(0x2D, 1) * 64 + 8160
  end

  def read_adc_vbat()
    return self.charger_read(0x2C, 1) * 64 + 8160
  end

  def read_adc_vbus()
    return self.charger_read(0x27, 1) * 96
  end

  def read_adc_ichg()
    return self.charger_read(0x29, 1) * 128
  end

  def read_adc_idchg()
    return self.charger_read(0x28, 1) * 512
  end

  def read_adc_iin()
    return self.charger_read(0x2B, 1) * 100
  end

  def read_vsysmin()
    return self.read_value_reg(0x0C, 100, 8)
  end

  def set_system_voltage_min()
    self.write_value_reg(0x0C, self.settings.system_voltage_min, 100, 8)
  end

  def read_iin_dpm_host(addr)
    var current = self.read_value_reg(addr, 100, 8)

    if (current == 0) current = 300 end
    if (current > 0) current += 200 end
    return current
  end

  def read_iin_host()
    return self.read_iin_dpm_host(0x0E)
  end

  def set_input_current_limit()
    self.write_value_reg(0x0E, self.settings.input_current_limit_1, 100, 8)
  end

  def read_iin_dpm()
    return self.read_iin_dpm_host(0x24)
  end

  def set_input_voltage_min()
    self.write_value_reg(0x0A, self.settings.input_voltage_min, 64, 6)
  end

  def read_input_voltage_limit()
    return self.read_value_reg(0x0A, 64, 6)
  end

  def read_charger_status()
    var cs = ChargerStatus()
    var reg = self.charger_read(0x21, 1)

    cs.power_adapter_present = ((reg & 0x80) == 0x80)
    cs.in_fast_charge_mode = ((reg & 0x04) == 0x04)
    cs.in_pre_charge_mode = ((reg & 0x02) == 0x02)
  
    return cs
  end

  # Reads all ADC values from the charger and stores the read values
  def read_measured_values()
    var m = ChargerMeasurements()

    m.system_voltage = self.read_adc_vsys()
    m.battery_voltage = self.read_adc_vbat()
    m.battery_charge_current = self.read_adc_ichg()
    m.battery_discharge_current = self.read_adc_idchg()
    m.vbus_voltage = self.read_adc_vbus()
    m.input_current = self.read_adc_iin()

    return m
  end

  # Calculates derived values from measured values
  def calculate_derived_values()
    var m = self.measurements
    var dv = ChargerDerivedValues()

    dv.sys_current = m.input_current + m.battery_charge_current + m.battery_discharge_current
    dv.input_power = m.vbus_voltage * m.input_current / 1000000
    dv.charge_power = m.battery_voltage * m.battery_charge_current / 1000000
    dv.discharge_power = m.battery_voltage * m.battery_discharge_current / 1000000
    dv.sys_power = dv.input_power + dv.charge_power + dv.discharge_power
    dv.battery_percentage = (m.battery_voltage - 15400) * 100 / 6000

    return dv
  end

  def start_charge()
    self.write_charge_current(self.settings.charge_current_max)
  end

  def stop_charge()
    self.write_charge_current(0)
  end

  def read_status()
    return self.status
  end

  def read_derived_values()
    return self.derived_values
  end

  def read_settings()
    return self.settings
  end

  def read_measurements()
    return self.measurements
  end

  # Executed every second
  def every_second()
    self.measurements = self.read_measured_values()
    self.status = self.read_charger_status()
    self.derived_values = self.calculate_derived_values()
  end

  # Charger class initialization
  def init()
    self.status = ChargerStatus()
    self.derived_values = ChargerDerivedValues()
    self.settings = ChargerSettings()
    self.measurements = ChargerMeasurements()

    # Write settings to charger
    self.set_charge_voltage_max()
    self.set_system_voltage_min()
    self.set_input_current_limit()
    self.set_input_voltage_min()

    # Set performance mode (ChargeOption0.EN_LWPWR=0b)
    self.charger_write(0x00, 0x0E67, 2)

    # Set EN_EXTILIM=0b in order to not use input current limit set by hardware but using current limit set in iin_host and iin_dpm
    # TODO Set ChargeOption2.EN_EXTILIM=0b

    # Start ADC conversion
    self.enable_adc()

    tasmota.add_driver(self)
  end

  def close()
    tasmota.remove_driver(self)
  end
end

# Create charger instance
chrg = Charger()