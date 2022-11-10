import 'package:hooks_riverpod/hooks_riverpod.dart';

class Logger extends ProviderObserver {
  @override
  void didUpdateProvider(ProviderBase provider, Object? previousValue,
      Object? newValue, ProviderContainer container) {
    print('''{
      "provider": "${provider.name ?? provider.runtimeType}"
      "newValue": "$newValue"
    }''');
    super.didUpdateProvider(provider, previousValue, newValue, container);
  }
}
