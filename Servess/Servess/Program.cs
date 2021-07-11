using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using FunctionalUtility.Extensions;
using FunctionalUtility.ResultDetails.Errors;
using FunctionalUtility.ResultUtility;
using ModelsValidation.ResultDetails;
using servess.Attributes;
using servess.MethodErrors;
using servess.Models;

namespace servess {
    public static class Program {
        public static void Main(string[] args) {
            try {
                InnerMain(args)
                    .OnSuccessOperateWhen(result => result is not null, result => {
                        Console.WriteLine(result);
                        return MethodResult<object?>.Ok(null);
                    })
                    .OnFail(methodResult => {
                        Console.WriteLine(methodResult.Detail.Title);
                        switch (methodResult.Detail) {
                            case CommandNotFoundError _:
                            case ScopeNotFoundError _:
                                Console.WriteLine(methodResult.Detail.Message);
                                break;
                            case MissInputError _:
                            case TypeMissMachError _: {
                                var error = (methodResult.Detail as ArgumentValidationError)!;
                                foreach (var (key, value) in error.ModelErrors) {
                                    Console.WriteLine($"{key}: {value}");
                                }
                                break;
                            }

                            default:
                                //TODO: Check and complete
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

        private static MethodResult<object?> InnerMain(IReadOnlyList<string> args) =>
            Utility.GetScopes(Assembly.GetExecutingAssembly())
                .OnSuccess(scopes => {
                    switch (args.Count) {
                        case 0:
                        case 1:
                            //servess
                            //servess -h
                            //servess --help
                            ShowScopesHelp(scopes);
                            return MethodResult<object?>.Ok(null);
                        default:
                            //AppName scope command [options]
                            return Execute(args, scopes);
                    }
                });

        private static void ShowScopesHelp(IEnumerable<Type> scopes) =>
            Console.WriteLine(Utility.ScopesHelp(scopes));

        private static MethodResult<object?> Execute(IReadOnlyList<string> args, IReadOnlyCollection<Type> scopes) {
            var targetScopeMethodResult = Utility.GetScope(scopes, args[0]);
            if (!targetScopeMethodResult.IsSuccess) {
                return MethodResult<object?>.Fail(targetScopeMethodResult.Detail);
            }

            var targetScope = targetScopeMethodResult.Value;

            if (Utility.IsHelpFlag(args[1])) {
                //servess SCOPE -h || servess SCOPE --help
                return ShowScopeCommandsHelp(targetScope).MapMethodResult((object?) null);
            }

            var commandClassMethodResult =
                Utility.GetCommandClass(targetScope, args[1]); //servess SCOPE COMMAND ...inputs...
            if (!commandClassMethodResult.IsSuccess) {
                return MethodResult<object?>.Fail(commandClassMethodResult.Detail);
            }

            var commandClass = commandClassMethodResult.Value;

            var commandAttributesMethodResult = GetCommandAttributes(commandClass);
            if (!commandAttributesMethodResult.IsSuccess) {
                return MethodResult<object?>.Fail(commandAttributesMethodResult.Detail);
            }

            var commandAttributes = commandAttributesMethodResult.Value;

            var operatorMethodResult = Utility.GetOperatorMethod(commandClass);
            if (!operatorMethodResult.IsSuccess) {
                return MethodResult<object?>.Fail(operatorMethodResult.Detail);
            }

            var operatorMethod = operatorMethodResult.Value;

            var inputsMethodResult = ParseInputs(args.Skip(1).ToList())
                .OnSuccess(inputs => PairWithCommandAttributes(inputs, commandAttributes)
                    .OnSuccess(inputList => EnsureRequireFlagsExist(inputList, commandAttributes)
                        .OnSuccess(() => SortInputsBaseOperatorMethod(inputList, operatorMethod))));
            if (!inputsMethodResult.IsSuccess) {
                return MethodResult<object?>.Fail(inputsMethodResult.Detail);
            }

            var sortInputs = inputsMethodResult.Value.Select(input => input is null ? input : input.Value);

            return TryExtensions.Try(() => operatorMethod.Invoke(null, new object[] {sortInputs}));
        }

        private static MethodResult<List<InputModel?>> SortInputsBaseOperatorMethod(List<InputModel> inputList,
            MethodBase operatorMethod) => TryExtensions.Try(() => {
            var methodParameters = operatorMethod.GetParameters();
            return methodParameters
                .Select(parameter => inputList.SingleOrDefault(input => input.ParameterName == parameter.Name))
                .ToList();
        });

        private static MethodResult EnsureRequireFlagsExist(IEnumerable<InputModel> inputModels,
            IEnumerable<KeyValuePair<PropertyInfo, InputAttribute>> commandAttributes) {
            var missInputs = commandAttributes.Where(commandAttribute =>
                    commandAttribute.Value.IsRequired &&
                    inputModels.All(input => input.ParameterName != commandAttribute.Value.Name))
                .Select(commandAttribute => commandAttribute.Value).ToList();
            if (!missInputs.Any()) {
                return MethodResult.Ok();
            }

            return MethodResult.Fail(new MissInputError(missInputs.Select(missInput =>
                new KeyValuePair<string, string>(missInput.Name, "Argument is required."))));
        }

        private static MethodResult<List<InputModel>> PairWithCommandAttributes(
            IEnumerable<InputModel> inputs,
            IEnumerable<KeyValuePair<PropertyInfo, InputAttribute>> commandAttributes) {
            var inputList = inputs.ToList();
            var commandAttributeList = commandAttributes.ToList();

            if (inputList.IsNullOrEmpty()) {
                return MethodResult<List<InputModel>>.Ok(new List<InputModel>());
            }

            var methodResult = inputList.SelectResults(input =>
                GetParameterName(input.ParameterName, commandAttributeList)
                    .OnSuccess(parameterName => EnsureValueTypeIsCorrect(input, commandAttributeList)
                        .OnSuccess(() => new InputModel(parameterName, input.Value))));
            return !methodResult.IsSuccess
                ? MethodResult<List<InputModel>>.Fail(methodResult.Detail)
                : MethodResult<List<InputModel>>.Ok(methodResult.Value);
        }

        private static MethodResult EnsureValueTypeIsCorrect(InputModel inputModel,
            IEnumerable<KeyValuePair<PropertyInfo, InputAttribute>> commandAttributes) {
            var targetCommandAttribute = commandAttributes
                .Single(commandAttribute =>
                    commandAttribute.Value.Name == inputModel.ParameterName);

            if (!targetCommandAttribute.Value.HasValue)
                return MethodResult.Ok();

            return targetCommandAttribute.Key.PropertyType == inputModel.Value!.GetType()
                ? MethodResult.Ok()
                : MethodResult.Fail(
                    new TypeMissMachError(
                        new KeyValuePair<string, string>(inputModel.ParameterName, "Type isn't valid")));
        }

        private static MethodResult<List<KeyValuePair<PropertyInfo, InputAttribute>>> GetCommandAttributes(
            Type commandClass) =>
            Utility.GetCommandInputs(commandClass)
                .OnSuccess(commandInputs => commandInputs
                    .Select(commandInput =>
                        new KeyValuePair<PropertyInfo, InputAttribute>(commandInput,
                            commandInput.GetCustomAttribute<InputAttribute>()!)).ToList());

        private static MethodResult ShowScopeCommandsHelp(Type targetScope) =>
            Utility.ScopeCommandsHelp(targetScope)
                .OnSuccess(helpStr => Console.WriteLine(helpStr));

        //TODO: Move private methods?

        private static MethodResult<IEnumerable<InputModel>> ParseInputs(
            IReadOnlyList<string> inputs) {
            var result = new List<InputModel>();

            for (var i = 0; i < inputs.Count; i++) {
                var input = inputs[i]!;

                // this input must be a flag
                var flagResult = Utility.IsFlag(input)
                    .OnSuccessFailWhen(isFlag => !isFlag, new BadRequestError(title: "Input Error",
                        message: "Key-Value structure isn't valid."));
                if (!flagResult.IsSuccess)
                    return MethodResult<IEnumerable<InputModel>>.Fail(flagResult.Detail);
                //======================================================================================

                //Break for if this item is last item (don't check next item that isn't exist!)
                if (i + 1 >= inputs.Count) {
                    result.Add(new InputModel(input, null));
                    break;
                }

                //Check next item
                var nextInput = inputs[i + 1];

                flagResult = Utility.IsFlag(nextInput);
                if (!flagResult.IsSuccess)
                    return MethodResult<IEnumerable<InputModel>>.Fail(flagResult.Detail);

                if (flagResult.Value) {
                    //Input is simple flag without value
                    result.Add(new InputModel(input, null));
                }
                else {
                    //Input has key-value structure.
                    result.Add(new InputModel(input, nextInput));
                    i++; //Skip from value
                }
            }

            return MethodResult<IEnumerable<InputModel>>.Ok(result);
        }

        private static MethodResult<string> GetParameterName(string flag,
            IEnumerable<KeyValuePair<PropertyInfo, InputAttribute>> commandAttributes) =>
            GetNameFromFlag(flag)
                .TryOnSuccess(pureName => commandAttributes.SingleOrDefault(
                    commandAttribute => commandAttribute.Value.ShortName == pureName))
                // .OnSuccessFailWhen(result => result is null, //TODO: ***
                //     new ArgumentValidationError(new KeyValuePair<string, string>(flag, "Parameter isn't valid.")))
                .OnSuccess(result => result.Value.Name);

        private static MethodResult<string> GetNameFromFlag(string flag) =>
            TryExtensions.Try(() => flag.StartsWith('-')
                ? flag.Remove(0, 1)
                : flag.Remove(0, 2));
    }
}