import { hilog } from '@kit.PerformanceAnalysisKit';
import { wifiManager } from '@kit.ConnectivityKit';
import { WifiModel } from '../models/WifiModel';

const DOMAIN = 0x0000;
const TAG = 'WifiService';

export class WifiService {
  static isWifiEnabled(): boolean {
    try {
      return wifiManager.isWifiActiveSync();
    } catch (e) {
      hilog.error(DOMAIN, TAG, '%{public}s', 'isWifiActiveSync error: ' + JSON.stringify(e));
      return false;
    }
  }

  static getLinkedInfo(): wifiManager.WifiLinkedInfo | null {
    try {
      let linkedInfo = wifiManager.getLinkedInfoSync();
      return linkedInfo;
    } catch (e) {
      hilog.error(DOMAIN, TAG, '%{public}s', 'getLinkedInfoSync error: ' + JSON.stringify(e));
      return null;
    }
  }

  static async scan(): Promise<WifiModel[]> {
    try {
      await wifiManager.startScan();
      await WifiService.delay(1500);
      return WifiService.getScanResults();
    } catch (e) {
      hilog.error(DOMAIN, TAG, '%{public}s', 'scan error: ' + JSON.stringify(e));
      return [];
    }
  }

  static getScanResults(): WifiModel[] {
    try {
      let results = wifiManager.getScanInfoList();
      let models: WifiModel[] = [];
      for (let i = 0; i < results.length; i++) {
        models.push(WifiModel.fromScanInfo(results[i]));
      }
      hilog.info(DOMAIN, TAG, '%{public}s', 'getScanInfoList count: ' + results.length);
      return models;
    } catch (e) {
      hilog.error(DOMAIN, TAG, '%{public}s', 'getScanInfoList error: ' + JSON.stringify(e));
      return [];
    }
  }

  private static delay(ms: number): Promise<void> {
    return new Promise<void>(function (resolve: () => void) {
      setTimeout(resolve, ms);
    });
  }
}
