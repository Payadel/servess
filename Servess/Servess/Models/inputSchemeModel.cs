﻿using System;
using System.Reflection;
using Servess.Attributes;

namespace Servess.Models {
    public class InputSchemeModel {
        public PropertyInfo PropertyInfo { get; }
        public InputAttribute InputAttribute { get; }

        public InputSchemeModel(PropertyInfo propertyInfo, InputAttribute inputAttribute) {
            PropertyInfo = propertyInfo ?? throw new ArgumentNullException(nameof(propertyInfo));
            InputAttribute = inputAttribute ?? throw new ArgumentNullException(nameof(inputAttribute));
        }
    }
}