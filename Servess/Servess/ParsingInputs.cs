using System;
using System.Collections.Generic;
using System.Linq;
using FunctionalUtility.Extensions;
using FunctionalUtility.ResultDetails.Errors;
using FunctionalUtility.ResultUtility;
using ModelsValidation.ResultDetails;
using servess.MethodErrors;
using servess.Models;

//TODO: Check inputs

namespace servess {
    public static class ParsingInputs {
        public static MethodResult<List<InputModel>> Parse(List<string> args, List<InputSchemeModel> inputSchemes) =>
            ParseInputs(args)
                .OnSuccess(inputs => PairWithCommandAttributes(inputs, inputSchemes)
                    .OnSuccess(inputList => EnsureRequireFlagsExist(inputList, inputSchemes)
                        .OnSuccess(() => inputList)));

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

                //Break for, if this item is last item (don't check next item that isn't exist!)
                if (i + 1 >= inputs.Count) {
                    result.Add(new InputModel(input, input, null));
                    break;
                }

                //Check next item
                var nextInput = inputs[i + 1];

                flagResult = Utility.IsFlag(nextInput);
                if (!flagResult.IsSuccess)
                    return MethodResult<IEnumerable<InputModel>>.Fail(flagResult.Detail);

                if (flagResult.Value) {
                    //Input is simple flag without value
                    result.Add(new InputModel(input, input, null));
                }
                else {
                    //Input has key-value structure.
                    result.Add(new InputModel(input, input, nextInput));
                    i++; //Skip from value
                }
            }

            return MethodResult<IEnumerable<InputModel>>.Ok(result);
        }

        private static MethodResult<List<InputModel>> PairWithCommandAttributes(
            IEnumerable<InputModel> inputs,
            IEnumerable<InputSchemeModel> inputSchemeModels) {
            var inputList = inputs.ToList();
            var inputSchemeList = inputSchemeModels.ToList();

            if (inputList.IsNullOrEmpty()) {
                return MethodResult<List<InputModel>>.Ok(inputList);
            }

            var methodResult = inputList.SelectResults(input =>
                UpdateParameterName(input, inputSchemeList)
                    .OnSuccess(updatedInput => EnsureValueTypeIsCorrect(updatedInput, inputSchemeList)));
            return !methodResult.IsSuccess
                ? MethodResult<List<InputModel>>.Fail(methodResult.Detail)
                : MethodResult<List<InputModel>>.Ok(methodResult.Value);
        }

        private static MethodResult<InputModel> EnsureValueTypeIsCorrect(InputModel inputModel,
            IEnumerable<InputSchemeModel> commandAttributes) {
            var targetCommandAttribute = commandAttributes
                .Single(commandAttribute =>
                    commandAttribute.InputAttribute.CliName == inputModel.CliName);

            if (!targetCommandAttribute.InputAttribute.HasValue)
                return MethodResult<InputModel>.Ok(inputModel);

            try {
                var value = Convert.ChangeType(inputModel.Value, targetCommandAttribute.PropertyInfo.PropertyType);
                return MethodResult<InputModel>.Ok(new InputModel(inputModel.CliName, inputModel.ParameterName, value));
            }
            catch (Exception) {
                return MethodResult<InputModel>.Fail(
                    new TypeMissMachError(
                        new KeyValuePair<string, string>(inputModel.CliName, "Type isn't valid")));
            }
        }

        private static MethodResult EnsureRequireFlagsExist(IEnumerable<InputModel> inputModels,
            IEnumerable<InputSchemeModel> commandAttributes) {
            var missInputs = commandAttributes.Where(commandAttribute =>
                    commandAttribute.InputAttribute.IsRequired &&
                    inputModels.All(input => input.CliName != commandAttribute.InputAttribute.CliName))
                .Select(commandAttribute => commandAttribute.InputAttribute).ToList();
            if (!missInputs.Any()) {
                return MethodResult.Ok();
            }

            return MethodResult.Fail(new MissInputError(missInputs.Select(missInput =>
                new KeyValuePair<string, string>(missInput.CliName, "Argument is required."))));
        }

        private static MethodResult<InputModel> UpdateParameterName(InputModel inputModel,
            IEnumerable<InputSchemeModel> inputSchemeModels) =>
            GetNameFromFlag(inputModel.CliName)
                .TryOnSuccess(pureName => inputSchemeModels.SingleOrDefault(
                    inputSchemeModel => inputSchemeModel.InputAttribute.ShortName == pureName))
                .OnSuccessFailWhen(inputSchemeModel => inputSchemeModel is null, //TODO: Check
                    new ArgumentValidationError(new KeyValuePair<string, string>(inputModel.CliName,
                        "Parameter isn't valid.")))
                .OnSuccess(inputSchemeModel =>
                    new InputModel(inputSchemeModel!.InputAttribute.CliName,
                        inputSchemeModel.InputAttribute.ParameterName, inputModel.Value));

        private static MethodResult<string> GetNameFromFlag(string flag) =>
            TryExtensions.Try(() => flag.StartsWith('-')
                ? flag.Remove(0, 1)
                : flag.Remove(0, 2));
    }
}