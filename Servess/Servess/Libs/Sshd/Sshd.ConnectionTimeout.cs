using System.Collections.Generic;
using System.IO;
using System.Linq;
using FunctionalUtility.Extensions;
using FunctionalUtility.ResultDetails.Errors;
using FunctionalUtility.ResultUtility;
using Servess.Attributes;

//TODO: Show values

namespace Servess.Libs.Sshd {
    public static partial class Sshd {
        [Command("connection-timeout", "SSH connection timeout")]
        public class ConnectionTimeoutClass {
            [Input("path", "p", "SSHD file path", nameof(Path), false)]
            public string? Path { get; set; }

            [Input("interval", "i",
                "Client Alive Interval", nameof(ClientAliveInterval), isRequired: false)]
            public int? ClientAliveInterval { get; set; }

            [Input("count-max", "c",
                "Client Alive Count Max", nameof(ClientAliveCountMax), isRequired: false)]
            public int? ClientAliveCountMax { get; set; }

            private const string Separator = " ";
            private const string CommentSign = "#";

            [Operator]
            public MethodResult<string> Operation() {
                const string clientAliveIntervalKey = "ClientAliveInterval";
                const string clientAliveCountMaxKey = "ClientAliveCountMax";
                var path = Path ?? ConfigFilePath;

                if (!File.Exists(path)) {
                    return MethodResult<string>.Fail(new NotFoundError(title: "File Not Found",
                        message: $"Can't find {path}"));
                }

                return TryExtensions.Try(() => {
                    var lines = File.ReadAllLines(path).ToList();
                    using var fileStream = new FileStream(path, FileMode.Open, FileAccess.ReadWrite,
                        FileShare.Read);

                    MethodResult<List<string>>.Ok(null!)
                        .OperateWhen(ClientAliveInterval is not null, () =>
                            Utility.AddOrUpdateKeyValue(lines, clientAliveIntervalKey,
                                    ClientAliveInterval.ToString()!, " ", "#")
                                .OnSuccess(newLines => lines = newLines))
                        .OnSuccessOperateWhen(ClientAliveCountMax is not null, () => Utility.AddOrUpdateKeyValue(lines,
                                clientAliveCountMaxKey,
                                ClientAliveCountMax.ToString()!, Separator, CommentSign)
                            .OnSuccess(newLines => lines = newLines));

                    fileStream.Close();
                    File.WriteAllLines(path, lines);
                    return MethodResult<string>.Ok("Done");
                });
            }
        }
    }
}