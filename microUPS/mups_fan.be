class MUPSFan

  var rpm
  var percent
  var aht_read_state
  var aht_read_data

  # gets fan speed in rpm
  def get_fan_rpm()
    return self.rpm
  end

  # Sets fan speed in rpm
  def set_fan_rpm(rpm)
  end

  # Gets fan speed in %
  def get_fan_speed_percent()
    return self.percent
  end

  # Sets fan speed given in %
  def set_fan_speed_percent(val)
    self.percent = val
    tasmota.cmd(format("Backlog Channel4 %d; Channel5 %d", val, val), true)
  end

  def aht_read_handler()
    if (self.aht_read_state == 1)
      wire2._begin_transmission(0x38)
      wire2._write(0xAC)
      wire2._write(0x33)
      wire2._write(0x00)
      wire2._end_transmission()

      self.aht_read_state = 2
    elif (self.aht_read_state == 2)

      wire2._request_from(0x38, 6)
      self.aht_read_data = bytes(6)
      while (wire2._available())
        self.aht_read_data.append(wire2._read())
      end
        # Stop reading AHT25
      self.aht_read_state = 0

      print(self.aht_read_data)
    end
  end

  def every_250ms()
    self.aht_read_handler()
  end

  def every_second()
    # Start reading AHT25
    if (self.aht_read_state == 0)
      self.aht_read_state = 1
    end
    # Get fan speed
    # TODO: Find out how to get real RPM
  end

  def init()
    self.rpm = 0
    self.percent = 0
    self.aht_read_state = 0

    tasmota.add_driver(self)
  end
end

mups_fan = MUPSFan()