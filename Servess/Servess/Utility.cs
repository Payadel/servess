using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using servess.Attributes;

namespace servess {
    public static class Utility {
        public static bool IsHelpOption(string option) {
            option = option.ToLower();
            return option == "-h" || option == "--help" || option == "help";
        }

        public static List<Type> GetScopes(Assembly assembly) =>
            assembly.GetTypes()
                .Where(type => type.IsClass && type.IsPublic && type.GetCustomAttribute<ScopeAttribute>() is not null)
                .ToList();

        public static Type? GetScope(IEnumerable<Type> scopes, string targetScope) {
            targetScope = targetScope.ToLower();
            return scopes.SingleOrDefault(scope =>
                scope.GetCustomAttribute<ScopeAttribute>()!.Name.ToLower() == targetScope);
        }

        public static IEnumerable<MethodInfo> GetCommands(Type scope) => scope
            .GetMethods()
            .Where(method => method.IsPublic && method.GetCustomAttribute<CommandAttribute>() is not null);

        public static MethodInfo? GetCommand(Type scope, string command) {
            command = command.ToLower();
            return GetCommands(scope).SingleOrDefault(method =>
                method.GetCustomAttribute<CommandAttribute>()!.Name.ToLower() == command);
        }

        public static int FindLineIndex(IEnumerable<string> lines, string key) {
            var list = lines.ToList();
            key = key.ToLower();
            var lineIndex = list.TakeWhile(line => !line.ToLower().StartsWith($"{key} ")).Count();
            return lineIndex >= list.Count ? -1 : lineIndex;
        }

        public static string GenerateKeyValue(string key, string value) =>
            $"{key} {value}";
    }
}