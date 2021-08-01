using System;
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

            [Input("port", "po",
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

                    var currentPortMethodResult = Utility.FindLineIndex(lines, PortKey, Separator, CommentSign)
                        .OnSuccessFailWhen(index => index < 0, new InternalError(message: "Can not find current port!"))
                        .OnSuccess(index => Utility.GetValue(lines[index], PortKey, Separator, CommentSign))
                        .TryOnSuccess(Convert.ToInt32);
                    if (!currentPortMethodResult.IsSuccess) {
                        return MethodResult<string>.Fail(currentPortMethodResult.Detail);
                    }

                    var currentPort = currentPortMethodResult.Value;
                    if (currentPort == Port) {
                        return MethodResult<string>.Ok($"Duplicate port. No change. ({currentPort})");
                    }

                    Console.WriteLine($"Current port: {currentPort}");

                    var checkPortResult = Utility.ExecuteBashCommand($"sudo lsof -i:{Port}");
                    if (!string.IsNullOrEmpty(checkPortResult)) {
                        return MethodResult<string>.Fail(
                            new BadRequestError(message: $"Port is not free.\n{checkPortResult}"));
                    }

                    return Utility.AddOrUpdateKeyValue(lines, PortKey, Port.ToString(), Separator, CommentSign)
                        .OnSuccess(newLines => FirewallUtility.AllowPort(Port)
                            .TryOnSuccess(() => File.WriteAllLines(path, newLines))
                            .OnSuccess(() => MethodResult<string>.Ok("Done")));
                });
            }
        }
    }
}