using FunctionalUtility.ResultUtility;

namespace Servess {
    public static class FirewallUtility {
        public static MethodResult AllowPort(int port) {
            Utility.ExecuteBashCommand($"sudo ufw allow {port}");
            return MethodResult.Ok(); //TODO: Validate result
        }
        
        public static MethodResult DenyPort(int port) {
            Utility.ExecuteBashCommand($"sudo ufw deny {port}");
            return MethodResult.Ok(); //TODO: Validate result
        }
    }
}