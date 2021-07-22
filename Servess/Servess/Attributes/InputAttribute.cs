namespace Servess.Attributes {
    [System.AttributeUsage(System.AttributeTargets.Property)]
    public class InputAttribute : System.Attribute {
        public string CliName { get; }
        public string ShortName { get; }
        public string Description { get; } //TODO: Generate auto help text
        public string ParameterName { get; }
        public bool IsRequired { get; }
        public bool HasValue { get; } //TODO: Only boolean type can hasn't value

        public InputAttribute(string cliName, string shortName, string description, string parameterName,
            bool isRequired = true,
            bool hasValue = true) {
            CliName = cliName.ToLower();
            ShortName = shortName.ToLower();
            Description = description;
            ParameterName = parameterName;
            IsRequired = isRequired;
            HasValue = hasValue;
        }
    }
}