using System;

namespace servess.Models {
    public class InputModel {
        public string ParameterName { get; set; }
        public object? Value { get; set; }

        public InputModel(string parameterName, object? value) {
            ParameterName = parameterName ?? throw new ArgumentNullException(nameof(parameterName));
            Value = value;
        }
    }
}