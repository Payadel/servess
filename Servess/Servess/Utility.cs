using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Diagnostics;
using System.Linq;
using System.Reflection;
using System.Text;
using FunctionalUtility.Extensions;
using FunctionalUtility.ResultDetails.Errors;
using FunctionalUtility.ResultUtility;
using ModelsValidation;
using Servess.Attributes;
using Servess.MethodErrors;
using Servess.Models;

//TODO: Separate?

namespace Servess {
    public static class Utility {
        public static bool IsHelpFlag(string option) {
            if (string.IsNullOrEmpty(option))
                return false;

            option = option.ToLower();
            return option == "-h" || option == "--help" || option == "help";
        }

        public static MethodResult<List<Type>> GetScopes([Required] Assembly assembly) =>
            Method.MethodParametersMustValid(new[] {assembly})
                .TryOnSuccess(() => assembly.GetTypes()
                    .Where(type =>
                        type.IsClass && type.IsPublic && type.GetCustomAttribute<ScopeAttribute>() is not null)
                    .ToList());

        public static MethodResult<Type> GetScope(IEnumerable<Type> scopes, string targetScope) {
            var scopeList = scopes.ToList();
            if (scopeList.IsNullOrEmpty() || targetScope.IsNullOrEmpty()) {
                return MethodResult<Type>.Fail(new ScopeNotFoundError(message: ScopesHelp(scopeList)));
            }

            targetScope = targetScope.ToLower();
            return TryExtensions.Try(() => scopeList.SingleOrDefault(scope =>
                    scope.GetCustomAttribute<ScopeAttribute>()!.Name.ToLower() == targetScope)
                .Map(result => result is null
                    ? MethodResult<Type>.Fail(new ScopeNotFoundError(message: ScopesHelp(scopeList)))
                    : MethodResult<Type>.Ok(result)));
        }

        public static MethodResult<IEnumerable<Type>> GetCommandClasses([Required] Type scope) =>
            Method.MethodParametersMustValid(new[] {scope})
                .TryOnSuccess(() => scope.GetNestedTypes(BindingFlags.Public)
                    .Where(type =>
                        type.IsClass && type.GetCustomAttribute<CommandAttribute>() is not null));

        public static MethodResult<Type> GetCommandClass(Type scope, string command) {
            command = command.ToLower();
            return GetCommandClasses(scope)
                .TryOnSuccess(commandClasses => commandClasses.SingleOrDefault(commandClass =>
                        commandClass.GetCustomAttribute<CommandAttribute>()!.Name.ToLower() == command)
                    .Map(result => result is null
                        ? ScopeHelp(scope)
                            .OnSuccess(helpStr => MethodResult<Type>.Fail(new CommandNotFoundError(message: helpStr)))
                        : MethodResult<Type>.Ok(result)));
        }

        public static MethodResult<MethodInfo> GetOperatorMethod([Required] Type targetClass) =>
            Method.MethodParametersMustValid(new[] {targetClass})
                .TryOnSuccess(() => targetClass.GetMethods()
                    .Single(method => method.IsPublic && method.GetCustomAttribute<OperatorAttribute>() is not null));

        public static MethodResult<IEnumerable<PropertyInfo>> GetCommandInputs([Required] Type targetClass) =>
            Method.MethodParametersMustValid(new[] {targetClass})
                .TryOnSuccess(() => targetClass.GetProperties()
                    .Where(prop => prop.GetCustomAttribute<InputAttribute>() is not null));

        public static MethodResult<List<string>> AddOrUpdateKeyValue([Required] List<string> lines,
            [Required] string key,
            [Required] string value, string separator,
            [Required] string commentSign) =>
            Method.MethodParametersMustValid(new object?[] {lines, key, value, separator, commentSign})
                .OnSuccess(() => FindLineIndex(lines, key, separator, commentSign))
                .OnSuccess(lineIndex => AddOrUpdateKeyValue(lines, key, value, separator, commentSign, lineIndex));

        public static MethodResult<List<string>> AddOrUpdateKeyValue([Required] List<string> lines,
            [Required] string key,
            string value, string separator,
            [Required] string commentSign, int targetLineIndex) =>
            Method.MethodParametersMustValid(new object?[] {lines, key, value, separator, commentSign, targetLineIndex})
                .TryOnSuccess(() => GenerateKeyValue(key, value, separator)
                    .Map(result => {
                        if (targetLineIndex < 0) {
                            lines.Add("");
                            lines.Add(result);
                        }
                        else {
                            lines[targetLineIndex] = result;
                        }

                        return MethodResult<List<string>>.Ok(lines);
                    }));

        public static MethodResult<bool> IsFlag(string input) =>
            TryExtensions.Try(() => input.StartsWith('-') || input.StartsWith("--"))
                .OnFail(() => MethodResult<bool>.Ok(false));

        public static MethodResult<int> FindLineIndex([Required] IReadOnlyCollection<string> lines,
            string key, string separator, string commentSign) =>
            TryExtensions.Try(() => {
                key = key.ToLower();
                var keyWithSeparator = $"{key}{separator}";

                //TODO: What happen if we have multi comment signs?
                var commentSignWithSpace = $"{commentSign}{separator}";
                var selectedLines = new List<(string line, int index, bool isComment)>();
                for (var i = 0; i < lines.Count; i++) {
                    if (!lines.ElementAt(i).ToLower().Contains(keyWithSeparator)) continue;
                    var line = RemoveExtraSpaces(lines.ElementAt(i));
                    var isComment = line.StartsWith(commentSign) || line.StartsWith(commentSignWithSpace);
                    selectedLines.Add((line, i, isComment));
                }

                switch (selectedLines.Count) {
                    case 0:
                        return MethodResult<int>.Ok(-1);
                    case 1:
                        return MethodResult<int>.Ok(selectedLines.First().index);
                    default:
                        var unCommentedResults =
                            selectedLines.Where(selectedLineDetail => !selectedLineDetail.isComment).ToList();

                        return unCommentedResults.Count switch {
                            0 => MethodResult<int>.Ok(selectedLines.First(selectedLineDetail =>
                                    selectedLineDetail.isComment)
                                .index),
                            1 => MethodResult<int>.Ok(unCommentedResults.First().index),
                            _ => MethodResult<int>.Fail(new TooManyKeysFoundError(unCommentedResults.Select(item =>
                                new KeyValuePair<string, string>($"line {item.index}", "Key detected!"))))
                        };
                }
            });

        public static MethodResult<string> GetValue(string input, string key, string separator, string commentSign) =>
            MethodResult<string>.Ok("")
                .OnSuccess(() => RemoveExtraSpaces(input))
                .OnSuccessOperateWhen(result => result.StartsWith(commentSign), result => {
                    var keyIndex = result.IndexOf(key, StringComparison.Ordinal);
                    return MethodResult<string>.Ok(result.Remove(0, keyIndex));
                })
                .OnSuccessFailWhen(result => !result.StartsWith($"{key}{separator}"),
                    new BadRequestError(title: "Key Value Detection Error", message: $"Can't detect key in {input}"))
                .OnSuccess(result => result.Length > 0 ? input.Remove(0, (key + separator).Length) : "");

        private static string GenerateKeyValue(string key, string value, string separator = " ") =>
            $"{key}{separator}{value}";

        /// <summary>
        /// Remove all extra spaces and tabs between words in the specified string!
        /// </summary>
        /// <param name="str">The specified string.</param>
        /// TODD: Test
        private static string RemoveExtraSpaces(string str) {
            str = str.Trim();
            StringBuilder sb = new StringBuilder();

            var space = false;
            foreach (var c in str) {
                if (char.IsWhiteSpace(c) || c == (char) 9) {
                    space = true;
                }
                else {
                    if (space) {
                        sb.Append(' ');
                    }

                    sb.Append(c);
                    space = false;
                }
            }

            return sb.ToString();
        }

        public static string ScopesHelp(IEnumerable<Type> scopes) {
            var sb = new StringBuilder();
            sb.AppendLine()
                .AppendLine($" Usage:  {AppConstants.AppName} SCOPE COMMAND [INPUTS]")
                .AppendLine()
                .AppendLine(" Scopes:");

            foreach (var scopeAttribute in scopes.Select(scope => scope.GetCustomAttribute<ScopeAttribute>())) {
                sb.AppendLine($"\t{scopeAttribute!.Name}\t{scopeAttribute!.Description}");
            }

            sb.AppendLine()
                .AppendLine($"Run {AppConstants.AppName} SCOPE --help for more information.");
            return sb.ToString();
        }

        public static MethodResult<string> ScopeHelp(Type targetScope) =>
            GetCommandClasses(targetScope)
                .OnSuccess(commands => {
                    var sb = new StringBuilder();
                    sb.AppendLine()
                        .AppendLine($" Usage:  {AppConstants.AppName} {targetScope.Name.ToLower()} COMMAND [INPUTS]")
                        .AppendLine()
                        .AppendLine(" Commands:");

                    foreach (var attribute in commands.Select(command => command.GetCustomAttribute<CommandAttribute>())
                    ) {
                        sb.AppendLine($"\t{attribute!.Name}\t{attribute!.Description}");
                    }

                    sb.AppendLine()
                        .AppendLine($"Run {AppConstants.AppName} SCOPE COMMAND --help for more information.");

                    return MethodResult<string>.Ok(sb.ToString());
                });

        public static MethodResult<string> CommandHelp(string scopeName, string commandName,
            IEnumerable<InputSchemeModel> inputSchemes) =>
            TryExtensions.Try(() => {
                var sb = new StringBuilder();
                sb.AppendLine()
                    .AppendLine($" Usage:  {AppConstants.AppName} {scopeName} {commandName} [INPUTS]")
                    .AppendLine()
                    .AppendLine(" Inputs:");

                foreach (var inputAttribute in inputSchemes.Select(inputScheme => inputScheme.InputAttribute)
                ) {
                    var isRequired = inputAttribute.IsRequired ? "required" : "optional";
                    var hasValue = inputAttribute.HasValue ? "key-value" : "flag only";
                    sb.AppendLine(
                        $"\t{GetShortParameterName(inputAttribute.ShortName)}  {GetLongParameterName(inputAttribute.CliName)}\t{inputAttribute.Description}\t{isRequired}\t{hasValue}");
                }

                return MethodResult<string>.Ok(sb.ToString());
            });

        public static string GetLongParameterName(string pureName) => "--" + pureName;
        public static string GetShortParameterName(string pureName) => "-" + pureName;
        public static bool IsLongParameterName(string name) => name.StartsWith("--");

        public static MethodResult<string> GetNameFromFlag(string flag) =>
            TryExtensions.Try(() => flag.StartsWith("--")
                ? flag.Remove(0, 2) // --name
                : flag.Remove(0, 1)); // -name

        public static bool IsNullable(Type type) => Nullable.GetUnderlyingType(type) != null;

        public static bool HaveDuplicateItems<T>(List<T>? list1, List<T>? list2) {
            if (list1 is null || list2 is null) return false;

            var uniqueItems = list1.Except(list2).Count();
            return uniqueItems != list1.Count;
        }

        public static string CombineList<T>(IEnumerable<T> list, string separator) {
            var sb = new StringBuilder();
            foreach (var item in list) {
                sb.Append(item).Append(separator);
            }

            if (sb.Length > 0) {
                sb.Remove(sb.Length - 1, 1);
            }

            return sb.ToString();
        }

        public static string ExecuteBashCommand(string command) {
            // according to: https://stackoverflow.com/a/15262019/637142
            // thans to this we will pass everything as one command
            command = command.Replace("\"", "\"\"");

            var proc = new Process {
                StartInfo = new ProcessStartInfo {
                    FileName = "/bin/bash",
                    Arguments = "-c \"" + command + "\"",
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    CreateNoWindow = true
                }
            };

            proc.Start();
            proc.WaitForExit();

            return proc.StandardOutput.ReadToEnd();
        }
    }
}