using System;
using System.Collections;
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
                .OnSuccess(inputs => UpdateNamesWithPropertyNames(inputs, inputSchemes))
                .OnSuccess(inputs => EnsureArgumentCountValid(inputs, inputSchemes)
                    .OnSuccess(() => EnsureValueTypesAreCorrect(inputs, inputSchemes))
                    .OnSuccess(updatedInputs => EnsureRequireFlagsExist(updatedInputs, inputSchemes)
                        .OnSuccess(() => updatedInputs)));

        //Convert inputs to InputModel and ensures base structure is valid.
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

        private static MethodResult EnsureArgumentCountValid(IReadOnlyCollection<InputModel> inputModels,
            ICollection inputSchemes) {
            if (inputModels.Count > inputSchemes.Count) {
                return MethodResult.Fail(new BadRequestError(title: "Too many arguments",
                    message: $"maximum {inputSchemes.Count} inputs are expected."));
            }

            var uniqueItems = inputModels
                .Select(item => item.ParameterName)
                .Distinct()
                .Count();
            if (uniqueItems != inputModels.Count) {
                return MethodResult.Fail(new BadRequestError(title: "Duplicate Input",
                    message: $"Duplicate input is not allowed."));
            }

            return MethodResult.Ok();
        }

        private static MethodResult<List<InputModel>> UpdateNamesWithPropertyNames(
            IEnumerable<InputModel> inputs,
            IEnumerable<InputSchemeModel> inputSchemeModels) =>
            inputs.SelectResults(input =>
                UpdateParameterName(input, inputSchemeModels));

        private static MethodResult<List<InputModel>> EnsureValueTypesAreCorrect(IEnumerable<InputModel> inputModels,
            IEnumerable<InputSchemeModel> inputSchemes) =>
            inputModels.SelectResults(inputModel => EnsureValueTypeIsCorrect(inputModel, inputSchemes));

        private static MethodResult<InputModel> EnsureValueTypeIsCorrect(InputModel inputModel,
            IEnumerable<InputSchemeModel> inputSchemes) =>
            TryExtensions.Try(() => inputSchemes.Single(inputScheme =>
                    inputScheme.InputAttribute.ParameterName == inputModel.ParameterName))
                .OnFail(() => MethodResult<InputSchemeModel>.Fail(new ArgumentValidationError(
                    new KeyValuePair<string, string>(inputModel.CliName, "Argument isn't valid."))))
                .TryOnSuccess(targetSchemeModel => EnsureValueTypeIsCorrect(targetSchemeModel, inputModel))
                .OnFail(() => MethodResult<InputModel>.Fail(new ArgumentValidationError(
                    new KeyValuePair<string, string>(inputModel.CliName, "Value isn't valid."))));

        private static MethodResult<InputModel> EnsureValueTypeIsCorrect(InputSchemeModel schemeModel,
            InputModel inputModel) => schemeModel.InputAttribute.HasValue
            ? ChangeType(inputModel.Value, schemeModel.PropertyInfo.PropertyType)
                .OnSuccess(value =>
                    MethodResult<InputModel>.Ok(new InputModel(inputModel.CliName, inputModel.ParameterName, value)))
            : ValueMustNull(inputModel.Value)
                .OnSuccess(() => new InputModel(inputModel.CliName, inputModel.ParameterName, true));

        private static MethodResult<object?> ChangeType(object? value, Type targetType) =>
            TryExtensions.Try(() => Utility.IsNullable(targetType)
                ? Convert.ChangeType(value, Nullable.GetUnderlyingType(targetType)!)
                : Convert.ChangeType(value, targetType));


        private static MethodResult ValueMustNull(object? value) =>
            value is null
                ? MethodResult.Ok()
                : MethodResult.Fail(new BadRequestError());

        private static MethodResult EnsureRequireFlagsExist(IReadOnlyCollection<InputModel> inputModels,
            IEnumerable<InputSchemeModel> inputSchemeModels) {
            var missingParameters = (from inputSchemeModel in inputSchemeModels
                where inputSchemeModel.InputAttribute.IsRequired
                let requiredParameter = inputModels.SingleOrDefault(inputModel =>
                    inputModel.ParameterName == inputSchemeModel.InputAttribute.ParameterName)
                where requiredParameter?.Value is null
                select inputSchemeModel).ToList();

            if (missingParameters.Count > 0) {
                return MethodResult.Fail(new MissInputError(missingParameters.Select(missingParameter =>
                    new KeyValuePair<string, string>(missingParameter.InputAttribute.ParameterName,
                        "Argument is required."))));
            }

            return MethodResult.Ok();
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
                    new InputModel(inputModel.CliName,
                        inputSchemeModel!.InputAttribute.ParameterName, inputModel.Value));

        private static MethodResult<string> GetNameFromFlag(string flag) =>
            TryExtensions.Try(() => flag.StartsWith('-')
                ? flag.Remove(0, 1) // -name
                : flag.Remove(0, 2)); // --name
    }
}