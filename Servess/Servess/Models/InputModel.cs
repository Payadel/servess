using System;

namespace servess.Models {
    public class InputModel {
        public string CliName { get; set; }
        public string ParameterName { get; set; }
        public object? Value { get; set; }

        public InputModel(string cliName, string parameterName, object? value) {
            CliName = cliName ?? throw new ArgumentNullException(nameof(cliName));
            ParameterName = parameterName ?? throw new ArgumentNullException(nameof(ParameterName));
            Value = value;
        }
    }
}