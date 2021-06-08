using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using servess.Attributes;

namespace servess {
    public static class Program {
        public static void Main(string[] args) {
            try {
                InnerMain(args);
            }
            catch (Exception e) {
                Console.WriteLine("\nAn exception has occured.\n");
                Console.WriteLine(e);
            }
        }

        private static void InnerMain(string[] args) {
            var scopes = Utility.GetScopes(Assembly.GetExecutingAssembly());

            switch (args.Length) {
                case 0:
                case 1:
                    //servess -h
                    //servess --help
                    ShowHelp(scopes);
                    break;
                default:
                    //AppName scope command [options]
                    Execute(args, scopes);
                    break;
            }
        }

        private static void Execute(IReadOnlyList<string> args, IReadOnlyCollection<Type> scopes) {
            //Get SCOPE
            var targetScope = Utility.GetScope(scopes, args[0]);
            if (targetScope is null) {
                Console.WriteLine("SCOPE not found.");
                ShowHelp(scopes);
                return;
            }

            //Help?
            if (Utility.IsHelpOption(args[1])) {
                var commands = Utility.GetCommands(targetScope).ToList();
                Console.WriteLine();
                Console.WriteLine($" Usage:  {AppConstants.AppName} {args[0]} COMMAND [OPTIONS]");
                Console.WriteLine();
                Console.WriteLine(" Commands:");
                foreach (var attribute in commands.Select(command => command.GetCustomAttribute<CommandAttribute>())) {
                    Console.WriteLine($"\t{attribute!.Name}\t{attribute!.Description}");
                }

                Console.WriteLine();
                Console.WriteLine($"Run {AppConstants.AppName} SCOPE COMMAND --help for more information.");
                return;
            }

            //Get COMMAND
            var targetCommand = Utility.GetCommand(targetScope, args[1]);
            if (targetCommand is null) {
                Console.WriteLine("COMMAND not found.");
                ShowHelp(scopes);
                return;
            }

            //Invoke
            var result = targetCommand.Invoke(null, new object[] {args.Skip(2).ToArray()});
            if (result is not null) {
                Console.WriteLine(result);
            }
        }

        private static void ShowHelp(IEnumerable<Type> scopes) {
            Console.WriteLine();
            Console.WriteLine($" Usage:  {AppConstants.AppName} SCOPE COMMAND [OPTIONS]");
            Console.WriteLine();
            Console.WriteLine(" Scopes:");
            foreach (var scopeAttribute in scopes.Select(scope=> scope.GetCustomAttribute<ScopeAttribute>())) {
                Console.WriteLine($"\t{scopeAttribute!.Name}\t{scopeAttribute!.Description}");
            }

            Console.WriteLine();
            Console.WriteLine($"Run {AppConstants.AppName} SCOPE --help for more information.");
        }
    }
}