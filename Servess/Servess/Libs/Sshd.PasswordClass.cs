using System;
using System.IO;
using System.Linq;
using FunctionalUtility.Extensions;
using FunctionalUtility.ResultDetails.Errors;
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
                "Enable password", nameof(EnablePassword), isRequired: false, hasValue: false)]
            public bool? EnablePassword { get; set; }

            private const string Separator = " ";
            private const string CommentSign = "#";

            [Operator]
            public MethodResult<string> Operation() {
                switch (DisablePassword) {
                    case null when EnablePassword is null:
                        return MethodResult<string>.Fail(
                            new BadRequestError(message: "Error! at least one of the flags must set."));
                    case not null when EnablePassword is not null:
                        return MethodResult<string>.Fail(
                            new BadRequestError(message: "Error! Can't set both disable and enable flags."));
                }

                const string permitRootLogin = "PermitRootLogin";
                var path = Path ?? ConfigFilePath;

                if (!File.Exists(path)) {
                    return MethodResult<string>.Fail(new NotFoundError(title: "File Not Found",
                        message: $"Can't find {path}"));
                }

                return TryExtensions.Try(() => {
                    var lines = File.ReadAllLines(path).ToList();
                    using var fileStream = new FileStream(path, FileMode.Open, FileAccess.ReadWrite,
                        FileShare.Read);

                    var methodResult = Utility.AddOrUpdateKeyValue(lines, permitRootLogin,
                        DisablePassword is not null ? "without-password" : "yes", Separator, CommentSign);

                    fileStream.Close();

                    return methodResult.TryOnSuccess(newLines => File.WriteAllLines(path, newLines))
                        .OnSuccess(() => MethodResult<string>.Ok("Done"));
                });
            }
        }
    }
}