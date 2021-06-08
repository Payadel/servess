namespace servess.Attributes {
    [System.AttributeUsage(System.AttributeTargets.Class)]
    public class ScopeAttribute : System.Attribute {
        public string Name { get; }
        public string Description { get; }

        public ScopeAttribute(string name, string description) {
            Name = name.ToLower();
            Description = description.ToLower();
        }
    }
}