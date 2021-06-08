namespace servess.Attributes {
    [System.AttributeUsage(System.AttributeTargets.Method)]
    public class CommandAttribute : System.Attribute {
        public string Name { get; }
        public string Description { get; }

        public CommandAttribute(string name, string description) {
            Name = name.ToLower();
            Description = description.ToLower();
        }
    }
}