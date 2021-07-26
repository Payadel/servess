using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using FunctionalUtility.Extensions;
using FunctionalUtility.ResultDetails.Errors;
using FunctionalUtility.ResultUtility;
using Servess.Attributes;

namespace Servess.Libs.Sshd {
    public static partial class Sshd {
        [Command("password", "Enable/Disable users login password")]
        public class Password {
            [Input("path", "p", "SSHD file path", nameof(Path), false)]
            public string Path { get; set; } = ConfigFilePath;

            [Input("disabled-list", "dl",
                "Show users can't use login password", nameof(DisabledList), isRequired: false, hasValue: false)]
            public bool? DisabledList { get; set; }

            [Input("disable-password", "dp",
                "Disable user passwords", nameof(DisableUserPassword), isRequired: false)]
            public string? DisableUserPassword { get; set; }

            [Input("enable-password", "ep",
                "Enable user passwords", nameof(EnableUserPassword), isRequired: false)]
            public string? EnableUserPassword { get; set; }

            [Input("separator", "s",
                "Separator char that separates names in input", nameof(NameSeparator), isRequired: false)]
            public char NameSeparator { get; set; } = ' ';

            // private const string CommentSign = "#";
            private const string DisablePasswordGroupName = "disabled-password";

            [Operator]
            public MethodResult<string> Operation() {
                var path = Path;

                var targetDisablePasswords = DisableUserPassword?.ToLower().Split(NameSeparator).Distinct().ToList();
                var targetEnablePasswords = EnableUserPassword?.ToLower().Split(NameSeparator).Distinct().ToList();
                if (Utility.HaveDuplicateItems(targetDisablePasswords, targetEnablePasswords)) {
                    return MethodResult<string>.Fail(
                        new BadRequestError(message: "Enable and Disable list have duplicate items."));
                }

                if (DisabledList is null && targetDisablePasswords.IsNullOrEmpty() &&
                    targetEnablePasswords.IsNullOrEmpty()) {
                    return MethodResult<string>.Ok("Done");
                }

                if (!File.Exists(path)) {
                    return MethodResult<string>.Fail(new NotFoundError(title: "File Not Found",
                        message: $"Can't find {path}"));
                }

                if (!targetDisablePasswords.IsNullOrEmpty() || !targetEnablePasswords.IsNullOrEmpty()) {
                    EnsureGroupIsExist();
                    EnsureQueryIsExist();
                }

                var currentDisabledUsers = GetDisableUsers();
                if (!targetDisablePasswords.IsNullOrEmpty()) {
                    foreach (var user in targetDisablePasswords!.Where(user => !currentDisabledUsers.Contains(user))) {
                        DisablePassword(user);
                    }
                }

                if (!targetEnablePasswords.IsNullOrEmpty()) {

                    Console.WriteLine("currentDisabledUsers:");
                    foreach (var a in currentDisabledUsers) {
                        Console.WriteLine(a);
                    }
                    
                    Console.WriteLine("targetEnablePasswords:");
                    foreach (var a in targetEnablePasswords ?? new List<string>()) {
                        Console.WriteLine(a);
                    }
                    
                    foreach (var user in currentDisabledUsers.Where(user => targetEnablePasswords!.Contains(user))) {
                        EnablePassword(user);
                    }
                }

                if (DisabledList is not null) {
                    Console.Write("Users whose passwords are disabled: ");
                    foreach (var user in GetDisableUsers()) {
                        Console.Write($"{user} ");
                    }

                    Console.WriteLine();
                }

                return MethodResult<string>.Ok("Done");
            }

            private static void EnsureGroupIsExist() {
                var isGroupExist = !string.IsNullOrEmpty(
                    Utility.ExecuteBashCommand($"cat /etc/group | grep \"{DisablePasswordGroupName}\""));
                if (isGroupExist) {
                    return;
                }

                Utility.ExecuteBashCommand($"groupadd \"{DisablePasswordGroupName}\"");
            }

            private void EnsureQueryIsExist() {
                var isQueryExist = !string.IsNullOrEmpty(
                    Utility.ExecuteBashCommand($"cat {Path} | grep \"Match Group {DisablePasswordGroupName}\""));
                if (isQueryExist) return;

                var sb = new StringBuilder();
                sb.Append(File.ReadAllText(Path))
                    .AppendLine()
                    .AppendLine($"Match Group {DisablePasswordGroupName}")
                    .AppendLine("    PasswordAuthentication no");
                File.WriteAllText(Path, sb.ToString());
            }

            private static void DisablePassword(string user) {
                //Add user to group
                Console.Write($"Adds {user} to {DisablePasswordGroupName}... ");
                Utility.ExecuteBashCommand($"sudo usermod -aG {DisablePasswordGroupName} \"{user}\"");
                Console.WriteLine("Done");
            }

            private static void EnablePassword(string user) {
                //Remove user from group
                Console.Write($"Removes {user} from {DisablePasswordGroupName}... ");
                Utility.ExecuteBashCommand($"gpasswd -d \"{user}\" {DisablePasswordGroupName}");
                Console.WriteLine("Done");
            }

            private static List<string> GetDisableUsers() {
                var group = Utility.ExecuteBashCommand($"cat /etc/group | grep {DisablePasswordGroupName}");
                if (string.IsNullOrEmpty(group)) {
                    return new List<string>();
                }

                return group.Split(":")[3]
                    .Split(",")
                    .ToList();
            }
        }
    }
}