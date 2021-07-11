namespace servess.Attributes {
    [System.AttributeUsage(System.AttributeTargets.Class)]
    public class CommandAttribute : System.Attribute {
        public string Name { get; }
        public string Description { get; }

        public CommandAttribute(string name, string description) {
            Name = name.ToLower();
            Description = description;
        }
    }
}