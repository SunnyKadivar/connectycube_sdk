import '../peer_connection.dart';

class ConferencePeerConnection extends PeerConnection {
  ConferencePeerConnection(int userId, CubePeerConnectionStateCallback peerConnectionStateCallback) : super(userId, peerConnectionStateCallback, false);
}