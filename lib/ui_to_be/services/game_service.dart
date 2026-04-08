/// Cloud gaming service for Moonlight/Sunshine integration.
///
/// TODO: Implement game session launching and management.
/// - The Malaysia Gaming VPS runs Sunshine (host) on a Windows VM
/// - Client connects via Moonlight (native app or browser-based)
/// - Session management: one concurrent session per user (enforced by backend)
/// - coturn TURN/STUN server handles NAT traversal for streaming
/// - First-time users must complete Steam login inside the streaming session
/// - Subsequent sessions auto-login to Steam (persistent session on VM)
/// - Backend API: POST /api/gaming/session/start, POST /api/gaming/session/end
/// - Session inactivity timeout managed server-side
class GameService {
  /// TODO: Launch a Moonlight cloud gaming session.
  /// Options:
  /// 1. Open Moonlight app via deep link / intent (if installed)
  ///    Android: Intent with moonlight:// scheme
  ///    Windows: Launch moonlight.exe with connection parameters
  /// 2. Open browser-based Moonlight web client at session URL
  ///    URL format: https://moonlight.ecomgear.dev/session/{sessionId}
  /// Steps:
  /// 1. Call backend API to allocate a gaming session slot
  /// 2. Receive session connection details (Sunshine host IP, session token)
  /// 3. Launch Moonlight with those connection details
  /// 4. Monitor session status via polling or WebSocket
  static Future<void> launchSession() async {
    // TODO: Implement Moonlight session launch
    // 1. POST /api/gaming/session/start -> { hostIp, sessionToken, sunshinePort }
    // 2. url_launcher.launch('moonlight://pair/{hostIp}') or open browser URL
    await Future.delayed(const Duration(seconds: 2));
  }

  /// TODO: End the current cloud gaming session.
  /// - Notify backend to release the session slot
  /// - Clean up any local session state
  static Future<void> endSession() async {
    // TODO: POST /api/gaming/session/end
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// TODO: Check if the user needs first-time Steam login.
  /// Queries the backend to see if the user's assigned Steam seat
  /// has been activated (Steam login completed at least once).
  static Future<bool> needsSteamSetup() async {
    // TODO: GET /api/gaming/steam-status -> { needsSetup: bool }
    return true;
  }
}
