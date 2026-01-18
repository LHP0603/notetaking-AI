abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  @override
  Future<bool> get isConnected async {
    // TODO: Implement actual network connectivity check
    // You can use connectivity_plus package for this
    return true;
  }
}
