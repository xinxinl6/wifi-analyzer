import { hilog } from '@kit.PerformanceAnalysisKit';
import { WifiService } from './WifiService';
import { WifiModel } from '../models/WifiModel';

const DOMAIN = 0x0000;
const TAG = 'WifiScanner';

@ObservedV2
export class WifiScanner {
  @Trace scanResults: WifiModel[] = [];
  @Trace isScanning: boolean = false;
  @Trace lastScanTime: number = 0;
  private timerId: number = -1;

  startScanning(intervalMs: number = 12000): void {
    if (this.isScanning) {
      return;
    }
    this.isScanning = true;
    this.scanOnce();
    this.timerId = setInterval(() => {
      this.scanOnce();
    }, intervalMs);
    hilog.info(DOMAIN, TAG, '%{public}s', 'startScanning interval: ' + intervalMs + 'ms');
  }

  stopScanning(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
    this.isScanning = false;
    hilog.info(DOMAIN, TAG, '%{public}s', 'stopScanning');
  }

  async scanOnce(): Promise<void> {
    try {
      let results = await WifiService.scan();
      this.scanResults = results;
      this.lastScanTime = Date.now();
      hilog.info(DOMAIN, TAG, '%{public}s', 'scanOnce completed: ' + results.length + ' APs');
    } catch (e) {
      hilog.error(DOMAIN, TAG, '%{public}s', 'scanOnce error: ' + JSON.stringify(e));
    }
  }

  refresh(): void {
    this.scanOnce();
  }
}
