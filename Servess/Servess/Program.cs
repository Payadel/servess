using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using FunctionalUtility.Extensions;
using FunctionalUtility.ResultDetails.Errors;
using FunctionalUtility.ResultUtility;
using ModelsValidation.ResultDetails;
using Servess.Attributes;
using Servess.Models;

//TODO: Reorder methods

namespace Servess {
    public static class Program {
        public static void Main(string[] args) {
            try {
                InnerMain(args)
                    .OnSuccessOperateWhen(result => result is not null,
                        result => {
                            Console.WriteLine(result);
                            return MethodResult<string?>.Ok(result);
                        })
                    .OnFail(methodResult => {
                        Console.WriteLine(methodResult.Detail.Title);
                        switch (methodResult.Detail) {
                            case ArgumentValidationError validationError: {
                                foreach (var (key, value) in validationError.ModelErrors) {
                                    Console.WriteLine($"{key}: {value}");
                                }

                                break;
                            }
                            case ExceptionError exceptionError:
                                Console.WriteLine(exceptionError.Message);
                                Console.WriteLine();
                                Console.WriteLine(exceptionError.StackTrace);
                                break;
                            case NotFoundError:
                            case BadRequestError:
                            default:
                                Console.WriteLine(methodResult.Detail.Message);
                                break;
                        }
                    });
            }
            catch (Exception e) {
                Console.WriteLine("\nAn exception has occured.\n");
                Console.WriteLine(e);
            }
        }

        private static MethodResult<string?> InnerMain(IReadOnlyList<string> args) =>
            Utility.GetScopes(Assembly.GetExecutingAssembly())
                .OnSuccess(scopes => {
                    switch (args.Count) {
                        case 0:
                        case 1:
                            //servess
                            //servess -h
                            //servess --help
                            ShowScopesHelp(scopes);
                            return MethodResult<string?>.Ok(null);
                        default:
                            //AppName scope command [inputs]
                            return Execute(args, scopes);
                    }
                });

        private static void ShowScopesHelp(IEnumerable<Type> scopes) =>
            Console.WriteLine(Utility.ScopesHelp(scopes));

        private static MethodResult ShowCommandHelp(string scopeName, string commandName,
            IEnumerable<InputSchemeModel> inputSchemes) =>
            Utility.CommandHelp(scopeName, commandName, inputSchemes)
                .OnSuccess(result => Console.WriteLine(result));

        private static MethodResult<string?> Execute(IReadOnlyList<string> args, IEnumerable<Type> scopes) {
            //servess SCOPE COMMAND ...inputs...
            //Get SCOPE
            var targetScopeMethodResult = Utility.GetScope(scopes, args[0]);
            if (!targetScopeMethodResult.IsSuccess) {
                return MethodResult<string?>.Fail(targetScopeMethodResult.Detail);
            }

            var scopeClassType = targetScopeMethodResult.Value;
            //=====================================================================================

            //Need Help about SCOPE?
            if (Utility.IsHelpFlag(args[1])) {
                //servess SCOPE -h || servess SCOPE --help
                return ShowScopeHelp(scopeClassType).MapMethodResult((string?) null);
            }
            //=====================================================================================

            //Get COMMAND
            var commandClassMethodResult =
                Utility.GetCommandClass(scopeClassType, args[1]); //servess SCOPE COMMAND ...inputs...
            if (!commandClassMethodResult.IsSuccess) {
                return MethodResult<string?>.Fail(commandClassMethodResult.Detail);
            }

            var commandClassType = commandClassMethodResult.Value;
            //=====================================================================================

            //Get Inputs schemes like property info and InputAttribute
            var inputSchemesMethodResult = GetInputSchemes(commandClassType);
            if (!inputSchemesMethodResult.IsSuccess) {
                return MethodResult<string?>.Fail(inputSchemesMethodResult.Detail);
            }

            var inputSchemes = inputSchemesMethodResult.Value;
            //=====================================================================================

            //TODO: We can use https://github.com/khalidabuhakmeh/ConsoleTables
            //Need Help about COMMAND?
            if (args.Count < 3 || Utility.IsHelpFlag(args[2])) {
                //servess SCOPE COMMAND -h || servess SCOPE COMMAND --help
                return ShowCommandHelp(args[0], args[1], inputSchemes).MapMethodResult((string?) null);
            }
            //=====================================================================================

            //Get operator method for invoking
            var operatorMethodResult = Utility.GetOperatorMethod(commandClassType);
            if (!operatorMethodResult.IsSuccess) {
                return MethodResult<string?>.Fail(operatorMethodResult.Detail);
            }

            var operatorMethod = operatorMethodResult.Value;
            //=====================================================================================

            //Parse arguments
            var inputsMethodResult = ParsingInputs.Parse(args.Skip(2).ToList(), inputSchemes);
            if (!inputsMethodResult.IsSuccess) {
                return MethodResult<string?>.Fail(inputsMethodResult.Detail);
            }

            var inputList = inputsMethodResult.Value;
            //=====================================================================================

            //Invoke
            return InvokeOperatorMethod(commandClassType, inputList, operatorMethod);
        }

        private static MethodResult<string?> InvokeOperatorMethod(Type commandClassType,
            IReadOnlyCollection<InputModel> inputModels, MethodBase operatorMethod) =>
            TryExtensions.Try(() => Activator.CreateInstance(commandClassType))
                .OnSuccess(commandObj => UpdateCommandClassProperties(inputModels, commandObj!)
                    .TryOnSuccess(() => operatorMethod.Invoke(commandObj, null))
                    .OnSuccess(invokeResult => {
                        return invokeResult switch {
                            MethodResult<string?> methodResultWithString => methodResultWithString,
                            MethodResult simpleMethodResult => simpleMethodResult.MapMethodResult((string?) null),
                            _ => MethodResult<string?>.Ok(null)
                        };
                    }));

        private static MethodResult UpdateCommandClassProperties(
            IEnumerable<InputModel> inputModels, object commandObj) =>
            inputModels.ForEachUntilIsSuccess(inputModel => TryExtensions.Try(() =>
                commandObj.GetType().GetProperty(inputModel.ParameterName)!.SetValue(commandObj, inputModel.Value)));

        private static MethodResult<List<InputSchemeModel>> GetInputSchemes(
            Type commandClass) =>
            Utility.GetCommandInputs(commandClass)
                .OnSuccess(commandInputs => commandInputs
                    .Select(commandInput =>
                        new InputSchemeModel(commandInput,
                            commandInput.GetCustomAttribute<InputAttribute>()!)).ToList());

        private static MethodResult ShowScopeHelp(Type targetScope) =>
            Utility.ScopeHelp(targetScope)
                .OnSuccess(helpStr => Console.WriteLine(helpStr));

        //TODO: Move private methods?
    }
}