/*
  xdrv_82_esp32_ethernet.ino - ESP32 (PoE) ethernet support for Tasmota

  Copyright (C) 2021  Theo Arends

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#ifdef ESP32
//#if CONFIG_IDF_TARGET_ESP32
#ifdef USE_ETHERNET
/*********************************************************************************************\
 * Ethernet support for ESP32
 *
 * Dedicated fixed Phy pins (EMAC)
 * GPIO17 - EMAC_CLK_OUT_180
 * GPIO19 - EMAC_TXD0(RMII)
 * GPIO21 - EMAC_TX_EN(RMII)
 * GPIO22 - EMAC_TXD1(RMII)
 * GPIO25 - EMAC_RXD0(RMII)
 * GPIO26 - EMAC_RXD1(RMII)
 * GPIO27 - EMAC_RX_CRS_DV
 *
 * {"NAME":"Olimex ESP32-PoE","GPIO":[1,1,1,1,1,1,0,0,5536,1,1,1,1,0,5600,0,0,0,0,5568,0,0,0,0,0,0,0,0,1,1,1,1,1,0,0,1],"FLAG":0,"BASE":1}
 * GPIO12 = ETH POWER
 * GPIO18 = ETH MDIO
 * GPIO23 = ETH MDC
 * #define ETH_TYPE          0                   // LAN8720
 * #define ETH_CLKMODE       ETH_CLOCK_GPIO17_OUT
 * #define ETH_ADDRESS       0
 *
 * {"NAME":"wESP32","GPIO":[0,0,1,0,1,1,0,0,1,1,1,1,5568,5600,1,0,0,0,0,1,0,0,0,0,0,0,0,0,1,1,1,1,1,0,0,1],"FLAG":0,"BASE":1}
 * GPIO16 = ETH MDC
 * GPIO17 = ETH MDIO
 * #define ETH_TYPE          0                   // LAN8720
 * #define ETH_CLKMODE       ETH_CLOCK_GPIO0_IN
 * #define ETH_ADDRESS       0
 *
 * {"NAME":"WT32-ETH01","GPIO":[1,1,1,1,1,1,0,0,1,0,1,1,3840,576,5600,0,0,0,0,5568,0,0,0,0,0,0,0,0,1,1,0,1,1,0,0,1],"FLAG":0,"BASE":1}
 * GPIO16 = Force Hi
 * GPIO18 = ETH MDIO
 * GPIO23 = ETH MDC
 * #define ETH_TYPE          0                   // LAN8720
 * #define ETH_CLKMODE       ETH_CLOCK_GPIO0_IN
 * #define ETH_ADDRESS       1
 *
 * Used SPI
 * SPI_MOSI
 * SPI_MISO
 * SPI_CLK
 * SPI_RST = Tasmota ETH_POWER
 * SPI_IRQ = Tasmota ETH_MDIO
 * SPI_CS  = Tasmota ETH_MDC
\*********************************************************************************************/

#define XDRV_82           82

/*
// Olimex ESP32-PoE
#define ETH_CLKMODE       ETH_CLOCK_GPIO17_OUT
#define ETH_POWER_PIN     12

//********************************************************************************************

#ifndef ETH_ADDRESS
#define ETH_ADDRESS       0                      // ETH.h uint8_t:          0 = PHY0 .. 31 = PHY31
#endif

#ifndef ETH_TYPE
#define ETH_TYPE          0                      // 0 = LAN8720, 1 = TLK110/IP101, 2 = RTL8201, 3 = DP83848, 4 = RFU, 5 = KSZ8081, 6 = KSZ8041, 7 = JL1101, 8 = W5500, 9 = KSZ8851, 10 = DM9051
#endif

#ifndef ETH_CLKMODE
#define ETH_CLKMODE       ETH_CLOCK_GPIO0_IN     // ETH.h eth_clock_mode_t: 0 = ETH_CLOCK_GPIO0_IN, 1 = ETH_CLOCK_GPIO0_OUT, 2 = ETH_CLOCK_GPIO16_OUT, 3 = ETH_CLOCK_GPIO17_OUT
#endif
*/

#include <ETH.h>

const uint8_t eth_type_xtable[] = {
  0,     //  0 = LAN8720
  1,     //  1 = TLK110/IP101
  2,     //  2 = RTL8201
  4,     //  3 = DP83848 (is 4 in core3)
  0,     //  4 = RFU - Reserved for Future Use
  6,     //  5 = KSZ8081 (is 6 in core3)
  5,     //  6 = KSZ8041 (is 5 in core3)
  3,     //  7 = JL1101 (is 3 in core3)
  8,     //  8 = W5500 (is new in core3 and using SPI)
  9,     //  9 = KSZ8851 (is new in core3 and using SPI)
  7      // 10 = DM9051 (is 7 in core3 and using SPI)
};
char eth_hostname[sizeof(TasmotaGlobal.hostname)];
uint8_t eth_config_change;

extern esp_netif_t* get_esp_interface_netif(esp_interface_t interface);

void EthernetEvent(arduino_event_t *event);
void EthernetEvent(arduino_event_t *event) {
  switch (event->event_id) {
    case ARDUINO_EVENT_ETH_START:
      AddLog(LOG_LEVEL_DEBUG, PSTR(D_LOG_ETH D_ATTEMPTING_CONNECTION));
      ETH.setHostname(eth_hostname);
      break;

    case ARDUINO_EVENT_ETH_CONNECTED:
      AddLog(LOG_LEVEL_INFO, PSTR(D_LOG_ETH D_CONNECTED " at %dMbps%s, Mac %s, Hostname %s"),
        ETH.linkSpeed(), (ETH.fullDuplex()) ? " Full Duplex" : "",
        ETH.macAddress().c_str(), eth_hostname
        );
        
      // AddLog(LOG_LEVEL_DEBUG, D_LOG_ETH "ETH.enableIPV6() -> %i", ETH.enableIPV6());
      break;
      
    case ARDUINO_EVENT_ETH_GOT_IP:
      // AddLog(LOG_LEVEL_DEBUG, PSTR(D_LOG_ETH "Mac %s, IPAddress %_I, Hostname %s"),
      //   ETH.macAddress().c_str(), (uint32_t)ETH.localIP(), eth_hostname);
      Settings->eth_ipv4_address[1] = (uint32_t)ETH.gatewayIP();
      Settings->eth_ipv4_address[2] = (uint32_t)ETH.subnetMask();
      if (0 == Settings->eth_ipv4_address[0]) {  // At this point ETH.dnsIP() are NOT correct unless DHCP
        Settings->eth_ipv4_address[3] = (uint32_t)ETH.dnsIP();
        Settings->eth_ipv4_address[4] = (uint32_t)ETH.dnsIP(1);
      }
      TasmotaGlobal.rules_flag.eth_connected = 1;
      TasmotaGlobal.global_state.eth_down = 0;
      AddLog(LOG_LEVEL_DEBUG, PSTR("ETH: IPv4 %_I, mask %_I, gateway %_I"),
              event->event_info.got_ip.ip_info.ip.addr,
              event->event_info.got_ip.ip_info.netmask.addr,
              event->event_info.got_ip.ip_info.gw.addr);
      WiFiHelper::scrubDNS();    // internal calls to reconnect can zero the DNS servers, save DNS for future use
      break;

#ifdef USE_IPV6
    case ARDUINO_EVENT_ETH_GOT_IP6:
    {
      ip_addr_t ip_addr6;
      ip_addr_copy_from_ip6(ip_addr6, event->event_info.got_ip6.ip6_info.ip);
      IPAddress addr(&ip_addr6);
      AddLog(LOG_LEVEL_DEBUG, PSTR("%s: IPv6 %s %s"),
             event->event_id == ARDUINO_EVENT_ETH_GOT_IP6 ? "ETH" : "WIF",
             IPv6isLocal(addr) ? PSTR("Local") : PSTR("Global"), addr.toString().c_str());
      if (!IPv6isLocal(addr)) {    // declare network up on IPv6
        TasmotaGlobal.rules_flag.eth_connected = 1;
        TasmotaGlobal.global_state.eth_down = 0;
      }
      WiFiHelper::scrubDNS();    // internal calls to reconnect can zero the DNS servers, save DNS for future use
    }
    break;
#endif // USE_IPV6

    case ARDUINO_EVENT_ETH_DISCONNECTED:
      AddLog(LOG_LEVEL_INFO, PSTR(D_LOG_ETH "Disconnected"));
      TasmotaGlobal.rules_flag.eth_disconnected = 1;
      TasmotaGlobal.global_state.eth_down = 1;
      break;

    case ARDUINO_EVENT_ETH_STOP:
      AddLog(LOG_LEVEL_DEBUG, PSTR(D_LOG_ETH "Stopped"));
      TasmotaGlobal.global_state.eth_down = 1;
      break;

    default:
      break;
  }
}

void EthernetSetIp(void) {
  // Set static IP
  ETH.config(Settings->eth_ipv4_address[0],       // IPAddress local_ip
             Settings->eth_ipv4_address[1],       // IPAddress gateway
             Settings->eth_ipv4_address[2],       // IPAddress subnet
             Settings->eth_ipv4_address[3],       // IPAddress dns1
             Settings->eth_ipv4_address[4]);      // IPAddress dns2
}

void EthernetInit(void) {
  if (!Settings->flag4.network_ethernet) { return; }

  int eth_type = eth_type_xtable[Settings->eth_type];
#if CONFIG_ETH_USE_ESP32_EMAC
  if (WT32_ETH01 == TasmotaGlobal.module_type) {
    Settings->eth_address = 1;                    // EthAddress
    Settings->eth_type = 0;                       // EthType 0 = LAN8720
    Settings->eth_clk_mode = 0;                   // EthClockMode 0 = ETH_CLOCK_GPIO0_IN
  }
#else  // No CONFIG_ETH_USE_ESP32_EMAC
  if (Settings->eth_type < 7) {
    Settings->eth_type = 8;                       // Select W5500 (SPI) for non-EMAC hardware
  }
  eth_type = eth_type_xtable[Settings->eth_type] -7;  // As No EMAC support substract EMAC enums (According ETH.cpp debug info)
#endif  // CONFIG_ETH_USE_ESP32_EMAC

  if (Settings->eth_type < 7) {
    // CONFIG_ETH_USE_ESP32_EMAC
    if (!PinUsed(GPIO_ETH_PHY_MDC) && !PinUsed(GPIO_ETH_PHY_MDIO)) {  // && should be || but keep for backward compatibility
      AddLog(LOG_LEVEL_DEBUG_MORE, PSTR(D_LOG_ETH "No ETH MDC and ETH MDIO GPIO defined"));
      return;
    }
  } else {
    // ETH_SPI_SUPPORTS_CUSTOM
    if (!PinUsed(GPIO_ETH_PHY_MDC) || !PinUsed(GPIO_ETH_PHY_MDIO) || !PinUsed(GPIO_ETH_PHY_POWER)) {
      AddLog(LOG_LEVEL_DEBUG_MORE, PSTR(D_LOG_ETH "No ETH MDC (SPI CS), ETH MDIO (SPI IRQ) and ETH POWER (SPI RST) GPIO defined"));
      return;
    }
  }

  eth_config_change = 0;

  strlcpy(eth_hostname, TasmotaGlobal.hostname, sizeof(eth_hostname) -5);  // Make sure there is room for "-eth"
  strcat(eth_hostname, "-eth");

  WiFi.onEvent(EthernetEvent);

  int eth_mdc = Pin(GPIO_ETH_PHY_MDC);       // Ethernet SPI CS (chip select)
  int eth_mdio = Pin(GPIO_ETH_PHY_MDIO);     // Ethernet SPI IRQ
  int eth_power = Pin(GPIO_ETH_PHY_POWER);   // Ethernet SPI RST

#ifdef USE_IPV6
  ETH.enableIPv6();   // enable Link-Local
#endif // USE_IPV6

  bool init_ok = false;
  if (Settings->eth_type < 7) {
#if CONFIG_ETH_USE_ESP32_EMAC
    init_ok = (ETH.begin((eth_phy_type_t)eth_type, Settings->eth_address, eth_mdc, eth_mdio, eth_power, (eth_clock_mode_t)Settings->eth_clk_mode));
#endif  // CONFIG_ETH_USE_ESP32_EMAC
  } else {
    // ETH_SPI_SUPPORTS_CUSTOM
    // SPISettings(ETH_PHY_SPI_FREQ_MHZ * 1000 * 1000, MSBFIRST, SPI_MODE0);  // 20MHz
    SPI.begin(Pin(GPIO_SPI_CLK), Pin(GPIO_SPI_MISO), Pin(GPIO_SPI_MOSI), -1);
    init_ok = (ETH.begin((eth_phy_type_t)eth_type, Settings->eth_address, eth_mdc, eth_mdio, eth_power, SPI, ETH_PHY_SPI_FREQ_MHZ));
  }
  if (!init_ok) {
    AddLog(LOG_LEVEL_DEBUG, PSTR(D_LOG_ETH "Bad EthType or init error"));
    return;
  };

  if (Settings->eth_ipv4_address[0]) {
    EthernetSetIp();                             // Set static IP
  }
}

IPAddress EthernetLocalIP(void) {
  return ETH.localIP();
}

// Check to see if we have any routable IP address
// IPv4 has always priority
// Copy the value of the IP if pointer provided (optional)
bool EthernetGetIP(IPAddress *ip) {
#ifdef USE_IPV6
  if ((uint32_t)ETH.localIP() != 0) {
    if (ip != nullptr) { *ip = ETH.localIP(); }
    return true;
  }
  IPAddress lip;
  if (EthernetGetIPv6(&lip)) {
    if (ip != nullptr) { *ip = lip; }
    return true;
  }
  if (ip != nullptr) { *ip = IPAddress(); }
  return false;
#else
  // IPv4 only
  if (ip != nullptr) { *ip = ETH.localIP(); }
  return (uint32_t)ETH.localIP() != 0;
#endif // USE_IPV6
}
bool EthernetHasIP(void) {
  return EthernetGetIP(nullptr);
}
String EthernetGetIPStr(void) {
  IPAddress ip;
  if (EthernetGetIP(&ip)) {
    return ip.toString();
  } else {
    return String();
  }
}

char* EthernetHostname(void) {
  return eth_hostname;
}

String EthernetMacAddress(void) {
  return ETH.macAddress();
}

void EthernetConfigChange(void) {
  if (eth_config_change) {
    eth_config_change--;
    if (!eth_config_change) {
      EthernetSetIp();
    }
  }
}

/*********************************************************************************************\
 * Commands
\*********************************************************************************************/

#define D_CMND_ETHADDRESS   "Address"
#define D_CMND_ETHTYPE      "Type"
#define D_CMND_ETHCLOCKMODE "ClockMode"
#define D_CMND_ETHIPADDRESS D_CMND_IPADDRESS
#define D_CMND_ETHGATEWAY   D_JSON_GATEWAY
#define D_CMND_ETHNETMASK   D_JSON_SUBNETMASK
#define D_CMND_ETHDNS       D_JSON_DNSSERVER

const char kEthernetCommands[] PROGMEM = "Eth|"  // Prefix
  "ernet|" D_CMND_ETHADDRESS "|" D_CMND_ETHTYPE "|" D_CMND_ETHCLOCKMODE "|"
  D_CMND_ETHIPADDRESS "|" D_CMND_ETHGATEWAY "|" D_CMND_ETHNETMASK "|" D_CMND_ETHDNS ;

void (* const EthernetCommand[])(void) PROGMEM = {
  &CmndEthernet, &CmndEthAddress, &CmndEthType, &CmndEthClockMode,
  &CmndEthSetIpConfig, &CmndEthSetIpConfig, &CmndEthSetIpConfig, &CmndEthSetIpConfig };

#define ETH_PARAM_OFFSET 4                       // Offset of command index in above table of first CmndEthIpConfig

void CmndEthernet(void) {
  if ((XdrvMailbox.payload >= 0) && (XdrvMailbox.payload <= 1)) {
    Settings->flag4.network_ethernet = XdrvMailbox.payload;
    TasmotaGlobal.restart_flag = 2;
  }
  ResponseCmndStateText(Settings->flag4.network_ethernet);
}

void CmndEthAddress(void) {
  if ((XdrvMailbox.payload >= 0) && (XdrvMailbox.payload <= 31)) {
    Settings->eth_address = XdrvMailbox.payload;
    TasmotaGlobal.restart_flag = 2;
  }
  ResponseCmndNumber(Settings->eth_address);
}

void CmndEthType(void) {
  if ((XdrvMailbox.payload >= 0) && (XdrvMailbox.payload < sizeof(eth_type_xtable))) {
    Settings->eth_type = XdrvMailbox.payload;
    TasmotaGlobal.restart_flag = 2;
  }
  ResponseCmndNumber(Settings->eth_type);
}

void CmndEthClockMode(void) {
  if ((XdrvMailbox.payload >= 0) && (XdrvMailbox.payload <= 3)) {
    Settings->eth_clk_mode = XdrvMailbox.payload;
    TasmotaGlobal.restart_flag = 2;
  }
  ResponseCmndNumber(Settings->eth_clk_mode);
}

void CmndEthSetIpConfig(void) {
  uint32_t param_id = XdrvMailbox.command_code -ETH_PARAM_OFFSET;

  char cmnd_idx[2] = { 0 };
  if (3 == param_id) {                           // EthDnsServer
    if ((XdrvMailbox.index < 1) || (XdrvMailbox.index > 2)) {
      XdrvMailbox.index = 1;
    }
    cmnd_idx[0] = '0' + XdrvMailbox.index;
    param_id += XdrvMailbox.index -1;            // EthDnsServer2
  }

  if (XdrvMailbox.data_len) {
    uint32_t ipv4_address;
    if (ParseIPv4(&ipv4_address, XdrvMailbox.data)) {
      Settings->eth_ipv4_address[param_id] = ipv4_address;
      eth_config_change = 2;
    }
  }

  char network_address[22] = { 0 };
  if (0 == param_id) {
    if (!Settings->eth_ipv4_address[0]) {
      ext_snprintf_P(network_address, sizeof(network_address), PSTR(" (%_I)"), (uint32_t)ETH.localIP());
    }
  }
  Response_P(PSTR("{\"%s%s\":\"%_I%s\"}"), XdrvMailbox.command, cmnd_idx, Settings->eth_ipv4_address[param_id], network_address);
}

/*********************************************************************************************\
 * Interface
\*********************************************************************************************/

bool Xdrv82(uint32_t function) {
  bool result = false;

  switch (function) {
    case FUNC_EVERY_SECOND:
      EthernetConfigChange();
      break;
    case FUNC_COMMAND:
      result = DecodeCommand(kEthernetCommands, EthernetCommand);
      break;
    case FUNC_INIT:
      EthernetInit();
      break;
    case FUNC_ACTIVE:
      result = true;
      break;
  }
  return result;
}

#endif  // USE_ETHERNET
//#endif  // CONFIG_IDF_TARGET_ESP32
#endif  // ESP32
