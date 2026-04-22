sealed class AppConstants {
  static const String appName = 'OneNET';
  static const String appBrand = 'eCG';
  static const String appFullName = 'eCG OneNET';
  static const String appVersion = '0.1.0';
  static const String appBuildTag = 'ALPHA';
  static const String appVersionDisplay = 'v$appVersion $appBuildTag';

  // Portal URLs
  static const String portalUrl = 'https://onenet.ecomgear.dev';
  static const String portalSignupUrl = '$portalUrl/auth';
  static const String portalResetPasswordUrl = '$portalUrl/reset-password';
  static const String portalPlansUrl = '$portalUrl/plans';
  static const String portalAccountUrl = '$portalUrl/dashboard';
  static const String portalDownloadsUrl = '$portalUrl/downloads';
  static const String supportUrl = '$portalUrl/support';

  // Supabase
  static const String supabaseUrl = 'https://fcxztzinesryeojdkzyb.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_A6f4iCajbZDaa2CWEzyksA_mqTO4SAw';

  // Supabase Edge Function endpoints
  static const String loginEndpoint = '$supabaseUrl/functions/v1/login';
  static const String registerEndpoint = '$supabaseUrl/functions/v1/register';
  static const String logoutEndpoint = '$supabaseUrl/functions/v1/logout';
  static const String vpnConnectEndpoint = '$supabaseUrl/functions/v1/vpn_connect';
  static const String getUsageEndpoint = '$supabaseUrl/functions/v1/get_usage';
  static const String getProfileEndpoint = '$supabaseUrl/functions/v1/get_profile';
  static const String storageGatewayEndpoint = '$supabaseUrl/functions/v1/storage-gateway';

  static const String vpnNodesEndpoint =
      '$supabaseUrl/rest/v1/vpn_nodes?select=id,hostname,public_ip,region,is_online&is_online=eq.true&order=created_at.asc';
}
