import Foundation

public class MagnetScannerSwift {
    var scanners = [String: Scanner]()
    var callback: ((Dictionary<String, AnyObject>) -> Void)!

    public init(callback: (Dictionary<String, AnyObject>) -> Void) {
        scanners["ble"] = BeaconScanner(callback: callback);
        scanners["network"] = ScannerNetwork(callback: callback);
    }

    public func start() {
        for (_, scanner) in scanners { scanner.start() }
    }

    public func stop() {
        for (_, scanner) in scanners { scanner.stop() }
    }
}
