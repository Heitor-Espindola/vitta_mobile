import 'package:flutter_test/flutter_test.dart';
import 'package:vitta_mobile/dataconnect_generated/mobile_connector.dart';

void main() {
  test('SDK oficial do mobile connector pode ser carregado', () {
    expect(MobileConnectorConnector.connectorConfig, isNotNull);
  });
}
