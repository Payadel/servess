using System.IO;
using System.Linq;
using FunctionalUtility.Extensions;
using FunctionalUtility.ResultDetails.Errors;
using FunctionalUtility.ResultUtility;
using Servess.Attributes;

namespace Servess.Libs.Sshd {
    public static partial class Sshd {
        [Command("port", "Change ssh port")]
        public class PortClass {
            [Input("path", "p", "SSHD file path", nameof(Path), false)]
            public string? Path { get; set; }

            [Input("port", "p",
                "Port Number", nameof(Port), isRequired: true, hasValue: true)]
            public int Port { get; set; }

            private const string Separator = " ";
            private const string CommentSign = "#";
            private const string PortKey = "Port";

            [Operator]
            public MethodResult<string> Operation() {
                var path = Path ?? ConfigFilePath;

                if (!File.Exists(path)) {
                    return MethodResult<string>.Fail(new NotFoundError(title: "File Not Found",
                        message: $"Can't find {path}"));
                }

                return TryExtensions.Try(() => {
                    var lines = File.ReadAllLines(path).ToList();
                    using var fileStream = new FileStream(path, FileMode.Open, FileAccess.ReadWrite,
                        FileShare.Read);

                    var checkPortResult = Utility.ExecuteBashCommand($"sudo lsof -i:{Port}");
                    if (!string.IsNullOrEmpty(checkPortResult)) {
                        return MethodResult<string>.Fail(
                            new BadRequestError(message: $"Port is not free.\n{checkPortResult}"));
                    }

                    var methodResult =
                        Utility.AddOrUpdateKeyValue(lines, PortKey, Port.ToString(), Separator, CommentSign);

                    fileStream.Close();

                    return methodResult.TryOnSuccess(newLines => File.WriteAllLines(path, newLines))
                        .OnSuccess(() => MethodResult<string>.Ok("Done"));
                });
            }
        }
    }
}