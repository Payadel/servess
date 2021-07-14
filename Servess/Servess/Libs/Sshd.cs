using servess.Attributes;

//TODO: Ensure command, input and other attribute isn't repetitive.
//TODO: Restart ssh service after changes

namespace servess.Libs
{
    [Scope("sshd", "sshd config")]
    public static partial class Sshd
    {
        private const string ConfigFilePath = @"/etc/ssh/sshd_config";
    }
}