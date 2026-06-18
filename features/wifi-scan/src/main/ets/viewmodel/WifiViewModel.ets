import { WifiScanner } from '../service/WifiScanner';
import { WifiModel } from '../models/WifiModel';

export class WifiViewModel {
  private scanner: WifiScanner;

  constructor() {
    this.scanner = new WifiScanner();
  }

  getScanner(): WifiScanner {
    return this.scanner;
  }

  getStats(): WifiStats {
    let results = this.scanner.scanResults;
    let total = results.length;
    let avgRssi = 0;
    let bestSsid = '';

    if (total > 0) {
      let sum = 0;
      let bestSignal = -100;
      for (let i = 0; i < total; i++) {
        let item = results[i];
        sum = sum + item.rssi;
        if (item.rssi > bestSignal) {
          bestSignal = item.rssi;
          bestSsid = item.ssid;
        }
      }
      avgRssi = Math.round(sum / total);
    }

    return {
      total: total,
      avgRssi: avgRssi,
      bestSsid: bestSsid
    };
  }
}

export interface WifiStats {
  total: number;
  avgRssi: number;
  bestSsid: string;
}
