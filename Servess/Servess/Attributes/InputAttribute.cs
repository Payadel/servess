namespace servess.Attributes {
    [System.AttributeUsage(System.AttributeTargets.Property)]
    public class InputAttribute : System.Attribute {
        public string Name { get; }
        public string ShortName { get; }
        public string Description { get; } //TODO: Generate auto help text
        public bool IsRequired { get; }
        public bool HasValue { get; }

        public InputAttribute(string name, string shortName, string description, bool isRequired = true,
            bool hasValue = true) {
            Name = name.ToLower();
            ShortName = shortName.ToLower();
            Description = description;
            IsRequired = isRequired;
            HasValue = hasValue;
        }
    }
}