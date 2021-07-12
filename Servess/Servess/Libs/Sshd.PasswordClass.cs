using System;
using FunctionalUtility.ResultUtility;
using servess.Attributes;

namespace servess.Libs {
    public static partial class Sshd {
        [Command("password", "disable/enable login with password")]
        public class PasswordClass {
            [Input("path", "p", "SSHD file path", nameof(Path), false)]
            public string? Path { get; set; }

            [Input("disable", "d",
                "Disable password", nameof(DisablePassword), isRequired: false, hasValue: false)]
            public bool DisablePassword { get; set; }

            [Input("enable", "e",
                "Enable password", nameof(EnablePassword), isRequired: false, hasValue: false)]
            public bool EnablePassword { get; set; }

            //TODO: Test non-value property

            [Operator]
            public void Operation() {
                //TODO: ****
                Console.WriteLine($"path: {Path}");
                Console.WriteLine($"DisablePassword: {DisablePassword}");
                Console.WriteLine($"EnablePassword: {EnablePassword}");
                if (DisablePassword && EnablePassword) {
                    Console.WriteLine("Error! Can't set both disable and enable flag.");
                }
            }
        }
    }
}