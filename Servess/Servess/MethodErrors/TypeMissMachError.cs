using System;
using System.Collections.Generic;
using ModelsValidation.ResultDetails;

namespace Servess.MethodErrors {
    public class TypeMissMachError : ArgumentValidationError {
        public TypeMissMachError(KeyValuePair<string, string> modelError, string? title = "Type Mismatch",
            string? message = null, Exception? exception = null, bool showDefaultMessageToUser = true,
            object? moreDetail = null) : base(modelError, title, message, exception, showDefaultMessageToUser,
            moreDetail) { }

        public TypeMissMachError(IEnumerable<KeyValuePair<string, string>> modelErrors, string? title = "Type Mismatch",
            string? message = null, Exception? exception = null, bool showDefaultMessageToUser = true,
            object? moreDetail = null) : base(modelErrors, title, message, exception, showDefaultMessageToUser,
            moreDetail) { }
    }
}