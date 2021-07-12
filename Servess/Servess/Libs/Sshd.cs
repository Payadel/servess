using servess.Attributes;

//TODO: Ensure command, input and other attribute isn't repetitive.

namespace servess.Libs {
    [Scope("sshd", "sshd config")]
    public static partial class Sshd {
        private const string ConfigFilePath = @"/etc/ssh/sshd_config";
        //TODO: Convert to new style
        // [Command("disable-password", "disable login with password")]
        // public static void DisablePassword(string[] inputs) {
        //     switch (inputs.Length) {
        //         case 0:
        //             Operator();
        //             break;
        //         case 1 when Utility.IsHelpFlag(inputs[0]):
        //             // -h/--help
        //             ShowHelp();
        //             break;
        //         case 1 when IsValidInput(inputs[0]):
        //             //true/false
        //             Operator(bool.Parse(inputs[0]));
        //             break;
        //         case 2 when IsValidOption(inputs[0]):
        //             // -p/--path path
        //             Operator(customPath: inputs[1]);
        //             break;
        //         case 3 when IsValidInput(inputs[0]) && IsValidOption(inputs[1]):
        //             // true/false -p/--path path
        //             Operator(bool.Parse(inputs[0]), inputs[2]);
        //             break;
        //         default:
        //             Console.WriteLine("Invalid option.\n");
        //             ShowHelp();
        //             break;
        //     }
        //
        //     static void ShowHelp() {
        //         Console.WriteLine($" Usage:  {AppConstants.AppName} SCOPE COMMAND [OPTIONS]");
        //         Console.WriteLine();
        //         Console.WriteLine(" Input:");
        //         Console.WriteLine("\tboolean\ttrue/false (default is true)");
        //         Console.WriteLine();
        //         Console.WriteLine(" Options:");
        //         Console.WriteLine("\t-p --path\tsshd config file");
        //     }
        //
        //     static MethodResult Operator(bool disablePassword = true, string? customPath = null) {
        //         const string permitRootLogin = "PermitRootLogin";
        //         var path = customPath ?? ConfigFilePath;
        //
        //         var lines = File.ReadAllLines(path).ToList();
        //         using var fileStream = new FileStream(path, FileMode.Open, FileAccess.ReadWrite,
        //             FileShare.Read);
        //
        //         var methodResult = Utility.AddOrUpdateKeyValue(lines, permitRootLogin,
        //             disablePassword ? "without-password" : "yes");
        //         fileStream.Close();
        //
        //         return methodResult.OnSuccess(lines => File.WriteAllLines(path, lines));
        //     }
        //
        //     static bool IsValidInput(string value) => value.ToLower() == "true" || value.ToLower() == "false";
        //     static bool IsValidOption(string value) => value.ToLower() == "-p" || value.ToLower() == "--path";
        // }

        // [Command("connection-timeout", "SSH Connection Timeout")]
        // public static void ConnectionTimeout(string[] inputs) {
        //     switch (inputs.Length) {
        //         case 0:
        //             Operation();
        //             break;
        //         case 1 when Utility.IsHelpFlag(inputs[0]):
        //             // -h/--help
        //             ShowHelp();
        //             break;
        //         case 1 when IsValidInput(inputs[0]):
        //             //true/false
        //             Operation(bool.Parse(inputs[0]));
        //             break;
        //         case 2 when IsValidOption(inputs[0]):
        //             // -p/--path path
        //             Operation(customPath: inputs[1]);
        //             break;
        //         case 3 when IsValidInput(inputs[0]) && IsValidOption(inputs[1]):
        //             // true/false -p/--path path
        //             Operation(bool.Parse(inputs[0]), inputs[2]);
        //             break;
        //         default:
        //             Console.WriteLine("Invalid option.\n");
        //             ShowHelp();
        //             break;
        //     }
        //
        //     static void ShowHelp() {
        //         Console.WriteLine($" Usage:  {AppConstants.AppName} SCOPE COMMAND [OPTIONS]");
        //         Console.WriteLine();
        //         Console.WriteLine(" Input:");
        //         Console.WriteLine("\tboolean\ttrue/false (default is true)");
        //         Console.WriteLine();
        //         Console.WriteLine(" Options:");
        //         Console.WriteLine("\t-p --path\tsshd config file");
        //     }
        //
        //     static void Operation(int? clientAliveInterval = null, int? clientAliveCountMax = null,
        //         string? customPath = null) {
        //         const string clientAliveIntervalKey = "ClientAliveInterval";
        //         const string clientAliveCountMaxKey = "ClientAliveCountMax";
        //         var path = customPath ?? ConfigFilePath;
        //
        //         var lines = File.ReadAllLines(path).ToList();
        //         using var fileStream = new FileStream(path, FileMode.Open, FileAccess.ReadWrite,
        //             FileShare.Read);
        //
        //         if (clientAliveInterval is not null) {
        //             lines = Utility.AddOrUpdateKeyValue(lines, clientAliveIntervalKey, clientAliveInterval.ToString()!);
        //         }
        //
        //         if (clientAliveInterval is not null) {
        //             lines = Utility.AddOrUpdateKeyValue(lines, clientAliveCountMaxKey, clientAliveCountMax.ToString()!);
        //         }
        //
        //         fileStream.Close();
        //         File.WriteAllLines(path, lines);
        //     }
        //
        //     static bool IsValidInput(string value) => value.ToLower() == "true" || value.ToLower() == "false";
        //     static bool IsValidOption(string value) => value.ToLower() == "-p" || value.ToLower() == "--path";
        // }
    }
}