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
            public bool? DisablePassword { get; set; }

            [Input("enable", "e",
                "Enable password", nameof(EnablePassword), isRequired: true, hasValue: true)]
            public bool? EnablePassword { get; set; }

            //TODO: Test non-value property

            [Operator]
            public void Operation() {
                if (DisablePassword is null && EnablePassword is null) {
                    Console.WriteLine("Error! at least one flag must set.");
                    return;
                }

                if (DisablePassword is not null && EnablePassword is not null) {
                    Console.WriteLine("Error! Can't set both disable and enable flag.");
                    return;
                }

                //TODO: ****
                Print(Path, nameof(Path));
                Print(DisablePassword, nameof(DisablePassword));
                Print(EnablePassword, nameof(EnablePassword));

                static void Print(object? value, string name) {
                    Console.Write($"{name}: ");
                    var valueDisplay = value ?? "NULL";
                    Console.WriteLine(valueDisplay);
                }
            }
        }
    }
}