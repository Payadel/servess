using Servess.Attributes;

namespace Servess.Libs.Firewall {
    [Scope("firewall", "firewall config")]
    public static partial class Firewall {
        private const string ConfigFilePath = @"/etc/default/ufw";
    }
}