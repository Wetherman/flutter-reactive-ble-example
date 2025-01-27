import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:blestream/src/ble/ble_device_connector.dart';
import 'package:blestream/src/ble/ble_device_interactor.dart';
import 'package:blestream/src/ble/ble_scanner.dart';
import 'package:blestream/src/ble/ble_status_monitor.dart';
import 'package:blestream/src/ui/ble_status_screen.dart';
import 'package:blestream/src/ui/device_list.dart';
import 'package:provider/provider.dart';
import 'package:blestream/globals.dart' as g;
import 'src/ble/ble_logger.dart';

var _themeColor = g.olive; // Colors.lightGreen;

final materialThemeData = ThemeData(
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(color: Colors.blue.shade600),
    primaryColor: Colors.blue,
    secondaryHeaderColor: Colors.blue,
    canvasColor: Colors.blue,
    textTheme:
        const TextTheme().copyWith(bodyLarge: const TextTheme().bodyMedium),
    colorScheme: ColorScheme.fromSwatch(primarySwatch: g.olive)
        .copyWith(background: Colors.white)
        .copyWith(secondary: g.olive));
const cupertinoTheme = CupertinoThemeData(
    primaryColor: Color.fromRGBO(53, 95, 80, 1),
    barBackgroundColor: Color.fromRGBO(53, 95, 80, 1),
    scaffoldBackgroundColor: Colors.white);

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final _bleLogger = BleLogger();
  final _ble = FlutterReactiveBle();
  final _scanner = BleScanner(ble: _ble, logMessage: _bleLogger.addToLog);
  final _monitor = BleStatusMonitor(_ble);
  final _connector = BleDeviceConnector(
    ble: _ble,
    logMessage: _bleLogger.addToLog,
  );
  final _serviceDiscoverer = BleDeviceInteractor(
    bleDiscoverServices: _ble.discoverServices,
    readCharacteristic: _ble.readCharacteristic,
    writeWithResponse: _ble.writeCharacteristicWithResponse,
    writeWithOutResponse: _ble.writeCharacteristicWithoutResponse,
    subscribeToCharacteristic: _ble.subscribeToCharacteristic,
    logMessage: _bleLogger.addToLog,
  );
  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: _scanner),
        Provider.value(value: _monitor),
        Provider.value(value: _connector),
        Provider.value(value: _serviceDiscoverer),
        Provider.value(value: _bleLogger),
        StreamProvider<BleScannerState?>(
          create: (_) => _scanner.state,
          initialData: const BleScannerState(
            discoveredDevices: [],
            scanIsInProgress: false,
          ),
        ),
        StreamProvider<BleStatus?>(
          create: (_) => _monitor.state,
          initialData: BleStatus.unknown,
        ),
        StreamProvider<ConnectionStateUpdate>(
          create: (_) => _connector.state,
          initialData: const ConnectionStateUpdate(
            deviceId: 'Unknown device',
            connectionState: DeviceConnectionState.disconnected,
            failure: null,
          ),
        ),
      ],
      child: PlatformApp(
        title: 'blestream example',
        color: _themeColor,
        // theme: ThemeData(primarySwatch: _themeColor),
        home: const HomeScreen(),
      ),
    ),
  );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Consumer<BleStatus?>(
        builder: (_, status, __) {
          if (status == BleStatus.ready) {
            return const DeviceListScreen();
          } else {
            return BleStatusScreen(status: status ?? BleStatus.unknown);
          }
        },
      );
}
