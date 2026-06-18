import { wifiManager } from '@kit.ConnectivityKit';

@ObservedV2
export class WifiModel {
  @Trace bssid: string = '';
  @Trace ssid: string = '';
  @Trace rssi: number = -100;
  @Trace band: number = 0;
  @Trace channel: number = 0;
  @Trace securityType: string = '';
  @Trace connected: boolean = false;

  static fromScanInfo(info: wifiManager.WifiScanInfo): WifiModel {
    let model = new WifiModel();
    model.ssid = info.ssid || '';
    model.bssid = info.bssid || '';
    model.rssi = info.rssi || -100;
    model.band = WifiModel.calcBand(info.frequency);
    model.channel = WifiModel.freqToChannel(info.frequency);
    model.securityType = WifiModel.resolveSecurityType(info.securityType);
    model.connected = false;
    return model;
  }

  getSignalLabel(): Resource {
    if (this.rssi >= -50) {
      return $r('app.string.signal_excellent');
    }
    if (this.rssi >= -60) {
      return $r('app.string.signal_good');
    }
    if (this.rssi >= -70) {
      return $r('app.string.signal_fair');
    }
    if (this.rssi >= -80) {
      return $r('app.string.signal_weak');
    }
    return $r('app.string.signal_poor');
  }

  getSignalLevel(): number {
    if (this.rssi >= -50) {
      return 4;
    }
    if (this.rssi >= -60) {
      return 3;
    }
    if (this.rssi >= -70) {
      return 2;
    }
    if (this.rssi >= -80) {
      return 1;
    }
    return 0;
  }

  getBandLabel(): string {
    if (this.band === 1) {
      return '5GHz';
    }
    return '2.4GHz';
  }

  private static calcBand(frequency: number): number {
    if (frequency >= 2400 && frequency < 2500) {
      return 0;
    }
    if (frequency >= 5000 && frequency <= 6000) {
      return 1;
    }
    return 0;
  }

  private static freqToChannel(frequency: number): number {
    if (frequency >= 2412 && frequency <= 2484) {
      return Math.round((frequency - 2407) / 5);
    }
    if (frequency >= 5170 && frequency <= 5825) {
      return Math.round((frequency - 5000) / 5);
    }
    return 0;
  }

  private static resolveSecurityType(securityType: number): string {
    if (securityType === 0) {
      return 'OPEN';
    }
    if (securityType === 1) {
      return 'WEP';
    }
    if (securityType === 2) {
      return 'PSK';
    }
    if (securityType === 3) {
      return 'EAP';
    }
    if (securityType === 4) {
      return 'SAE';
    }
    if (securityType === 5) {
      return 'OWE';
    }
    return 'UNKNOWN';
  }
}
