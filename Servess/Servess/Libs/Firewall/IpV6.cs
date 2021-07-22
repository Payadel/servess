using System.IO;
using System.Linq;
using FunctionalUtility.Extensions;
using FunctionalUtility.ResultDetails.Errors;
using FunctionalUtility.ResultUtility;
using Servess.Attributes;

namespace Servess.Libs.Firewall {
    public static partial class Firewall {
        [Command("ipv6", "Enable/Disable IP V6")]
        public class IpV6 {
            [Input("path", "p", "Config file path", nameof(Path), false)]
            public string? Path { get; set; }

            [Input("enable", "e",
                "Enable IP V6", nameof(Enable), isRequired: false, hasValue: false)]
            public bool? Enable { get; set; }

            [Input("disable", "d",
                "Disable IP V6", nameof(Disable), isRequired: false, hasValue: false)]
            public bool? Disable { get; set; }

            private const string Separator = "=";
            private const string CommentSign = "#";

            [Operator]
            public MethodResult<string> Operation() {
                const string ipV6Key = "IPV6";
                var path = Path ?? ConfigFilePath;

                switch (Enable) {
                    case null when Disable is null:
                        return MethodResult<string>.Fail(
                            new BadRequestError(message: "Error! at least one of the flags must set."));
                    case not null when Disable is not null:
                        return MethodResult<string>.Fail(
                            new BadRequestError(message: "Error! Can't set both disable and enable flags."));
                }

                if (!File.Exists(path)) {
                    return MethodResult<string>.Fail(new NotFoundError(title: "File Not Found",
                        message: $"Can't find {path}"));
                }

                return TryExtensions.Try(() => {
                    var lines = File.ReadAllLines(path).ToList();
                    using var fileStream = new FileStream(path, FileMode.Open, FileAccess.ReadWrite,
                        FileShare.Read);

                    var methodResult = Utility.AddOrUpdateKeyValue(lines, ipV6Key,
                        Enable is not null ? "yes" : "no", Separator, CommentSign);

                    fileStream.Close();

                    return methodResult.TryOnSuccess(newLines => File.WriteAllLines(path, newLines))
                        .OnSuccess(() => MethodResult<string>.Ok("Done"));
                });
            }
        }
    }
}